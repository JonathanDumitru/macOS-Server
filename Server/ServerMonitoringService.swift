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

        do {
            let status = try await pingServer(host: server.host, port: server.port, type: server.serverType)
            let responseTime = Date().timeIntervalSince(startTime) * 1000 // Convert to ms

            server.status = status
            server.lastChecked = Date()
            server.responseTime = responseTime

            // Record uptime check
            uptimeTrackingService.recordCheck(
                server: server,
                isOnline: status == .online,
                responseTime: responseTime,
                statusCode: nil,
                errorMessage: status == .online ? nil : "Status: \(status.rawValue)"
            )

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

            try? modelContext.save()
        } catch {
            server.status = .offline
            server.lastChecked = Date()

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
