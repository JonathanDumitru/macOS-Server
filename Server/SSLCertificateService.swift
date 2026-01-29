//
//  SSLCertificateService.swift
//  Server
//
//  Created by Claude on 1/27/26.
//

import Foundation
import Security

class SSLCertificateService {
    static let shared = SSLCertificateService()

    private init() {}

    // MARK: - Check Certificate

    func checkCertificate(host: String, port: Int = 443) async throws -> SSLCertificateInfo {
        let info = SSLCertificateInfo(serverId: UUID())

        guard let url = URL(string: "https://\(host):\(port)") else {
            info.checkError = "Invalid host"
            info.isValid = false
            return info
        }

        let delegate = SSLSessionDelegate()
        let session = URLSession(
            configuration: .ephemeral,
            delegate: delegate,
            delegateQueue: nil
        )

        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 10

        do {
            let (_, response) = try await session.data(for: request)

            if let _ = response as? HTTPURLResponse,
               let certInfo = delegate.certificateInfo {
                // Copy certificate info
                info.commonName = certInfo.commonName
                info.issuer = certInfo.issuer
                info.organization = certInfo.organization
                info.serialNumber = certInfo.serialNumber
                info.signatureAlgorithm = certInfo.signatureAlgorithm
                info.validFrom = certInfo.validFrom
                info.validUntil = certInfo.validUntil
                info.isValid = certInfo.isValid
                info.chainLength = certInfo.chainLength
                info.isChainComplete = certInfo.isChainComplete
                info.subjectAltNames = certInfo.subjectAltNames
                info.lastChecked = Date()
            }
        } catch {
            info.checkError = error.localizedDescription
            info.isValid = false

            // Try to get certificate info even if connection fails
            if let certInfo = delegate.certificateInfo {
                info.commonName = certInfo.commonName
                info.issuer = certInfo.issuer
                info.validFrom = certInfo.validFrom
                info.validUntil = certInfo.validUntil
            }
        }

        session.invalidateAndCancel()
        return info
    }

    // MARK: - Parse Certificate

    func parseCertificateDetails(from certificate: SecCertificate) -> CertificateDetails {
        var details = CertificateDetails()

        // Get subject summary (common name)
        if let summary = SecCertificateCopySubjectSummary(certificate) as String? {
            details.commonName = summary
        }

        // Get certificate data
        let certData = SecCertificateCopyData(certificate) as Data

        // Parse using Security framework
        var error: Unmanaged<CFError>?
        if let values = SecCertificateCopyValues(certificate, nil, &error) as? [CFString: Any] {
            // Extract NotBefore
            if let notBefore = values[kSecOIDX509V1ValidityNotBefore] as? [String: Any],
               let value = notBefore[kSecPropertyKeyValue as String] as? Double {
                details.validFrom = Date(timeIntervalSinceReferenceDate: value)
            }

            // Extract NotAfter
            if let notAfter = values[kSecOIDX509V1ValidityNotAfter] as? [String: Any],
               let value = notAfter[kSecPropertyKeyValue as String] as? Double {
                details.validUntil = Date(timeIntervalSinceReferenceDate: value)
            }

            // Extract Issuer
            if let issuerDict = values[kSecOIDX509V1IssuerName] as? [String: Any],
               let issuerValues = issuerDict[kSecPropertyKeyValue as String] as? [[String: Any]] {
                for item in issuerValues {
                    if let label = item[kSecPropertyKeyLabel as String] as? String,
                       let value = item[kSecPropertyKeyValue as String] as? String {
                        if label == "2.5.4.3" || label.contains("Common Name") {
                            details.issuer = value
                        } else if label == "2.5.4.10" || label.contains("Organization") {
                            details.organization = value
                        }
                    }
                }
            }

            // Extract Serial Number
            if let serialDict = values[kSecOIDX509V1SerialNumber] as? [String: Any],
               let serialData = serialDict[kSecPropertyKeyValue as String] as? Data {
                details.serialNumber = serialData.map { String(format: "%02X", $0) }.joined(separator: ":")
            }

            // Extract Signature Algorithm
            if let sigAlgDict = values[kSecOIDX509V1SignatureAlgorithm] as? [String: Any],
               let sigAlgValue = sigAlgDict[kSecPropertyKeyValue as String] as? String {
                details.signatureAlgorithm = sigAlgValue
            }

            // Extract Subject Alternative Names
            if let sanDict = values[kSecOIDSubjectAltName] as? [String: Any],
               let sanValues = sanDict[kSecPropertyKeyValue as String] as? [[String: Any]] {
                for item in sanValues {
                    if let value = item[kSecPropertyKeyValue as String] as? String {
                        details.subjectAltNames.append(value)
                    }
                }
            }
        }

        return details
    }
}

// MARK: - SSL Session Delegate

private class SSLSessionDelegate: NSObject, URLSessionDelegate {
    var certificateInfo: SSLCertificateInfo?

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        let info = SSLCertificateInfo(serverId: UUID())

        // Get certificate count
        let certificateCount = SecTrustGetCertificateCount(serverTrust)
        info.chainLength = certificateCount

        // Get the leaf certificate (server certificate)
        if certificateCount > 0,
           let certificate = SecTrustGetCertificateAtIndex(serverTrust, 0) {
            let details = SSLCertificateService.shared.parseCertificateDetails(from: certificate)
            info.commonName = details.commonName
            info.issuer = details.issuer
            info.organization = details.organization
            info.serialNumber = details.serialNumber
            info.signatureAlgorithm = details.signatureAlgorithm
            info.validFrom = details.validFrom
            info.validUntil = details.validUntil
            info.subjectAltNames = details.subjectAltNames
        }

        // Evaluate trust
        var secResult: SecTrustResultType = .invalid
        SecTrustEvaluate(serverTrust, &secResult)

        info.isValid = secResult == .unspecified || secResult == .proceed
        info.isChainComplete = certificateCount > 1

        // Check expiry
        if let validUntil = info.validUntil {
            let isExpired = validUntil < Date()
            if isExpired {
                info.isValid = false
            }
        }

        info.lastChecked = Date()
        self.certificateInfo = info

        completionHandler(.useCredential, URLCredential(trust: serverTrust))
    }
}

// MARK: - Certificate Details

struct CertificateDetails {
    var commonName: String?
    var issuer: String?
    var organization: String?
    var serialNumber: String?
    var signatureAlgorithm: String?
    var validFrom: Date?
    var validUntil: Date?
    var subjectAltNames: [String] = []
}

// MARK: - SSL Errors

enum SSLError: LocalizedError {
    case invalidHost
    case connectionFailed
    case certificateParsingFailed
    case certificateExpired
    case certificateInvalid

    var errorDescription: String? {
        switch self {
        case .invalidHost: return "Invalid host address"
        case .connectionFailed: return "Could not establish SSL connection"
        case .certificateParsingFailed: return "Failed to parse certificate"
        case .certificateExpired: return "Certificate has expired"
        case .certificateInvalid: return "Certificate is invalid"
        }
    }
}
