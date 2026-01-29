//
//  SSLStatusBadge.swift
//  Server
//
//  Created by Claude on 1/27/26.
//

import SwiftUI

struct SSLStatusBadge: View {
    let certificate: SSLCertificateInfo?
    var showLabel: Bool = true
    var size: BadgeSize = .regular

    enum BadgeSize {
        case small
        case regular
        case large

        var iconSize: CGFloat {
            switch self {
            case .small: return 9
            case .regular: return 11
            case .large: return 14
            }
        }

        var fontSize: CGFloat {
            switch self {
            case .small: return 9
            case .regular: return 10
            case .large: return 12
            }
        }

        var padding: CGFloat {
            switch self {
            case .small: return 4
            case .regular: return 6
            case .large: return 8
            }
        }
    }

    var body: some View {
        if let cert = certificate {
            HStack(spacing: 3) {
                Image(systemName: cert.expiryStatus.icon)
                    .font(.system(size: size.iconSize, weight: .medium))

                if showLabel {
                    if let days = cert.daysUntilExpiry {
                        if days < 0 {
                            Text("Expired")
                                .font(.system(size: size.fontSize, weight: .medium))
                        } else {
                            Text("\(days)d")
                                .font(.system(size: size.fontSize, weight: .medium))
                        }
                    } else {
                        Text(cert.isValid ? "Valid" : "Invalid")
                            .font(.system(size: size.fontSize, weight: .medium))
                    }
                }
            }
            .foregroundStyle(cert.expiryStatus.color)
            .padding(.horizontal, size.padding)
            .padding(.vertical, size.padding / 2)
            .background(cert.expiryStatus.color.opacity(0.12), in: Capsule())
            .help(cert.formattedDaysRemaining)
        } else {
            HStack(spacing: 3) {
                Image(systemName: "lock.open.fill")
                    .font(.system(size: size.iconSize))
                if showLabel {
                    Text("N/A")
                        .font(.system(size: size.fontSize, weight: .medium))
                }
            }
            .foregroundStyle(.tertiary)
            .padding(.horizontal, size.padding)
            .padding(.vertical, size.padding / 2)
            .background(Color.secondary.opacity(0.08), in: Capsule())
        }
    }
}

// MARK: - SSL Expiry Countdown Badge

struct SSLExpiryCountdown: View {
    let certificate: SSLCertificateInfo

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: certificate.expiryStatus.icon)
                .font(.system(size: 20))
                .foregroundStyle(certificate.expiryStatus.color)

            VStack(alignment: .leading, spacing: 2) {
                Text(certificate.formattedDaysRemaining)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(certificate.expiryStatus.color)

                if let validUntil = certificate.validUntil {
                    Text("Expires: \(validUntil, format: .dateTime.month().day().year())")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(certificate.expiryStatus.color.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(certificate.expiryStatus.color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - SSL Status Card

struct SSLStatusCard: View {
    let certificate: SSLCertificateInfo?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: certificate?.expiryStatus.icon ?? "lock.open.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(certificate?.expiryStatus.color ?? .gray)

                VStack(alignment: .leading, spacing: 2) {
                    Text("SSL Certificate")
                        .font(.system(size: 14, weight: .semibold))

                    Text(certificate?.expiryStatus.rawValue ?? "Not Available")
                        .font(.system(size: 12))
                        .foregroundStyle(certificate?.expiryStatus.color ?? .secondary)
                }

                Spacer()

                if let cert = certificate {
                    SSLStatusBadge(certificate: cert, size: .large)
                }
            }

            Divider()

            if let cert = certificate {
                // Certificate details
                VStack(alignment: .leading, spacing: 8) {
                    if let commonName = cert.commonName {
                        SSLInfoRow(label: "Common Name", value: commonName)
                    }

                    if let issuer = cert.issuer {
                        SSLInfoRow(label: "Issuer", value: issuer)
                    }

                    if let validUntil = cert.validUntil {
                        SSLInfoRow(
                            label: "Expires",
                            value: validUntil.formatted(date: .abbreviated, time: .omitted),
                            valueColor: cert.expiryStatus.color
                        )
                    }

                    SSLInfoRow(label: "Valid", value: cert.isValid ? "Yes" : "No")
                }
            } else {
                Text("No SSL certificate information available")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        )
    }
}

private struct SSLInfoRow: View {
    let label: String
    let value: String
    var valueColor: Color = .primary

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(valueColor)
                .lineLimit(1)
        }
    }
}

// MARK: - Preview

#Preview("SSL Badges") {
    let healthyCert = SSLCertificateInfo(
        serverId: UUID(),
        commonName: "example.com",
        validUntil: Calendar.current.date(byAdding: .day, value: 120, to: Date()),
        isValid: true
    )

    let warningCert = SSLCertificateInfo(
        serverId: UUID(),
        commonName: "example.com",
        validUntil: Calendar.current.date(byAdding: .day, value: 15, to: Date()),
        isValid: true
    )

    let criticalCert = SSLCertificateInfo(
        serverId: UUID(),
        commonName: "example.com",
        validUntil: Calendar.current.date(byAdding: .day, value: 3, to: Date()),
        isValid: true
    )

    let expiredCert = SSLCertificateInfo(
        serverId: UUID(),
        commonName: "example.com",
        validUntil: Calendar.current.date(byAdding: .day, value: -5, to: Date()),
        isValid: false
    )

    return VStack(spacing: 16) {
        HStack(spacing: 12) {
            SSLStatusBadge(certificate: healthyCert)
            SSLStatusBadge(certificate: warningCert)
            SSLStatusBadge(certificate: criticalCert)
            SSLStatusBadge(certificate: expiredCert)
            SSLStatusBadge(certificate: nil)
        }

        SSLExpiryCountdown(certificate: warningCert)

        SSLStatusCard(certificate: healthyCert)
    }
    .padding()
    .frame(width: 400)
}
