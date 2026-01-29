//
//  MaintenanceWindow.swift
//  Server
//
//  Created by Claude on 1/28/26.
//

import Foundation
import SwiftData

/// Represents a scheduled maintenance window for a server
@Model
final class MaintenanceWindow {
    var id: UUID
    var serverId: UUID
    var serverName: String

    // Schedule
    var title: String
    var description_: String?
    var scheduledStart: Date
    var scheduledEnd: Date

    // Actual Times
    var actualStart: Date?
    var actualEnd: Date?

    // Status
    var status: MaintenanceStatus

    // Recurrence
    var isRecurring: Bool
    var recurrencePattern: RecurrencePattern?
    var recurrenceInterval: Int // e.g., every 2 weeks
    var recurrenceEndDate: Date?

    // Notifications
    var notifyBeforeMinutes: Int // Send reminder notification
    var notifyOnStart: Bool
    var notifyOnEnd: Bool

    // Notes
    var notes: String?
    var completionNotes: String?

    // Metadata
    var createdAt: Date
    var createdBy: String?

    var isActive: Bool {
        let now = Date()
        if let actualStart = actualStart {
            if let actualEnd = actualEnd {
                return false // Already completed
            }
            return now >= actualStart // In progress
        }
        return status == .inProgress
    }

    var isUpcoming: Bool {
        let now = Date()
        return status == .scheduled && scheduledStart > now
    }

    var isPast: Bool {
        return status == .completed || status == .cancelled
    }

    var duration: TimeInterval {
        return scheduledEnd.timeIntervalSince(scheduledStart)
    }

    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60

        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }

    var timeUntilStart: TimeInterval? {
        guard status == .scheduled else { return nil }
        return scheduledStart.timeIntervalSince(Date())
    }

    var formattedTimeUntilStart: String? {
        guard let interval = timeUntilStart, interval > 0 else { return nil }

        let days = Int(interval) / 86400
        let hours = (Int(interval) % 86400) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if days > 0 {
            return "in \(days)d \(hours)h"
        } else if hours > 0 {
            return "in \(hours)h \(minutes)m"
        } else {
            return "in \(minutes)m"
        }
    }

    init(
        serverId: UUID,
        serverName: String,
        title: String,
        scheduledStart: Date,
        scheduledEnd: Date
    ) {
        self.id = UUID()
        self.serverId = serverId
        self.serverName = serverName
        self.title = title
        self.scheduledStart = scheduledStart
        self.scheduledEnd = scheduledEnd
        self.status = .scheduled
        self.isRecurring = false
        self.recurrenceInterval = 1
        self.notifyBeforeMinutes = 30
        self.notifyOnStart = true
        self.notifyOnEnd = true
        self.createdAt = Date()
    }

    func start() {
        status = .inProgress
        actualStart = Date()
    }

    func complete(notes: String? = nil) {
        status = .completed
        actualEnd = Date()
        completionNotes = notes
    }

    func cancel() {
        status = .cancelled
    }

    func createNextOccurrence() -> MaintenanceWindow? {
        guard isRecurring, let pattern = recurrencePattern else { return nil }

        let calendar = Calendar.current
        var nextStart: Date?
        var nextEnd: Date?

        switch pattern {
        case .daily:
            nextStart = calendar.date(byAdding: .day, value: recurrenceInterval, to: scheduledStart)
            nextEnd = calendar.date(byAdding: .day, value: recurrenceInterval, to: scheduledEnd)
        case .weekly:
            nextStart = calendar.date(byAdding: .weekOfYear, value: recurrenceInterval, to: scheduledStart)
            nextEnd = calendar.date(byAdding: .weekOfYear, value: recurrenceInterval, to: scheduledEnd)
        case .monthly:
            nextStart = calendar.date(byAdding: .month, value: recurrenceInterval, to: scheduledStart)
            nextEnd = calendar.date(byAdding: .month, value: recurrenceInterval, to: scheduledEnd)
        }

        guard let start = nextStart, let end = nextEnd else { return nil }

        // Check if past recurrence end date
        if let endDate = recurrenceEndDate, start > endDate {
            return nil
        }

        let nextWindow = MaintenanceWindow(
            serverId: serverId,
            serverName: serverName,
            title: title,
            scheduledStart: start,
            scheduledEnd: end
        )

        nextWindow.description_ = description_
        nextWindow.isRecurring = isRecurring
        nextWindow.recurrencePattern = recurrencePattern
        nextWindow.recurrenceInterval = recurrenceInterval
        nextWindow.recurrenceEndDate = recurrenceEndDate
        nextWindow.notifyBeforeMinutes = notifyBeforeMinutes
        nextWindow.notifyOnStart = notifyOnStart
        nextWindow.notifyOnEnd = notifyOnEnd
        nextWindow.notes = notes

        return nextWindow
    }
}

// MARK: - Enums

enum MaintenanceStatus: String, Codable, CaseIterable {
    case scheduled = "Scheduled"
    case inProgress = "In Progress"
    case completed = "Completed"
    case cancelled = "Cancelled"

    var icon: String {
        switch self {
        case .scheduled: return "calendar.badge.clock"
        case .inProgress: return "wrench.and.screwdriver"
        case .completed: return "checkmark.circle"
        case .cancelled: return "xmark.circle"
        }
    }

    var color: String {
        switch self {
        case .scheduled: return "blue"
        case .inProgress: return "orange"
        case .completed: return "green"
        case .cancelled: return "gray"
        }
    }
}

enum RecurrencePattern: String, Codable, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"

    var description: String {
        switch self {
        case .daily: return "Repeats daily"
        case .weekly: return "Repeats weekly"
        case .monthly: return "Repeats monthly"
        }
    }
}
