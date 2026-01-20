//
//  ContentView.swift
//  Server
//
//  Created by Jonathan Hines Dumitru on 1/13/26.
//
//  NOTE: This is the old template view. The app now uses DashboardView as the main view.
//  This file is kept for reference but is no longer used in the main app.

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    @Query private var servers: [Server]

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "server.rack")
                .font(.system(size: 80))
                .foregroundStyle(.blue)
            
            Text("Server Monitor Dashboard")
                .font(.largeTitle.bold())
            
            Text("This app has been migrated to the new DashboardView")
                .foregroundStyle(.secondary)
            
            if servers.isEmpty {
                Button {
                    SampleData.createSampleServers(in: modelContext)
                } label: {
                    Label("Load Sample Data", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            } else {
                Text("Sample data loaded!")
                    .foregroundStyle(.green)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
