//
//  ServerMonitoringService.swift
//  Server
//
//  Created by Jonathan Hines Dumitru on 1/13/26.
//

import Foundation
import SwiftData
import Network
internal import Combine

// MARK: - Connection Check Result
struct ConnectionCheckResult {
    let status: ServerStatus
    let responseTime: Double // in milliseconds
    let errorMessage: String?

    static func online(responseTime: Double) -> ConnectionCheckResult {
        ConnectionCheckResult(status: .online, responseTime: responseTime, errorMessage: nil)
    }

    static func offline(error: String, responseTime: Double = 0) -> ConnectionCheckResult {
        ConnectionCheckResult(status: .offline, responseTime: responseTime, errorMessage: error)
    }

    static func warning(responseTime: Double, message: String? = nil) -> ConnectionCheckResult {
        ConnectionCheckResult(status: .warning, responseTime: responseTime, errorMessage: message)
    }
}

// MARK: - Server Monitoring Service
@MainActor
class ServerMonitoringService: ObservableObject {
    @Published var isMonitoring = false
    private var monitoringTask: Task<Void, Never>?

    private let modelContext: ModelContext
    private let notificationService = NotificationService.shared
    private let connectionTimeout: TimeInterval = 10.0
    private let maxRetries = 2

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        // Setup notification categories on init
        notificationService.setupNotificationCategories()
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

        // Check servers concurrently for faster monitoring
        await withTaskGroup(of: Void.self) { group in
            for server in servers {
                group.addTask { @MainActor in
                    await self.checkServer(server)
                }
            }
        }
    }

    func checkServer(_ server: Server) async {
        let previousStatus = server.status
        let now = Date()

        // Perform the check with retry logic
        let result = await performCheckWithRetry(server: server)

        // Update uptime tracking before changing status
        updateUptimeTracking(server: server, previousStatus: previousStatus, newStatus: result.status, now: now)

        server.status = result.status
        server.lastChecked = now
        server.responseTime = result.responseTime

        // Log the check with appropriate detail
        let logMessage: String
        let logLevel: LogLevel

        switch result.status {
        case .online:
            logMessage = "Server check completed: Online (Response time: \(String(format: "%.2f", result.responseTime))ms)"
            logLevel = .info
        case .warning:
            logMessage = "Server check completed: Warning - \(result.errorMessage ?? "High latency") (Response time: \(String(format: "%.2f", result.responseTime))ms)"
            logLevel = .warning
        case .offline:
            logMessage = "Server check failed: \(result.errorMessage ?? "Connection failed")"
            logLevel = .error
        case .unknown:
            logMessage = "Server check completed: Unable to determine status"
            logLevel = .warning
        }

        // Log status change separately if status changed
        if previousStatus != result.status && previousStatus != .unknown {
            let statusChangeLog = ServerLog(
                timestamp: Date(),
                message: "Status changed from \(previousStatus.rawValue) to \(result.status.rawValue)",
                level: result.status == .online ? .info : .error
            )
            statusChangeLog.server = server
            modelContext.insert(statusChangeLog)

            // Send notification for status change
            await notificationService.notifyServerStatusChange(
                serverName: server.name,
                previousStatus: previousStatus,
                newStatus: result.status,
                errorMessage: result.errorMessage
            )
        }

        // Send error notification if offline (even if status didn't change)
        if result.status == .offline, let errorMessage = result.errorMessage {
            await notificationService.notifyError(
                serverName: server.name,
                errorMessage: errorMessage
            )
        }

        let log = ServerLog(
            timestamp: Date(),
            message: logMessage,
            level: logLevel
        )
        log.server = server
        modelContext.insert(log)

        // Create metric snapshot (still mock for now - will be replaced in feature #9)
        let metric = ServerMetric(
            timestamp: Date(),
            cpuUsage: Double.random(in: 10...80),
            memoryUsage: Double.random(in: 30...90),
            diskUsage: Double.random(in: 40...85),
            networkIn: Double.random(in: 0...100),
            networkOut: Double.random(in: 0...100),
            activeConnections: Int.random(in: 0...50)
        )
        metric.server = server
        modelContext.insert(metric)

        // Check alert thresholds
        await checkAlertThresholds(server: server, metric: metric, responseTime: result.responseTime)

        try? modelContext.save()
    }

    // MARK: - Alert Threshold Checking

    private func checkAlertThresholds(server: Server, metric: ServerMetric, responseTime: Double) async {
        // Fetch all enabled thresholds
        let descriptor = FetchDescriptor<AlertThreshold>(
            predicate: #Predicate { $0.isEnabled }
        )
        guard let thresholds = try? modelContext.fetch(descriptor) else { return }

        for threshold in thresholds {
            let currentValue: Double?

            switch threshold.metricType {
            case .cpuUsage:
                currentValue = metric.cpuUsage
            case .memoryUsage:
                currentValue = metric.memoryUsage
            case .diskUsage:
                currentValue = metric.diskUsage
            case .responseTime:
                currentValue = responseTime
            case .networkIn:
                currentValue = metric.networkIn
            case .networkOut:
                currentValue = metric.networkOut
            }

            guard let value = currentValue else { continue }

            // Check if threshold is exceeded
            if threshold.isExceeded(by: value) {
                // Check cooldown
                if threshold.shouldAlert(forServerID: server.id.uuidString) {
                    // Record the alert
                    threshold.recordAlert(forServerID: server.id.uuidString)

                    // Create alert event
                    let alertEvent = AlertEvent(
                        metricType: threshold.metricType,
                        thresholdValue: threshold.thresholdValue,
                        actualValue: value,
                        severity: threshold.severity,
                        serverName: server.name,
                        serverID: server.id.uuidString
                    )
                    modelContext.insert(alertEvent)

                    // Log the threshold breach
                    let log = ServerLog(
                        timestamp: Date(),
                        message: "Threshold exceeded: \(threshold.metricType.rawValue) is \(String(format: "%.1f", value))\(threshold.metricType.unit) (threshold: \(threshold.comparison.rawValue) \(String(format: "%.0f", threshold.thresholdValue))\(threshold.metricType.unit))",
                        level: threshold.severity == .critical ? .error : .warning
                    )
                    log.server = server
                    modelContext.insert(log)

                    // Send notification
                    await notificationService.notifyThresholdExceeded(
                        serverName: server.name,
                        metricName: threshold.metricType.rawValue,
                        currentValue: value,
                        thresholdValue: threshold.thresholdValue
                    )
                }
            }
        }
    }

    // MARK: - Uptime Tracking

    private func updateUptimeTracking(server: Server, previousStatus: ServerStatus, newStatus: ServerStatus, now: Date) {
        // Initialize monitoring start date if not set
        if server.monitoringStartDate == nil {
            server.monitoringStartDate = now
            server.lastStatusChangeDate = now
        }

        // Calculate duration of previous status
        if let lastChange = server.lastStatusChangeDate {
            let duration = now.timeIntervalSince(lastChange)

            // Update cumulative counters
            switch previousStatus {
            case .online:
                server.totalOnlineSeconds += duration
            case .offline:
                server.totalOfflineSeconds += duration
            case .warning:
                server.totalWarningSeconds += duration
            case .unknown:
                break // Don't count unknown time
            }

            // If status changed, create an uptime record and update last change date
            if previousStatus != newStatus && previousStatus != .unknown {
                // Create record for the previous status period
                let record = UptimeRecord(
                    timestamp: lastChange,
                    status: previousStatus,
                    durationSeconds: duration
                )
                record.server = server
                modelContext.insert(record)

                // Update the last status change date
                server.lastStatusChangeDate = now
            }
        } else {
            // First check ever
            server.lastStatusChangeDate = now
        }

        // Update legacy uptime field for backwards compatibility (current online streak)
        if newStatus == .online {
            if let lastChange = server.lastStatusChangeDate, previousStatus == .online {
                server.uptime = now.timeIntervalSince(lastChange)
            } else {
                server.uptime = 0
            }
        } else {
            server.uptime = nil
        }
    }

    // MARK: - Check with Retry Logic

    private func performCheckWithRetry(server: Server) async -> ConnectionCheckResult {
        var lastResult: ConnectionCheckResult?

        for attempt in 0..<maxRetries {
            if attempt > 0 {
                // Exponential backoff: 1s, 2s
                try? await Task.sleep(for: .seconds(Double(attempt)))
            }

            let result = await performSingleCheck(server: server)
            lastResult = result

            // If online or warning, no need to retry
            if result.status == .online || result.status == .warning {
                return result
            }
        }

        return lastResult ?? .offline(error: "All connection attempts failed")
    }

    private func performSingleCheck(server: Server) async -> ConnectionCheckResult {
        let startTime = Date()

        switch server.serverType {
        case .http:
            return await checkHTTP(host: server.host, port: server.port, useSSL: false, startTime: startTime)
        case .https:
            return await checkHTTP(host: server.host, port: server.port, useSSL: true, startTime: startTime)
        case .ssh:
            return await checkTCPPort(host: server.host, port: server.port, startTime: startTime, expectedBanner: "SSH")
        case .ftp:
            return await checkTCPPort(host: server.host, port: server.port, startTime: startTime, expectedBanner: "220")
        case .database:
            return await checkTCPPort(host: server.host, port: server.port, startTime: startTime, expectedBanner: nil)
        case .custom:
            // For custom servers, first try ICMP ping, then TCP
            let pingResult = await performICMPPing(host: server.host, startTime: startTime)
            if pingResult.status == .online {
                // Also verify the port is open
                let tcpResult = await checkTCPPort(host: server.host, port: server.port, startTime: startTime, expectedBanner: nil)
                return tcpResult
            }
            return pingResult
        }
    }

    // MARK: - HTTP/HTTPS Check

    private func checkHTTP(host: String, port: Int, useSSL: Bool, startTime: Date) async -> ConnectionCheckResult {
        let scheme = useSSL ? "https" : "http"
        let defaultPort = useSSL ? 443 : 80

        // Only include port in URL if it's non-standard
        let urlString: String
        if port == defaultPort {
            urlString = "\(scheme)://\(host)"
        } else {
            urlString = "\(scheme)://\(host):\(port)"
        }

        guard let url = URL(string: urlString) else {
            return .offline(error: "Invalid URL: \(urlString)")
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = connectionTimeout
        request.httpMethod = "HEAD"
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData

        // Custom URL session configuration
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = connectionTimeout
        config.timeoutIntervalForResource = connectionTimeout
        config.waitsForConnectivity = false
        let session = URLSession(configuration: config)

        do {
            let (_, response) = try await session.data(for: request)
            let responseTime = Date().timeIntervalSince(startTime) * 1000

            guard let httpResponse = response as? HTTPURLResponse else {
                return .offline(error: "Invalid HTTP response", responseTime: responseTime)
            }

            switch httpResponse.statusCode {
            case 200...299:
                // Check for slow response (>2 seconds = warning)
                if responseTime > 2000 {
                    return .warning(responseTime: responseTime, message: "Slow response time")
                }
                return .online(responseTime: responseTime)
            case 300...399:
                return .warning(responseTime: responseTime, message: "Redirect (HTTP \(httpResponse.statusCode))")
            case 401, 403:
                // Auth required but server is reachable
                return .warning(responseTime: responseTime, message: "Authentication required (HTTP \(httpResponse.statusCode))")
            case 500...599:
                return .warning(responseTime: responseTime, message: "Server error (HTTP \(httpResponse.statusCode))")
            default:
                return .offline(error: "HTTP \(httpResponse.statusCode)", responseTime: responseTime)
            }
        } catch let error as URLError {
            let responseTime = Date().timeIntervalSince(startTime) * 1000

            switch error.code {
            case .timedOut:
                return .offline(error: "Connection timed out", responseTime: responseTime)
            case .cannotConnectToHost:
                return .offline(error: "Cannot connect to host", responseTime: responseTime)
            case .networkConnectionLost:
                return .offline(error: "Network connection lost", responseTime: responseTime)
            case .notConnectedToInternet:
                return .offline(error: "No internet connection", responseTime: responseTime)
            case .dnsLookupFailed:
                return .offline(error: "DNS lookup failed", responseTime: responseTime)
            case .secureConnectionFailed:
                return .offline(error: "SSL/TLS connection failed", responseTime: responseTime)
            case .serverCertificateUntrusted:
                return .warning(responseTime: responseTime, message: "Untrusted SSL certificate")
            default:
                return .offline(error: error.localizedDescription, responseTime: responseTime)
            }
        } catch {
            let responseTime = Date().timeIntervalSince(startTime) * 1000
            return .offline(error: error.localizedDescription, responseTime: responseTime)
        }
    }

    // MARK: - TCP Port Check using Network framework

    private func checkTCPPort(host: String, port: Int, startTime: Date, expectedBanner: String?) async -> ConnectionCheckResult {
        return await withCheckedContinuation { continuation in
            let endpoint = NWEndpoint.hostPort(host: NWEndpoint.Host(host), port: NWEndpoint.Port(integerLiteral: UInt16(port)))
            let connection = NWConnection(to: endpoint, using: .tcp)

            var hasResumed = false
            let resumeOnce: (ConnectionCheckResult) -> Void = { result in
                guard !hasResumed else { return }
                hasResumed = true
                connection.cancel()
                continuation.resume(returning: result)
            }

            // Timeout handler
            let timeoutWork = DispatchWorkItem {
                let responseTime = Date().timeIntervalSince(startTime) * 1000
                resumeOnce(.offline(error: "Connection timed out", responseTime: responseTime))
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + self.connectionTimeout, execute: timeoutWork)

            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    timeoutWork.cancel()
                    let responseTime = Date().timeIntervalSince(startTime) * 1000

                    if let expectedBanner = expectedBanner {
                        // Try to read banner
                        connection.receive(minimumIncompleteLength: 1, maximumLength: 1024) { data, _, _, error in
                            if let data = data, let banner = String(data: data, encoding: .utf8) {
                                if banner.contains(expectedBanner) {
                                    resumeOnce(.online(responseTime: responseTime))
                                } else {
                                    resumeOnce(.warning(responseTime: responseTime, message: "Unexpected service banner"))
                                }
                            } else if error != nil {
                                // Port is open but couldn't read banner
                                resumeOnce(.online(responseTime: responseTime))
                            } else {
                                resumeOnce(.online(responseTime: responseTime))
                            }
                        }
                    } else {
                        // No banner expected, port open is enough
                        if responseTime > 2000 {
                            resumeOnce(.warning(responseTime: responseTime, message: "Slow connection"))
                        } else {
                            resumeOnce(.online(responseTime: responseTime))
                        }
                    }

                case .failed(let error):
                    timeoutWork.cancel()
                    let responseTime = Date().timeIntervalSince(startTime) * 1000
                    let errorMessage = self.categorizeNWError(error)
                    resumeOnce(.offline(error: errorMessage, responseTime: responseTime))

                case .cancelled:
                    timeoutWork.cancel()

                case .waiting(let error):
                    // Connection is waiting, might be a network issue
                    let responseTime = Date().timeIntervalSince(startTime) * 1000
                    if responseTime > self.connectionTimeout * 1000 {
                        timeoutWork.cancel()
                        let errorMessage = self.categorizeNWError(error)
                        resumeOnce(.offline(error: errorMessage, responseTime: responseTime))
                    }

                default:
                    break
                }
            }

            connection.start(queue: .global())
        }
    }

    private func categorizeNWError(_ error: NWError) -> String {
        switch error {
        case .posix(let code):
            switch code {
            case .ECONNREFUSED:
                return "Connection refused"
            case .ETIMEDOUT:
                return "Connection timed out"
            case .EHOSTUNREACH:
                return "Host unreachable"
            case .ENETUNREACH:
                return "Network unreachable"
            case .ECONNRESET:
                return "Connection reset by peer"
            default:
                return "Network error: \(code)"
            }
        case .dns(let dnsError):
            return "DNS error: \(dnsError)"
        case .tls(let tlsError):
            return "TLS error: \(tlsError)"
        default:
            return "Connection failed: \(error.localizedDescription)"
        }
    }

    // MARK: - ICMP Ping using system ping command

    private func performICMPPing(host: String, startTime: Date) async -> ConnectionCheckResult {
        return await withCheckedContinuation { continuation in
            let process = Process()
            let pipe = Pipe()

            process.executableURL = URL(fileURLWithPath: "/sbin/ping")
            process.arguments = ["-c", "1", "-t", "5", host] // 1 ping, 5 second timeout
            process.standardOutput = pipe
            process.standardError = pipe

            var hasResumed = false
            let resumeOnce: (ConnectionCheckResult) -> Void = { result in
                guard !hasResumed else { return }
                hasResumed = true
                continuation.resume(returning: result)
            }

            process.terminationHandler = { process in
                let responseTime = Date().timeIntervalSince(startTime) * 1000
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""

                if process.terminationStatus == 0 {
                    // Parse ping time from output if possible
                    if let pingTime = self.parsePingTime(from: output) {
                        if pingTime > 500 { // >500ms is considered slow
                            resumeOnce(.warning(responseTime: pingTime, message: "High latency"))
                        } else {
                            resumeOnce(.online(responseTime: pingTime))
                        }
                    } else {
                        resumeOnce(.online(responseTime: responseTime))
                    }
                } else {
                    // Ping failed - parse error from output
                    if output.contains("Unknown host") || output.contains("cannot resolve") {
                        resumeOnce(.offline(error: "DNS lookup failed", responseTime: responseTime))
                    } else if output.contains("Request timeout") || output.contains("100.0% packet loss") {
                        resumeOnce(.offline(error: "Host unreachable (ping timeout)", responseTime: responseTime))
                    } else {
                        resumeOnce(.offline(error: "Ping failed", responseTime: responseTime))
                    }
                }
            }

            do {
                try process.run()
            } catch {
                let responseTime = Date().timeIntervalSince(startTime) * 1000
                resumeOnce(.offline(error: "Failed to execute ping: \(error.localizedDescription)", responseTime: responseTime))
            }
        }
    }

    private func parsePingTime(from output: String) -> Double? {
        // Parse "time=X.XXX ms" from ping output
        let pattern = #"time[=<](\d+\.?\d*)\s*ms"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: []),
           let match = regex.firstMatch(in: output, options: [], range: NSRange(output.startIndex..., in: output)),
           let range = Range(match.range(at: 1), in: output) {
            return Double(output[range])
        }
        return nil
    }
}

// MARK: - Server Error Types
enum ServerError: LocalizedError {
    case invalidURL
    case connectionFailed
    case timeout
    case connectionRefused
    case hostUnreachable
    case dnsLookupFailed
    case sslError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid server URL"
        case .connectionFailed: return "Connection failed"
        case .timeout: return "Connection timed out"
        case .connectionRefused: return "Connection refused"
        case .hostUnreachable: return "Host unreachable"
        case .dnsLookupFailed: return "DNS lookup failed"
        case .sslError(let detail): return "SSL error: \(detail)"
        }
    }
}
