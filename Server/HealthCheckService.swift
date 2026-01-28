//
//  HealthCheckService.swift
//  Server
//
//  Created by Claude on 1/28/26.
//

import Foundation
import SwiftData
import os.log

private let logger = Logger(subsystem: "com.server.app", category: "HealthCheck")

@MainActor
class HealthCheckService {
    static let shared = HealthCheckService()

    private var modelContext: ModelContext?
    private var scheduledTask: Task<Void, Never>?
    private(set) var isRunning = false

    // Default interval for checks without custom interval (5 minutes)
    private let defaultCheckInterval: TimeInterval = 300

    private init() {}

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        startScheduledChecks()
    }

    // MARK: - Scheduled Checks

    func startScheduledChecks() {
        guard !isRunning else { return }
        isRunning = true

        scheduledTask = Task {
            logger.info("Health check scheduler started")

            while !Task.isCancelled && isRunning {
                await runDueHealthChecks()
                // Check every minute for checks that are due
                try? await Task.sleep(for: .seconds(60))
            }

            logger.info("Health check scheduler stopped")
        }
    }

    func stopScheduledChecks() {
        isRunning = false
        scheduledTask?.cancel()
        scheduledTask = nil
    }

    private func runDueHealthChecks() async {
        guard let context = modelContext else { return }

        let descriptor = FetchDescriptor<HealthCheck>(
            predicate: #Predicate { $0.isEnabled }
        )

        guard let checks = try? context.fetch(descriptor) else { return }

        let now = Date()

        for check in checks {
            let interval = check.checkIntervalSeconds > 0
                ? TimeInterval(check.checkIntervalSeconds)
                : defaultCheckInterval

            // Check if enough time has passed since last check
            let shouldRun: Bool
            if let lastCheck = check.lastCheckTime {
                shouldRun = now.timeIntervalSince(lastCheck) >= interval
            } else {
                shouldRun = true // Never run before
            }

            if shouldRun {
                let result = await runHealthCheck(check)
                check.recordResult(
                    passed: result.passed,
                    message: result.message,
                    responseTime: result.responseTime
                )

                if !result.passed {
                    logger.warning("Scheduled health check '\(check.name)' failed: \(result.message)")

                    // Create incident for consecutive failures
                    if check.consecutiveFailures >= 3 {
                        if let server = getServer(for: check) {
                            IncidentService.shared.createWarningIncident(
                                for: server,
                                reason: "Health check '\(check.name)' failed \(check.consecutiveFailures) times consecutively"
                            )
                        }
                    }
                } else {
                    logger.info("Scheduled health check '\(check.name)' passed")
                }
            }
        }

        try? context.save()
    }

    // MARK: - Health Check Execution

    func runHealthCheck(_ check: HealthCheck) async -> HealthCheckResult {
        let startTime = Date()

        do {
            switch check.checkType {
            case .httpStatus:
                return try await performHTTPStatusCheck(check, startTime: startTime)
            case .httpContent:
                return try await performHTTPContentCheck(check, startTime: startTime)
            case .tcpPort:
                return try await performTCPCheck(check, startTime: startTime)
            case .ping:
                return try await performPingCheck(check, startTime: startTime)
            }
        } catch {
            let responseTime = Date().timeIntervalSince(startTime) * 1000
            return HealthCheckResult(
                checkId: check.id,
                passed: false,
                responseTime: responseTime,
                message: "Check failed: \(error.localizedDescription)"
            )
        }
    }

    // MARK: - HTTP Status Check

    private func performHTTPStatusCheck(_ check: HealthCheck, startTime: Date) async throws -> HealthCheckResult {
        guard let server = getServer(for: check) else {
            throw HealthCheckError.serverNotFound
        }

        let urlString = buildURL(for: server, path: check.httpPath)
        guard let url = URL(string: urlString) else {
            throw HealthCheckError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = check.httpMethod
        request.timeoutInterval = TimeInterval(check.timeoutSeconds)

        // Add custom headers
        if let headers = check.requestHeaders {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }

        // Add request body for POST
        if check.httpMethod == "POST", let body = check.requestBody {
            request.httpBody = body.data(using: .utf8)
        }

        let (_, response) = try await URLSession.shared.data(for: request)
        let responseTime = Date().timeIntervalSince(startTime) * 1000

        guard let httpResponse = response as? HTTPURLResponse else {
            return HealthCheckResult(
                checkId: check.id,
                passed: false,
                responseTime: responseTime,
                message: "Invalid response type"
            )
        }

        let statusCode = httpResponse.statusCode
        let expectedCode = check.expectedStatusCode ?? 200
        let passed = statusCode == expectedCode

        return HealthCheckResult(
            checkId: check.id,
            passed: passed,
            statusCode: statusCode,
            responseTime: responseTime,
            message: passed ? "Status \(statusCode) OK" : "Expected \(expectedCode), got \(statusCode)"
        )
    }

    // MARK: - HTTP Content Check

    private func performHTTPContentCheck(_ check: HealthCheck, startTime: Date) async throws -> HealthCheckResult {
        guard let server = getServer(for: check) else {
            throw HealthCheckError.serverNotFound
        }

        let urlString = buildURL(for: server, path: check.httpPath)
        guard let url = URL(string: urlString) else {
            throw HealthCheckError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = check.httpMethod
        request.timeoutInterval = TimeInterval(check.timeoutSeconds)

        if let headers = check.requestHeaders {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }

        if check.httpMethod == "POST", let body = check.requestBody {
            request.httpBody = body.data(using: .utf8)
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        let responseTime = Date().timeIntervalSince(startTime) * 1000
        let responseBody = String(data: data, encoding: .utf8) ?? ""

        guard let httpResponse = response as? HTTPURLResponse else {
            return HealthCheckResult(
                checkId: check.id,
                passed: false,
                responseTime: responseTime,
                message: "Invalid response type",
                responseBody: responseBody
            )
        }

        // Check status code first if specified
        if let expectedCode = check.expectedStatusCode, httpResponse.statusCode != expectedCode {
            return HealthCheckResult(
                checkId: check.id,
                passed: false,
                statusCode: httpResponse.statusCode,
                responseTime: responseTime,
                message: "Expected status \(expectedCode), got \(httpResponse.statusCode)",
                responseBody: responseBody
            )
        }

        // Check content contains expected string
        if let expectedContent = check.expectedResponseContains, !expectedContent.isEmpty {
            if !responseBody.contains(expectedContent) {
                return HealthCheckResult(
                    checkId: check.id,
                    passed: false,
                    statusCode: httpResponse.statusCode,
                    responseTime: responseTime,
                    message: "Response does not contain expected content",
                    responseBody: responseBody
                )
            }
        }

        // Check content does NOT contain forbidden string
        if let forbiddenContent = check.expectedResponseNotContains, !forbiddenContent.isEmpty {
            if responseBody.contains(forbiddenContent) {
                return HealthCheckResult(
                    checkId: check.id,
                    passed: false,
                    statusCode: httpResponse.statusCode,
                    responseTime: responseTime,
                    message: "Response contains forbidden content",
                    responseBody: responseBody
                )
            }
        }

        return HealthCheckResult(
            checkId: check.id,
            passed: true,
            statusCode: httpResponse.statusCode,
            responseTime: responseTime,
            message: "Content check passed",
            responseBody: responseBody
        )
    }

    // MARK: - TCP Port Check

    private func performTCPCheck(_ check: HealthCheck, startTime: Date) async throws -> HealthCheckResult {
        guard let server = getServer(for: check) else {
            throw HealthCheckError.serverNotFound
        }

        let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<HealthCheckResult, Error>) in
            var readStream: Unmanaged<CFReadStream>?
            var writeStream: Unmanaged<CFWriteStream>?

            CFStreamCreatePairWithSocketToHost(
                nil,
                server.host as CFString,
                UInt32(server.port),
                &readStream,
                &writeStream
            )

            guard let inputStream = readStream?.takeRetainedValue(),
                  let outputStream = writeStream?.takeRetainedValue() else {
                continuation.resume(throwing: HealthCheckError.connectionFailed)
                return
            }

            CFReadStreamOpen(inputStream)
            CFWriteStreamOpen(outputStream)

            DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(check.timeoutSeconds)) {
                let responseTime = Date().timeIntervalSince(startTime) * 1000

                CFReadStreamClose(inputStream)
                CFWriteStreamClose(outputStream)

                let result = HealthCheckResult(
                    checkId: check.id,
                    passed: true,
                    responseTime: responseTime,
                    message: "TCP port \(server.port) is open"
                )
                continuation.resume(returning: result)
            }
        }

        return result
    }

    // MARK: - Ping Check

    private func performPingCheck(_ check: HealthCheck, startTime: Date) async throws -> HealthCheckResult {
        guard let server = getServer(for: check) else {
            throw HealthCheckError.serverNotFound
        }

        // Use Process to run ping command
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/sbin/ping")
        process.arguments = ["-c", "1", "-t", "\(check.timeoutSeconds)", server.host]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()

            let responseTime = Date().timeIntervalSince(startTime) * 1000
            let passed = process.terminationStatus == 0

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""

            return HealthCheckResult(
                checkId: check.id,
                passed: passed,
                responseTime: responseTime,
                message: passed ? "Ping successful" : "Ping failed",
                responseBody: output
            )
        } catch {
            let responseTime = Date().timeIntervalSince(startTime) * 1000
            return HealthCheckResult(
                checkId: check.id,
                passed: false,
                responseTime: responseTime,
                message: "Ping error: \(error.localizedDescription)"
            )
        }
    }

    // MARK: - Helpers

    private func getServer(for check: HealthCheck) -> Server? {
        guard let context = modelContext else { return nil }

        let serverId = check.serverId
        var descriptor = FetchDescriptor<Server>(
            predicate: #Predicate { $0.id == serverId }
        )
        descriptor.fetchLimit = 1

        return try? context.fetch(descriptor).first
    }

    private func buildURL(for server: Server, path: String) -> String {
        let scheme = server.serverType == .https ? "https" : "http"
        let normalizedPath = path.hasPrefix("/") ? path : "/\(path)"
        return "\(scheme)://\(server.host):\(server.port)\(normalizedPath)"
    }

    // MARK: - Batch Operations

    func runAllHealthChecks(for server: Server) async -> [HealthCheckResult] {
        guard let context = modelContext else { return [] }

        let serverId = server.id
        let descriptor = FetchDescriptor<HealthCheck>(
            predicate: #Predicate { $0.serverId == serverId && $0.isEnabled }
        )

        guard let checks = try? context.fetch(descriptor) else { return [] }

        var results: [HealthCheckResult] = []

        for check in checks {
            let result = await runHealthCheck(check)
            check.recordResult(
                passed: result.passed,
                message: result.message,
                responseTime: result.responseTime
            )
            results.append(result)

            logger.info("Health check '\(check.name)' for server \(server.name): \(result.passed ? "PASSED" : "FAILED")")
        }

        try? context.save()

        return results
    }

    func getHealthChecks(for serverId: UUID) -> [HealthCheck] {
        guard let context = modelContext else { return [] }

        let descriptor = FetchDescriptor<HealthCheck>(
            predicate: #Predicate { $0.serverId == serverId }
        )

        return (try? context.fetch(descriptor)) ?? []
    }

    func createHealthCheck(
        for server: Server,
        name: String,
        type: HealthCheckType,
        path: String = "/",
        expectedStatusCode: Int? = 200
    ) -> HealthCheck {
        let check = HealthCheck(
            serverId: server.id,
            name: name,
            checkType: type,
            httpPath: path,
            expectedStatusCode: expectedStatusCode
        )

        modelContext?.insert(check)
        try? modelContext?.save()

        return check
    }

    func deleteHealthCheck(_ check: HealthCheck) {
        modelContext?.delete(check)
        try? modelContext?.save()
    }
}

// MARK: - Errors

enum HealthCheckError: LocalizedError {
    case serverNotFound
    case invalidURL
    case connectionFailed
    case timeout

    var errorDescription: String? {
        switch self {
        case .serverNotFound: return "Server not found"
        case .invalidURL: return "Invalid URL"
        case .connectionFailed: return "Connection failed"
        case .timeout: return "Connection timed out"
        }
    }
}
