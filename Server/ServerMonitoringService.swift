//
//  ServerMonitoringService.swift
//  Server
//
//  Created by Jonathan Hines Dumitru on 1/13/26.
//

import Foundation
import SwiftData
internal import Combine

@MainActor
class ServerMonitoringService: ObservableObject {
    @Published var isMonitoring = false
    private var monitoringTask: Task<Void, Never>?

    private let modelContext: ModelContext
    private let uptimeTrackingService: UptimeTrackingService
    private var sslCheckCounter: [UUID: Int] = [:]
    private let sslCheckInterval = 10 // Check SSL every 10 regular checks

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.uptimeTrackingService = UptimeTrackingService(modelContext: modelContext)
    }
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        
        monitoringTask = Task {
            while !Task.isCancelled && isMonitoring {
                await checkAllServers()
                try? await Task.sleep(for: .seconds(30)) // Check every 30 seconds
            }
        }
    }
    
    func stopMonitoring() {
        isMonitoring = false
        monitoringTask?.cancel()
        monitoringTask = nil
    }
    
    func checkAllServers() async {
        let descriptor = FetchDescriptor<Server>()
        guard let servers = try? modelContext.fetch(descriptor) else { return }
        
        for server in servers {
            await checkServer(server)
        }
    }
    
    func checkServer(_ server: Server) async {
        let startTime = Date()

        // Store previous status for notification comparison
        let previousStatus = NotificationService.shared.getPreviousStatus(for: server)

        do {
            let status = try await pingServer(host: server.host, port: server.port, type: server.serverType)
            let responseTime = Date().timeIntervalSince(startTime) * 1000 // Convert to ms

            server.status = status
            server.lastChecked = Date()
            server.responseTime = responseTime

            // Check for status change and send notification
            NotificationService.shared.checkServerStatusChange(server: server, previousStatus: previousStatus)

            // Record uptime check
            uptimeTrackingService.recordCheck(
                server: server,
                isOnline: status == .online,
                responseTime: responseTime,
                statusCode: nil,
                errorMessage: status == .online ? nil : "Status: \(status.rawValue)"
            )

            // Check response time threshold for notifications (uses preference setting)
            NotificationService.shared.checkResponseThreshold(server: server)

            // Log the check
            let log = ServerLog(
                timestamp: Date(),
                message: "Server check completed: \(status.rawValue) (Response time: \(String(format: "%.2f", responseTime))ms)",
                level: status == .online ? .info : .warning
            )
            log.server = server
            modelContext.insert(log)

            // Create metric snapshot
            let metric = ServerMetric(
                timestamp: Date(),
                cpuUsage: Double.random(in: 10...80), // Mock data - replace with real metrics
                memoryUsage: Double.random(in: 30...90),
                diskUsage: Double.random(in: 40...85),
                networkIn: Double.random(in: 0...100),
                networkOut: Double.random(in: 0...100),
                activeConnections: Int.random(in: 0...50)
            )
            metric.server = server
            modelContext.insert(metric)

            // Check SSL certificate for HTTPS servers (less frequently)
            if server.serverType == .https {
                await checkSSLCertificateIfNeeded(server)
            }

            try? modelContext.save()
        } catch {
            server.status = .offline
            server.lastChecked = Date()

            // Check for status change and send notification
            NotificationService.shared.checkServerStatusChange(server: server, previousStatus: previousStatus)

            // Record uptime check (failed)
            uptimeTrackingService.recordCheck(
                server: server,
                isOnline: false,
                responseTime: nil,
                statusCode: nil,
                errorMessage: error.localizedDescription
            )

            let log = ServerLog(
                timestamp: Date(),
                message: "Server check failed: \(error.localizedDescription)",
                level: .error
            )
            log.server = server
            modelContext.insert(log)

            try? modelContext.save()
        }
    }
    
    private func pingServer(host: String, port: Int, type: ServerType) async throws -> ServerStatus {
        // Build URL based on server type
        let urlString: String
        switch type {
        case .http:
            urlString = "http://\(host):\(port)"
        case .https:
            urlString = "https://\(host):\(port)"
        default:
            // For non-HTTP servers, we'll do a basic TCP connection check
            return try await checkTCPConnection(host: host, port: port)
        }
        
        guard let url = URL(string: urlString) else {
            throw ServerError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        request.httpMethod = "HEAD"
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            return .unknown
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return .online
        case 300...399:
            return .warning
        default:
            return .offline
        }
    }
    
    private func checkTCPConnection(host: String, port: Int) async throws -> ServerStatus {
        // Simple TCP connection check using CFStream
        // This is a simplified implementation
        return try await withCheckedThrowingContinuation { continuation in
            var readStream: Unmanaged<CFReadStream>?
            var writeStream: Unmanaged<CFWriteStream>?

            CFStreamCreatePairWithSocketToHost(
                nil,
                host as CFString,
                UInt32(port),
                &readStream,
                &writeStream
            )

            guard let inputStream = readStream?.takeRetainedValue(),
                  let outputStream = writeStream?.takeRetainedValue() else {
                continuation.resume(throwing: ServerError.connectionFailed)
                return
            }

            CFReadStreamOpen(inputStream)
            CFWriteStreamOpen(outputStream)

            // Simple check - if we can open the streams, consider it online
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                CFReadStreamClose(inputStream)
                CFWriteStreamClose(outputStream)
                continuation.resume(returning: .online)
            }
        }
    }

    // MARK: - SSL Certificate Checking

    private func checkSSLCertificateIfNeeded(_ server: Server) async {
        let counter = sslCheckCounter[server.id] ?? 0
        sslCheckCounter[server.id] = counter + 1

        // Check SSL every N regular checks, or if no certificate exists
        let shouldCheck = server.sslCertificate == nil || counter % sslCheckInterval == 0

        guard shouldCheck else { return }

        do {
            let certInfo = try await SSLCertificateService.shared.checkCertificate(
                host: server.host,
                port: server.port
            )
            certInfo.serverId = server.id

            // Update or create certificate
            if let existing = server.sslCertificate {
                existing.commonName = certInfo.commonName
                existing.issuer = certInfo.issuer
                existing.organization = certInfo.organization
                existing.serialNumber = certInfo.serialNumber
                existing.signatureAlgorithm = certInfo.signatureAlgorithm
                existing.validFrom = certInfo.validFrom
                existing.validUntil = certInfo.validUntil
                existing.isValid = certInfo.isValid
                existing.chainLength = certInfo.chainLength
                existing.isChainComplete = certInfo.isChainComplete
                existing.subjectAltNames = certInfo.subjectAltNames
                existing.lastChecked = Date()
                existing.checkError = certInfo.checkError
            } else {
                modelContext.insert(certInfo)
                server.sslCertificate = certInfo
            }

            // Log SSL check and send notification
            if let days = certInfo.daysUntilExpiry, days <= 30 {
                let log = ServerLog(
                    timestamp: Date(),
                    message: "SSL certificate expires in \(days) days",
                    level: days <= 7 ? .error : .warning
                )
                log.server = server
                modelContext.insert(log)

                // Send SSL expiry notification
                NotificationService.shared.sendSSLExpiryNotification(server: server, daysRemaining: days)
            }
        } catch {
            // Log SSL check error
            let log = ServerLog(
                timestamp: Date(),
                message: "SSL certificate check failed: \(error.localizedDescription)",
                level: .warning
            )
            log.server = server
            modelContext.insert(log)
        }
    }

    func forceSSLCheck(_ server: Server) async {
        guard server.serverType == .https else { return }
        sslCheckCounter[server.id] = 0
        await checkSSLCertificateIfNeeded(server)
        try? modelContext.save()
    }
}

enum ServerError: LocalizedError {
    case invalidURL
    case connectionFailed
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid server URL"
        case .connectionFailed: return "Connection failed"
        case .timeout: return "Connection timeout"
        }
    }
}
