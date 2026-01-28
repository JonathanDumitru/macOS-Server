//
//  MaintenanceService.swift
//  Server
//
//  Created by Claude on 1/28/26.
//

import Foundation
import SwiftData
import UserNotifications
import os.log

private let logger = Logger(subsystem: "com.server.app", category: "Maintenance")

@MainActor
class MaintenanceService: ObservableObject {
    static let shared = MaintenanceService()

    private var modelContext: ModelContext?
    private var checkTask: Task<Void, Never>?

    @Published var upcomingMaintenance: [MaintenanceWindow] = []
    @Published var activeMaintenance: [MaintenanceWindow] = []

    private init() {}

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        startMaintenanceMonitor()
        refreshMaintenance()
    }

    // MARK: - Monitoring

    private func startMaintenanceMonitor() {
        checkTask?.cancel()
        checkTask = Task {
            while !Task.isCancelled {
                await checkMaintenanceWindows()
                try? await Task.sleep(for: .seconds(60)) // Check every minute
            }
        }
    }

    private func checkMaintenanceWindows() async {
        guard let context = modelContext else { return }

        let now = Date()

        // Fetch scheduled maintenance windows
        let descriptor = FetchDescriptor<MaintenanceWindow>(
            predicate: #Predicate { $0.status == .scheduled || $0.status == .inProgress }
        )

        guard let windows = try? context.fetch(descriptor) else { return }

        for window in windows {
            // Check if maintenance should start
            if window.status == .scheduled && now >= window.scheduledStart {
                logger.info("Starting maintenance: \(window.title)")
                window.start()

                // Mark server as in maintenance in IncidentService
                IncidentService.shared.setMaintenance(serverId: window.serverId, inMaintenance: true)

                // Send start notification
                if window.notifyOnStart {
                    sendMaintenanceNotification(
                        title: "Maintenance Started",
                        body: "\(window.title) for \(window.serverName) has begun",
                        identifier: "maintenance-start-\(window.id.uuidString)"
                    )
                }
            }

            // Check if maintenance should auto-complete
            if window.status == .inProgress && now >= window.scheduledEnd {
                logger.info("Auto-completing maintenance: \(window.title)")
                window.complete(notes: "Auto-completed at scheduled end time")

                // Clear maintenance mode
                IncidentService.shared.setMaintenance(serverId: window.serverId, inMaintenance: false)

                // Send end notification
                if window.notifyOnEnd {
                    sendMaintenanceNotification(
                        title: "Maintenance Completed",
                        body: "\(window.title) for \(window.serverName) has completed",
                        identifier: "maintenance-end-\(window.id.uuidString)"
                    )
                }

                // Create next occurrence if recurring
                if let nextWindow = window.createNextOccurrence() {
                    context.insert(nextWindow)
                    logger.info("Created next maintenance occurrence: \(nextWindow.scheduledStart)")
                }
            }

            // Send reminder notification
            if window.status == .scheduled && window.notifyBeforeMinutes > 0 {
                let reminderTime = window.scheduledStart.addingTimeInterval(-Double(window.notifyBeforeMinutes * 60))
                if now >= reminderTime && now < window.scheduledStart {
                    let identifier = "maintenance-reminder-\(window.id.uuidString)"
                    if !hasRecentlyNotified(identifier: identifier) {
                        sendMaintenanceNotification(
                            title: "Upcoming Maintenance",
                            body: "\(window.title) for \(window.serverName) starts in \(window.notifyBeforeMinutes) minutes",
                            identifier: identifier
                        )
                    }
                }
            }
        }

        try? context.save()
        refreshMaintenance()
    }

    func refreshMaintenance() {
        guard let context = modelContext else { return }

        let now = Date()

        // Upcoming (scheduled, in future)
        var upcomingDescriptor = FetchDescriptor<MaintenanceWindow>(
            predicate: #Predicate { $0.status == .scheduled },
            sortBy: [SortDescriptor(\MaintenanceWindow.scheduledStart)]
        )
        upcomingDescriptor.fetchLimit = 10
        upcomingMaintenance = (try? context.fetch(upcomingDescriptor)) ?? []

        // Active (in progress)
        let activeDescriptor = FetchDescriptor<MaintenanceWindow>(
            predicate: #Predicate { $0.status == .inProgress }
        )
        activeMaintenance = (try? context.fetch(activeDescriptor)) ?? []
    }

    // MARK: - CRUD Operations

    func scheduleMaintenance(
        for server: Server,
        title: String,
        description: String?,
        startDate: Date,
        endDate: Date,
        isRecurring: Bool = false,
        recurrencePattern: RecurrencePattern? = nil,
        recurrenceInterval: Int = 1
    ) -> MaintenanceWindow {
        let window = MaintenanceWindow(
            serverId: server.id,
            serverName: server.name,
            title: title,
            scheduledStart: startDate,
            scheduledEnd: endDate
        )

        window.description_ = description
        window.isRecurring = isRecurring
        window.recurrencePattern = recurrencePattern
        window.recurrenceInterval = recurrenceInterval

        modelContext?.insert(window)
        try? modelContext?.save()

        refreshMaintenance()
        logger.info("Scheduled maintenance: \(title) for \(server.name)")

        return window
    }

    func startMaintenance(_ window: MaintenanceWindow) {
        window.start()
        IncidentService.shared.setMaintenance(serverId: window.serverId, inMaintenance: true)

        if window.notifyOnStart {
            sendMaintenanceNotification(
                title: "Maintenance Started",
                body: "\(window.title) for \(window.serverName) has begun",
                identifier: "maintenance-start-\(window.id.uuidString)"
            )
        }

        try? modelContext?.save()
        refreshMaintenance()
    }

    func completeMaintenance(_ window: MaintenanceWindow, notes: String? = nil) {
        window.complete(notes: notes)
        IncidentService.shared.setMaintenance(serverId: window.serverId, inMaintenance: false)

        if window.notifyOnEnd {
            sendMaintenanceNotification(
                title: "Maintenance Completed",
                body: "\(window.title) for \(window.serverName) has completed",
                identifier: "maintenance-end-\(window.id.uuidString)"
            )
        }

        // Create next occurrence if recurring
        if let nextWindow = window.createNextOccurrence() {
            modelContext?.insert(nextWindow)
        }

        try? modelContext?.save()
        refreshMaintenance()
    }

    func cancelMaintenance(_ window: MaintenanceWindow) {
        window.cancel()

        // Clear maintenance mode if was in progress
        if window.status == .inProgress {
            IncidentService.shared.setMaintenance(serverId: window.serverId, inMaintenance: false)
        }

        try? modelContext?.save()
        refreshMaintenance()
    }

    func deleteMaintenance(_ window: MaintenanceWindow) {
        modelContext?.delete(window)
        try? modelContext?.save()
        refreshMaintenance()
    }

    func getMaintenanceWindows(for serverId: UUID) -> [MaintenanceWindow] {
        guard let context = modelContext else { return [] }

        let descriptor = FetchDescriptor<MaintenanceWindow>(
            predicate: #Predicate { $0.serverId == serverId },
            sortBy: [SortDescriptor(\MaintenanceWindow.scheduledStart, order: .reverse)]
        )

        return (try? context.fetch(descriptor)) ?? []
    }

    func isInMaintenanceWindow(serverId: UUID) -> Bool {
        guard let context = modelContext else { return false }

        let descriptor = FetchDescriptor<MaintenanceWindow>(
            predicate: #Predicate { $0.serverId == serverId && $0.status == .inProgress }
        )

        let windows = (try? context.fetch(descriptor)) ?? []
        return !windows.isEmpty
    }

    // MARK: - Notifications

    private var recentNotifications: [String: Date] = [:]

    private func hasRecentlyNotified(identifier: String) -> Bool {
        guard let lastNotified = recentNotifications[identifier] else { return false }
        return Date().timeIntervalSince(lastNotified) < 3600 // Within last hour
    }

    private func sendMaintenanceNotification(title: String, body: String, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "MAINTENANCE"

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
        recentNotifications[identifier] = Date()
    }
}
