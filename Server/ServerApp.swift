//
//  ServerApp.swift
//  Server
//
//  Created by Jonathan Hines Dumitru on 1/13/26.
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct ServerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Server.self,
            ServerMetric.self,
            ServerLog.self,
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            DashboardView(modelContext: sharedModelContainer.mainContext)
        }
        .modelContainer(sharedModelContainer)
        .defaultSize(width: 1200, height: 800)

        #if os(macOS)
        Settings {
            SettingsView()
        }
        #endif
    }
}

// MARK: - App Delegate for Notification Handling
class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set ourselves as the notification center delegate
        UNUserNotificationCenter.current().delegate = self

        // Setup notification categories
        Task { @MainActor in
            NotificationService.shared.setupNotificationCategories()
        }

        // Set default notification preferences if not already set
        let defaults = UserDefaults.standard
        if defaults.object(forKey: "enableNotifications") == nil {
            defaults.set(true, forKey: "enableNotifications")
        }
        if defaults.object(forKey: "notifyOnStatusChange") == nil {
            defaults.set(true, forKey: "notifyOnStatusChange")
        }
        if defaults.object(forKey: "notifyOnError") == nil {
            defaults.set(true, forKey: "notifyOnError")
        }
    }

    // Handle notifications when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    // Handle notification actions
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let actionIdentifier = response.actionIdentifier

        switch actionIdentifier {
        case "VIEW_SERVER":
            // Bring app to foreground and navigate to server
            NSApplication.shared.activate(ignoringOtherApps: true)
            if let serverName = userInfo["serverName"] as? String {
                // Post notification to navigate to server
                NotificationCenter.default.post(
                    name: .navigateToServer,
                    object: nil,
                    userInfo: ["serverName": serverName]
                )
            }

        case "CHECK_NOW":
            // Trigger a server check
            if let serverName = userInfo["serverName"] as? String {
                NotificationCenter.default.post(
                    name: .checkServerNow,
                    object: nil,
                    userInfo: ["serverName": serverName]
                )
            }

        case UNNotificationDefaultActionIdentifier:
            // User tapped on the notification itself
            NSApplication.shared.activate(ignoringOtherApps: true)

        case UNNotificationDismissActionIdentifier:
            // User dismissed the notification
            break

        default:
            break
        }

        completionHandler()
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let navigateToServer = Notification.Name("navigateToServer")
    static let checkServerNow = Notification.Name("checkServerNow")
}
