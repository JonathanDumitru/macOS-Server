//
//  UptimeRecord.swift
//  Server
//
//  Created by Claude on 1/27/26.
//

import Foundation
import SwiftData

/// Records individual server status checks for uptime calculation
@Model
final class UptimeRecord {
    var id: UUID
    var serverId: UUID
    var timestamp: Date
    var isOnline: Bool
    var responseTime: Double?
    var statusCode: Int?
    var errorMessage: String?

    init(
        id: UUID = UUID(),
        serverId: UUID,
        timestamp: Date = Date(),
        isOnline: Bool,
        responseTime: Double? = nil,
        statusCode: Int? = nil,
        errorMessage: String? = nil
    ) {
        self.id = id
        self.serverId = serverId
        self.timestamp = timestamp
        self.isOnline = isOnline
        self.responseTime = responseTime
        self.statusCode = statusCode
        self.errorMessage = errorMessage
    }
}

// MARK: - Uptime Period

enum UptimePeriod: String, CaseIterable, Identifiable {
    case day24h = "24 Hours"
    case week7d = "7 Days"
    case month30d = "30 Days"
    case quarter90d = "90 Days"

    var id: String { rawValue }

    var days: Int {
        switch self {
        case .day24h: return 1
        case .week7d: return 7
        case .month30d: return 30
        case .quarter90d: return 90
        }
    }

    var startDate: Date {
        Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
    }

    var shortName: String {
        switch self {
        case .day24h: return "24h"
        case .week7d: return "7d"
        case .month30d: return "30d"
        case .quarter90d: return "90d"
        }
    }
}
