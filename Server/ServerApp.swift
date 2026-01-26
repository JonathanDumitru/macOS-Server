//
//  ServerApp.swift
//  Server
//
//  Created by Jonathan Hines Dumitru on 1/13/26.
//

import SwiftUI
import SwiftData

@main
struct ServerApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Server.self,
            ServerMetric.self,
            ServerLog.self,
            ServerGroup.self,
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
