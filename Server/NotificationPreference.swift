//
//  NotificationPreference.swift
//  Server
//
//  Created by Claude on 1/27/26.
//

import Foundation
import SwiftData

@Model
final class NotificationPreference {
    var id: UUID
    var serverId: UUID? // nil = global setting

    // Status notifications
    var notifyOnOffline: Bool
    var notifyOnOnline: Bool
    var notifyOnWarning: Bool

    // Response time notifications
    var notifyOnResponseThreshold: Bool
    var responseThresholdMs: Double

    // SSL notifications
    var notifyOnSSLExpiry: Bool
    var sslExpiryDaysThreshold: Int

    // Sound settings
    var playSound: Bool
    var useCriticalSound: Bool

    // Quiet hours
    var quietHoursEnabled: Bool
    var quietHoursStart: Int // Hour 0-23
    var quietHoursEnd: Int

    // Created/Updated
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        serverId: UUID? = nil,
        notifyOnOffline: Bool = true,
        notifyOnOnline: Bool = true,
        notifyOnWarning: Bool = true,
        notifyOnResponseThreshold: Bool = false,
        responseThresholdMs: Double = 1000,
        notifyOnSSLExpiry: Bool = true,
        sslExpiryDaysThreshold: Int = 30,
        playSound: Bool = true,
        useCriticalSound: Bool = false,
        quietHoursEnabled: Bool = false,
        quietHoursStart: Int = 22,
        quietHoursEnd: Int = 7,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.serverId = serverId
        self.notifyOnOffline = notifyOnOffline
        self.notifyOnOnline = notifyOnOnline
        self.notifyOnWarning = notifyOnWarning
        self.notifyOnResponseThreshold = notifyOnResponseThreshold
        self.responseThresholdMs = responseThresholdMs
        self.notifyOnSSLExpiry = notifyOnSSLExpiry
        self.sslExpiryDaysThreshold = sslExpiryDaysThreshold
        self.playSound = playSound
        self.useCriticalSound = useCriticalSound
        self.quietHoursEnabled = quietHoursEnabled
        self.quietHoursStart = quietHoursStart
        self.quietHoursEnd = quietHoursEnd
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Quiet Hours Check

    var isInQuietHours: Bool {
        guard quietHoursEnabled else { return false }

        let hour = Calendar.current.component(.hour, from: Date())

        if quietHoursStart < quietHoursEnd {
            return hour >= quietHoursStart && hour < quietHoursEnd
        } else {
            return hour >= quietHoursStart || hour < quietHoursEnd
        }
    }

    // MARK: - Default Global Preferences

    static func createDefault() -> NotificationPreference {
        NotificationPreference()
    }
}

// MARK: - Notification Type

enum NotificationType: String, Codable, CaseIterable {
    case statusOffline = "Server Offline"
    case statusOnline = "Server Online"
    case statusWarning = "Server Warning"
    case responseThreshold = "High Response Time"
    case sslExpiry = "SSL Certificate Expiry"

    var icon: String {
        switch self {
        case .statusOffline: return "xmark.circle.fill"
        case .statusOnline: return "checkmark.circle.fill"
        case .statusWarning: return "exclamationmark.triangle.fill"
        case .responseThreshold: return "clock.fill"
        case .sslExpiry: return "lock.fill"
        }
    }

    var defaultEnabled: Bool {
        switch self {
        case .statusOffline, .statusOnline, .sslExpiry: return true
        case .statusWarning, .responseThreshold: return false
        }
    }
}
