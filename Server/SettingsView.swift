//
//  SettingsView.swift
//  Server
//
//  Created by Jonathan Hines Dumitru on 1/13/26.
//

import SwiftUI
import SwiftData
import UserNotifications

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
    @AppStorage("showMenuBarIcon") private var showMenuBarIcon = true
    @AppStorage("launchAtLogin") private var launchAtLogin = false

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

            Section {
                Toggle("Show Menu Bar Icon", isOn: $showMenuBarIcon)

                Text("Quick access to server status from the menu bar")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Menu Bar")
            } footer: {
                if showMenuBarIcon {
                    Text("Click the menu bar icon to see a quick overview of all servers")
                        .font(.caption)
                }
            }

            Section {
                Toggle("Launch at Login", isOn: $launchAtLogin)

                Text("Automatically start the app when you log in")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Startup")
            }
        }
        .formStyle(.grouped)
        .padding()
        .onChange(of: showMenuBarIcon) { _, newValue in
            // Post notification to update menu bar visibility
            NotificationCenter.default.post(name: .menuBarVisibilityChanged, object: newValue)
        }
    }
}

struct NotificationSettingsView: View {
    @Binding var enableNotifications: Bool
    @Binding var notifyOnStatusChange: Bool
    @Binding var notifyOnError: Bool
    @StateObject private var notificationService = NotificationService.shared

    // Additional notification settings
    @AppStorage("notifyOnOffline") private var notifyOnOffline = true
    @AppStorage("notifyOnOnline") private var notifyOnOnline = true
    @AppStorage("notifyOnWarning") private var notifyOnWarning = true
    @AppStorage("notifyOnSSLExpiry") private var notifyOnSSLExpiry = true
    @AppStorage("sslExpiryDaysThreshold") private var sslExpiryDaysThreshold = 30
    @AppStorage("notifyOnResponseThreshold") private var notifyOnResponseThreshold = false
    @AppStorage("responseThresholdMs") private var responseThresholdMs = 1000
    @AppStorage("playNotificationSound") private var playNotificationSound = true
    @AppStorage("quietHoursEnabled") private var quietHoursEnabled = false
    @AppStorage("quietHoursStart") private var quietHoursStart = 22
    @AppStorage("quietHoursEnd") private var quietHoursEnd = 7

    var body: some View {
        Form {
            // Authorization Status
            Section {
                HStack {
                    Image(systemName: notificationService.isAuthorized ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(notificationService.isAuthorized ? .green : .red)
                    Text(notificationService.isAuthorized ? "Notifications Enabled" : "Notifications Disabled")
                    Spacer()
                    if !notificationService.isAuthorized {
                        Button("Open Settings") {
                            notificationService.openSystemPreferences()
                        }
                        .buttonStyle(.link)
                    }
                }
            } header: {
                Text("System Status")
            } footer: {
                if !notificationService.isAuthorized {
                    Text("Enable notifications in System Preferences to receive alerts")
                        .font(.caption)
                }
            }

            // Status Notifications
            Section {
                Toggle("Server Goes Offline", isOn: $notifyOnOffline)
                Toggle("Server Comes Online", isOn: $notifyOnOnline)
                Toggle("Server Warning Status", isOn: $notifyOnWarning)
            } header: {
                Text("Status Notifications")
            } footer: {
                Text("Receive alerts when server status changes")
                    .font(.caption)
            }

            // SSL Notifications
            Section {
                Toggle("SSL Certificate Expiry", isOn: $notifyOnSSLExpiry)

                if notifyOnSSLExpiry {
                    Picker("Alert When", selection: $sslExpiryDaysThreshold) {
                        Text("7 days before").tag(7)
                        Text("14 days before").tag(14)
                        Text("30 days before").tag(30)
                        Text("60 days before").tag(60)
                        Text("90 days before").tag(90)
                    }
                }
            } header: {
                Text("SSL Notifications")
            } footer: {
                Text("Get notified before SSL certificates expire")
                    .font(.caption)
            }

            // Response Time Notifications
            Section {
                Toggle("High Response Time Alert", isOn: $notifyOnResponseThreshold)

                if notifyOnResponseThreshold {
                    Picker("Threshold", selection: $responseThresholdMs) {
                        Text("500ms").tag(500)
                        Text("1 second").tag(1000)
                        Text("2 seconds").tag(2000)
                        Text("5 seconds").tag(5000)
                    }
                }
            } header: {
                Text("Performance Notifications")
            } footer: {
                Text("Alert when server response time exceeds threshold")
                    .font(.caption)
            }

            // Sound Settings
            Section {
                Toggle("Play Sound", isOn: $playNotificationSound)
            } header: {
                Text("Sound")
            }

            // Quiet Hours
            Section {
                Toggle("Enable Quiet Hours", isOn: $quietHoursEnabled)

                if quietHoursEnabled {
                    HStack {
                        Text("From")
                        Picker("Start", selection: $quietHoursStart) {
                            ForEach(0..<24, id: \.self) { hour in
                                Text(formatHour(hour)).tag(hour)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 100)

                        Text("to")

                        Picker("End", selection: $quietHoursEnd) {
                            ForEach(0..<24, id: \.self) { hour in
                                Text(formatHour(hour)).tag(hour)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 100)
                    }
                }
            } header: {
                Text("Quiet Hours")
            } footer: {
                Text("Suppress notifications during specified hours")
                    .font(.caption)
            }

            // Test Notification
            Section {
                Button("Send Test Notification") {
                    sendTestNotification()
                }
                .disabled(!notificationService.isAuthorized)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        var components = DateComponents()
        components.hour = hour
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return "\(hour):00"
    }

    private func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Test Notification"
        content.body = "Notifications are working correctly!"
        content.sound = playNotificationSound ? .default : nil

        let request = UNNotificationRequest(
            identifier: "test-notification",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }
}

struct DataSettingsView: View {
    @Binding var maxLogEntries: Int
    @Binding var maxMetricEntries: Int
    @Environment(\.modelContext) private var modelContext

    @State private var showClearLogsAlert = false
    @State private var showClearMetricsAlert = false
    @State private var showClearUptimeAlert = false
    @State private var logCount = 0
    @State private var metricCount = 0
    @State private var uptimeCount = 0

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
                Button("Clear All Logs (\(logCount))", role: .destructive) {
                    showClearLogsAlert = true
                }

                Button("Clear All Metrics (\(metricCount))", role: .destructive) {
                    showClearMetricsAlert = true
                }

                Button("Clear Uptime History (\(uptimeCount))", role: .destructive) {
                    showClearUptimeAlert = true
                }
            } header: {
                Text("Data Management")
            } footer: {
                Text("This action cannot be undone")
                    .font(.caption)
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            refreshCounts()
        }
        .alert("Clear All Logs?", isPresented: $showClearLogsAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                clearLogs()
            }
        } message: {
            Text("This will permanently delete \(logCount) log entries.")
        }
        .alert("Clear All Metrics?", isPresented: $showClearMetricsAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                clearMetrics()
            }
        } message: {
            Text("This will permanently delete \(metricCount) metric entries.")
        }
        .alert("Clear Uptime History?", isPresented: $showClearUptimeAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                clearUptimeHistory()
            }
        } message: {
            Text("This will permanently delete \(uptimeCount) uptime records.")
        }
    }

    private func refreshCounts() {
        do {
            let logDescriptor = FetchDescriptor<ServerLog>()
            logCount = try modelContext.fetchCount(logDescriptor)

            let metricDescriptor = FetchDescriptor<ServerMetric>()
            metricCount = try modelContext.fetchCount(metricDescriptor)

            let uptimeDescriptor = FetchDescriptor<UptimeRecord>()
            uptimeCount = try modelContext.fetchCount(uptimeDescriptor)
        } catch {
            logCount = 0
            metricCount = 0
            uptimeCount = 0
        }
    }

    private func clearLogs() {
        do {
            let descriptor = FetchDescriptor<ServerLog>()
            let logs = try modelContext.fetch(descriptor)
            for log in logs {
                modelContext.delete(log)
            }
            try modelContext.save()
            refreshCounts()
        } catch {
            // Error clearing logs
        }
    }

    private func clearMetrics() {
        do {
            let descriptor = FetchDescriptor<ServerMetric>()
            let metrics = try modelContext.fetch(descriptor)
            for metric in metrics {
                modelContext.delete(metric)
            }
            try modelContext.save()
            refreshCounts()
        } catch {
            // Error clearing metrics
        }
    }

    private func clearUptimeHistory() {
        do {
            let recordDescriptor = FetchDescriptor<UptimeRecord>()
            let records = try modelContext.fetch(recordDescriptor)
            for record in records {
                modelContext.delete(record)
            }

            let dailyDescriptor = FetchDescriptor<UptimeDaily>()
            let dailies = try modelContext.fetch(dailyDescriptor)
            for daily in dailies {
                modelContext.delete(daily)
            }

            try modelContext.save()
            refreshCounts()
        } catch {
            // Error clearing uptime history
        }
    }
}

#Preview {
    SettingsView()
}
