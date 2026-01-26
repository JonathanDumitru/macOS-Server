//
//  SettingsView.swift
//  Server
//
//  Created by Jonathan Hines Dumitru on 1/13/26.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("monitoringInterval") private var monitoringInterval = 30
    @AppStorage("enableNotifications") private var enableNotifications = true
    @AppStorage("notifyOnStatusChange") private var notifyOnStatusChange = true
    @AppStorage("notifyOnError") private var notifyOnError = true
    @AppStorage("maxLogEntries") private var maxLogEntries = 1000
    @AppStorage("maxMetricEntries") private var maxMetricEntries = 500
    
    var body: some View {
        TabView {
            GeneralSettingsView(
                monitoringInterval: $monitoringInterval
            )
            .tabItem {
                Label("General", systemImage: "gear")
            }

            GroupSettingsView()
            .tabItem {
                Label("Groups", systemImage: "folder.fill")
            }

            NotificationSettingsView(
                enableNotifications: $enableNotifications,
                notifyOnStatusChange: $notifyOnStatusChange,
                notifyOnError: $notifyOnError
            )
            .tabItem {
                Label("Notifications", systemImage: "bell")
            }

            DataSettingsView(
                maxLogEntries: $maxLogEntries,
                maxMetricEntries: $maxMetricEntries
            )
            .tabItem {
                Label("Data", systemImage: "cylinder")
            }
        }
        .frame(width: 500, height: 450)
    }
}

struct GeneralSettingsView: View {
    @Binding var monitoringInterval: Int
    
    var body: some View {
        Form {
            Section {
                Picker("Monitoring Interval", selection: $monitoringInterval) {
                    Text("15 seconds").tag(15)
                    Text("30 seconds").tag(30)
                    Text("1 minute").tag(60)
                    Text("2 minutes").tag(120)
                    Text("5 minutes").tag(300)
                }
                
                Text("How often to check server status")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Monitoring")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct NotificationSettingsView: View {
    @Binding var enableNotifications: Bool
    @Binding var notifyOnStatusChange: Bool
    @Binding var notifyOnError: Bool
    
    var body: some View {
        Form {
            Section {
                Toggle("Enable Notifications", isOn: $enableNotifications)
                
                Toggle("Status Changes", isOn: $notifyOnStatusChange)
                    .disabled(!enableNotifications)
                
                Toggle("Errors", isOn: $notifyOnError)
                    .disabled(!enableNotifications)
            } header: {
                Text("Notification Settings")
            } footer: {
                Text("Receive notifications when server status changes or errors occur")
                    .font(.caption)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct DataSettingsView: View {
    @Binding var maxLogEntries: Int
    @Binding var maxMetricEntries: Int
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        Form {
            Section {
                Stepper("Max Log Entries: \(maxLogEntries)", value: $maxLogEntries, in: 100...10000, step: 100)
                
                Stepper("Max Metric Entries: \(maxMetricEntries)", value: $maxMetricEntries, in: 100...5000, step: 100)
                
                Text("Older entries will be automatically deleted")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Data Retention")
            }
            
            Section {
                Button("Clear All Logs", role: .destructive) {
                    clearLogs()
                }
                
                Button("Clear All Metrics", role: .destructive) {
                    clearMetrics()
                }
            } header: {
                Text("Data Management")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
    
    private func clearLogs() {
        // Implementation for clearing logs
    }
    
    private func clearMetrics() {
        // Implementation for clearing metrics
    }
}

#Preview {
    SettingsView()
}
