//
//  SSLCertificateInfo.swift
//  Server
//
//  Created by Claude on 1/27/26.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class SSLCertificateInfo {
    var id: UUID
    var serverId: UUID

    // Certificate details
    var commonName: String?
    var issuer: String?
    var organization: String?
    var serialNumber: String?
    var signatureAlgorithm: String?

    // Validity
    var validFrom: Date?
    var validUntil: Date?
    var isValid: Bool

    // Chain info
    var chainLength: Int
    var isChainComplete: Bool

    // Subject Alternative Names
    var subjectAltNames: [String]

    // Tracking
    var lastChecked: Date
    var checkError: String?

    init(
        id: UUID = UUID(),
        serverId: UUID,
        commonName: String? = nil,
        issuer: String? = nil,
        organization: String? = nil,
        serialNumber: String? = nil,
        signatureAlgorithm: String? = nil,
        validFrom: Date? = nil,
        validUntil: Date? = nil,
        isValid: Bool = false,
        chainLength: Int = 0,
        isChainComplete: Bool = false,
        subjectAltNames: [String] = [],
        lastChecked: Date = Date(),
        checkError: String? = nil
    ) {
        self.id = id
        self.serverId = serverId
        self.commonName = commonName
        self.issuer = issuer
        self.organization = organization
        self.serialNumber = serialNumber
        self.signatureAlgorithm = signatureAlgorithm
        self.validFrom = validFrom
        self.validUntil = validUntil
        self.isValid = isValid
        self.chainLength = chainLength
        self.isChainComplete = isChainComplete
        self.subjectAltNames = subjectAltNames
        self.lastChecked = lastChecked
        self.checkError = checkError
    }

    // MARK: - Computed Properties

    var daysUntilExpiry: Int? {
        guard let validUntil = validUntil else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: validUntil).day
    }

    var expiryStatus: SSLExpiryStatus {
        guard let days = daysUntilExpiry else { return .unknown }
        if days < 0 { return .expired }
        if days <= 7 { return .critical }
        if days <= 30 { return .warning }
        if days <= 90 { return .attention }
        return .healthy
    }

    var formattedExpiry: String {
        guard let validUntil = validUntil else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: validUntil)
    }

    var formattedDaysRemaining: String {
        guard let days = daysUntilExpiry else { return "Unknown" }
        if days < 0 {
            return "Expired \(abs(days)) days ago"
        } else if days == 0 {
            return "Expires today"
        } else if days == 1 {
            return "1 day remaining"
        } else {
            return "\(days) days remaining"
        }
    }
}

// MARK: - SSL Expiry Status

enum SSLExpiryStatus: String {
    case healthy = "Healthy"
    case attention = "Attention"
    case warning = "Warning"
    case critical = "Critical"
    case expired = "Expired"
    case unknown = "Unknown"
    case error = "Error"

    var color: Color {
        switch self {
        case .healthy: return .green
        case .attention: return .blue
        case .warning: return .orange
        case .critical, .expired: return .red
        case .unknown, .error: return .gray
        }
    }

    var icon: String {
        switch self {
        case .healthy: return "lock.fill"
        case .attention: return "lock.fill"
        case .warning: return "exclamationmark.lock.fill"
        case .critical, .expired: return "lock.slash.fill"
        case .unknown, .error: return "lock.open.fill"
        }
    }

    var description: String {
        switch self {
        case .healthy: return "Certificate valid for more than 90 days"
        case .attention: return "Certificate expires within 90 days"
        case .warning: return "Certificate expires within 30 days"
        case .critical: return "Certificate expires within 7 days"
        case .expired: return "Certificate has expired"
        case .unknown: return "Certificate status unknown"
        case .error: return "Error checking certificate"
        }
    }
}

// MARK: - SSL Alert Thresholds

struct SSLAlertThresholds {
    var alertAt90Days: Bool = true
    var alertAt30Days: Bool = true
    var alertAt7Days: Bool = true
    var alertOnExpired: Bool = true
    var alertOnInvalid: Bool = true

    static let `default` = SSLAlertThresholds()

    func shouldAlert(for certificate: SSLCertificateInfo) -> Bool {
        guard let days = certificate.daysUntilExpiry else {
            return alertOnInvalid && !certificate.isValid
        }

        if days < 0 && alertOnExpired { return true }
        if days <= 7 && alertAt7Days { return true }
        if days <= 30 && alertAt30Days { return true }
        if days <= 90 && alertAt90Days { return true }

        return false
    }
}
