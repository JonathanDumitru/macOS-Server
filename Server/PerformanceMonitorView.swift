//
//  PerformanceMonitorView.swift
//  Server
//
//  Created by Claude on 1/28/26.
//

import SwiftUI
import SwiftData
import Charts

struct PerformanceMonitorView: View {
    @Query private var servers: [Server]
    @State private var selectedServer: Server?
    @State private var refreshInterval: RefreshInterval = .seconds5
    @State private var isLiveUpdating = true
    @State private var selectedMetricType: MetricType = .all
    @State private var timeRange: TimeRange = .minutes15

    enum RefreshInterval: Int, CaseIterable, Identifiable {
        case seconds1 = 1
        case seconds5 = 5
        case seconds10 = 10
        case seconds30 = 30

        var id: Int { rawValue }
        var label: String {
            switch self {
            case .seconds1: return "1 sec"
            case .seconds5: return "5 sec"
            case .seconds10: return "10 sec"
            case .seconds30: return "30 sec"
            }
        }
    }

    enum MetricType: String, CaseIterable, Identifiable {
        case all = "All Metrics"
        case cpu = "CPU"
        case memory = "Memory"
        case disk = "Disk"
        case network = "Network"

        var id: String { rawValue }
    }

    enum TimeRange: String, CaseIterable, Identifiable {
        case minutes5 = "5 min"
        case minutes15 = "15 min"
        case minutes30 = "30 min"
        case hour1 = "1 hour"

        var id: String { rawValue }

        var seconds: TimeInterval {
            switch self {
            case .minutes5: return 300
            case .minutes15: return 900
            case .minutes30: return 1800
            case .hour1: return 3600
            }
        }
    }

    var body: some View {
        HSplitView {
            // Server Selection Panel
            VStack(spacing: 0) {
                HStack {
                    Text("Servers")
                        .font(.headline)
                    Spacer()
                    Circle()
                        .fill(isLiveUpdating ? .green : .gray)
                        .frame(width: 8, height: 8)
                }
                .padding()

                Divider()

                List(servers, selection: $selectedServer) { server in
                    ServerMetricRow(server: server)
                        .tag(server)
                }
                .listStyle(.inset)
            }
            .frame(minWidth: 220, maxWidth: 280)

            // Performance Charts Panel
            VStack(spacing: 0) {
                // Toolbar
                HStack {
                    Picker("Metrics", selection: $selectedMetricType) {
                        ForEach(MetricType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .frame(width: 140)

                    Picker("Time Range", selection: $timeRange) {
                        ForEach(TimeRange.allCases) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .frame(width: 100)

                    Spacer()

                    Toggle(isOn: $isLiveUpdating) {
                        Label("Live", systemImage: isLiveUpdating ? "play.fill" : "pause.fill")
                    }
                    .toggleStyle(.button)

                    Picker("Refresh", selection: $refreshInterval) {
                        ForEach(RefreshInterval.allCases) { interval in
                            Text(interval.label).tag(interval)
                        }
                    }
                    .frame(width: 90)
                    .disabled(!isLiveUpdating)
                }
                .padding()

                Divider()

                if let server = selectedServer {
                    PerformanceChartsView(
                        server: server,
                        metricType: selectedMetricType,
                        timeRange: timeRange,
                        isLive: isLiveUpdating
                    )
                } else {
                    emptyState
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Select a Server")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text("Choose a server to view real-time performance metrics")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Server Metric Row

struct ServerMetricRow: View {
    let server: Server

    var latestMetric: ServerMetric? {
        server.metrics.sorted { $0.timestamp > $1.timestamp }.first
    }

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

            if let metric = latestMetric {
                HStack(spacing: 12) {
                    MiniMetricView(label: "CPU", value: metric.cpuUsage, color: .blue)
                    MiniMetricView(label: "MEM", value: metric.memoryUsage, color: .orange)
                    MiniMetricView(label: "DISK", value: metric.diskUsage, color: .purple)
                }
            } else {
                Text("No metrics available")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct MiniMetricView: View {
    let label: String
    let value: Double?
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 8, weight: .medium))
                .foregroundStyle(.secondary)
            Text(value != nil ? "\(Int(value!))%" : "--")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(color)
        }
    }
}

// MARK: - Performance Charts View

struct PerformanceChartsView: View {
    let server: Server
    let metricType: PerformanceMonitorView.MetricType
    let timeRange: PerformanceMonitorView.TimeRange
    let isLive: Bool

    var filteredMetrics: [ServerMetric] {
        let cutoff = Date().addingTimeInterval(-timeRange.seconds)
        return server.metrics
            .filter { $0.timestamp >= cutoff }
            .sorted { $0.timestamp < $1.timestamp }
    }

    var latestMetric: ServerMetric? {
        server.metrics.sorted { $0.timestamp > $1.timestamp }.first
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Current Values Summary
                CurrentMetricsSummaryView(metric: latestMetric, server: server)

                // Charts based on selection
                switch metricType {
                case .all:
                    CPUChartView(metrics: filteredMetrics)
                    MemoryChartView(metrics: filteredMetrics)
                    DiskChartView(metrics: filteredMetrics)
                    NetworkChartView(metrics: filteredMetrics)
                case .cpu:
                    CPUChartView(metrics: filteredMetrics, expanded: true)
                case .memory:
                    MemoryChartView(metrics: filteredMetrics, expanded: true)
                case .disk:
                    DiskChartView(metrics: filteredMetrics, expanded: true)
                case .network:
                    NetworkChartView(metrics: filteredMetrics, expanded: true)
                }
            }
            .padding()
        }
    }
}

// MARK: - Current Metrics Summary

struct CurrentMetricsSummaryView: View {
    let metric: ServerMetric?
    let server: Server

    var body: some View {
        HStack(spacing: 16) {
            MetricGaugeView(
                title: "CPU",
                value: metric?.cpuUsage ?? 0,
                icon: "cpu",
                color: cpuColor
            )

            MetricGaugeView(
                title: "Memory",
                value: metric?.memoryUsage ?? 0,
                icon: "memorychip",
                color: memoryColor
            )

            MetricGaugeView(
                title: "Disk",
                value: metric?.diskUsage ?? 0,
                icon: "internaldrive",
                color: diskColor
            )

            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "arrow.down.circle")
                        .foregroundStyle(.green)
                    Text("In: \(formatNetwork(metric?.networkIn))")
                        .font(.system(size: 12, design: .monospaced))
                }
                HStack {
                    Image(systemName: "arrow.up.circle")
                        .foregroundStyle(.blue)
                    Text("Out: \(formatNetwork(metric?.networkOut))")
                        .font(.system(size: 12, design: .monospaced))
                }
                Text("Connections: \(metric?.activeConnections ?? 0)")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
        }
    }

    private var cpuColor: Color {
        guard let cpu = metric?.cpuUsage else { return .gray }
        return cpu > 80 ? .red : (cpu > 60 ? .orange : .green)
    }

    private var memoryColor: Color {
        guard let mem = metric?.memoryUsage else { return .gray }
        return mem > 85 ? .red : (mem > 70 ? .orange : .green)
    }

    private var diskColor: Color {
        guard let disk = metric?.diskUsage else { return .gray }
        return disk > 90 ? .red : (disk > 75 ? .orange : .green)
    }

    private func formatNetwork(_ value: Double?) -> String {
        guard let value = value else { return "--" }
        if value >= 1000 {
            return String(format: "%.1f GB/s", value / 1000)
        }
        return String(format: "%.0f MB/s", value)
    }
}

struct MetricGaugeView: View {
    let title: String
    let value: Double
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 8)
                    .frame(width: 70, height: 70)

                Circle()
                    .trim(from: 0, to: value / 100)
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 70, height: 70)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundStyle(color)
                    Text("\(Int(value))%")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
            }

            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }
}

// MARK: - Individual Charts

struct CPUChartView: View {
    let metrics: [ServerMetric]
    var expanded: Bool = false

    var body: some View {
        ChartContainerView(title: "CPU Usage", icon: "cpu", color: .blue) {
            Chart {
                ForEach(metrics, id: \.timestamp) { metric in
                    if let cpu = metric.cpuUsage {
                        LineMark(
                            x: .value("Time", metric.timestamp),
                            y: .value("CPU %", cpu)
                        )
                        .foregroundStyle(.blue)
                        .interpolationMethod(.catmullRom)

                        AreaMark(
                            x: .value("Time", metric.timestamp),
                            y: .value("CPU %", cpu)
                        )
                        .foregroundStyle(.blue.opacity(0.1))
                        .interpolationMethod(.catmullRom)
                    }
                }

                // Threshold lines
                RuleMark(y: .value("Warning", 60))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    .foregroundStyle(.orange.opacity(0.5))

                RuleMark(y: .value("Critical", 80))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    .foregroundStyle(.red.opacity(0.5))
            }
            .chartYScale(domain: 0...100)
            .chartYAxis {
                AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                    AxisValueLabel {
                        if let v = value.as(Int.self) {
                            Text("\(v)%")
                                .font(.system(size: 10))
                        }
                    }
                    AxisGridLine()
                }
            }
            .frame(height: expanded ? 300 : 180)
        }
    }
}

struct MemoryChartView: View {
    let metrics: [ServerMetric]
    var expanded: Bool = false

    var body: some View {
        ChartContainerView(title: "Memory Usage", icon: "memorychip", color: .orange) {
            Chart {
                ForEach(metrics, id: \.timestamp) { metric in
                    if let memory = metric.memoryUsage {
                        LineMark(
                            x: .value("Time", metric.timestamp),
                            y: .value("Memory %", memory)
                        )
                        .foregroundStyle(.orange)
                        .interpolationMethod(.catmullRom)

                        AreaMark(
                            x: .value("Time", metric.timestamp),
                            y: .value("Memory %", memory)
                        )
                        .foregroundStyle(.orange.opacity(0.1))
                        .interpolationMethod(.catmullRom)
                    }
                }

                RuleMark(y: .value("Warning", 70))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    .foregroundStyle(.orange.opacity(0.5))

                RuleMark(y: .value("Critical", 85))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    .foregroundStyle(.red.opacity(0.5))
            }
            .chartYScale(domain: 0...100)
            .chartYAxis {
                AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                    AxisValueLabel {
                        if let v = value.as(Int.self) {
                            Text("\(v)%")
                                .font(.system(size: 10))
                        }
                    }
                    AxisGridLine()
                }
            }
            .frame(height: expanded ? 300 : 180)
        }
    }
}

struct DiskChartView: View {
    let metrics: [ServerMetric]
    var expanded: Bool = false

    var body: some View {
        ChartContainerView(title: "Disk Usage", icon: "internaldrive", color: .purple) {
            Chart {
                ForEach(metrics, id: \.timestamp) { metric in
                    if let disk = metric.diskUsage {
                        LineMark(
                            x: .value("Time", metric.timestamp),
                            y: .value("Disk %", disk)
                        )
                        .foregroundStyle(.purple)
                        .interpolationMethod(.catmullRom)

                        AreaMark(
                            x: .value("Time", metric.timestamp),
                            y: .value("Disk %", disk)
                        )
                        .foregroundStyle(.purple.opacity(0.1))
                        .interpolationMethod(.catmullRom)
                    }
                }

                RuleMark(y: .value("Warning", 75))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    .foregroundStyle(.orange.opacity(0.5))

                RuleMark(y: .value("Critical", 90))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    .foregroundStyle(.red.opacity(0.5))
            }
            .chartYScale(domain: 0...100)
            .chartYAxis {
                AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                    AxisValueLabel {
                        if let v = value.as(Int.self) {
                            Text("\(v)%")
                                .font(.system(size: 10))
                        }
                    }
                    AxisGridLine()
                }
            }
            .frame(height: expanded ? 300 : 180)
        }
    }
}

struct NetworkChartView: View {
    let metrics: [ServerMetric]
    var expanded: Bool = false

    var body: some View {
        ChartContainerView(title: "Network I/O", icon: "network", color: .cyan) {
            Chart {
                ForEach(metrics, id: \.timestamp) { metric in
                    if let netIn = metric.networkIn {
                        LineMark(
                            x: .value("Time", metric.timestamp),
                            y: .value("In", netIn)
                        )
                        .foregroundStyle(.green)
                        .interpolationMethod(.catmullRom)
                    }

                    if let netOut = metric.networkOut {
                        LineMark(
                            x: .value("Time", metric.timestamp),
                            y: .value("Out", netOut)
                        )
                        .foregroundStyle(.blue)
                        .interpolationMethod(.catmullRom)
                    }
                }
            }
            .chartForegroundStyleScale([
                "In": .green,
                "Out": .blue
            ])
            .chartLegend(position: .top)
            .frame(height: expanded ? 300 : 180)
        }
    }
}

struct ChartContainerView<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
            }

            content()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }
}

#Preview {
    PerformanceMonitorView()
}
