//
//  DashboardWidgets.swift
//  Server
//
//  Created by Claude on 1/28/26.
//

import SwiftUI
import SwiftData

// MARK: - Widget Types

enum DashboardWidgetType: String, CaseIterable, Codable, Identifiable {
    case serverStatus
    case uptimeOverview
    case recentIncidents
    case sslCertificates
    case responseTime
    case quickActions
    case systemHealth
    case maintenanceSchedule

    var id: String { rawValue }

    var title: String {
        switch self {
        case .serverStatus: return "Server Status"
        case .uptimeOverview: return "Uptime Overview"
        case .recentIncidents: return "Recent Incidents"
        case .sslCertificates: return "SSL Certificates"
        case .responseTime: return "Response Times"
        case .quickActions: return "Quick Actions"
        case .systemHealth: return "System Health"
        case .maintenanceSchedule: return "Maintenance"
        }
    }

    var icon: String {
        switch self {
        case .serverStatus: return "server.rack"
        case .uptimeOverview: return "clock.arrow.circlepath"
        case .recentIncidents: return "exclamationmark.triangle"
        case .sslCertificates: return "lock.shield"
        case .responseTime: return "gauge.with.needle"
        case .quickActions: return "bolt"
        case .systemHealth: return "heart.text.square"
        case .maintenanceSchedule: return "calendar.badge.clock"
        }
    }

    var defaultSize: WidgetSize {
        switch self {
        case .serverStatus, .uptimeOverview, .systemHealth: return .large
        case .recentIncidents, .responseTime: return .medium
        case .sslCertificates, .quickActions, .maintenanceSchedule: return .small
        }
    }
}

enum WidgetSize: String, Codable, CaseIterable {
    case small
    case medium
    case large

    var columns: Int {
        switch self {
        case .small: return 1
        case .medium: return 2
        case .large: return 3
        }
    }
}

// MARK: - Widget Configuration

struct DashboardWidget: Identifiable, Codable, Equatable {
    var id: UUID
    var type: DashboardWidgetType
    var size: WidgetSize
    var order: Int
    var isVisible: Bool

    init(id: UUID = UUID(), type: DashboardWidgetType, size: WidgetSize? = nil, order: Int, isVisible: Bool = true) {
        self.id = id
        self.type = type
        self.size = size ?? type.defaultSize
        self.order = order
        self.isVisible = isVisible
    }
}

// MARK: - Widget Manager

@Observable
class DashboardWidgetManager {
    static let shared = DashboardWidgetManager()

    var widgets: [DashboardWidget] = []

    private let widgetsKey = "dashboardWidgets"

    private init() {
        loadWidgets()
    }

    func loadWidgets() {
        if let data = UserDefaults.standard.data(forKey: widgetsKey),
           let decoded = try? JSONDecoder().decode([DashboardWidget].self, from: data) {
            widgets = decoded.sorted { $0.order < $1.order }
        } else {
            // Default widgets
            widgets = [
                DashboardWidget(type: .serverStatus, order: 0),
                DashboardWidget(type: .systemHealth, order: 1),
                DashboardWidget(type: .recentIncidents, order: 2),
                DashboardWidget(type: .responseTime, order: 3),
                DashboardWidget(type: .sslCertificates, order: 4),
                DashboardWidget(type: .quickActions, order: 5),
            ]
        }
    }

    func saveWidgets() {
        if let data = try? JSONEncoder().encode(widgets) {
            UserDefaults.standard.set(data, forKey: widgetsKey)
        }
    }

    func moveWidget(from source: IndexSet, to destination: Int) {
        widgets.move(fromOffsets: source, toOffset: destination)
        for (index, _) in widgets.enumerated() {
            widgets[index].order = index
        }
        saveWidgets()
    }

    func toggleWidget(_ id: UUID) {
        if let index = widgets.firstIndex(where: { $0.id == id }) {
            widgets[index].isVisible.toggle()
            saveWidgets()
        }
    }

    func setWidgetSize(_ id: UUID, size: WidgetSize) {
        if let index = widgets.firstIndex(where: { $0.id == id }) {
            widgets[index].size = size
            saveWidgets()
        }
    }

    func resetToDefaults() {
        UserDefaults.standard.removeObject(forKey: widgetsKey)
        loadWidgets()
    }
}

// MARK: - Widget Container View

struct WidgetContainerView<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(color)
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
            }

            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
        )
    }
}

// MARK: - Individual Widgets

struct ServerStatusWidget: View {
    let servers: [Server]

    private var statusCounts: (online: Int, offline: Int, warning: Int) {
        (
            servers.filter { $0.status == .online }.count,
            servers.filter { $0.status == .offline }.count,
            servers.filter { $0.status == .warning }.count
        )
    }

    var body: some View {
        WidgetContainerView(title: "Server Status", icon: "server.rack", color: .blue) {
            HStack(spacing: 16) {
                StatusPill(count: statusCounts.online, label: "Online", color: .green)
                StatusPill(count: statusCounts.offline, label: "Offline", color: .red)
                StatusPill(count: statusCounts.warning, label: "Warning", color: .orange)
            }

            if servers.isEmpty {
                Text("No servers configured")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                let healthyPercent = Double(statusCounts.online) / Double(servers.count) * 100
                HStack {
                    Text("Health:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(Int(healthyPercent))%")
                        .font(.caption.bold())
                        .foregroundStyle(healthyPercent >= 80 ? .green : (healthyPercent >= 50 ? .orange : .red))
                }
            }
        }
    }
}

struct StatusPill: View {
    let count: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct UptimeOverviewWidget: View {
    @Environment(\.modelContext) private var modelContext
    let servers: [Server]

    var body: some View {
        WidgetContainerView(title: "Uptime Overview", icon: "clock.arrow.circlepath", color: .green) {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(servers.prefix(5)) { server in
                    HStack {
                        Circle()
                            .fill(Color(server.status.color))
                            .frame(width: 8, height: 8)
                        Text(server.name)
                            .font(.system(size: 12))
                            .lineLimit(1)
                        Spacer()
                        if let uptime = server.uptime {
                            Text(formatUptime(uptime))
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if servers.count > 5 {
                    Text("+ \(servers.count - 5) more servers")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    private func formatUptime(_ interval: TimeInterval) -> String {
        let days = Int(interval) / 86400
        let hours = (Int(interval) % 86400) / 3600
        if days > 0 {
            return "\(days)d \(hours)h"
        }
        return "\(hours)h"
    }
}

struct RecentIncidentsWidget: View {
    @Query(sort: \Incident.startTime, order: .reverse) private var incidents: [Incident]

    var recentIncidents: [Incident] {
        Array(incidents.prefix(5))
    }

    var body: some View {
        WidgetContainerView(title: "Recent Incidents", icon: "exclamationmark.triangle", color: .orange) {
            if recentIncidents.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle")
                        .foregroundStyle(.green)
                    Text("No recent incidents")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(recentIncidents) { incident in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(incident.severity.color)
                                .frame(width: 8, height: 8)
                            Text(incident.title)
                                .font(.system(size: 11))
                                .lineLimit(1)
                            Spacer()
                            Text(incident.startTime, style: .relative)
                                .font(.system(size: 10))
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
        }
    }
}

struct SSLCertificatesWidget: View {
    let servers: [Server]

    var expiringCerts: [(server: Server, daysRemaining: Int)] {
        servers.compactMap { server in
            guard let cert = server.sslCertificate,
                  let days = cert.daysUntilExpiry,
                  days <= 30 else { return nil }
            return (server, days)
        }.sorted { $0.daysRemaining < $1.daysRemaining }
    }

    var body: some View {
        WidgetContainerView(title: "SSL Certificates", icon: "lock.shield", color: .purple) {
            if expiringCerts.isEmpty {
                HStack {
                    Image(systemName: "checkmark.seal")
                        .foregroundStyle(.green)
                    Text("All certificates valid")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(expiringCerts.prefix(3), id: \.server.id) { item in
                        HStack {
                            Text(item.server.name)
                                .font(.system(size: 11))
                                .lineLimit(1)
                            Spacer()
                            Text("\(item.daysRemaining)d")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(item.daysRemaining <= 7 ? .red : .orange)
                        }
                    }
                }
            }
        }
    }
}

struct ResponseTimeWidget: View {
    let servers: [Server]

    var sortedByResponseTime: [Server] {
        servers
            .filter { $0.responseTime != nil }
            .sorted { ($0.responseTime ?? 0) > ($1.responseTime ?? 0) }
    }

    var body: some View {
        WidgetContainerView(title: "Response Times", icon: "gauge.with.needle", color: .cyan) {
            if sortedByResponseTime.isEmpty {
                Text("No response time data")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(sortedByResponseTime.prefix(4)) { server in
                        HStack {
                            Text(server.name)
                                .font(.system(size: 11))
                                .lineLimit(1)
                            Spacer()
                            if let rt = server.responseTime {
                                Text("\(Int(rt))ms")
                                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                                    .foregroundStyle(rt < 200 ? .green : (rt < 500 ? .orange : .red))
                            }
                        }
                    }
                }
            }
        }
    }
}

struct QuickActionsWidget: View {
    let onRefreshAll: () -> Void
    let onAddServer: () -> Void

    var body: some View {
        WidgetContainerView(title: "Quick Actions", icon: "bolt", color: .yellow) {
            VStack(spacing: 8) {
                Button {
                    onRefreshAll()
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh All Servers")
                        Spacer()
                    }
                    .font(.system(size: 12))
                }
                .buttonStyle(.bordered)

                Button {
                    onAddServer()
                } label: {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add New Server")
                        Spacer()
                    }
                    .font(.system(size: 12))
                }
                .buttonStyle(.bordered)

                Button {
                    NotificationCenter.default.post(name: .exportServers, object: nil)
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export Configuration")
                        Spacer()
                    }
                    .font(.system(size: 12))
                }
                .buttonStyle(.bordered)
            }
        }
    }
}

struct SystemHealthWidget: View {
    let servers: [Server]

    var avgCPU: Double {
        let cpus = servers.compactMap { $0.metrics.last?.cpuUsage }
        guard !cpus.isEmpty else { return 0 }
        return cpus.reduce(0, +) / Double(cpus.count)
    }

    var avgMemory: Double {
        let mems = servers.compactMap { $0.metrics.last?.memoryUsage }
        guard !mems.isEmpty else { return 0 }
        return mems.reduce(0, +) / Double(mems.count)
    }

    var avgDisk: Double {
        let disks = servers.compactMap { $0.metrics.last?.diskUsage }
        guard !disks.isEmpty else { return 0 }
        return disks.reduce(0, +) / Double(disks.count)
    }

    var body: some View {
        WidgetContainerView(title: "System Health", icon: "heart.text.square", color: .pink) {
            VStack(spacing: 12) {
                HealthMetricRow(label: "CPU", value: avgCPU, color: avgCPU > 80 ? .red : (avgCPU > 60 ? .orange : .green))
                HealthMetricRow(label: "Memory", value: avgMemory, color: avgMemory > 85 ? .red : (avgMemory > 70 ? .orange : .green))
                HealthMetricRow(label: "Disk", value: avgDisk, color: avgDisk > 90 ? .red : (avgDisk > 75 ? .orange : .green))
            }
        }
    }
}

struct HealthMetricRow: View {
    let label: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(value))%")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(color)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.secondary.opacity(0.2))
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: geo.size.width * (value / 100))
                }
            }
            .frame(height: 6)
        }
    }
}

struct MaintenanceScheduleWidget: View {
    @Query(
        filter: #Predicate<MaintenanceWindow> { $0.status == .scheduled },
        sort: \MaintenanceWindow.startTime
    ) private var scheduledMaintenance: [MaintenanceWindow]

    var body: some View {
        WidgetContainerView(title: "Maintenance", icon: "calendar.badge.clock", color: .indigo) {
            if scheduledMaintenance.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle")
                        .foregroundStyle(.green)
                    Text("No scheduled maintenance")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(scheduledMaintenance.prefix(3)) { window in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(window.title)
                                    .font(.system(size: 11))
                                    .lineLimit(1)
                                Text(window.startTime, style: .date)
                                    .font(.system(size: 10))
                                    .foregroundStyle(.tertiary)
                            }
                            Spacer()
                            Text(window.startTime, style: .relative)
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Widget Customization View

struct WidgetCustomizationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var manager = DashboardWidgetManager.shared

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Customize Dashboard")
                    .font(.headline)
                Spacer()
                Button("Done") {
                    dismiss()
                }
            }
            .padding()

            Divider()

            List {
                Section("Visible Widgets") {
                    ForEach(manager.widgets.filter { $0.isVisible }) { widget in
                        WidgetConfigRow(widget: widget, manager: manager)
                    }
                    .onMove { source, destination in
                        manager.moveWidget(from: source, to: destination)
                    }
                }

                Section("Hidden Widgets") {
                    ForEach(manager.widgets.filter { !$0.isVisible }) { widget in
                        WidgetConfigRow(widget: widget, manager: manager)
                    }
                }

                Section {
                    Button("Reset to Defaults") {
                        manager.resetToDefaults()
                    }
                    .foregroundStyle(.red)
                }
            }
        }
        .frame(width: 400, height: 500)
    }
}

struct WidgetConfigRow: View {
    let widget: DashboardWidget
    let manager: DashboardWidgetManager

    var body: some View {
        HStack {
            Image(systemName: widget.type.icon)
                .frame(width: 24)
                .foregroundStyle(.blue)

            Text(widget.type.title)

            Spacer()

            Picker("Size", selection: Binding(
                get: { widget.size },
                set: { manager.setWidgetSize(widget.id, size: $0) }
            )) {
                ForEach(WidgetSize.allCases, id: \.self) { size in
                    Text(size.rawValue.capitalized).tag(size)
                }
            }
            .frame(width: 100)

            Button {
                manager.toggleWidget(widget.id)
            } label: {
                Image(systemName: widget.isVisible ? "eye" : "eye.slash")
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Widget Grid View

struct WidgetGridView: View {
    let servers: [Server]
    let onRefreshAll: () -> Void
    let onAddServer: () -> Void
    @State private var manager = DashboardWidgetManager.shared

    var visibleWidgets: [DashboardWidget] {
        manager.widgets.filter { $0.isVisible }.sorted { $0.order < $1.order }
    }

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 250, maximum: 400), spacing: 16)
        ], spacing: 16) {
            ForEach(visibleWidgets) { widget in
                widgetView(for: widget.type)
            }
        }
    }

    @ViewBuilder
    private func widgetView(for type: DashboardWidgetType) -> some View {
        switch type {
        case .serverStatus:
            ServerStatusWidget(servers: servers)
        case .uptimeOverview:
            UptimeOverviewWidget(servers: servers)
        case .recentIncidents:
            RecentIncidentsWidget()
        case .sslCertificates:
            SSLCertificatesWidget(servers: servers)
        case .responseTime:
            ResponseTimeWidget(servers: servers)
        case .quickActions:
            QuickActionsWidget(onRefreshAll: onRefreshAll, onAddServer: onAddServer)
        case .systemHealth:
            SystemHealthWidget(servers: servers)
        case .maintenanceSchedule:
            MaintenanceScheduleWidget()
        }
    }
}
