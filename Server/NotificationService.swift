//
//  NotificationService.swift
//  Server
//
//  Created by Claude on 1/27/26.
//

import Foundation
import UserNotifications
internal import Combine
internal import Combine

@MainActor
class NotificationService: ObservableObject {
    var objectWillChange: ObservableObjectPublisher

    static let shared = NotificationService()

    @Published var isAuthorized = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private init() {
        Task {
            await checkAuthorizationStatus()
        }
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            await checkAuthorizationStatus()
            return granted
        } catch {
            print("Failed to request notification authorization: \(error)")
            return false
        }
    }

    func checkAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
        isAuthorized = settings.authorizationStatus == .authorized
    }

    // MARK: - Server Status Notifications

    func notifyServerStatusChange(
        serverName: String,
        previousStatus: ServerStatus,
        newStatus: ServerStatus,
        errorMessage: String? = nil
    ) async {
        guard isAuthorized else {
            // Try to request authorization
            let granted = await requestAuthorization()
            guard granted else { return }
        }

        // Check user preferences
        guard UserDefaults.standard.bool(forKey: "enableNotifications"),
              UserDefaults.standard.bool(forKey: "notifyOnStatusChange") else {
            return
        }

        let content = UNMutableNotificationContent()
        content.sound = .default

        switch newStatus {
        case .online:
            content.title = "✅ Server Online"
            content.subtitle = serverName
            content.body = "Server is now online and responding."
            content.categoryIdentifier = "SERVER_ONLINE"

        case .offline:
            content.title = "🔴 Server Offline"
            content.subtitle = serverName
            if let error = errorMessage {
                content.body = "Server is offline: \(error)"
            } else {
                content.body = "Server is not responding."
            }
            content.categoryIdentifier = "SERVER_OFFLINE"
            content.interruptionLevel = .timeSensitive

        case .warning:
            content.title = "⚠️ Server Warning"
            content.subtitle = serverName
            if let error = errorMessage {
                content.body = "Server issue: \(error)"
            } else {
                content.body = "Server is experiencing issues."
            }
            content.categoryIdentifier = "SERVER_WARNING"

        case .unknown:
            content.title = "❓ Server Status Unknown"
            content.subtitle = serverName
            content.body = "Unable to determine server status."
            content.categoryIdentifier = "SERVER_UNKNOWN"
        }

        // Add user info for handling notification actions
        content.userInfo = [
            "serverName": serverName,
            "previousStatus": previousStatus.rawValue,
            "newStatus": newStatus.rawValue
        ]

        let request = UNNotificationRequest(
            identifier: "server-status-\(serverName)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil // Deliver immediately
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Failed to schedule notification: \(error)")
        }
    }

    // MARK: - Error Notifications

    func notifyError(
        serverName: String,
        errorMessage: String
    ) async {
        guard isAuthorized else {
            let granted = await requestAuthorization()
            guard granted else { return }
        }

        // Check user preferences
        guard UserDefaults.standard.bool(forKey: "enableNotifications"),
              UserDefaults.standard.bool(forKey: "notifyOnError") else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "❌ Server Error"
        content.subtitle = serverName
        content.body = errorMessage
        content.sound = .default
        content.categoryIdentifier = "SERVER_ERROR"
        content.interruptionLevel = .timeSensitive

        content.userInfo = [
            "serverName": serverName,
            "errorMessage": errorMessage
        ]

        let request = UNNotificationRequest(
            identifier: "server-error-\(serverName)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Failed to schedule error notification: \(error)")
        }
    }

    // MARK: - Alert Threshold Notifications (for future use)

    func notifyThresholdExceeded(
        serverName: String,
        metricName: String,
        currentValue: Double,
        thresholdValue: Double
    ) async {
        guard isAuthorized else {
            let granted = await requestAuthorization()
            guard granted else { return }
        }

        guard UserDefaults.standard.bool(forKey: "enableNotifications") else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "📊 Threshold Exceeded"
        content.subtitle = serverName
        content.body = "\(metricName) is at \(String(format: "%.1f", currentValue))% (threshold: \(String(format: "%.1f", thresholdValue))%)"
        content.sound = .default
        content.categoryIdentifier = "THRESHOLD_EXCEEDED"

        content.userInfo = [
            "serverName": serverName,
            "metricName": metricName,
            "currentValue": currentValue,
            "thresholdValue": thresholdValue
        ]

        let request = UNNotificationRequest(
            identifier: "threshold-\(serverName)-\(metricName)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Failed to schedule threshold notification: \(error)")
        }
    }

    // MARK: - SSL Certificate Notifications (for future use)

    func notifySSLCertificateExpiring(
        serverName: String,
        daysUntilExpiry: Int
    ) async {
        guard isAuthorized else {
            let granted = await requestAuthorization()
            guard granted else { return }
        }

        guard UserDefaults.standard.bool(forKey: "enableNotifications") else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "🔐 SSL Certificate Expiring"
        content.subtitle = serverName

        if daysUntilExpiry <= 0 {
            content.body = "SSL certificate has expired!"
            content.interruptionLevel = .critical
        } else if daysUntilExpiry <= 7 {
            content.body = "SSL certificate expires in \(daysUntilExpiry) day\(daysUntilExpiry == 1 ? "" : "s")!"
            content.interruptionLevel = .timeSensitive
        } else {
            content.body = "SSL certificate expires in \(daysUntilExpiry) days."
        }

        content.sound = .default
        content.categoryIdentifier = "SSL_EXPIRING"

        content.userInfo = [
            "serverName": serverName,
            "daysUntilExpiry": daysUntilExpiry
        ]

        let request = UNNotificationRequest(
            identifier: "ssl-\(serverName)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Failed to schedule SSL notification: \(error)")
        }
    }

    // MARK: - Notification Categories Setup

    func setupNotificationCategories() {
        let viewAction = UNNotificationAction(
            identifier: "VIEW_SERVER",
            title: "View Server",
            options: [.foreground]
        )

        let checkNowAction = UNNotificationAction(
            identifier: "CHECK_NOW",
            title: "Check Now",
            options: []
        )

        let dismissAction = UNNotificationAction(
            identifier: "DISMISS",
            title: "Dismiss",
            options: [.destructive]
        )

        // Server status categories
        let onlineCategory = UNNotificationCategory(
            identifier: "SERVER_ONLINE",
            actions: [viewAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )

        let offlineCategory = UNNotificationCategory(
            identifier: "SERVER_OFFLINE",
            actions: [viewAction, checkNowAction, dismissAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        let warningCategory = UNNotificationCategory(
            identifier: "SERVER_WARNING",
            actions: [viewAction, checkNowAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )

        let errorCategory = UNNotificationCategory(
            identifier: "SERVER_ERROR",
            actions: [viewAction, checkNowAction, dismissAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        let thresholdCategory = UNNotificationCategory(
            identifier: "THRESHOLD_EXCEEDED",
            actions: [viewAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )

        let sslCategory = UNNotificationCategory(
            identifier: "SSL_EXPIRING",
            actions: [viewAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([
            onlineCategory,
            offlineCategory,
            warningCategory,
            errorCategory,
            thresholdCategory,
            sslCategory
        ])
    }

    // MARK: - Clear Notifications

    func clearAllNotifications() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    func clearNotifications(forServer serverName: String) {
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            let identifiersToRemove = notifications
                .filter { notification in
                    guard let name = notification.request.content.userInfo["serverName"] as? String else {
                        return false
                    }
                    return name == serverName
                }
                .map { $0.request.identifier }

            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiersToRemove)
        }
    }
}
