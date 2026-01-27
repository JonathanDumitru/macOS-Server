//
//  ServerDetailView.swift
//  Server
//
//  Created by Jonathan Hines Dumitru on 1/13/26.
//

import SwiftUI
import SwiftData
import Charts

struct ServerDetailView: View {
    @Bindable var server: Server
    @State private var selectedTab: DetailTab = .overview
    
    enum DetailTab: String, CaseIterable {
        case overview = "Overview"
        case metrics = "Metrics"
        case logs = "Logs"
        
        var icon: String {
            switch self {
            case .overview: return "info.circle"
            case .metrics: return "chart.xyaxis.line"
            case .logs: return "list.bullet.rectangle"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            ServerDetailHeaderView(server: server)
                .padding()
            
            Divider()
            
            // Tab Picker
            Picker("View", selection: $selectedTab) {
                ForEach(DetailTab.allCases, id: \.self) { tab in
                    Label(tab.rawValue, systemImage: tab.icon)
                        .tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            
            // Content
            TabView(selection: $selectedTab) {
                ServerOverviewView(server: server)
                    .tag(DetailTab.overview)
                
                ServerMetricsView(server: server)
                    .tag(DetailTab.metrics)
                
                ServerLogsView(server: server)
                    .tag(DetailTab.logs)
            }
            .tabViewStyle(.automatic)
        }
        .navigationTitle(server.name)
        .navigationSubtitle("\(server.host):\(server.port)")
    }
}

struct ServerDetailHeaderView: View {
    let server: Server
    
    var body: some View {
        HStack(spacing: 16) {
            // Server icon and status
            VStack {
                ZStack(alignment: .bottomTrailing) {
                    Image(systemName: server.serverType.iconName)
                        .font(.system(size: 42))
                        .foregroundStyle(.blue)
                        .frame(width: 68, height: 68)
                        .background(.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                    
                    Circle()
                        .fill(Color(server.status.color))
                        .frame(width: 16, height: 16)
                        .overlay(
                            Circle()
                                .stroke(Color(nsColor: .controlBackgroundColor), lineWidth: 2)
                        )
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(server.name)
                    .font(.system(size: 20, weight: .bold))
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(server.status.color))
                        .frame(width: 6, height: 6)
                    Text(server.status.rawValue.uppercased())
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color(server.status.color))
                }
                
                if let lastChecked = server.lastChecked {
                    Text("Last checked: \(lastChecked, style: .relative)")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Quick stats
            HStack(spacing: 20) {
                if let responseTime = server.responseTime {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(Int(responseTime))ms")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                        Text("Response Time")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }

                // Uptime percentage
                VStack(alignment: .trailing, spacing: 2) {
                    Text(server.formattedUptimePercentage)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(uptimeColor(for: server.uptimePercentage))
                    Text("Uptime")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }

                // Current streak
                VStack(alignment: .trailing, spacing: 2) {
                    Text(server.formattedCurrentStreak)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(server.status.color))
                            .frame(width: 6, height: 6)
                        Text("Streak")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: .black.opacity(0.06), radius: 3, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
        )
    }
    
    private func formatUptime(_ seconds: TimeInterval) -> String {
        let days = Int(seconds) / 86400
        let hours = (Int(seconds) % 86400) / 3600
        if days > 0 {
            return "\(days)d \(hours)h"
        } else {
            return "\(hours)h"
        }
    }

    private func uptimeColor(for percentage: Double) -> Color {
        switch percentage {
        case 99.9...: return .green
        case 99.0..<99.9: return .mint
        case 95.0..<99.0: return .yellow
        case 90.0..<95.0: return .orange
        default: return .red
        }
    }
}

struct ServerOverviewView: View {
    let server: Server
    @State private var selectedUptimePeriod: UptimePeriod = .day

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Connection Info
                GroupBox("Connection Information") {
                    VStack(alignment: .leading, spacing: 12) {
                        InfoRow(label: "Host", value: server.host)
                        InfoRow(label: "Port", value: "\(server.port)")
                        InfoRow(label: "Type", value: server.serverType.rawValue)
                        InfoRow(label: "Status", value: server.status.rawValue)
                    }
                    .padding(8)
                }

                // Uptime Statistics
                GroupBox {
                    VStack(alignment: .leading, spacing: 16) {
                        // Period selector
                        HStack {
                            Text("Time Period:")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                            Picker("Period", selection: $selectedUptimePeriod) {
                                ForEach(UptimePeriod.allCases, id: \.self) { period in
                                    Text(period.rawValue).tag(period)
                                }
                            }
                            .pickerStyle(.segmented)
                            .frame(maxWidth: 400)
                        }

                        let stats = server.uptimeStats(for: selectedUptimePeriod)

                        // Uptime gauge and stats
                        HStack(spacing: 30) {
                            // Large uptime gauge
                            VStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 10)

                                    Circle()
                                        .trim(from: 0, to: stats.uptimePercentage / 100)
                                        .stroke(
                                            uptimeGradient(for: stats.uptimePercentage),
                                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                                        )
                                        .rotationEffect(.degrees(-90))

                                    VStack(spacing: 2) {
                                        Text(String(format: "%.2f", stats.uptimePercentage))
                                            .font(.system(size: 28, weight: .bold, design: .rounded))
                                        Text("%")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .frame(width: 100, height: 100)

                                Text("Uptime")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.secondary)
                            }

                            // Stats breakdown
                            VStack(alignment: .leading, spacing: 12) {
                                UptimeStatRow(
                                    icon: "checkmark.circle.fill",
                                    color: .green,
                                    label: "Online",
                                    value: formatDuration(stats.totalOnlineSeconds)
                                )

                                UptimeStatRow(
                                    icon: "xmark.circle.fill",
                                    color: .red,
                                    label: "Offline",
                                    value: formatDuration(stats.totalOfflineSeconds)
                                )

                                UptimeStatRow(
                                    icon: "clock.fill",
                                    color: .blue,
                                    label: "Current Streak",
                                    value: "\(stats.formattedStreak) (\(stats.currentStreakStatus.rawValue))"
                                )

                                if let lastChange = stats.lastStatusChange {
                                    UptimeStatRow(
                                        icon: "arrow.triangle.2.circlepath",
                                        color: .purple,
                                        label: "Last Change",
                                        value: lastChange.formatted(date: .abbreviated, time: .shortened)
                                    )
                                }
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding(8)
                } label: {
                    Label("Uptime Statistics", systemImage: "chart.bar.fill")
                }

                // Notes
                GroupBox("Notes") {
                    if server.notes.isEmpty {
                        Text("No notes")
                            .foregroundStyle(.secondary)
                            .italic()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                    } else {
                        Text(server.notes)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                    }
                }

                // Recent Metrics Summary
                if let latestMetric = server.metrics.sorted(by: { $0.timestamp > $1.timestamp }).first {
                    GroupBox("Latest Metrics") {
                        HStack(spacing: 20) {
                            if let cpu = latestMetric.cpuUsage {
                                MetricGaugeView(title: "CPU", value: cpu, color: .blue)
                            }
                            if let memory = latestMetric.memoryUsage {
                                MetricGaugeView(title: "Memory", value: memory, color: .orange)
                            }
                            if let disk = latestMetric.diskUsage {
                                MetricGaugeView(title: "Disk", value: disk, color: .purple)
                            }
                        }
                        .padding(8)
                    }
                }
            }
            .padding()
        }
    }

    private func uptimeGradient(for percentage: Double) -> LinearGradient {
        let color: Color
        switch percentage {
        case 99.9...: color = .green
        case 99.0..<99.9: color = .mint
        case 95.0..<99.0: color = .yellow
        case 90.0..<95.0: color = .orange
        default: color = .red
        }
        return LinearGradient(
            colors: [color, color.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func formatDuration(_ seconds: Double) -> String {
        guard seconds > 0 else { return "0m" }
        let days = Int(seconds) / 86400
        let hours = (Int(seconds) % 86400) / 3600
        let minutes = (Int(seconds) % 3600) / 60

        if days > 0 {
            return "\(days)d \(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct UptimeStatRow: View {
    let icon: String
    let color: Color
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 16)

            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .frame(width: 100, alignment: .leading)

            Text(value)
                .font(.system(size: 12, weight: .medium))
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .semibold))
        }
    }
}

struct MetricGaugeView: View {
    let title: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.15), lineWidth: 6)
                
                Circle()
                    .trim(from: 0, to: value / 100)
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                
                Text("\(Int(value))%")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
            }
            .frame(width: 70, height: 70)
            
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ServerMetricsView: View {
    let server: Server
    @State private var selectedMetricType: MetricType = .cpu
    
    enum MetricType: String, CaseIterable {
        case cpu = "CPU"
        case memory = "Memory"
        case disk = "Disk"
        case network = "Network"
    }
    
    var recentMetrics: [ServerMetric] {
        server.metrics
            .sorted(by: { $0.timestamp > $1.timestamp })
            .prefix(50)
            .reversed()
    }
    
    var body: some View {
        VStack {
            Picker("Metric", selection: $selectedMetricType) {
                ForEach(MetricType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            
            if recentMetrics.isEmpty {
                ContentUnavailableView(
                    "No Metrics Available",
                    systemImage: "chart.xyaxis.line",
                    description: Text("Metrics will appear here once monitoring begins")
                )
            } else {
                Chart(recentMetrics) { metric in
                    switch selectedMetricType {
                    case .cpu:
                        if let cpu = metric.cpuUsage {
                            LineMark(
                                x: .value("Time", metric.timestamp),
                                y: .value("Usage", cpu)
                            )
                            .foregroundStyle(.blue)
                        }
                    case .memory:
                        if let memory = metric.memoryUsage {
                            LineMark(
                                x: .value("Time", metric.timestamp),
                                y: .value("Usage", memory)
                            )
                            .foregroundStyle(.orange)
                        }
                    case .disk:
                        if let disk = metric.diskUsage {
                            LineMark(
                                x: .value("Time", metric.timestamp),
                                y: .value("Usage", disk)
                            )
                            .foregroundStyle(.purple)
                        }
                    case .network:
                        if let networkIn = metric.networkIn {
                            LineMark(
                                x: .value("Time", metric.timestamp),
                                y: .value("In", networkIn)
                            )
                            .foregroundStyle(.green)
                        }
                        if let networkOut = metric.networkOut {
                            LineMark(
                                x: .value("Time", metric.timestamp),
                                y: .value("Out", networkOut)
                            )
                            .foregroundStyle(.red)
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(date, format: .dateTime.hour().minute())
                            }
                        }
                    }
                }
                .padding()
            }
            
            Spacer()
        }
    }
}

struct ServerLogsView: View {
    let server: Server
    @State private var selectedLogLevel: LogLevel?
    
    var filteredLogs: [ServerLog] {
        let sorted = server.logs.sorted(by: { $0.timestamp > $1.timestamp })
        if let level = selectedLogLevel {
            return sorted.filter { $0.level == level }
        }
        return sorted
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Filter bar
            HStack {
                Text("Filter:")
                    .foregroundStyle(.secondary)
                
                Picker("Level", selection: $selectedLogLevel) {
                    Text("All").tag(nil as LogLevel?)
                    ForEach(LogLevel.allCases, id: \.self) { level in
                        Text(level.rawValue).tag(level as LogLevel?)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding()
            
            Divider()
            
            if filteredLogs.isEmpty {
                ContentUnavailableView(
                    "No Logs",
                    systemImage: "list.bullet.rectangle",
                    description: Text("Server logs will appear here")
                )
            } else {
                List(filteredLogs) { log in
                    LogItemView(log: log)
                }
                .listStyle(.plain)
            }
        }
    }
}

struct LogItemView: View {
    let log: ServerLog
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: log.level.iconName)
                .foregroundStyle(Color(log.level.color))
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(log.level.rawValue.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color(log.level.color))
                    
                    Spacer()
                    
                    Text(log.timestamp, style: .time)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                
                Text(log.message)
                    .font(.system(size: 12))
                    .foregroundStyle(.primary)
            }
        }
        .padding(.vertical, 6)
    }
}
