//
//  AlertThreshold.swift
//  Server
//
//  Created by Claude on 1/27/26.
//

import Foundation
import SwiftData

/// Defines a threshold for triggering alerts
@Model
final class AlertThreshold {
    var id: UUID
    var metricType: AlertMetricType
    var thresholdValue: Double
    var comparison: ThresholdComparison
    var isEnabled: Bool
    var severity: AlertSeverity
    var cooldownMinutes: Int // Minimum time between repeated alerts

    // Track when we last alerted for this threshold per server
    var lastAlertTimestamps: [String: Date] = [:] // serverID: lastAlertTime

    init(
        id: UUID = UUID(),
        metricType: AlertMetricType,
        thresholdValue: Double,
        comparison: ThresholdComparison = .greaterThan,
        isEnabled: Bool = true,
        severity: AlertSeverity = .warning,
        cooldownMinutes: Int = 5
    ) {
        self.id = id
        self.metricType = metricType
        self.thresholdValue = thresholdValue
        self.comparison = comparison
        self.isEnabled = isEnabled
        self.severity = severity
        self.cooldownMinutes = cooldownMinutes
    }

    /// Check if this threshold is exceeded by the given value
    func isExceeded(by value: Double) -> Bool {
        switch comparison {
        case .greaterThan:
            return value > thresholdValue
        case .lessThan:
            return value < thresholdValue
        case .greaterThanOrEqual:
            return value >= thresholdValue
        case .lessThanOrEqual:
            return value <= thresholdValue
        case .equals:
            return abs(value - thresholdValue) < 0.001
        }
    }

    /// Check if we should alert for this server (respects cooldown)
    func shouldAlert(forServerID serverID: String) -> Bool {
        guard isEnabled else { return false }

        if let lastAlert = lastAlertTimestamps[serverID] {
            let cooldownInterval = TimeInterval(cooldownMinutes * 60)
            return Date().timeIntervalSince(lastAlert) >= cooldownInterval
        }

        return true
    }

    /// Mark that we alerted for this server
    func recordAlert(forServerID serverID: String) {
        lastAlertTimestamps[serverID] = Date()
    }
}

// MARK: - Alert Metric Type

enum AlertMetricType: String, Codable, CaseIterable, Identifiable {
    case cpuUsage = "CPU Usage"
    case memoryUsage = "Memory Usage"
    case diskUsage = "Disk Usage"
    case responseTime = "Response Time"
    case networkIn = "Network In"
    case networkOut = "Network Out"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .cpuUsage: return "cpu"
        case .memoryUsage: return "memorychip"
        case .diskUsage: return "internaldrive"
        case .responseTime: return "clock"
        case .networkIn: return "arrow.down.circle"
        case .networkOut: return "arrow.up.circle"
        }
    }

    var unit: String {
        switch self {
        case .cpuUsage, .memoryUsage, .diskUsage: return "%"
        case .responseTime: return "ms"
        case .networkIn, .networkOut: return "MB/s"
        }
    }

    var defaultThreshold: Double {
        switch self {
        case .cpuUsage: return 80
        case .memoryUsage: return 85
        case .diskUsage: return 90
        case .responseTime: return 2000
        case .networkIn: return 100
        case .networkOut: return 100
        }
    }

    var minValue: Double {
        return 0
    }

    var maxValue: Double {
        switch self {
        case .cpuUsage, .memoryUsage, .diskUsage: return 100
        case .responseTime: return 10000
        case .networkIn, .networkOut: return 1000
        }
    }
}

// MARK: - Threshold Comparison

enum ThresholdComparison: String, Codable, CaseIterable {
    case greaterThan = ">"
    case lessThan = "<"
    case greaterThanOrEqual = ">="
    case lessThanOrEqual = "<="
    case equals = "="

    var description: String {
        switch self {
        case .greaterThan: return "Greater than"
        case .lessThan: return "Less than"
        case .greaterThanOrEqual: return "Greater than or equal"
        case .lessThanOrEqual: return "Less than or equal"
        case .equals: return "Equals"
        }
    }
}

// MARK: - Alert Severity

enum AlertSeverity: String, Codable, CaseIterable {
    case info = "Info"
    case warning = "Warning"
    case critical = "Critical"

    var icon: String {
        switch self {
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .critical: return "xmark.octagon.fill"
        }
    }

    var color: String {
        switch self {
        case .info: return "blue"
        case .warning: return "orange"
        case .critical: return "red"
        }
    }
}

// MARK: - Alert Event

/// Records when an alert was triggered
@Model
final class AlertEvent {
    var id: UUID
    var timestamp: Date
    var metricType: AlertMetricType
    var thresholdValue: Double
    var actualValue: Double
    var severity: AlertSeverity
    var serverName: String
    var serverID: String
    var isAcknowledged: Bool

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        metricType: AlertMetricType,
        thresholdValue: Double,
        actualValue: Double,
        severity: AlertSeverity,
        serverName: String,
        serverID: String,
        isAcknowledged: Bool = false
    ) {
        self.id = id
        self.timestamp = timestamp
        self.metricType = metricType
        self.thresholdValue = thresholdValue
        self.actualValue = actualValue
        self.severity = severity
        self.serverName = serverName
        self.serverID = serverID
        self.isAcknowledged = isAcknowledged
    }
}

// MARK: - Default Thresholds

extension AlertThreshold {
    static func createDefaultThresholds() -> [AlertThreshold] {
        [
            AlertThreshold(
                metricType: .cpuUsage,
                thresholdValue: 80,
                comparison: .greaterThan,
                severity: .warning,
                cooldownMinutes: 5
            ),
            AlertThreshold(
                metricType: .cpuUsage,
                thresholdValue: 95,
                comparison: .greaterThan,
                severity: .critical,
                cooldownMinutes: 2
            ),
            AlertThreshold(
                metricType: .memoryUsage,
                thresholdValue: 85,
                comparison: .greaterThan,
                severity: .warning,
                cooldownMinutes: 5
            ),
            AlertThreshold(
                metricType: .memoryUsage,
                thresholdValue: 95,
                comparison: .greaterThan,
                severity: .critical,
                cooldownMinutes: 2
            ),
            AlertThreshold(
                metricType: .diskUsage,
                thresholdValue: 85,
                comparison: .greaterThan,
                severity: .warning,
                cooldownMinutes: 30
            ),
            AlertThreshold(
                metricType: .diskUsage,
                thresholdValue: 95,
                comparison: .greaterThan,
                severity: .critical,
                cooldownMinutes: 10
            ),
            AlertThreshold(
                metricType: .responseTime,
                thresholdValue: 2000,
                comparison: .greaterThan,
                severity: .warning,
                cooldownMinutes: 5
            ),
            AlertThreshold(
                metricType: .responseTime,
                thresholdValue: 5000,
                comparison: .greaterThan,
                severity: .critical,
                cooldownMinutes: 2
            )
        ]
    }
}
