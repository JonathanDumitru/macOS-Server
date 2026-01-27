//
//  NotificationService.swift
//  Server
//
//  Created by Claude on 1/27/26.
//

import Foundation
import UserNotifications
import AppKit

@MainActor
class NotificationService: ObservableObject {
    static let shared = NotificationService()

    @Published var isAuthorized = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private var previousServerStates: [UUID: ServerStatus] = [:]
    private var notificationCooldowns: [String: Date] = [:]
    private let cooldownInterval: TimeInterval = 300 // 5 minutes between same notifications

    private init() {
        Task {
            await checkAuthorizationStatus()
        }
    }

    // MARK: - Authorization

    func requestAuthorization() async {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted
            await checkAuthorizationStatus()
        } catch {
            print("Notification authorization failed: \(error)")
        }
    }

    func checkAuthorizationStatus() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
        isAuthorized = settings.authorizationStatus == .authorized
    }

    func openSystemPreferences() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Setup

    func setupNotificationCategories() {
        let checkAction = UNNotificationAction(
            identifier: "CHECK_NOW",
            title: "Check Now",
            options: .foreground
        )

        let dismissAction = UNNotificationAction(
            identifier: "DISMISS",
            title: "Dismiss",
            options: .destructive
        )

        let serverStatusCategory = UNNotificationCategory(
            identifier: "SERVER_STATUS",
            actions: [checkAction, dismissAction],
            intentIdentifiers: []
        )

        let sslExpiryCategory = UNNotificationCategory(
            identifier: "SSL_EXPIRY",
            actions: [checkAction, dismissAction],
            intentIdentifiers: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([
            serverStatusCategory,
            sslExpiryCategory
        ])
    }

    // MARK: - Server Status Notifications

    func checkServerStatusChange(server: Server, previousStatus: ServerStatus?) {
        guard isAuthorized else { return }

        let newStatus = server.status
        guard let previous = previousStatus, previous != newStatus else {
            // Store initial state
            previousServerStates[server.id] = newStatus
            return
        }

        // Status changed
        if newStatus == .offline && previous != .offline {
            sendServerOfflineNotification(server: server)
        } else if newStatus == .online && previous == .offline {
            sendServerOnlineNotification(server: server)
        } else if newStatus == .warning && previous == .online {
            sendServerWarningNotification(server: server)
        }

        previousServerStates[server.id] = newStatus
    }

    func getPreviousStatus(for server: Server) -> ServerStatus? {
        return previousServerStates[server.id]
    }

    func storePreviousStatus(for server: Server) {
        previousServerStates[server.id] = server.status
    }

    private func sendServerOfflineNotification(server: Server) {
        let identifier = "offline-\(server.id.uuidString)"
        guard !isInCooldown(identifier: identifier) else { return }

        sendNotification(
            title: "Server Offline",
            body: "\(server.name) is now offline",
            subtitle: server.host,
            identifier: identifier,
            categoryIdentifier: "SERVER_STATUS",
            sound: .default
        )
    }

    private func sendServerOnlineNotification(server: Server) {
        let identifier = "online-\(server.id.uuidString)"
        guard !isInCooldown(identifier: identifier) else { return }

        sendNotification(
            title: "Server Back Online",
            body: "\(server.name) is now online",
            subtitle: server.host,
            identifier: identifier,
            categoryIdentifier: "SERVER_STATUS",
            sound: .default
        )
    }

    private func sendServerWarningNotification(server: Server) {
        let identifier = "warning-\(server.id.uuidString)"
        guard !isInCooldown(identifier: identifier) else { return }

        sendNotification(
            title: "Server Warning",
            body: "\(server.name) has a warning status",
            subtitle: server.host,
            identifier: identifier,
            categoryIdentifier: "SERVER_STATUS",
            sound: .default
        )
    }

    // MARK: - Response Time Notifications

    func checkResponseThreshold(server: Server, threshold: Double) {
        guard isAuthorized else { return }
        guard let responseTime = server.responseTime, responseTime > threshold else { return }

        let identifier = "threshold-\(server.id.uuidString)"
        guard !isInCooldown(identifier: identifier) else { return }

        sendNotification(
            title: "High Response Time",
            body: "\(server.name): \(Int(responseTime))ms (threshold: \(Int(threshold))ms)",
            subtitle: server.host,
            identifier: identifier,
            categoryIdentifier: "SERVER_STATUS",
            sound: .default
        )
    }

    // MARK: - SSL Notifications

    func sendSSLExpiryNotification(server: Server, daysRemaining: Int) {
        guard isAuthorized else { return }

        let identifier = "ssl-expiry-\(server.id.uuidString)-\(daysRemaining)"
        guard !isInCooldown(identifier: identifier) else { return }

        let urgency: String
        if daysRemaining <= 0 {
            urgency = "has expired"
        } else if daysRemaining <= 7 {
            urgency = "expires in \(daysRemaining) day\(daysRemaining == 1 ? "" : "s")"
        } else {
            urgency = "expires in \(daysRemaining) days"
        }

        sendNotification(
            title: "SSL Certificate Warning",
            body: "\(server.name) certificate \(urgency)",
            subtitle: server.host,
            identifier: identifier,
            categoryIdentifier: "SSL_EXPIRY",
            sound: daysRemaining <= 7 ? .defaultCritical : .default
        )
    }

    // MARK: - Core Notification Sending

    private func sendNotification(
        title: String,
        body: String,
        subtitle: String? = nil,
        identifier: String,
        categoryIdentifier: String? = nil,
        sound: UNNotificationSound? = .default
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        if let subtitle = subtitle {
            content.subtitle = subtitle
        }
        if let sound = sound {
            content.sound = sound
        }
        if let categoryIdentifier = categoryIdentifier {
            content.categoryIdentifier = categoryIdentifier
        }

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil // Immediate delivery
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to send notification: \(error)")
            }
        }

        // Set cooldown
        notificationCooldowns[identifier] = Date()
    }

    // MARK: - Cooldown Management

    private func isInCooldown(identifier: String) -> Bool {
        guard let lastSent = notificationCooldowns[identifier] else { return false }
        return Date().timeIntervalSince(lastSent) < cooldownInterval
    }

    func clearCooldowns() {
        notificationCooldowns.removeAll()
    }

    // MARK: - Badge Management

    func updateBadgeCount(_ count: Int) {
        NSApplication.shared.dockTile.badgeLabel = count > 0 ? "\(count)" : nil
    }

    func clearBadge() {
        NSApplication.shared.dockTile.badgeLabel = nil
    }

    // MARK: - Remove Notifications

    func removeDeliveredNotifications(for server: Server) {
        let identifiers = [
            "offline-\(server.id.uuidString)",
            "online-\(server.id.uuidString)",
            "warning-\(server.id.uuidString)",
            "threshold-\(server.id.uuidString)"
        ]
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    func removeAllDeliveredNotifications() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
}

// MARK: - Quiet Hours

struct QuietHours {
    var isEnabled: Bool = false
    var startHour: Int = 22 // 10 PM
    var endHour: Int = 7 // 7 AM

    var isCurrentlyQuiet: Bool {
        guard isEnabled else { return false }

        let hour = Calendar.current.component(.hour, from: Date())

        if startHour < endHour {
            // Simple case: quiet hours don't span midnight
            return hour >= startHour && hour < endHour
        } else {
            // Quiet hours span midnight
            return hour >= startHour || hour < endHour
        }
    }
}
