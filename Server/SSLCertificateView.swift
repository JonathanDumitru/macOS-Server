//
//  SSLCertificateView.swift
//  Server
//
//  Created by Claude on 1/27/26.
//

import SwiftUI
import SwiftData

struct SSLCertificateView: View {
    let server: Server
    @State private var isLoading = false
    @State private var checkError: String?

    var certificate: SSLCertificateInfo? {
        server.sslCertificate
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Status Header
                if let cert = certificate {
                    SSLExpiryCountdown(certificate: cert)
                } else {
                    noSSLView
                }

                // Certificate Details
                if let cert = certificate {
                    certificateDetailsSection(cert)
                    validitySection(cert)
                    chainInfoSection(cert)

                    if !cert.subjectAltNames.isEmpty {
                        subjectAltNamesSection(cert)
                    }
                }

                // Actions
                actionsSection

                // Last Check Info
                if let cert = certificate {
                    lastCheckSection(cert)
                }
            }
            .padding()
        }
    }

    // MARK: - No SSL View

    private var noSSLView: some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.open.fill")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            if server.serverType != .https {
                Text("SSL not applicable")
                    .font(.system(size: 14, weight: .semibold))
                Text("This server is not using HTTPS")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            } else {
                Text("No SSL Certificate Data")
                    .font(.system(size: 14, weight: .semibold))
                Text("Check the certificate to retrieve details")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }

    // MARK: - Certificate Details Section

    private func certificateDetailsSection(_ cert: SSLCertificateInfo) -> some View {
        GroupBox("Certificate Details") {
            VStack(alignment: .leading, spacing: 10) {
                if let commonName = cert.commonName {
                    DetailRow(label: "Common Name", value: commonName)
                }

                if let issuer = cert.issuer {
                    DetailRow(label: "Issuer", value: issuer)
                }

                if let org = cert.organization {
                    DetailRow(label: "Organization", value: org)
                }

                if let serial = cert.serialNumber {
                    DetailRow(label: "Serial Number", value: serial, isMonospace: true)
                }

                if let sigAlg = cert.signatureAlgorithm {
                    DetailRow(label: "Signature Algorithm", value: sigAlg)
                }
            }
            .padding(8)
        }
    }

    // MARK: - Validity Section

    private func validitySection(_ cert: SSLCertificateInfo) -> some View {
        GroupBox("Validity Period") {
            VStack(alignment: .leading, spacing: 10) {
                if let validFrom = cert.validFrom {
                    DetailRow(
                        label: "Valid From",
                        value: validFrom.formatted(date: .abbreviated, time: .shortened)
                    )
                }

                if let validUntil = cert.validUntil {
                    DetailRow(
                        label: "Valid Until",
                        value: validUntil.formatted(date: .abbreviated, time: .shortened),
                        valueColor: cert.expiryStatus.color
                    )
                }

                DetailRow(
                    label: "Days Remaining",
                    value: cert.formattedDaysRemaining,
                    valueColor: cert.expiryStatus.color
                )

                DetailRow(
                    label: "Status",
                    value: cert.expiryStatus.rawValue,
                    valueColor: cert.expiryStatus.color
                )
            }
            .padding(8)
        }
    }

    // MARK: - Chain Info Section

    private func chainInfoSection(_ cert: SSLCertificateInfo) -> some View {
        GroupBox("Certificate Chain") {
            VStack(alignment: .leading, spacing: 10) {
                DetailRow(label: "Chain Length", value: "\(cert.chainLength) certificate(s)")

                DetailRow(
                    label: "Chain Complete",
                    value: cert.isChainComplete ? "Yes" : "No",
                    valueColor: cert.isChainComplete ? .green : .orange
                )

                DetailRow(
                    label: "Certificate Valid",
                    value: cert.isValid ? "Yes" : "No",
                    valueColor: cert.isValid ? .green : .red
                )
            }
            .padding(8)
        }
    }

    // MARK: - Subject Alt Names Section

    private func subjectAltNamesSection(_ cert: SSLCertificateInfo) -> some View {
        GroupBox("Subject Alternative Names") {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(cert.subjectAltNames, id: \.self) { name in
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.green)
                        Text(name)
                            .font(.system(size: 12, design: .monospaced))
                    }
                }
            }
            .padding(8)
        }
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        GroupBox("Actions") {
            VStack(spacing: 12) {
                Button {
                    Task {
                        await checkCertificate()
                    }
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text(certificate == nil ? "Check Certificate" : "Refresh Certificate")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(isLoading || server.serverType != .https)

                if let error = checkError {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text(error)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }

                if server.serverType != .https {
                    Text("SSL certificate checking is only available for HTTPS servers")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(8)
        }
    }

    // MARK: - Last Check Section

    private func lastCheckSection(_ cert: SSLCertificateInfo) -> some View {
        GroupBox("Last Check") {
            VStack(alignment: .leading, spacing: 10) {
                DetailRow(
                    label: "Checked At",
                    value: cert.lastChecked.formatted(date: .abbreviated, time: .shortened)
                )

                if let error = cert.checkError {
                    DetailRow(label: "Error", value: error, valueColor: .red)
                }
            }
            .padding(8)
        }
    }

    // MARK: - Check Certificate

    @MainActor
    private func checkCertificate() async {
        isLoading = true
        checkError = nil

        do {
            let certInfo = try await SSLCertificateService.shared.checkCertificate(
                host: server.host,
                port: server.port
            )
            certInfo.serverId = server.id
            server.sslCertificate = certInfo
        } catch {
            checkError = error.localizedDescription
        }

        isLoading = false
    }
}

// MARK: - Detail Row

private struct DetailRow: View {
    let label: String
    let value: String
    var valueColor: Color = .primary
    var isMonospace: Bool = false

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .frame(width: 140, alignment: .leading)

            Text(value)
                .font(.system(size: 12, weight: .medium, design: isMonospace ? .monospaced : .default))
                .foregroundStyle(valueColor)
                .textSelection(.enabled)

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview("SSL Certificate View") {
    let server = Server(
        name: "Example Server",
        host: "example.com",
        port: 443,
        serverType: .https
    )

    let cert = SSLCertificateInfo(
        serverId: server.id,
        commonName: "*.example.com",
        issuer: "DigiCert TLS RSA SHA256 2020 CA1",
        organization: "Example Inc.",
        serialNumber: "0A:1B:2C:3D:4E:5F",
        signatureAlgorithm: "SHA256withRSA",
        validFrom: Calendar.current.date(byAdding: .day, value: -100, to: Date()),
        validUntil: Calendar.current.date(byAdding: .day, value: 265, to: Date()),
        isValid: true,
        chainLength: 3,
        isChainComplete: true,
        subjectAltNames: ["example.com", "*.example.com", "www.example.com"]
    )

    server.sslCertificate = cert

    return SSLCertificateView(server: server)
        .frame(width: 500, height: 700)
}
