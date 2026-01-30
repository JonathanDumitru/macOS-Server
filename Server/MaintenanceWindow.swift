//
//  MaintenanceWindow.swift
//  Server
//
//  Scheduled maintenance periods to silence alerts
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class MaintenanceWindow {
    var id: UUID
    var name: String
    var windowDescription: String
    var startDate: Date
    var endDate: Date
    var isRecurring: Bool
    var recurrenceType: RecurrenceType
    var isEnabled: Bool
    var createdAt: Date

    // Relationships
    var server: Server?  // nil means global (applies to all servers)

    init(
        name: String,
        windowDescription: String = "",
        startDate: Date,
        endDate: Date,
        isRecurring: Bool = false,
        recurrenceType: RecurrenceType = .none,
        isEnabled: Bool = true,
        server: Server? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.windowDescription = windowDescription
        self.startDate = startDate
        self.endDate = endDate
        self.isRecurring = isRecurring
        self.recurrenceType = recurrenceType
        self.isEnabled = isEnabled
        self.server = server
        self.createdAt = Date()
    }

    // MARK: - Computed Properties

    var isActive: Bool {
        guard isEnabled else { return false }

        let now = Date()

        if isRecurring {
            return isActiveForRecurrence(at: now)
        } else {
            return now >= startDate && now <= endDate
        }
    }

    var statusText: String {
        if !isEnabled {
            return "Disabled"
        } else if isActive {
            return "Active"
        } else if Date() < startDate {
            return "Scheduled"
        } else {
            return "Completed"
        }
    }

    var statusColor: Color {
        if !isEnabled {
            return .secondary
        } else if isActive {
            return .orange
        } else if Date() < startDate {
            return .blue
        } else {
            return .green
        }
    }

    var durationText: String {
        let duration = endDate.timeIntervalSince(startDate)
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    var nextOccurrence: Date? {
        guard isEnabled else { return nil }

        let now = Date()

        if !isRecurring {
            return now < startDate ? startDate : nil
        }

        return calculateNextOccurrence(from: now)
    }

    // MARK: - Recurrence Logic

    private func isActiveForRecurrence(at date: Date) -> Bool {
        let calendar = Calendar.current

        // Get time components
        let startComponents = calendar.dateComponents([.hour, .minute], from: startDate)
        let endComponents = calendar.dateComponents([.hour, .minute], from: endDate)
        let currentComponents = calendar.dateComponents([.hour, .minute, .weekday], from: date)

        guard let startHour = startComponents.hour,
              let startMinute = startComponents.minute,
              let endHour = endComponents.hour,
              let endMinute = endComponents.minute,
              let currentHour = currentComponents.hour,
              let currentMinute = currentComponents.minute else {
            return false
        }

        let startMinutes = startHour * 60 + startMinute
        let endMinutes = endHour * 60 + endMinute
        let currentMinutes = currentHour * 60 + currentMinute

        // Check if current time is within window
        let isInTimeWindow: Bool
        if endMinutes > startMinutes {
            isInTimeWindow = currentMinutes >= startMinutes && currentMinutes <= endMinutes
        } else {
            // Window spans midnight
            isInTimeWindow = currentMinutes >= startMinutes || currentMinutes <= endMinutes
        }

        guard isInTimeWindow else { return false }

        // Check day-specific rules
        switch recurrenceType {
        case .daily:
            return true
        case .weekdays:
            let weekday = currentComponents.weekday ?? 1
            return weekday >= 2 && weekday <= 6  // Monday-Friday
        case .weekends:
            let weekday = currentComponents.weekday ?? 1
            return weekday == 1 || weekday == 7  // Sunday or Saturday
        case .weekly:
            let startWeekday = calendar.component(.weekday, from: startDate)
            let currentWeekday = currentComponents.weekday ?? 1
            return startWeekday == currentWeekday
        case .monthly:
            let startDay = calendar.component(.day, from: startDate)
            let currentDay = calendar.component(.day, from: date)
            return startDay == currentDay
        case .none:
            return false
        }
    }

    private func calculateNextOccurrence(from date: Date) -> Date? {
        let calendar = Calendar.current

        switch recurrenceType {
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: startDate)
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: startDate)
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: startDate)
        case .weekdays:
            var next = date
            repeat {
                next = calendar.date(byAdding: .day, value: 1, to: next) ?? next
                let weekday = calendar.component(.weekday, from: next)
                if weekday >= 2 && weekday <= 6 {
                    return next
                }
            } while next.timeIntervalSince(date) < 7 * 24 * 3600
            return nil
        case .weekends:
            var next = date
            repeat {
                next = calendar.date(byAdding: .day, value: 1, to: next) ?? next
                let weekday = calendar.component(.weekday, from: next)
                if weekday == 1 || weekday == 7 {
                    return next
                }
            } while next.timeIntervalSince(date) < 7 * 24 * 3600
            return nil
        case .none:
            return nil
        }
    }
}

// MARK: - Recurrence Type

enum RecurrenceType: String, Codable, CaseIterable {
    case none = "None"
    case daily = "Daily"
    case weekdays = "Weekdays"
    case weekends = "Weekends"
    case weekly = "Weekly"
    case monthly = "Monthly"

    var icon: String {
        switch self {
        case .none: return "calendar"
        case .daily: return "calendar.day.timeline.left"
        case .weekdays: return "briefcase"
        case .weekends: return "sun.max"
        case .weekly: return "calendar.badge.clock"
        case .monthly: return "calendar.badge.plus"
        }
    }
}

// MARK: - Maintenance Service

class MaintenanceService {
    static let shared = MaintenanceService()

    private init() {}

    /// Check if alerts should be silenced for a specific server
    func isInMaintenanceWindow(for server: Server?, modelContext: ModelContext) -> Bool {
        let descriptor = FetchDescriptor<MaintenanceWindow>(
            predicate: #Predicate { $0.isEnabled }
        )

        guard let windows = try? modelContext.fetch(descriptor) else {
            return false
        }

        for window in windows {
            guard window.isActive else { continue }

            // Global window (applies to all servers)
            if window.server == nil {
                return true
            }

            // Server-specific window
            if let windowServer = window.server, let checkServer = server {
                if windowServer.id == checkServer.id {
                    return true
                }
            }
        }

        return false
    }

    /// Get all active maintenance windows
    func getActiveWindows(modelContext: ModelContext) -> [MaintenanceWindow] {
        let descriptor = FetchDescriptor<MaintenanceWindow>(
            predicate: #Predicate { $0.isEnabled }
        )

        guard let windows = try? modelContext.fetch(descriptor) else {
            return []
        }

        return windows.filter { $0.isActive }
    }
}
