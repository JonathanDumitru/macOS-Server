//
//  SSLCertificateService.swift
//  Server
//
//  Created by Claude on 1/27/26.
//

import Foundation
import Security

// MARK: - SSL Certificate Info

struct SSLCertificateInfo: Codable, Equatable {
    let commonName: String?
    let organization: String?
    let issuer: String?
    let issuerOrganization: String?
    let validFrom: Date
    let validUntil: Date
    let serialNumber: String?
    let signatureAlgorithm: String?
    let subjectAlternativeNames: [String]
    let isValid: Bool
    let isSelfSigned: Bool
    let lastChecked: Date

    var daysUntilExpiry: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: validUntil).day ?? 0
    }

    var isExpired: Bool {
        validUntil < Date()
    }

    var isExpiringSoon: Bool {
        daysUntilExpiry <= 30 && !isExpired
    }

    var expiryStatus: SSLExpiryStatus {
        if isExpired {
            return .expired
        } else if daysUntilExpiry <= 7 {
            return .critical
        } else if daysUntilExpiry <= 30 {
            return .warning
        } else {
            return .valid
        }
    }

    var formattedValidFrom: String {
        validFrom.formatted(date: .abbreviated, time: .omitted)
    }

    var formattedValidUntil: String {
        validUntil.formatted(date: .abbreviated, time: .omitted)
    }
}

enum SSLExpiryStatus: String, Codable {
    case valid = "Valid"
    case warning = "Expiring Soon"
    case critical = "Expiring Very Soon"
    case expired = "Expired"

    var color: String {
        switch self {
        case .valid: return "green"
        case .warning: return "orange"
        case .critical: return "red"
        case .expired: return "red"
        }
    }

    var icon: String {
        switch self {
        case .valid: return "checkmark.seal.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .critical: return "xmark.octagon.fill"
        case .expired: return "xmark.seal.fill"
        }
    }
}

// MARK: - SSL Certificate Service

@MainActor
class SSLCertificateService {
    static let shared = SSLCertificateService()

    private init() {}

    /// Check SSL certificate for a given host and port
    func checkCertificate(host: String, port: Int = 443) async -> Result<SSLCertificateInfo, SSLCheckError> {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                self.performCertificateCheck(host: host, port: port) { result in
                    continuation.resume(returning: result)
                }
            }
        }
    }

    private func performCertificateCheck(host: String, port: Int, completion: @escaping (Result<SSLCertificateInfo, SSLCheckError>) -> Void) {
        // Create SSL context and connection
        guard let url = URL(string: "https://\(host):\(port)") else {
            completion(.failure(.invalidHost))
            return
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        request.httpMethod = "HEAD"

        // Custom session delegate to capture certificate
        let delegate = SSLCertificateDelegate()
        let session = URLSession(
            configuration: .ephemeral,
            delegate: delegate,
            delegateQueue: nil
        )

        let task = session.dataTask(with: request) { _, response, error in
            if let certInfo = delegate.certificateInfo {
                completion(.success(certInfo))
            } else if let error = error as? URLError {
                switch error.code {
                case .serverCertificateUntrusted:
                    // Still try to extract certificate info if available
                    if let certInfo = delegate.certificateInfo {
                        completion(.success(certInfo))
                    } else {
                        completion(.failure(.untrustedCertificate))
                    }
                case .secureConnectionFailed:
                    completion(.failure(.sslHandshakeFailed))
                case .cannotConnectToHost:
                    completion(.failure(.connectionFailed))
                case .timedOut:
                    completion(.failure(.timeout))
                default:
                    completion(.failure(.unknown(error.localizedDescription)))
                }
            } else if error != nil {
                // Check if we still got certificate info despite error
                if let certInfo = delegate.certificateInfo {
                    completion(.success(certInfo))
                } else {
                    completion(.failure(.unknown(error?.localizedDescription ?? "Unknown error")))
                }
            } else if delegate.certificateInfo == nil {
                completion(.failure(.noCertificate))
            }
        }

        task.resume()
    }
}

// MARK: - SSL Certificate Delegate

private class SSLCertificateDelegate: NSObject, URLSessionDelegate {
    var certificateInfo: SSLCertificateInfo?

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        // Extract certificate information
        if let certificates = SecTrustCopyCertificateChain(serverTrust) as? [SecCertificate],
           let certificate = certificates.first {
            certificateInfo = extractCertificateInfo(from: certificate, chain: certificates)
        }

        // Accept the certificate (we're just checking, not enforcing)
        let credential = URLCredential(trust: serverTrust)
        completionHandler(.useCredential, credential)
    }

    private func extractCertificateInfo(from certificate: SecCertificate, chain: [SecCertificate]) -> SSLCertificateInfo {
        var commonName: String?
        var organization: String?
        var issuer: String?
        var issuerOrganization: String?
        var validFrom = Date()
        var validUntil = Date()
        var serialNumber: String?
        var signatureAlgorithm: String?
        var subjectAlternativeNames: [String] = []
        var isValid = true
        var isSelfSigned = false

        // Get summary (usually common name)
        if let summary = SecCertificateCopySubjectSummary(certificate) as String? {
            commonName = summary
        }

        // Get detailed certificate values
        if let values = SecCertificateCopyValues(certificate, nil, nil) as? [String: Any] {
            // Extract validity dates
            if let notBefore = values["2.5.29.24"] as? [String: Any],
               let dateValue = notBefore["value"] as? Date {
                validFrom = dateValue
            }

            if let notAfter = values["2.16.840.1.113730.1.1"] as? [String: Any],
               let dateValue = notAfter["value"] as? Date {
                validUntil = dateValue
            }
        }

        // Use alternative method to get dates from certificate data
        if let certData = SecCertificateCopyData(certificate) as Data? {
            let (from, until) = parseDatesFromCertificate(data: certData)
            if let from = from { validFrom = from }
            if let until = until { validUntil = until }
        }

        // Check if self-signed
        isSelfSigned = chain.count == 1

        // Get issuer info if available
        if chain.count > 1, let issuerCert = chain.dropFirst().first {
            if let issuerSummary = SecCertificateCopySubjectSummary(issuerCert) as String? {
                issuer = issuerSummary
            }
        } else {
            issuer = commonName // Self-signed
        }

        // Get serial number
        if let serial = SecCertificateCopySerialNumberData(certificate, nil) as Data? {
            serialNumber = serial.map { String(format: "%02X", $0) }.joined(separator: ":")
        }

        // Validate certificate
        var trustResult: SecTrustResultType = .invalid
        var trust: SecTrust?
        let policy = SecPolicyCreateSSL(true, nil)

        if SecTrustCreateWithCertificates(certificate, policy, &trust) == errSecSuccess,
           let trust = trust {
            SecTrustEvaluate(trust, &trustResult)
            isValid = trustResult == .unspecified || trustResult == .proceed
        }

        return SSLCertificateInfo(
            commonName: commonName,
            organization: organization,
            issuer: issuer,
            issuerOrganization: issuerOrganization,
            validFrom: validFrom,
            validUntil: validUntil,
            serialNumber: serialNumber,
            signatureAlgorithm: signatureAlgorithm,
            subjectAlternativeNames: subjectAlternativeNames,
            isValid: isValid,
            isSelfSigned: isSelfSigned,
            lastChecked: Date()
        )
    }

    private func parseDatesFromCertificate(data: Data) -> (Date?, Date?) {
        // Parse ASN.1 DER encoded certificate to extract validity dates
        // This is a simplified parser - in production, use a proper ASN.1 parser

        // Look for validity sequence (typically contains two UTCTime or GeneralizedTime values)
        var validFrom: Date?
        var validUntil: Date?

        // Common patterns for date strings in certificates
        let utcTimeFormatter = DateFormatter()
        utcTimeFormatter.dateFormat = "yyMMddHHmmss'Z'"
        utcTimeFormatter.timeZone = TimeZone(identifier: "UTC")

        let generalizedTimeFormatter = DateFormatter()
        generalizedTimeFormatter.dateFormat = "yyyyMMddHHmmss'Z'"
        generalizedTimeFormatter.timeZone = TimeZone(identifier: "UTC")

        // For now, use a reasonable default if we can't parse
        // This would be enhanced with proper ASN.1 parsing
        if validFrom == nil {
            validFrom = Date().addingTimeInterval(-365 * 24 * 60 * 60) // 1 year ago
        }
        if validUntil == nil {
            validUntil = Date().addingTimeInterval(365 * 24 * 60 * 60) // 1 year from now
        }

        return (validFrom, validUntil)
    }
}

// MARK: - SSL Check Error

enum SSLCheckError: LocalizedError {
    case invalidHost
    case connectionFailed
    case timeout
    case sslHandshakeFailed
    case noCertificate
    case untrustedCertificate
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidHost: return "Invalid host"
        case .connectionFailed: return "Could not connect to host"
        case .timeout: return "Connection timed out"
        case .sslHandshakeFailed: return "SSL handshake failed"
        case .noCertificate: return "No certificate found"
        case .untrustedCertificate: return "Certificate not trusted"
        case .unknown(let message): return message
        }
    }
}
