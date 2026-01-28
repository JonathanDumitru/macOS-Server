//
//  ServerApp.swift
//  Server
//
//  Created by Jonathan Hines Dumitru on 1/13/26.
//

import SwiftUI
import SwiftData
import AppKit

// MARK: - App Delegate for Menu Bar

class AppDelegate: NSObject, NSApplicationDelegate {
    var menuBarController: MenuBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Menu bar is setup from the App struct after model container is ready
    }

    func applicationWillTerminate(_ notification: Notification) {
        menuBarController?.teardown()
    }
}

@main
struct ServerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("showMenuBarIcon") private var showMenuBarIcon = true

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Server.self,
            ServerMetric.self,
            ServerLog.self,
            ServerGroup.self,
            UptimeRecord.self,
            UptimeDaily.self,
            SSLCertificateInfo.self,
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
        // Setup notifications on app launch
        Task {
            await NotificationService.shared.requestAuthorization()
            NotificationService.shared.setupNotificationCategories()
        }
    }

    var body: some Scene {
        WindowGroup {
            DashboardView(modelContext: sharedModelContainer.mainContext)
                .onAppear {
                    setupMenuBar()
                    setupMenuBarObserver()
                }
        }
        .modelContainer(sharedModelContainer)
        .defaultSize(width: 1200, height: 800)
        .commands {
            ServerCommands()
        }

        #if os(macOS)
        Settings {
            SettingsView()
                .modelContainer(sharedModelContainer)
        }
        #endif
    }

    private func setupMenuBar() {
        Task { @MainActor in
            if showMenuBarIcon {
                if appDelegate.menuBarController == nil {
                    appDelegate.menuBarController = MenuBarController(modelContainer: sharedModelContainer)
                    appDelegate.menuBarController?.setup()
                }
            } else {
                appDelegate.menuBarController?.teardown()
                appDelegate.menuBarController = nil
            }
        }
    }

    private func setupMenuBarObserver() {
        NotificationCenter.default.addObserver(
            forName: .menuBarVisibilityChanged,
            object: nil,
            queue: .main
        ) { [self] notification in
            guard let shouldShow = notification.object as? Bool else { return }
            Task { @MainActor in
                if shouldShow {
                    if appDelegate.menuBarController == nil {
                        appDelegate.menuBarController = MenuBarController(modelContainer: sharedModelContainer)
                        appDelegate.menuBarController?.setup()
                    }
                } else {
                    appDelegate.menuBarController?.teardown()
                    appDelegate.menuBarController = nil
                }
            }
        }
    }
}
