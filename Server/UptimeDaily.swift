//
//  UptimeDaily.swift
//  Server
//
//  Created by Claude on 1/27/26.
//

import Foundation
import SwiftData
import SwiftUI

/// Daily aggregate of uptime records for efficient historical queries
@Model
final class UptimeDaily {
    var id: UUID
    var serverId: UUID
    var date: Date  // Normalized to start of day

    var totalChecks: Int
    var successfulChecks: Int
    var failedChecks: Int
    var warningChecks: Int

    var averageResponseTime: Double
    var minResponseTime: Double
    var maxResponseTime: Double

    var totalDowntimeSeconds: Int

    init(
        id: UUID = UUID(),
        serverId: UUID,
        date: Date
    ) {
        self.id = id
        self.serverId = serverId
        self.date = Calendar.current.startOfDay(for: date)
        self.totalChecks = 0
        self.successfulChecks = 0
        self.failedChecks = 0
        self.warningChecks = 0
        self.averageResponseTime = 0
        self.minResponseTime = Double.infinity
        self.maxResponseTime = 0
        self.totalDowntimeSeconds = 0
    }

    // MARK: - Computed Properties

    var uptimePercentage: Double {
        guard totalChecks > 0 else { return 0 }
        return Double(successfulChecks) / Double(totalChecks) * 100
    }

    var uptimeStatus: UptimeStatus {
        UptimeStatus.from(percentage: uptimePercentage)
    }

    var formattedUptime: String {
        String(format: "%.2f%%", uptimePercentage)
    }

    var formattedAverageResponseTime: String {
        guard averageResponseTime > 0 else { return "N/A" }
        return String(format: "%.0fms", averageResponseTime)
    }
}

// MARK: - Uptime Status

enum UptimeStatus: String {
    case excellent = "Excellent"
    case good = "Good"
    case fair = "Fair"
    case poor = "Poor"
    case critical = "Critical"
    case unknown = "Unknown"

    static func from(percentage: Double) -> UptimeStatus {
        switch percentage {
        case 99.9...100: return .excellent
        case 99.0..<99.9: return .good
        case 95.0..<99.0: return .fair
        case 90.0..<95.0: return .poor
        case 0..<90.0: return .critical
        default: return .unknown
        }
    }

    var color: Color {
        switch self {
        case .excellent: return .green
        case .good: return .blue
        case .fair: return .orange
        case .poor: return .red
        case .critical: return .red
        case .unknown: return .gray
        }
    }

    var icon: String {
        switch self {
        case .excellent: return "checkmark.seal.fill"
        case .good: return "checkmark.circle.fill"
        case .fair: return "exclamationmark.circle.fill"
        case .poor: return "exclamationmark.triangle.fill"
        case .critical: return "xmark.circle.fill"
        case .unknown: return "questionmark.circle.fill"
        }
    }
}

// MARK: - SLA Target

struct SLATarget {
    let percentage: Double
    let name: String

    static let threeNines = SLATarget(percentage: 99.9, name: "99.9% (Three Nines)")
    static let twoNines = SLATarget(percentage: 99.0, name: "99% (Two Nines)")
    static let oneNine = SLATarget(percentage: 90.0, name: "90%")

    static let all: [SLATarget] = [.threeNines, .twoNines, .oneNine]

    func allowedDowntime(for period: UptimePeriod) -> TimeInterval {
        let totalSeconds = TimeInterval(period.days * 24 * 60 * 60)
        return totalSeconds * (1 - percentage / 100)
    }

    func formattedAllowedDowntime(for period: UptimePeriod) -> String {
        let seconds = allowedDowntime(for: period)
        let minutes = Int(seconds / 60)
        let hours = minutes / 60
        let remainingMinutes = minutes % 60

        if hours > 0 {
            return "\(hours)h \(remainingMinutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}
