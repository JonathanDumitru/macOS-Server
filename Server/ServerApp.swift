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
    @AppStorage("showMenuBarExtra") private var showMenuBarExtra = true

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Server.self,
            ServerMetric.self,
            ServerLog.self,
            UptimeRecord.self,
            ServerGroup.self,
            ServerTag.self,
            AlertThreshold.self,
            AlertEvent.self,
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
        .commands {
            // Server Commands
            CommandGroup(after: .newItem) {
                Button("Add Server") {
                    NotificationCenter.default.post(name: .addServer, object: nil)
                }
                .keyboardShortcut("n", modifiers: [.command])

                Divider()

                Button("Export Servers...") {
                    NotificationCenter.default.post(name: .exportServers, object: nil)
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])
            }

            // View Commands
            CommandGroup(after: .sidebar) {
                Button("Toggle Monitoring") {
                    NotificationCenter.default.post(name: .toggleMonitoring, object: nil)
                }
                .keyboardShortcut("m", modifiers: [.command, .shift])

                Button("Refresh All") {
                    NotificationCenter.default.post(name: .refreshAll, object: nil)
                }
                .keyboardShortcut("r", modifiers: [.command])

                Divider()

                Button("Focus Search") {
                    NotificationCenter.default.post(name: .focusSearch, object: nil)
                }
                .keyboardShortcut("f", modifiers: [.command])

                Divider()

                Button("Dashboard") {
                    NotificationCenter.default.post(name: .navigateToSection, object: NavigationSection.dashboard)
                }
                .keyboardShortcut("1", modifiers: [.command])

                Button("Roles & Features") {
                    NotificationCenter.default.post(name: .navigateToSection, object: NavigationSection.rolesFeatures)
                }
                .keyboardShortcut("2", modifiers: [.command])

                Button("Storage") {
                    NotificationCenter.default.post(name: .navigateToSection, object: NavigationSection.storage)
                }
                .keyboardShortcut("3", modifiers: [.command])

                Button("Networking") {
                    NotificationCenter.default.post(name: .navigateToSection, object: NavigationSection.networking)
                }
                .keyboardShortcut("4", modifiers: [.command])

                Button("Security") {
                    NotificationCenter.default.post(name: .navigateToSection, object: NavigationSection.security)
                }
                .keyboardShortcut("5", modifiers: [.command])

                Button("Updates") {
                    NotificationCenter.default.post(name: .navigateToSection, object: NavigationSection.updates)
                }
                .keyboardShortcut("6", modifiers: [.command])
            }
        }

        #if os(macOS)
        Settings {
            SettingsView()
        }

        // Menu Bar Extra
        MenuBarExtra("Server Monitor", systemImage: "server.rack") {
            MenuBarView()
                .modelContainer(sharedModelContainer)
        }
        .menuBarExtraStyle(.window)
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
    static let addServer = Notification.Name("addServer")
    static let exportServers = Notification.Name("exportServers")
    static let toggleMonitoring = Notification.Name("toggleMonitoring")
    static let refreshAll = Notification.Name("refreshAll")
    static let focusSearch = Notification.Name("focusSearch")
    static let navigateToSection = Notification.Name("navigateToSection")
}
