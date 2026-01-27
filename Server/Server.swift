//
//  Server.swift
//  Server
//
//  Created by Jonathan Hines Dumitru on 1/13/26.
//

import Foundation
import SwiftData

@Model
final class Server {
    var id: UUID
    var name: String
    var host: String
    var port: Int
    var serverType: ServerType
    var status: ServerStatus
    var lastChecked: Date?
    var responseTime: Double? // in milliseconds
    var uptime: TimeInterval? // Legacy field - now computed from uptimeRecords
    var notes: String

    // Uptime tracking fields
    var monitoringStartDate: Date? // When we started monitoring this server
    var lastStatusChangeDate: Date? // When the status last changed
    var totalOnlineSeconds: Double = 0 // Cumulative online time
    var totalOfflineSeconds: Double = 0 // Cumulative offline time
    var totalWarningSeconds: Double = 0 // Cumulative warning time

    // Organization
    var group: ServerGroup? // Optional group assignment
    var tagNames: [String] = [] // Tag names stored as strings for simplicity

    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \ServerMetric.server)
    var metrics: [ServerMetric] = []

    @Relationship(deleteRule: .cascade, inverse: \ServerLog.server)
    var logs: [ServerLog] = []

    @Relationship(deleteRule: .cascade, inverse: \UptimeRecord.server)
    var uptimeRecords: [UptimeRecord] = []

    init(
        id: UUID = UUID(),
        name: String,
        host: String,
        port: Int,
        serverType: ServerType = .http,
        status: ServerStatus = .unknown,
        lastChecked: Date? = nil,
        responseTime: Double? = nil,
        uptime: TimeInterval? = nil,
        notes: String = "",
        monitoringStartDate: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.host = host
        self.port = port
        self.serverType = serverType
        self.status = status
        self.lastChecked = lastChecked
        self.responseTime = responseTime
        self.uptime = uptime
        self.notes = notes
        self.monitoringStartDate = monitoringStartDate ?? Date()
        self.lastStatusChangeDate = Date()
    }

    // MARK: - Uptime Computed Properties

    /// Total time this server has been monitored
    var totalMonitoredSeconds: Double {
        guard let startDate = monitoringStartDate else { return 0 }
        return Date().timeIntervalSince(startDate)
    }

    /// Uptime percentage (0-100) based on all tracked time
    var uptimePercentage: Double {
        let total = totalOnlineSeconds + totalOfflineSeconds + totalWarningSeconds
        guard total > 0 else { return 0 }
        // Count online + warning as "up" (warning means degraded but still responding)
        return ((totalOnlineSeconds + totalWarningSeconds) / total) * 100
    }

    /// Strict uptime percentage counting only fully online time
    var strictUptimePercentage: Double {
        let total = totalOnlineSeconds + totalOfflineSeconds + totalWarningSeconds
        guard total > 0 else { return 0 }
        return (totalOnlineSeconds / total) * 100
    }

    /// Current streak duration in seconds
    var currentStreakSeconds: Double {
        guard let lastChange = lastStatusChangeDate else { return 0 }
        return Date().timeIntervalSince(lastChange)
    }

    /// Formatted uptime percentage
    var formattedUptimePercentage: String {
        String(format: "%.2f%%", uptimePercentage)
    }

    /// Formatted current streak
    var formattedCurrentStreak: String {
        formatDuration(currentStreakSeconds)
    }

    /// Calculate uptime stats for a specific time period
    func uptimeStats(for period: UptimePeriod) -> UptimeStats {
        let now = Date()
        let cutoff: Date

        if period == .all {
            cutoff = monitoringStartDate ?? now
        } else {
            cutoff = now.addingTimeInterval(-period.seconds)
        }

        // Filter uptime records within the period
        let relevantRecords = uptimeRecords
            .filter { $0.timestamp >= cutoff }
            .sorted { $0.timestamp < $1.timestamp }

        var onlineSeconds: Double = 0
        var offlineSeconds: Double = 0
        var warningSeconds: Double = 0

        // Calculate durations from records
        for record in relevantRecords {
            guard let duration = record.durationSeconds else { continue }
            switch record.status {
            case .online: onlineSeconds += duration
            case .offline: offlineSeconds += duration
            case .warning: warningSeconds += duration
            case .unknown: break
            }
        }

        // Add current status duration
        let currentDuration = currentStreakSeconds
        switch status {
        case .online: onlineSeconds += min(currentDuration, period.seconds)
        case .offline: offlineSeconds += min(currentDuration, period.seconds)
        case .warning: warningSeconds += min(currentDuration, period.seconds)
        case .unknown: break
        }

        let total = onlineSeconds + offlineSeconds + warningSeconds
        let percentage = total > 0 ? ((onlineSeconds + warningSeconds) / total) * 100 : 0

        // Calculate average response time from metrics in period
        let recentMetrics = metrics.filter { $0.timestamp >= cutoff }
        let avgResponseTime: Double?
        if !recentMetrics.isEmpty, let lastResponse = responseTime {
            avgResponseTime = lastResponse
        } else {
            avgResponseTime = nil
        }

        return UptimeStats(
            uptimePercentage: percentage,
            totalOnlineSeconds: onlineSeconds,
            totalOfflineSeconds: offlineSeconds,
            totalMonitoredSeconds: total,
            currentStreak: currentStreakSeconds,
            currentStreakStatus: status,
            lastStatusChange: lastStatusChangeDate,
            averageResponseTime: avgResponseTime
        )
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let days = Int(seconds) / 86400
        let hours = (Int(seconds) % 86400) / 3600
        let minutes = (Int(seconds) % 3600) / 60

        if days > 0 {
            return "\(days)d \(hours)h"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

enum ServerType: String, Codable, CaseIterable {
    case http = "HTTP"
    case https = "HTTPS"
    case ftp = "FTP"
    case ssh = "SSH"
    case database = "Database"
    case custom = "Custom"
    
    var iconName: String {
        switch self {
        case .http, .https: return "globe"
        case .ftp: return "folder.fill"
        case .ssh: return "terminal.fill"
        case .database: return "cylinder.fill"
        case .custom: return "server.rack"
        }
    }
}

enum ServerStatus: String, Codable {
    case online = "Online"
    case offline = "Offline"
    case warning = "Warning"
    case unknown = "Unknown"
    
    var color: String {
        switch self {
        case .online: return "green"
        case .offline: return "red"
        case .warning: return "orange"
        case .unknown: return "gray"
        }
    }
}
