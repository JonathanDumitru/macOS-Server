//
//  HealthCheck.swift
//  Server
//
//  Created by Claude on 1/28/26.
//

import Foundation
import SwiftData

/// Custom health check configuration for a server
@Model
final class HealthCheck {
    var id: UUID
    var serverId: UUID
    var name: String
    var isEnabled: Bool

    // Check Type
    var checkType: HealthCheckType

    // HTTP Check Options
    var httpMethod: String // GET, POST, HEAD
    var httpPath: String // /health, /api/status, etc.
    var expectedStatusCode: Int? // 200, 201, etc.
    var expectedResponseContains: String? // String to search for in body
    var expectedResponseNotContains: String? // String that should NOT be in body
    var requestHeaders: [String: String]? // Custom headers
    var requestBody: String? // For POST requests
    var timeoutSeconds: Int

    // Check Schedule
    var checkIntervalSeconds: Int // How often to run (0 = use server default)

    // Last Result
    var lastCheckTime: Date?
    var lastCheckPassed: Bool?
    var lastCheckMessage: String?
    var lastResponseTime: Double?

    // Statistics
    var consecutiveFailures: Int
    var totalChecks: Int
    var totalFailures: Int

    var passRate: Double {
        guard totalChecks > 0 else { return 100.0 }
        return Double(totalChecks - totalFailures) / Double(totalChecks) * 100
    }

    init(
        serverId: UUID,
        name: String,
        checkType: HealthCheckType = .httpStatus,
        httpPath: String = "/",
        expectedStatusCode: Int? = 200
    ) {
        self.id = UUID()
        self.serverId = serverId
        self.name = name
        self.isEnabled = true
        self.checkType = checkType
        self.httpMethod = "GET"
        self.httpPath = httpPath
        self.expectedStatusCode = expectedStatusCode
        self.timeoutSeconds = 10
        self.checkIntervalSeconds = 0 // Use server default
        self.consecutiveFailures = 0
        self.totalChecks = 0
        self.totalFailures = 0
    }

    func recordResult(passed: Bool, message: String?, responseTime: Double?) {
        lastCheckTime = Date()
        lastCheckPassed = passed
        lastCheckMessage = message
        lastResponseTime = responseTime
        totalChecks += 1

        if passed {
            consecutiveFailures = 0
        } else {
            consecutiveFailures += 1
            totalFailures += 1
        }
    }

    func resetStatistics() {
        consecutiveFailures = 0
        totalChecks = 0
        totalFailures = 0
        lastCheckTime = nil
        lastCheckPassed = nil
        lastCheckMessage = nil
        lastResponseTime = nil
    }
}

// MARK: - Health Check Types

enum HealthCheckType: String, Codable, CaseIterable {
    case httpStatus = "HTTP Status"
    case httpContent = "HTTP Content"
    case tcpPort = "TCP Port"
    case ping = "Ping"

    var icon: String {
        switch self {
        case .httpStatus: return "number.circle"
        case .httpContent: return "doc.text.magnifyingglass"
        case .tcpPort: return "network"
        case .ping: return "waveform.path.ecg"
        }
    }

    var description: String {
        switch self {
        case .httpStatus: return "Check HTTP response status code"
        case .httpContent: return "Check HTTP response body content"
        case .tcpPort: return "Check TCP port connectivity"
        case .ping: return "Check ICMP ping response"
        }
    }
}

// MARK: - Health Check Result

struct HealthCheckResult {
    let checkId: UUID
    let passed: Bool
    let statusCode: Int?
    let responseTime: Double
    let message: String
    let responseBody: String?
    let timestamp: Date

    init(checkId: UUID, passed: Bool, statusCode: Int? = nil, responseTime: Double, message: String, responseBody: String? = nil) {
        self.checkId = checkId
        self.passed = passed
        self.statusCode = statusCode
        self.responseTime = responseTime
        self.message = message
        self.responseBody = responseBody
        self.timestamp = Date()
    }
}
