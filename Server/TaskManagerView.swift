//
//  TaskManagerView.swift
//  Server
//
//  Created by Claude on 1/28/26.
//

import SwiftUI
import SwiftData
import Charts

struct TaskManagerView: View {
    @Query private var servers: [Server]
    @State private var selectedServer: Server?
    @State private var selectedTab: TaskManagerTab = .processes
    @State private var searchText = ""
    @State private var sortOrder: ProcessSortOrder = .cpu
    @State private var sortAscending = false

    enum TaskManagerTab: String, CaseIterable, Identifiable {
        case processes = "Processes"
        case performance = "Performance"
        case users = "Users"
        case details = "Details"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .processes: return "list.bullet"
            case .performance: return "chart.line.uptrend.xyaxis"
            case .users: return "person.2"
            case .details: return "info.circle"
            }
        }
    }

    enum ProcessSortOrder: String, CaseIterable {
        case name = "Name"
        case cpu = "CPU"
        case memory = "Memory"
        case disk = "Disk"
        case network = "Network"
    }

    var body: some View {
        HSplitView {
            // Server List
            VStack(spacing: 0) {
                HStack {
                    Text("Servers")
                        .font(.headline)
                    Spacer()
                }
                .padding()

                Divider()

                List(servers, selection: $selectedServer) { server in
                    ServerResourceRow(server: server)
                        .tag(server)
                }
                .listStyle(.inset)
            }
            .frame(minWidth: 220, maxWidth: 280)

            // Task Manager Content
            if let server = selectedServer {
                VStack(spacing: 0) {
                    // Tab Bar
                    HStack(spacing: 0) {
                        ForEach(TaskManagerTab.allCases) { tab in
                            TabButton(
                                title: tab.rawValue,
                                icon: tab.icon,
                                isSelected: selectedTab == tab
                            ) {
                                selectedTab = tab
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    Divider()
                        .padding(.top, 8)

                    // Content
                    switch selectedTab {
                    case .processes:
                        ProcessListView(
                            server: server,
                            searchText: $searchText,
                            sortOrder: $sortOrder,
                            sortAscending: $sortAscending
                        )
                    case .performance:
                        PerformanceTabView(server: server)
                    case .users:
                        UsersTabView(server: server)
                    case .details:
                        DetailsTabView(server: server)
                    }
                }
            } else {
                emptyState
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Select a Server")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text("Choose a server to view running processes and resource usage")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Tab Button

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                    Text(title)
                        .font(.system(size: 12, weight: .medium))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }
            .foregroundStyle(isSelected ? .blue : .secondary)
            .background(
                isSelected ?
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.blue.opacity(0.1))
                    : nil
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Server Resource Row

struct ServerResourceRow: View {
    let server: Server

    var cpu: Double { server.metrics.last?.cpuUsage ?? 0 }
    var memory: Double { server.metrics.last?.memoryUsage ?? 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Circle()
                    .fill(Color(server.status.color))
                    .frame(width: 8, height: 8)
                Text(server.name)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
            }

            HStack(spacing: 12) {
                ResourceMiniBar(label: "CPU", value: cpu, color: .blue)
                ResourceMiniBar(label: "MEM", value: memory, color: .orange)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ResourceMiniBar: View {
    let label: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(label)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(value))%")
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .foregroundStyle(color)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.secondary.opacity(0.2))
                    RoundedRectangle(cornerRadius: 1)
                        .fill(color)
                        .frame(width: geo.size.width * (value / 100))
                }
            }
            .frame(height: 3)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Process List View

struct ProcessListView: View {
    let server: Server
    @Binding var searchText: String
    @Binding var sortOrder: TaskManagerView.ProcessSortOrder
    @Binding var sortAscending: Bool

    @State private var selectedProcess: SimulatedProcess?
    @State private var showEndProcessAlert = false

    var processes: [SimulatedProcess] {
        var list = SimulatedProcess.simulatedProcesses(for: server)

        // Filter
        if !searchText.isEmpty {
            list = list.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.user.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Sort
        list.sort { lhs, rhs in
            let result: Bool
            switch sortOrder {
            case .name: result = lhs.name < rhs.name
            case .cpu: result = lhs.cpu > rhs.cpu
            case .memory: result = lhs.memory > rhs.memory
            case .disk: result = lhs.diskIO > rhs.diskIO
            case .network: result = lhs.networkIO > rhs.networkIO
            }
            return sortAscending ? !result : result
        }

        return list
    }

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                TextField("Search processes...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 250)

                Spacer()

                Picker("Sort by", selection: $sortOrder) {
                    ForEach(TaskManagerView.ProcessSortOrder.allCases, id: \.self) { order in
                        Text(order.rawValue).tag(order)
                    }
                }
                .frame(width: 120)

                Button {
                    sortAscending.toggle()
                } label: {
                    Image(systemName: sortAscending ? "arrow.up" : "arrow.down")
                }

                Button(role: .destructive) {
                    if selectedProcess != nil {
                        showEndProcessAlert = true
                    }
                } label: {
                    Text("End Task")
                }
                .disabled(selectedProcess == nil)
            }
            .padding()

            // Process Table
            Table(processes, selection: $selectedProcess) {
                TableColumn("Name") { process in
                    HStack(spacing: 8) {
                        Image(systemName: process.type.icon)
                            .font(.system(size: 12))
                            .foregroundStyle(process.type.color)
                        Text(process.name)
                            .font(.system(size: 12))
                    }
                }
                .width(min: 180, ideal: 200)

                TableColumn("PID") { process in
                    Text("\(process.pid)")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                .width(60)

                TableColumn("Status") { process in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(process.status.color)
                            .frame(width: 6, height: 6)
                        Text(process.status.rawValue)
                            .font(.system(size: 11))
                    }
                }
                .width(80)

                TableColumn("CPU") { process in
                    HStack {
                        Text(String(format: "%.1f%%", process.cpu))
                            .font(.system(size: 11, design: .monospaced))
                        ProcessBarIndicator(value: process.cpu, maxValue: 100, color: .blue)
                    }
                }
                .width(100)

                TableColumn("Memory") { process in
                    HStack {
                        Text(formatMemory(process.memory))
                            .font(.system(size: 11, design: .monospaced))
                        ProcessBarIndicator(value: process.memory, maxValue: 8192, color: .orange)
                    }
                }
                .width(100)

                TableColumn("Disk") { process in
                    Text(formatIO(process.diskIO))
                        .font(.system(size: 11, design: .monospaced))
                }
                .width(80)

                TableColumn("Network") { process in
                    Text(formatIO(process.networkIO))
                        .font(.system(size: 11, design: .monospaced))
                }
                .width(80)

                TableColumn("User") { process in
                    Text(process.user)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .width(100)
            }
        }
        .alert("End Process?", isPresented: $showEndProcessAlert) {
            Button("Cancel", role: .cancel) { }
            Button("End Process", role: .destructive) {
                selectedProcess = nil
            }
        } message: {
            if let process = selectedProcess {
                Text("Are you sure you want to end '\(process.name)'? This may cause data loss.")
            }
        }
    }

    private func formatMemory(_ mb: Double) -> String {
        if mb >= 1024 {
            return String(format: "%.1f GB", mb / 1024)
        }
        return String(format: "%.0f MB", mb)
    }

    private func formatIO(_ mbps: Double) -> String {
        if mbps >= 1 {
            return String(format: "%.1f MB/s", mbps)
        }
        return String(format: "%.0f KB/s", mbps * 1024)
    }
}

struct ProcessBarIndicator: View {
    let value: Double
    let maxValue: Double
    let color: Color

    var normalizedValue: Double {
        min(value / maxValue, 1.0)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.secondary.opacity(0.15))
                RoundedRectangle(cornerRadius: 2)
                    .fill(color.opacity(0.6))
                    .frame(width: geo.size.width * normalizedValue)
            }
        }
        .frame(width: 30, height: 8)
    }
}

// MARK: - Performance Tab View

struct PerformanceTabView: View {
    let server: Server

    var latestMetric: ServerMetric? {
        server.metrics.last
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Resource Summary
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ResourceCard(
                        title: "CPU",
                        value: latestMetric?.cpuUsage ?? 0,
                        unit: "%",
                        icon: "cpu",
                        color: .blue
                    )
                    ResourceCard(
                        title: "Memory",
                        value: latestMetric?.memoryUsage ?? 0,
                        unit: "%",
                        icon: "memorychip",
                        color: .orange
                    )
                    ResourceCard(
                        title: "Disk",
                        value: latestMetric?.diskUsage ?? 0,
                        unit: "%",
                        icon: "internaldrive",
                        color: .purple
                    )
                    ResourceCard(
                        title: "Network",
                        value: (latestMetric?.networkIn ?? 0) + (latestMetric?.networkOut ?? 0),
                        unit: " MB/s",
                        icon: "network",
                        color: .green
                    )
                }

                // System Info
                GroupBox("System Information") {
                    VStack(spacing: 8) {
                        InfoRow(label: "Hostname", value: server.host)
                        InfoRow(label: "Status", value: server.status.rawValue)
                        InfoRow(label: "Response Time", value: server.responseTime != nil ? "\(Int(server.responseTime!)) ms" : "N/A")
                        InfoRow(label: "Active Connections", value: "\(latestMetric?.activeConnections ?? 0)")
                        if let uptime = server.uptime {
                            InfoRow(label: "Uptime", value: formatUptime(uptime))
                        }
                    }
                }
            }
            .padding()
        }
    }

    private func formatUptime(_ seconds: TimeInterval) -> String {
        let days = Int(seconds) / 86400
        let hours = (Int(seconds) % 86400) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        return "\(days)d \(hours)h \(minutes)m"
    }
}

struct ResourceCard: View {
    let title: String
    let value: Double
    let unit: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                Spacer()
            }

            Text("\(Int(value))\(unit)")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(color)

            // Mini chart placeholder
            RoundedRectangle(cornerRadius: 4)
                .fill(color.opacity(0.2))
                .frame(height: 30)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.system(size: 12))
    }
}

// MARK: - Users Tab View

struct UsersTabView: View {
    let server: Server

    var simulatedUsers: [SimulatedUser] {
        SimulatedUser.simulatedUsers(for: server)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Summary
            HStack {
                VStack(alignment: .leading) {
                    Text("\(simulatedUsers.count) Users")
                        .font(.headline)
                    Text("\(simulatedUsers.filter { $0.status == .active }.count) active sessions")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding()

            Divider()

            // User List
            List(simulatedUsers) { user in
                HStack(spacing: 12) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(user.status == .active ? .blue : .gray)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(user.name)
                            .font(.system(size: 13, weight: .medium))
                        Text(user.sessionType)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(user.status.color)
                                .frame(width: 6, height: 6)
                            Text(user.status.rawValue)
                                .font(.system(size: 11))
                        }
                        Text("Since \(user.loginTime, style: .time)")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.vertical, 4)
            }
            .listStyle(.inset)
        }
    }
}

// MARK: - Details Tab View

struct DetailsTabView: View {
    let server: Server

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                GroupBox("Server Details") {
                    VStack(spacing: 8) {
                        InfoRow(label: "Name", value: server.name)
                        InfoRow(label: "Host", value: server.host)
                        InfoRow(label: "Port", value: "\(server.port)")
                        InfoRow(label: "Type", value: server.serverType.rawValue)
                        InfoRow(label: "Status", value: server.status.rawValue)
                        if let lastChecked = server.lastChecked {
                            InfoRow(label: "Last Checked", value: lastChecked.formatted())
                        }
                    }
                }

                GroupBox("Resource Statistics") {
                    if let metric = server.metrics.last {
                        VStack(spacing: 8) {
                            InfoRow(label: "CPU Usage", value: metric.cpuUsage != nil ? "\(Int(metric.cpuUsage!))%" : "N/A")
                            InfoRow(label: "Memory Usage", value: metric.memoryUsage != nil ? "\(Int(metric.memoryUsage!))%" : "N/A")
                            InfoRow(label: "Disk Usage", value: metric.diskUsage != nil ? "\(Int(metric.diskUsage!))%" : "N/A")
                            InfoRow(label: "Network In", value: metric.networkIn != nil ? "\(Int(metric.networkIn!)) MB/s" : "N/A")
                            InfoRow(label: "Network Out", value: metric.networkOut != nil ? "\(Int(metric.networkOut!)) MB/s" : "N/A")
                            InfoRow(label: "Connections", value: "\(metric.activeConnections ?? 0)")
                        }
                    } else {
                        Text("No metrics available")
                            .foregroundStyle(.secondary)
                    }
                }

                GroupBox("Notes") {
                    if server.notes.isEmpty {
                        Text("No notes")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Text(server.notes)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Simulated Models

struct SimulatedProcess: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let pid: Int
    let cpu: Double
    let memory: Double
    let diskIO: Double
    let networkIO: Double
    let user: String
    let type: ProcessType
    let status: ProcessStatus

    enum ProcessType {
        case system
        case service
        case application
        case background

        var icon: String {
            switch self {
            case .system: return "gearshape.fill"
            case .service: return "server.rack"
            case .application: return "app.fill"
            case .background: return "circle.dashed"
            }
        }

        var color: Color {
            switch self {
            case .system: return .blue
            case .service: return .green
            case .application: return .purple
            case .background: return .gray
            }
        }
    }

    enum ProcessStatus: String {
        case running = "Running"
        case suspended = "Suspended"
        case waiting = "Waiting"

        var color: Color {
            switch self {
            case .running: return .green
            case .suspended: return .orange
            case .waiting: return .blue
            }
        }
    }

    static func simulatedProcesses(for server: Server) -> [SimulatedProcess] {
        let cpu = server.metrics.last?.cpuUsage ?? 30
        return [
            SimulatedProcess(name: "System", pid: 4, cpu: cpu * 0.1, memory: 128, diskIO: 0.5, networkIO: 0.1, user: "SYSTEM", type: .system, status: .running),
            SimulatedProcess(name: "svchost.exe", pid: 892, cpu: cpu * 0.15, memory: 256, diskIO: 1.2, networkIO: 0.5, user: "SYSTEM", type: .service, status: .running),
            SimulatedProcess(name: "nginx", pid: 1234, cpu: cpu * 0.2, memory: 512, diskIO: 2.5, networkIO: 15.0, user: "www-data", type: .service, status: .running),
            SimulatedProcess(name: "mysqld", pid: 2345, cpu: cpu * 0.25, memory: 2048, diskIO: 8.0, networkIO: 5.0, user: "mysql", type: .service, status: .running),
            SimulatedProcess(name: "redis-server", pid: 3456, cpu: cpu * 0.05, memory: 128, diskIO: 0.1, networkIO: 2.0, user: "redis", type: .service, status: .running),
            SimulatedProcess(name: "node", pid: 4567, cpu: cpu * 0.1, memory: 384, diskIO: 0.3, networkIO: 3.0, user: "app", type: .application, status: .running),
            SimulatedProcess(name: "python3", pid: 5678, cpu: cpu * 0.08, memory: 256, diskIO: 0.2, networkIO: 1.0, user: "app", type: .application, status: .running),
            SimulatedProcess(name: "cron", pid: 6789, cpu: 0.1, memory: 16, diskIO: 0.01, networkIO: 0, user: "root", type: .background, status: .waiting),
            SimulatedProcess(name: "rsyslogd", pid: 7890, cpu: 0.2, memory: 32, diskIO: 0.5, networkIO: 0.1, user: "syslog", type: .service, status: .running),
            SimulatedProcess(name: "dockerd", pid: 8901, cpu: cpu * 0.05, memory: 512, diskIO: 1.0, networkIO: 0.5, user: "root", type: .service, status: .running),
        ]
    }
}

struct SimulatedUser: Identifiable {
    let id = UUID()
    let name: String
    let sessionType: String
    let status: UserStatus
    let loginTime: Date

    enum UserStatus: String {
        case active = "Active"
        case idle = "Idle"
        case disconnected = "Disconnected"

        var color: Color {
            switch self {
            case .active: return .green
            case .idle: return .orange
            case .disconnected: return .gray
            }
        }
    }

    static func simulatedUsers(for server: Server) -> [SimulatedUser] {
        [
            SimulatedUser(name: "Administrator", sessionType: "Console", status: .active, loginTime: Date().addingTimeInterval(-3600)),
            SimulatedUser(name: "app_service", sessionType: "Service", status: .active, loginTime: Date().addingTimeInterval(-86400)),
            SimulatedUser(name: "backup_user", sessionType: "Remote Desktop", status: .idle, loginTime: Date().addingTimeInterval(-7200)),
            SimulatedUser(name: "monitor", sessionType: "Service", status: .active, loginTime: Date().addingTimeInterval(-172800)),
        ]
    }
}

#Preview {
    TaskManagerView()
}
