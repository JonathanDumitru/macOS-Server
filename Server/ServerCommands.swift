//
//  ServerCommands.swift
//  Server
//
//  Created by Claude on 1/28/26.
//

import SwiftUI

/// App-wide keyboard shortcuts and menu commands
struct ServerCommands: Commands {
    var body: some Commands {
        // Server menu commands
        CommandGroup(after: .newItem) {
            Button("Add Server...") {
                NotificationCenter.default.post(name: .addServerShortcut, object: nil)
            }
            .keyboardShortcut("n", modifiers: [.command])

            Divider()

            Button("Refresh All Servers") {
                NotificationCenter.default.post(name: .refreshAllServers, object: nil)
            }
            .keyboardShortcut("r", modifiers: [.command])

            Button("Refresh Selected Server") {
                NotificationCenter.default.post(name: .refreshSelectedServer, object: nil)
            }
            .keyboardShortcut("r", modifiers: [.command, .shift])
        }

        // Monitoring commands
        CommandMenu("Monitoring") {
            Button("Start Monitoring") {
                NotificationCenter.default.post(name: .startMonitoring, object: nil)
            }
            .keyboardShortcut("m", modifiers: [.command])

            Button("Stop Monitoring") {
                NotificationCenter.default.post(name: .stopMonitoring, object: nil)
            }
            .keyboardShortcut("m", modifiers: [.command, .shift])

            Divider()

            Button("Check All Now") {
                NotificationCenter.default.post(name: .refreshAllServers, object: nil)
            }
            .keyboardShortcut("u", modifiers: [.command])
        }

        // View commands
        CommandGroup(after: .sidebar) {
            Divider()

            Button("Show Dashboard") {
                NotificationCenter.default.post(name: .showDashboard, object: nil)
            }
            .keyboardShortcut("1", modifiers: [.command])

            Button("Show All Servers") {
                NotificationCenter.default.post(name: .showAllServers, object: nil)
            }
            .keyboardShortcut("2", modifiers: [.command])

            Divider()

            Button("Filter Online") {
                NotificationCenter.default.post(name: .filterServers, object: "online")
            }
            .keyboardShortcut("o", modifiers: [.command, .option])

            Button("Filter Offline") {
                NotificationCenter.default.post(name: .filterServers, object: "offline")
            }
            .keyboardShortcut("f", modifiers: [.command, .option])

            Button("Clear Filter") {
                NotificationCenter.default.post(name: .filterServers, object: nil)
            }
            .keyboardShortcut("0", modifiers: [.command, .option])
        }

        // Export/Import commands
        CommandGroup(after: .importExport) {
            Divider()

            Button("Export Servers...") {
                NotificationCenter.default.post(name: .exportServers, object: nil)
            }
            .keyboardShortcut("e", modifiers: [.command, .shift])

            Button("Import Servers...") {
                NotificationCenter.default.post(name: .importServers, object: nil)
            }
            .keyboardShortcut("i", modifiers: [.command, .shift])
        }
    }
}

// MARK: - Notification Names for Commands

extension Notification.Name {
    static let addServerShortcut = Notification.Name("addServerShortcut")
    static let refreshSelectedServer = Notification.Name("refreshSelectedServer")
    static let startMonitoring = Notification.Name("startMonitoring")
    static let stopMonitoring = Notification.Name("stopMonitoring")
    static let showDashboard = Notification.Name("showDashboard")
    static let showAllServers = Notification.Name("showAllServers")
    static let filterServers = Notification.Name("filterServers")
    static let exportServers = Notification.Name("exportServers")
    static let importServers = Notification.Name("importServers")
}
