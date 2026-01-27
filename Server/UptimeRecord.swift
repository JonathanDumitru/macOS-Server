//
//  UptimeRecord.swift
//  Server
//
//  Created by Claude on 1/27/26.
//

import Foundation
import SwiftData

/// Records a status change for uptime tracking
@Model
final class UptimeRecord {
    var id: UUID
    var timestamp: Date
    var status: ServerStatus
    var durationSeconds: Double? // Duration this status lasted (filled when status changes)

    // Relationship
    var server: Server?

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        status: ServerStatus,
        durationSeconds: Double? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.status = status
        self.durationSeconds = durationSeconds
    }
}

// MARK: - Uptime Statistics
struct UptimeStats {
    let uptimePercentage: Double // 0-100
    let totalOnlineSeconds: Double
    let totalOfflineSeconds: Double
    let totalMonitoredSeconds: Double
    let currentStreak: TimeInterval // Current online/offline streak
    let currentStreakStatus: ServerStatus
    let lastStatusChange: Date?
    let averageResponseTime: Double?

    var formattedPercentage: String {
        String(format: "%.2f%%", uptimePercentage)
    }

    var formattedStreak: String {
        formatDuration(currentStreak)
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let days = Int(seconds) / 86400
        let hours = (Int(seconds) % 86400) / 3600
        let minutes = (Int(seconds) % 3600) / 60

        if days > 0 {
            return "\(days)d \(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Time Period for Uptime Calculation
enum UptimePeriod: String, CaseIterable {
    case hour = "1 Hour"
    case day = "24 Hours"
    case week = "7 Days"
    case month = "30 Days"
    case all = "All Time"

    var seconds: TimeInterval {
        switch self {
        case .hour: return 3600
        case .day: return 86400
        case .week: return 604800
        case .month: return 2592000
        case .all: return .infinity
        }
    }
}
