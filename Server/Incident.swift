//
//  Incident.swift
//  Server
//
//  Created by Claude on 1/28/26.
//

import Foundation
import SwiftData

/// Represents a server incident (outage, recovery, warning, etc.)
@Model
final class Incident {
    var id: UUID
    var serverId: UUID
    var serverName: String
    var serverHost: String

    var type: IncidentType
    var status: IncidentStatus
    var severity: IncidentSeverity

    var startedAt: Date
    var resolvedAt: Date?
    var acknowledgedAt: Date?
    var acknowledgedBy: String?

    var title: String
    var incidentDescription: String?
    var resolution: String?

    // Duration tracking
    var durationSeconds: Int? {
        guard let resolved = resolvedAt else {
            return Int(Date().timeIntervalSince(startedAt))
        }
        return Int(resolved.timeIntervalSince(startedAt))
    }

    var formattedDuration: String {
        guard let seconds = durationSeconds else { return "Unknown" }

        if seconds < 60 {
            return "\(seconds)s"
        } else if seconds < 3600 {
            let minutes = seconds / 60
            return "\(minutes)m"
        } else if seconds < 86400 {
            let hours = seconds / 3600
            let minutes = (seconds % 3600) / 60
            return "\(hours)h \(minutes)m"
        } else {
            let days = seconds / 86400
            let hours = (seconds % 86400) / 3600
            return "\(days)d \(hours)h"
        }
    }

    init(
        serverId: UUID,
        serverName: String,
        serverHost: String,
        type: IncidentType,
        severity: IncidentSeverity = .medium,
        title: String,
        description: String? = nil
    ) {
        self.id = UUID()
        self.serverId = serverId
        self.serverName = serverName
        self.serverHost = serverHost
        self.type = type
        self.status = .active
        self.severity = severity
        self.startedAt = Date()
        self.title = title
        self.incidentDescription = description
    }

    func resolve(resolution: String? = nil) {
        self.status = .resolved
        self.resolvedAt = Date()
        self.resolution = resolution
    }

    func acknowledge(by user: String = "User") {
        self.acknowledgedAt = Date()
        self.acknowledgedBy = user
    }
}

// MARK: - Enums

enum IncidentType: String, Codable, CaseIterable {
    case outage = "Outage"
    case degraded = "Degraded Performance"
    case warning = "Warning"
    case sslExpiring = "SSL Expiring"
    case sslExpired = "SSL Expired"
    case highResponseTime = "High Response Time"
    case recovery = "Recovery"
    case maintenance = "Maintenance"

    var icon: String {
        switch self {
        case .outage: return "xmark.circle.fill"
        case .degraded: return "exclamationmark.triangle.fill"
        case .warning: return "exclamationmark.circle.fill"
        case .sslExpiring: return "lock.trianglebadge.exclamationmark"
        case .sslExpired: return "lock.slash"
        case .highResponseTime: return "clock.badge.exclamationmark"
        case .recovery: return "checkmark.circle.fill"
        case .maintenance: return "wrench.and.screwdriver"
        }
    }

    var color: String {
        switch self {
        case .outage, .sslExpired: return "red"
        case .degraded, .warning, .sslExpiring, .highResponseTime: return "orange"
        case .recovery: return "green"
        case .maintenance: return "blue"
        }
    }
}

enum IncidentStatus: String, Codable, CaseIterable {
    case active = "Active"
    case acknowledged = "Acknowledged"
    case resolved = "Resolved"

    var color: String {
        switch self {
        case .active: return "red"
        case .acknowledged: return "orange"
        case .resolved: return "green"
        }
    }
}

enum IncidentSeverity: String, Codable, CaseIterable {
    case critical = "Critical"
    case high = "High"
    case medium = "Medium"
    case low = "Low"

    var color: String {
        switch self {
        case .critical: return "red"
        case .high: return "orange"
        case .medium: return "yellow"
        case .low: return "blue"
        }
    }

    var weight: Int {
        switch self {
        case .critical: return 4
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }
}
