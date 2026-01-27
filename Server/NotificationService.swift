//
//  NotificationService.swift
//  Server
//
//  Created by Claude on 1/27/26.
//

import Foundation
import UserNotifications
import AppKit
import os.log

private let logger = Logger(subsystem: "com.server.app", category: "Notifications")

@MainActor
class NotificationService: ObservableObject {
    static let shared = NotificationService()

    @Published var isAuthorized = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private var previousServerStates: [UUID: ServerStatus] = [:]
    private var notificationCooldowns: [String: Date] = [:]
    private let cooldownInterval: TimeInterval = 300 // 5 minutes between same notifications

    // MARK: - Preference Accessors (read from AppStorage defaults)

    private var notifyOnOffline: Bool {
        UserDefaults.standard.object(forKey: "notifyOnOffline") as? Bool ?? true
    }

    private var notifyOnOnline: Bool {
        UserDefaults.standard.object(forKey: "notifyOnOnline") as? Bool ?? true
    }

    private var notifyOnWarning: Bool {
        UserDefaults.standard.object(forKey: "notifyOnWarning") as? Bool ?? true
    }

    private var notifyOnSSLExpiry: Bool {
        UserDefaults.standard.object(forKey: "notifyOnSSLExpiry") as? Bool ?? true
    }

    private var sslExpiryDaysThreshold: Int {
        UserDefaults.standard.object(forKey: "sslExpiryDaysThreshold") as? Int ?? 30
    }

    private var notifyOnResponseThreshold: Bool {
        UserDefaults.standard.object(forKey: "notifyOnResponseThreshold") as? Bool ?? false
    }

    private var responseThresholdMs: Int {
        UserDefaults.standard.object(forKey: "responseThresholdMs") as? Int ?? 1000
    }

    private var playNotificationSound: Bool {
        UserDefaults.standard.object(forKey: "playNotificationSound") as? Bool ?? true
    }

    private var quietHours: QuietHours {
        QuietHours(
            isEnabled: UserDefaults.standard.object(forKey: "quietHoursEnabled") as? Bool ?? false,
            startHour: UserDefaults.standard.object(forKey: "quietHoursStart") as? Int ?? 22,
            endHour: UserDefaults.standard.object(forKey: "quietHoursEnd") as? Int ?? 7
        )
    }

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
            logger.info("Notification authorization granted: \(granted)")
        } catch {
            logger.error("Notification authorization failed: \(error.localizedDescription)")
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
        guard !quietHours.isCurrentlyQuiet else {
            logger.debug("Suppressing notification during quiet hours")
            return
        }

        let newStatus = server.status
        guard let previous = previousStatus, previous != newStatus else {
            // Store initial state
            previousServerStates[server.id] = newStatus
            return
        }

        // Status changed - check preferences
        if newStatus == .offline && previous != .offline && notifyOnOffline {
            sendServerOfflineNotification(server: server)
        } else if newStatus == .online && previous == .offline && notifyOnOnline {
            sendServerOnlineNotification(server: server)
        } else if newStatus == .warning && previous == .online && notifyOnWarning {
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

        let sound: UNNotificationSound? = playNotificationSound ? .defaultCritical : nil

        sendNotification(
            title: "Server Offline",
            body: "\(server.name) is now offline",
            subtitle: server.host,
            identifier: identifier,
            categoryIdentifier: "SERVER_STATUS",
            sound: sound
        )
    }

    private func sendServerOnlineNotification(server: Server) {
        let identifier = "online-\(server.id.uuidString)"
        guard !isInCooldown(identifier: identifier) else { return }

        let sound: UNNotificationSound? = playNotificationSound ? .default : nil

        sendNotification(
            title: "Server Back Online",
            body: "\(server.name) is now online",
            subtitle: server.host,
            identifier: identifier,
            categoryIdentifier: "SERVER_STATUS",
            sound: sound
        )
    }

    private func sendServerWarningNotification(server: Server) {
        let identifier = "warning-\(server.id.uuidString)"
        guard !isInCooldown(identifier: identifier) else { return }

        let sound: UNNotificationSound? = playNotificationSound ? .default : nil

        sendNotification(
            title: "Server Warning",
            body: "\(server.name) has a warning status",
            subtitle: server.host,
            identifier: identifier,
            categoryIdentifier: "SERVER_STATUS",
            sound: sound
        )
    }

    // MARK: - Response Time Notifications

    func checkResponseThreshold(server: Server, threshold: Double? = nil) {
        guard isAuthorized else { return }
        guard notifyOnResponseThreshold else { return }
        guard !quietHours.isCurrentlyQuiet else { return }

        let effectiveThreshold = threshold ?? Double(responseThresholdMs)
        guard let responseTime = server.responseTime, responseTime > effectiveThreshold else { return }

        let identifier = "threshold-\(server.id.uuidString)"
        guard !isInCooldown(identifier: identifier) else { return }

        let sound: UNNotificationSound? = playNotificationSound ? .default : nil

        sendNotification(
            title: "High Response Time",
            body: "\(server.name): \(Int(responseTime))ms (threshold: \(Int(effectiveThreshold))ms)",
            subtitle: server.host,
            identifier: identifier,
            categoryIdentifier: "SERVER_STATUS",
            sound: sound
        )
    }

    // MARK: - SSL Notifications

    func sendSSLExpiryNotification(server: Server, daysRemaining: Int) {
        guard isAuthorized else { return }
        guard notifyOnSSLExpiry else { return }
        guard daysRemaining <= sslExpiryDaysThreshold else { return }
        guard !quietHours.isCurrentlyQuiet else { return }

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

        let sound: UNNotificationSound?
        if !playNotificationSound {
            sound = nil
        } else if daysRemaining <= 7 {
            sound = .defaultCritical
        } else {
            sound = .default
        }

        sendNotification(
            title: "SSL Certificate Warning",
            body: "\(server.name) certificate \(urgency)",
            subtitle: server.host,
            identifier: identifier,
            categoryIdentifier: "SSL_EXPIRY",
            sound: sound
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
                logger.error("Failed to send notification: \(error.localizedDescription)")
            } else {
                logger.debug("Notification sent: \(identifier)")
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
