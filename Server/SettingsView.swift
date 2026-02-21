//
//  SettingsView.swift
//  Server
//
//  Created by Jonathan Hines Dumitru on 1/13/26.
//

import SwiftUI
import UserNotifications

struct SettingsView: View {
    @AppStorage("monitoringInterval") private var monitoringInterval = 30
    @AppStorage("enableNotifications") private var enableNotifications = true
    @AppStorage("notifyOnStatusChange") private var notifyOnStatusChange = true
    @AppStorage("notifyOnError") private var notifyOnError = true
    @AppStorage("maxLogEntries") private var maxLogEntries = 1000
    @AppStorage("maxMetricEntries") private var maxMetricEntries = 500
    
    @State private var showingAlertThresholds = false

    var body: some View {
        TabView {
            GeneralSettingsView(
                monitoringInterval: $monitoringInterval
            )
            .tabItem {
                Label("General", systemImage: "gear")
            }

            NotificationSettingsView(
                enableNotifications: $enableNotifications,
                notifyOnStatusChange: $notifyOnStatusChange,
                notifyOnError: $notifyOnError
            )
            .tabItem {
                Label("Notifications", systemImage: "bell")
            }

            AlertSettingsView(showingAlertThresholds: $showingAlertThresholds)
                .tabItem {
                    Label("Alerts", systemImage: "exclamationmark.triangle")
                }

            DataSettingsView(
                maxLogEntries: $maxLogEntries,
                maxMetricEntries: $maxMetricEntries
            )
            .tabItem {
                Label("Data", systemImage: "cylinder")
            }
        }
        .frame(width: 550, height: 450)
        .sheet(isPresented: $showingAlertThresholds) {
            AlertThresholdsView()
        }
    }
}

enum AppAppearance: String, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var nsAppearance: NSAppearance? {
        switch self {
        case .system: return nil
        case .light: return NSAppearance(named: .aqua)
        case .dark: return NSAppearance(named: .darkAqua)
        }
    }
}

struct GeneralSettingsView: View {
    @Binding var monitoringInterval: Int
    @AppStorage("showMenuBarExtra") private var showMenuBarExtra = true
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("enableRealMetrics") private var enableRealMetrics = true
    @AppStorage("appAppearance") private var appAppearance: String = AppAppearance.system.rawValue

    var body: some View {
        Form {
            Section {
                Picker("Appearance", selection: $appAppearance) {
                    ForEach(AppAppearance.allCases, id: \.rawValue) { appearance in
                        Text(appearance.rawValue).tag(appearance.rawValue)
                    }
                }
                .onChange(of: appAppearance) { _, newValue in
                    applyAppearance(AppAppearance(rawValue: newValue) ?? .system)
                }

                Text("Choose between light, dark, or system appearance")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Appearance")
            }

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
                Toggle("Collect Real Metrics via SSH", isOn: $enableRealMetrics)

                Text("When enabled, collect actual CPU, memory, and disk metrics from servers with stored credentials. Requires SSH access.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if enableRealMetrics {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.blue)
                        Text("SSH key authentication recommended for best results")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Real Metrics")
            }

            Section {
                Toggle("Show in Menu Bar", isOn: $showMenuBarExtra)

                Text("Display a menu bar icon with quick access to server status")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Menu Bar")
            }

            Section {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .disabled(true) // Would need SMAppService to implement

                Text("Start Server Monitor when you log in (coming soon)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Startup")
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            applyAppearance(AppAppearance(rawValue: appAppearance) ?? .system)
        }
    }

    private func applyAppearance(_ appearance: AppAppearance) {
        NSApp.appearance = appearance.nsAppearance
    }
}

struct NotificationSettingsView: View {
    @Binding var enableNotifications: Bool
    @Binding var notifyOnStatusChange: Bool
    @Binding var notifyOnError: Bool
    @StateObject private var notificationService = NotificationService.shared

    var body: some View {
        Form {
            Section {
                HStack {
                    Text("System Permission")
                    Spacer()
                    Text(authorizationStatusText)
                        .foregroundStyle(authorizationStatusColor)
                }

                if notificationService.authorizationStatus == .notDetermined {
                    Button("Request Permission") {
                        Task {
                            await notificationService.requestAuthorization()
                        }
                    }
                } else if notificationService.authorizationStatus == .denied {
                    Button("Open System Settings") {
                        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    Text("Notifications are disabled in System Settings. Click above to enable them.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Permission Status")
            }

            Section {
                Toggle("Enable Notifications", isOn: $enableNotifications)
                    .disabled(!notificationService.isAuthorized)

                Toggle("Status Changes", isOn: $notifyOnStatusChange)
                    .disabled(!enableNotifications || !notificationService.isAuthorized)

                Toggle("Errors", isOn: $notifyOnError)
                    .disabled(!enableNotifications || !notificationService.isAuthorized)
            } header: {
                Text("Notification Preferences")
            } footer: {
                Text("Receive notifications when server status changes or errors occur")
                    .font(.caption)
            }

            Section {
                Button("Send Test Notification") {
                    Task {
                        await notificationService.notifyServerStatusChange(
                            serverName: "Test Server",
                            previousStatus: .online,
                            newStatus: .offline,
                            errorMessage: "This is a test notification"
                        )
                    }
                }
                .disabled(!notificationService.isAuthorized || !enableNotifications)

                Button("Clear All Notifications", role: .destructive) {
                    notificationService.clearAllNotifications()
                }
            } header: {
                Text("Actions")
            }
        }
        .formStyle(.grouped)
        .padding()
        .task {
            await notificationService.checkAuthorizationStatus()
        }
    }

    private var authorizationStatusText: String {
        switch notificationService.authorizationStatus {
        case .authorized: return "Authorized"
        case .denied: return "Denied"
        case .notDetermined: return "Not Requested"
        case .provisional: return "Provisional"
        case .ephemeral: return "Ephemeral"
        @unknown default: return "Unknown"
        }
    }

    private var authorizationStatusColor: Color {
        switch notificationService.authorizationStatus {
        case .authorized, .provisional, .ephemeral: return .green
        case .denied: return .red
        case .notDetermined: return .orange
        @unknown default: return .gray
        }
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

// MARK: - Alert Settings View

struct AlertSettingsView: View {
    @Binding var showingAlertThresholds: Bool
    @AppStorage("enableThresholdAlerts") private var enableThresholdAlerts = true

    var body: some View {
        Form {
            Section {
                Toggle("Enable Threshold Alerts", isOn: $enableThresholdAlerts)

                Text("Get notified when server metrics exceed configured thresholds")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Threshold Alerts")
            }

            Section {
                Button {
                    showingAlertThresholds = true
                } label: {
                    HStack {
                        Label("Configure Thresholds", systemImage: "slider.horizontal.3")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)

                Text("Set custom thresholds for CPU, memory, disk usage, and response time")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Threshold Configuration")
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Default Thresholds")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 16) {
                        ThresholdPreview(metric: "CPU", value: "80%", severity: .warning)
                        ThresholdPreview(metric: "Memory", value: "85%", severity: .warning)
                        ThresholdPreview(metric: "Disk", value: "90%", severity: .warning)
                    }
                }
            } header: {
                Text("Quick Reference")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct ThresholdPreview: View {
    let metric: String
    let value: String
    let severity: AlertSeverity

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: severity.icon)
                .foregroundStyle(Color(severity.color))

            Text(metric)
                .font(.system(size: 10, weight: .medium))

            Text("> \(value)")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }
}

#Preview {
    SettingsView()
}
