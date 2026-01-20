//
//  DashboardView.swift
//  Server
//
//  Created by Jonathan Hines Dumitru on 1/13/26.
//

import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var servers: [Server]
    @StateObject private var monitoringService: ServerMonitoringService
    @State private var appModel = AppModel()
    @State private var showingAddServer = false
    @State private var showingWelcome = false
    @State private var showingQuickAccessCustomization = false
    @AppStorage("hasLaunchedBefore") private var hasLaunchedBefore = false
    
    init(modelContext: ModelContext) {
        _monitoringService = StateObject(wrappedValue: ServerMonitoringService(modelContext: modelContext))
    }
    
    var body: some View {
        NavigationSplitView {
            SidebarView(
                selectedSection: $appModel.selectedSection,
                servers: servers,
                isMonitoring: monitoringService.isMonitoring,
                quickAccessItems: appModel.quickAccessItems.filter { $0.isPinned }.sorted { $0.order < $1.order },
                onToggleMonitoring: {
                    if monitoringService.isMonitoring {
                        monitoringService.stopMonitoring()
                    } else {
                        monitoringService.startMonitoring()
                    }
                },
                onAddServer: { showingAddServer = true },
                onCustomizeQuickAccess: { showingQuickAccessCustomization = true }
            )
            .navigationSplitViewColumnWidth(min: 240, ideal: 260, max: 280)
            .sheet(isPresented: $showingAddServer) {
                AddServerView()
            }
            .sheet(isPresented: $showingWelcome) {
                WelcomeView()
            }
            .sheet(isPresented: $showingQuickAccessCustomization) {
                QuickAccessCustomizationView(appModel: appModel)
            }
            .onAppear {
                if !hasLaunchedBefore && servers.isEmpty {
                    showingWelcome = true
                    hasLaunchedBefore = true
                }
            }
        } detail: {
            NavigationContentView(
                selectedSection: appModel.selectedSection,
                servers: servers,
                monitoringService: monitoringService,
                modelContext: modelContext,
                appModel: appModel
            )
        }
    }
}

// MARK: - Navigation

enum NavigationSection: String, CaseIterable, Identifiable, Codable {
    case dashboard
    case rolesFeatures
    case storage
    case networking
    case security
    case updates
    case eventViewer
    case services
    case performanceMonitor
    case diskManagement
    case taskManager
    case powershell
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .rolesFeatures: return "Roles & Features"
        case .storage: return "Storage"
        case .networking: return "Networking"
        case .security: return "Security"
        case .updates: return "Updates"
        case .eventViewer: return "Event Viewer"
        case .services: return "Services"
        case .performanceMonitor: return "Performance Monitor"
        case .diskManagement: return "Disk Management"
        case .taskManager: return "Task Manager"
        case .powershell: return "PowerShell"
        }
    }
    
    var icon: String {
        switch self {
        case .dashboard: return "square.grid.2x2"
        case .rolesFeatures: return "cube.box"
        case .storage: return "internaldrive"
        case .networking: return "network"
        case .security: return "lock.shield"
        case .updates: return "arrow.down.circle"
        case .eventViewer: return "list.bullet.rectangle"
        case .services: return "gearshape.2"
        case .performanceMonitor: return "chart.xyaxis.line"
        case .diskManagement: return "externaldrive"
        case .taskManager: return "list.bullet.clipboard"
        case .powershell: return "terminal"
        }
    }
    
    var isPrimary: Bool {
        switch self {
        case .dashboard, .rolesFeatures, .storage, .networking, .security, .updates:
            return true
        default:
            return false
        }
    }
}

// MARK: - Sidebar

struct SidebarView: View {
    @Binding var selectedSection: NavigationSection
    let servers: [Server]
    let isMonitoring: Bool
    let quickAccessItems: [QuickAccessItem]
    let onToggleMonitoring: () -> Void
    let onAddServer: () -> Void
    let onCustomizeQuickAccess: () -> Void
    
    var onlineCount: Int {
        servers.filter { $0.status == .online }.count
    }
    
    var offlineCount: Int {
        servers.filter { $0.status == .offline }.count
    }
    
    var warningCount: Int {
        servers.filter { $0.status == .warning }.count
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // App Identity Block
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 10) {
                    Image(systemName: "server.rack")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(.blue)
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text("SERVER-2025")
                            .font(.system(size: 16, weight: .bold, design: .default))
                            .foregroundStyle(.primary)
                        
                        Text("Datacenter Edition")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 16)
            .background(Color(nsColor: .windowBackgroundColor))
            
            Divider()
            
            // Navigation Content
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    // Primary Navigation
                    ForEach(NavigationSection.allCases.filter { $0.isPrimary }) { section in
                        NavigationItemView(
                            section: section,
                            isSelected: selectedSection == section,
                            action: { selectedSection = section }
                        )
                    }
                    
                    // Quick Access Section
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text("QUICK ACCESS")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                            
                            Button(action: onCustomizeQuickAccess) {
                                Image(systemName: "ellipsis.circle")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            .help("Customize Quick Access")
                        }
                        .padding(.horizontal, 14)
                        .padding(.top, 16)
                        .padding(.bottom, 4)
                        
                        ForEach(quickAccessItems) { item in
                            NavigationItemView(
                                section: item.destination,
                                isSelected: selectedSection == item.destination,
                                action: { selectedSection = item.destination }
                            )
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            
            Spacer()
            
            // Server Status Metrics (Bottom)
            VStack(spacing: 0) {
                Divider()
                
                VStack(spacing: 6) {
                    HStack {
                        Text("SERVER STATUS")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        if isMonitoring {
                            HStack(spacing: 3) {
                                Circle()
                                    .fill(.green)
                                    .frame(width: 6, height: 6)
                                Text("Live")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    HStack(spacing: 8) {
                        StatusBadge(count: onlineCount, color: .green, label: "Online")
                        StatusBadge(count: offlineCount, color: .red, label: "Offline")
                        StatusBadge(count: warningCount, color: .orange, label: "Warning")
                    }
                    
                    HStack(spacing: 6) {
                        Button(action: onToggleMonitoring) {
                            Label(
                                isMonitoring ? "Stop" : "Start",
                                systemImage: isMonitoring ? "pause.fill" : "play.fill"
                            )
                            .font(.system(size: 11, weight: .medium))
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        Button(action: onAddServer) {
                            Label("Add", systemImage: "plus")
                                .font(.system(size: 11, weight: .medium))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
                .padding(10)
            }
            .background(Color(nsColor: .controlBackgroundColor))
        }
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.95))
    }
}

struct NavigationItemView: View {
    let section: NavigationSection
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: section.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(isSelected ? .white : .secondary)
                    .frame(width: 16)
                
                Text(section.title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? .white : .primary)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(isSelected ? Color.accentColor : (isHovered ? Color(nsColor: .controlBackgroundColor) : Color.clear))
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 6)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct StatusBadge: View {
    let count: Int
    let color: Color
    let label: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            
            Text(label)
                .font(.system(size: 9, weight: .regular))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        )
    }
}

// MARK: - Navigation Content

struct NavigationContentView: View {
    let selectedSection: NavigationSection
    let servers: [Server]
    let monitoringService: ServerMonitoringService
    let modelContext: ModelContext
    @Bindable var appModel: AppModel
    
    @State private var selectedServer: Server?
    @State private var searchText = ""
    
    var filteredServers: [Server] {
        if searchText.isEmpty {
            return servers
        }
        return servers.filter { server in
            server.name.localizedCaseInsensitiveContains(searchText) ||
            server.host.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        Group {
            switch selectedSection {
            case .dashboard:
                if selectedServer != nil {
                    NavigationStack {
                        List(filteredServers, selection: $selectedServer) { server in
                            NavigationLink(value: server) {
                                ServerListItemView(server: server)
                            }
                            .contextMenu {
                                Button("Check Now") {
                                    Task {
                                        await monitoringService.checkServer(server)
                                    }
                                }
                                Divider()
                                Button("Delete", role: .destructive) {
                                    deleteServer(server)
                                }
                            }
                        }
                        .searchable(text: $searchText, prompt: "Search servers")
                        .navigationDestination(for: Server.self) { server in
                            ServerDetailView(server: server)
                        }
                    }
                } else {
                    OverallDashboardView(servers: servers)
                        .toolbar {
                            Button("View Servers") {
                                if let first = servers.first {
                                    selectedServer = first
                                }
                            }
                        }
                }
                
            case .rolesFeatures:
                RolesAndFeaturesView(appModel: appModel)
                
            case .storage:
                StorageView(appModel: appModel)
                
            case .networking:
                NetworkingView(appModel: appModel)
                
            case .security:
                SecurityView(appModel: appModel)
                
            case .updates:
                UpdatesView(appModel: appModel)
                
            default:
                PlaceholderSectionView(section: selectedSection)
            }
        }
    }
    
    private func deleteServer(_ server: Server) {
        withAnimation {
            modelContext.delete(server)
        }
    }
}

struct PlaceholderSectionView: View {
    let section: NavigationSection
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: section.icon)
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            Text(section.title)
                .font(.title2.bold())
            
            Text("This section is under development")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct DashboardHeaderView: View {
    let servers: [Server]
    let isMonitoring: Bool
    
    var onlineCount: Int {
        servers.filter { $0.status == .online }.count
    }
    
    var offlineCount: Int {
        servers.filter { $0.status == .offline }.count
    }
    
    var warningCount: Int {
        servers.filter { $0.status == .warning }.count
    }
    
    var body: some View {
        HStack(spacing: 12) {
            StatCardView(
                title: "Total",
                value: "\(servers.count)",
                icon: "server.rack",
                color: .blue
            )
            
            StatCardView(
                title: "Online",
                value: "\(onlineCount)",
                icon: "checkmark.circle.fill",
                color: .green
            )
            
            StatCardView(
                title: "Offline",
                value: "\(offlineCount)",
                icon: "xmark.circle.fill",
                color: .red
            )
            
            StatCardView(
                title: "Warning",
                value: "\(warningCount)",
                icon: "exclamationmark.triangle.fill",
                color: .orange
            )
        }
        .overlay(alignment: .topTrailing) {
            if isMonitoring {
                HStack(spacing: 4) {
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)
                    Text("Monitoring")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(6)
                .background(.ultraThinMaterial, in: Capsule())
            }
        }
    }
}

struct StatCardView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
        )
    }
}

// MARK: - Overall Dashboard View

struct OverallDashboardView: View {
    let servers: [Server]
    
    var body: some View {
        DetailPageContainer {
            VStack(alignment: .leading, spacing: 4) {
                Text("Server Dashboard")
                    .font(.system(size: 28, weight: .bold, design: .default))
                Text("Complete system overview and metrics")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 200, maximum: 280), spacing: 12)
            ], spacing: 12) {
                DashboardMetricCard(
                    title: "Uptime",
                    value: formatAverageUptime(),
                    subtitle: "Average",
                    icon: "clock.fill",
                    color: .green
                )
                
                DashboardMetricCard(
                    title: "Active Users",
                    value: "\(totalActiveConnections)",
                    subtitle: "Connected",
                    icon: "person.3.fill",
                    color: .blue
                )
                
                DashboardMetricCard(
                    title: "Running Services",
                    value: "\(onlineServers.count)/\(servers.count)",
                    subtitle: "Operational",
                    icon: "server.rack",
                    color: .purple
                )
                
                DashboardMetricCard(
                    title: "Security Alerts",
                    value: "\(securityAlertCount)",
                    subtitle: "Active",
                    icon: "exclamationmark.shield.fill",
                    color: warningServers.count > 0 ? .orange : .green
                )
                
                DashboardMetricCard(
                    title: "Failed Logins",
                    value: "\(failedLoginCount)",
                    subtitle: "Last 24h",
                    icon: "lock.slash.fill",
                    color: .red
                )
                
                DashboardMetricCard(
                    title: "Disk Usage",
                    value: formatPercentage(averageDiskUsage),
                    subtitle: "Average",
                    icon: "internaldrive.fill",
                    color: averageDiskUsage > 80 ? .red : .cyan
                )
                
                DashboardMetricCard(
                    title: "Network Traffic",
                    value: formatNetworkTraffic(totalNetworkTraffic),
                    subtitle: "Total I/O",
                    icon: "network",
                    color: .mint
                )
                
                DashboardMetricCard(
                    title: "Pending Updates",
                    value: "\(pendingUpdatesCount)",
                    subtitle: "Available",
                    icon: "arrow.down.circle.fill",
                    color: .indigo
                )
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Performance Metrics")
                    .font(.system(size: 18, weight: .semibold))
                
                HStack(spacing: 12) {
                    CPUUsageChartView(servers: servers)
                    MemoryUsageChartView(servers: servers)
                }
                .frame(height: 280)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Server Status")
                    .font(.system(size: 18, weight: .semibold))
                
                if servers.isEmpty {
                    ContentUnavailableView(
                        "No Servers",
                        systemImage: "server.rack",
                        description: Text("Add servers to monitor their status")
                    )
                    .frame(height: 200)
                } else {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 300, maximum: .infinity), spacing: 12)
                    ], spacing: 12) {
                        ForEach(servers) { server in
                            ServerStatusCardView(server: server)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    var onlineServers: [Server] {
        servers.filter { $0.status == .online }
    }
    
    var warningServers: [Server] {
        servers.filter { $0.status == .warning }
    }
    
    var totalActiveConnections: Int {
        servers.compactMap { server in
            server.metrics.last?.activeConnections
        }.reduce(0, +)
    }
    
    var securityAlertCount: Int {
        warningServers.count + servers.filter { $0.status == .offline }.count
    }
    
    var failedLoginCount: Int {
        // Mock data - count error logs
        servers.reduce(0) { total, server in
            total + server.logs.filter { $0.level == .error }.count
        }
    }
    
    var averageDiskUsage: Double {
        let diskUsages = servers.compactMap { server in
            server.metrics.last?.diskUsage
        }
        guard !diskUsages.isEmpty else { return 0 }
        return diskUsages.reduce(0, +) / Double(diskUsages.count)
    }
    
    var totalNetworkTraffic: Double {
        servers.reduce(0) { total, server in
            let networkIn = server.metrics.last?.networkIn ?? 0
            let networkOut = server.metrics.last?.networkOut ?? 0
            return total + networkIn + networkOut
        }
    }
    
    var pendingUpdatesCount: Int {
        // Mock data based on warning status
        warningServers.count * 2
    }
    
    // MARK: - Helper Methods
    
    private func formatAverageUptime() -> String {
        let uptimes = servers.compactMap { $0.uptime }
        guard !uptimes.isEmpty else { return "N/A" }
        
        let avgUptime = uptimes.reduce(0, +) / Double(uptimes.count)
        let days = Int(avgUptime) / 86400
        let hours = (Int(avgUptime) % 86400) / 3600
        
        if days > 0 {
            return "\(days)d \(hours)h"
        } else {
            return "\(hours)h"
        }
    }
    
    private func formatPercentage(_ value: Double) -> String {
        return "\(Int(value))%"
    }
    
    private func formatNetworkTraffic(_ value: Double) -> String {
        if value > 1000 {
            return String(format: "%.1f GB/s", value / 1000)
        } else {
            return String(format: "%.0f MB/s", value)
        }
    }
}

// MARK: - Dashboard Metric Card

struct DashboardMetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var isHealthyZero: Bool {
        (title.contains("Alert") || title.contains("Failed")) && (value == "0" || value == "N/A")
    }
    
    var isUnavailable: Bool {
        value == "N/A" && !isHealthyZero
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(isHealthyZero ? .green : color)
                    .frame(width: 20, height: 20)
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(isUnavailable ? .tertiary : .primary)
            
            Text(subtitle)
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
        )
    }
}

// MARK: - CPU Usage Chart

struct CPUUsageChartView: View {
    let servers: [Server]
    
    var allMetrics: [(server: String, timestamp: Date, value: Double)] {
        servers.flatMap { server in
            server.metrics
                .sorted(by: { $0.timestamp < $1.timestamp })
                .suffix(20)
                .compactMap { metric in
                    guard let cpu = metric.cpuUsage else { return nil }
                    return (server.name, metric.timestamp, cpu)
                }
        }
    }
    
    // Generate placeholder data when no real data exists
    var placeholderData: [(server: String, timestamp: Date, value: Double)] {
        let now = Date()
        return stride(from: 0, to: 20, by: 1).map { index in
            ("Demo Server", now.addingTimeInterval(TimeInterval(-600 * (20 - index))), Double.random(in: 15...45))
        }
    }
    
    var displayData: [(server: String, timestamp: Date, value: Double)] {
        allMetrics.isEmpty ? placeholderData : allMetrics
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("CPU Usage", systemImage: "cpu")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                if allMetrics.isEmpty {
                    Text("DEMO DATA")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.1), in: Capsule())
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
            
            Chart {
                ForEach(Array(displayData.enumerated()), id: \.offset) { _, metric in
                    LineMark(
                        x: .value("Time", metric.timestamp),
                        y: .value("CPU %", metric.value)
                    )
                    .foregroundStyle(by: .value("Server", metric.server))
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    
                    AreaMark(
                        x: .value("Time", metric.timestamp),
                        y: .value("CPU %", metric.value)
                    )
                    .foregroundStyle(by: .value("Server", metric.server))
                    .interpolationMethod(.catmullRom)
                    .opacity(0.1)
                }
            }
            .chartYScale(domain: 0...100)
            .chartYAxis {
                AxisMarks(position: .leading, values: [0, 25, 50, 75, 100]) { value in
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            Text("\(intValue)%")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                    }
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                        .foregroundStyle(Color.primary.opacity(0.1))
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .minute, count: 5)) { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            Text(date, format: .dateTime.hour().minute())
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                    }
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                        .foregroundStyle(Color.primary.opacity(0.1))
                }
            }
            .frame(height: 220)
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
        )
    }
}

// MARK: - Memory Usage Chart

struct MemoryUsageChartView: View {
    let servers: [Server]
    
    var allMetrics: [(server: String, timestamp: Date, value: Double)] {
        servers.flatMap { server in
            server.metrics
                .sorted(by: { $0.timestamp < $1.timestamp })
                .suffix(20)
                .compactMap { metric in
                    guard let memory = metric.memoryUsage else { return nil }
                    return (server.name, metric.timestamp, memory)
                }
        }
    }
    
    // Generate placeholder data when no real data exists
    var placeholderData: [(server: String, timestamp: Date, value: Double)] {
        let now = Date()
        return stride(from: 0, to: 20, by: 1).map { index in
            ("Demo Server", now.addingTimeInterval(TimeInterval(-600 * (20 - index))), Double.random(in: 40...70))
        }
    }
    
    var displayData: [(server: String, timestamp: Date, value: Double)] {
        allMetrics.isEmpty ? placeholderData : allMetrics
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Memory Usage", systemImage: "memorychip")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                if allMetrics.isEmpty {
                    Text("DEMO DATA")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.1), in: Capsule())
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
            
            Chart {
                ForEach(Array(displayData.enumerated()), id: \.offset) { _, metric in
                    AreaMark(
                        x: .value("Time", metric.timestamp),
                        y: .value("Memory %", metric.value)
                    )
                    .foregroundStyle(by: .value("Server", metric.server))
                    .interpolationMethod(.catmullRom)
                    .opacity(0.2)
                    
                    LineMark(
                        x: .value("Time", metric.timestamp),
                        y: .value("Memory %", metric.value)
                    )
                    .foregroundStyle(by: .value("Server", metric.server))
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }
            }
            .chartYScale(domain: 0...100)
            .chartYAxis {
                AxisMarks(position: .leading, values: [0, 25, 50, 75, 100]) { value in
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            Text("\(intValue)%")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                    }
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                        .foregroundStyle(Color.primary.opacity(0.1))
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .minute, count: 5)) { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            Text(date, format: .dateTime.hour().minute())
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                    }
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                        .foregroundStyle(Color.primary.opacity(0.1))
                }
            }
            .frame(height: 220)
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
        )
    }
}

// MARK: - Server Status Card

struct ServerStatusCardView: View {
    let server: Server
    
    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            ZStack {
                Circle()
                    .fill(Color(server.status.color).opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: server.serverType.iconName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color(server.status.color))
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(server.name)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color(server.status.color))
                        .frame(width: 6, height: 6)
                    
                    Text(server.status.rawValue.uppercased())
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color(server.status.color))
                }
                
                if let responseTime = server.responseTime {
                    Text("\(Int(responseTime))ms")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
            }
            
            Spacer()
            
            // Quick metrics
            if let latestMetric = server.metrics.last {
                VStack(alignment: .trailing, spacing: 4) {
                    if let cpu = latestMetric.cpuUsage {
                        HStack(spacing: 3) {
                            Image(systemName: "cpu")
                                .font(.system(size: 9))
                            Text("\(Int(cpu))%")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(.blue)
                    }
                    
                    if let memory = latestMetric.memoryUsage {
                        HStack(spacing: 3) {
                            Image(systemName: "memorychip")
                                .font(.system(size: 9))
                            Text("\(Int(memory))%")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(.orange)
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
        )
    }
}

