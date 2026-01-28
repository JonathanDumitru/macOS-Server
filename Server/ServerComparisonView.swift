//
//  ServerComparisonView.swift
//  Server
//
//  Created by Claude on 1/28/26.
//

import SwiftUI
import SwiftData
import Charts

struct ServerComparisonView: View {
    @Query private var servers: [Server]
    @State private var selectedServers: Set<UUID> = []
    @State private var comparisonMetric: ComparisonMetric = .responseTime
    @State private var timeRange: TimeRange = .hour1

    enum ComparisonMetric: String, CaseIterable, Identifiable {
        case responseTime = "Response Time"
        case cpuUsage = "CPU Usage"
        case memoryUsage = "Memory Usage"
        case diskUsage = "Disk Usage"
        case uptime = "Uptime"

        var id: String { rawValue }

        var unit: String {
            switch self {
            case .responseTime: return "ms"
            case .cpuUsage, .memoryUsage, .diskUsage: return "%"
            case .uptime: return ""
            }
        }

        var icon: String {
            switch self {
            case .responseTime: return "gauge.with.needle"
            case .cpuUsage: return "cpu"
            case .memoryUsage: return "memorychip"
            case .diskUsage: return "internaldrive"
            case .uptime: return "clock.arrow.circlepath"
            }
        }
    }

    enum TimeRange: String, CaseIterable, Identifiable {
        case hour1 = "1 Hour"
        case hours6 = "6 Hours"
        case hours24 = "24 Hours"
        case days7 = "7 Days"

        var id: String { rawValue }

        var interval: TimeInterval {
            switch self {
            case .hour1: return 3600
            case .hours6: return 3600 * 6
            case .hours24: return 3600 * 24
            case .days7: return 3600 * 24 * 7
            }
        }
    }

    var selectedServersList: [Server] {
        servers.filter { selectedServers.contains($0.id) }
    }

    var body: some View {
        HSplitView {
            // Server Selection Panel
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Select Servers")
                        .font(.headline)
                    Spacer()
                    Text("\(selectedServers.count) selected")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()

                Divider()

                // Server List
                List(servers, selection: $selectedServers) { server in
                    HStack {
                        Circle()
                            .fill(Color(server.status.color))
                            .frame(width: 8, height: 8)
                        Text(server.name)
                            .font(.system(size: 13))
                        Spacer()
                        if selectedServers.contains(server.id) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if selectedServers.contains(server.id) {
                            selectedServers.remove(server.id)
                        } else {
                            selectedServers.insert(server.id)
                        }
                    }
                }
                .listStyle(.inset)

                Divider()

                // Quick actions
                HStack {
                    Button("Select All") {
                        selectedServers = Set(servers.map { $0.id })
                    }
                    .buttonStyle(.link)

                    Button("Clear") {
                        selectedServers.removeAll()
                    }
                    .buttonStyle(.link)
                }
                .padding()
            }
            .frame(minWidth: 200, idealWidth: 250, maxWidth: 300)

            // Comparison Panel
            VStack(spacing: 0) {
                // Controls
                HStack {
                    Picker("Metric", selection: $comparisonMetric) {
                        ForEach(ComparisonMetric.allCases) { metric in
                            Label(metric.rawValue, systemImage: metric.icon).tag(metric)
                        }
                    }
                    .frame(width: 180)

                    Picker("Time Range", selection: $timeRange) {
                        ForEach(TimeRange.allCases) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .frame(width: 120)

                    Spacer()
                }
                .padding()

                Divider()

                if selectedServers.count < 2 {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Comparison Chart
                            ComparisonChartView(
                                servers: selectedServersList,
                                metric: comparisonMetric,
                                timeRange: timeRange
                            )
                            .frame(height: 300)

                            // Summary Table
                            ComparisonTableView(
                                servers: selectedServersList,
                                metric: comparisonMetric
                            )

                            // Ranking
                            ComparisonRankingView(
                                servers: selectedServersList,
                                metric: comparisonMetric
                            )
                        }
                        .padding()
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Select at Least Two Servers")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text("Choose servers from the list to compare their metrics side by side")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Comparison Chart

struct ComparisonChartView: View {
    let servers: [Server]
    let metric: ServerComparisonView.ComparisonMetric
    let timeRange: ServerComparisonView.TimeRange

    var chartData: [(server: String, timestamp: Date, value: Double)] {
        let cutoff = Date().addingTimeInterval(-timeRange.interval)

        return servers.flatMap { server in
            let metrics = server.metrics
                .filter { $0.timestamp >= cutoff }
                .sorted { $0.timestamp < $1.timestamp }

            return metrics.compactMap { m -> (String, Date, Double)? in
                let value: Double?
                switch metric {
                case .responseTime:
                    value = server.responseTime
                case .cpuUsage:
                    value = m.cpuUsage
                case .memoryUsage:
                    value = m.memoryUsage
                case .diskUsage:
                    value = m.diskUsage
                case .uptime:
                    value = server.uptime.map { $0 / 86400 } // Convert to days
                }
                guard let v = value else { return nil }
                return (server.name, m.timestamp, v)
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Trend Comparison")
                .font(.headline)

            if chartData.isEmpty {
                Text("No data available for the selected time range")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Chart {
                    ForEach(Array(chartData.enumerated()), id: \.offset) { _, data in
                        LineMark(
                            x: .value("Time", data.timestamp),
                            y: .value(metric.rawValue, data.value)
                        )
                        .foregroundStyle(by: .value("Server", data.server))
                        .interpolationMethod(.catmullRom)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text("\(Int(v))\(metric.unit)")
                                    .font(.system(size: 10))
                            }
                        }
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }
}

// MARK: - Comparison Table

struct ComparisonTableView: View {
    let servers: [Server]
    let metric: ServerComparisonView.ComparisonMetric

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Current Values")
                .font(.headline)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: min(servers.count, 4)), spacing: 12) {
                ForEach(servers) { server in
                    VStack(spacing: 8) {
                        HStack {
                            Circle()
                                .fill(Color(server.status.color))
                                .frame(width: 8, height: 8)
                            Text(server.name)
                                .font(.system(size: 12, weight: .medium))
                                .lineLimit(1)
                        }

                        Text(currentValue(for: server))
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(valueColor(for: server))

                        Text(metric.rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(nsColor: .windowBackgroundColor))
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }

    private func currentValue(for server: Server) -> String {
        switch metric {
        case .responseTime:
            if let rt = server.responseTime {
                return "\(Int(rt))\(metric.unit)"
            }
        case .cpuUsage:
            if let cpu = server.metrics.last?.cpuUsage {
                return "\(Int(cpu))\(metric.unit)"
            }
        case .memoryUsage:
            if let mem = server.metrics.last?.memoryUsage {
                return "\(Int(mem))\(metric.unit)"
            }
        case .diskUsage:
            if let disk = server.metrics.last?.diskUsage {
                return "\(Int(disk))\(metric.unit)"
            }
        case .uptime:
            if let uptime = server.uptime {
                let days = Int(uptime / 86400)
                return "\(days)d"
            }
        }
        return "N/A"
    }

    private func valueColor(for server: Server) -> Color {
        switch metric {
        case .responseTime:
            guard let rt = server.responseTime else { return .secondary }
            return rt < 200 ? .green : (rt < 500 ? .orange : .red)
        case .cpuUsage:
            guard let cpu = server.metrics.last?.cpuUsage else { return .secondary }
            return cpu < 60 ? .green : (cpu < 80 ? .orange : .red)
        case .memoryUsage:
            guard let mem = server.metrics.last?.memoryUsage else { return .secondary }
            return mem < 70 ? .green : (mem < 85 ? .orange : .red)
        case .diskUsage:
            guard let disk = server.metrics.last?.diskUsage else { return .secondary }
            return disk < 75 ? .green : (disk < 90 ? .orange : .red)
        case .uptime:
            return .green
        }
    }
}

// MARK: - Comparison Ranking

struct ComparisonRankingView: View {
    let servers: [Server]
    let metric: ServerComparisonView.ComparisonMetric

    var rankedServers: [(server: Server, value: Double, rank: Int)] {
        let serversWithValues = servers.compactMap { server -> (Server, Double)? in
            let value: Double?
            switch metric {
            case .responseTime:
                value = server.responseTime
            case .cpuUsage:
                value = server.metrics.last?.cpuUsage
            case .memoryUsage:
                value = server.metrics.last?.memoryUsage
            case .diskUsage:
                value = server.metrics.last?.diskUsage
            case .uptime:
                value = server.uptime
            }
            guard let v = value else { return nil }
            return (server, v)
        }

        // Sort based on metric (lower is better for response time, CPU, memory, disk; higher is better for uptime)
        let sorted: [(Server, Double)]
        switch metric {
        case .responseTime, .cpuUsage, .memoryUsage, .diskUsage:
            sorted = serversWithValues.sorted { $0.1 < $1.1 }
        case .uptime:
            sorted = serversWithValues.sorted { $0.1 > $1.1 }
        }

        return sorted.enumerated().map { (index, item) in
            (item.0, item.1, index + 1)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ranking")
                .font(.headline)

            VStack(spacing: 4) {
                ForEach(rankedServers, id: \.server.id) { item in
                    HStack {
                        // Rank badge
                        ZStack {
                            Circle()
                                .fill(rankColor(item.rank))
                                .frame(width: 28, height: 28)
                            Text("\(item.rank)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                        }

                        // Server info
                        Circle()
                            .fill(Color(item.server.status.color))
                            .frame(width: 8, height: 8)

                        Text(item.server.name)
                            .font(.system(size: 13))

                        Spacer()

                        // Value
                        Text(formatValue(item.value))
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundStyle(.secondary)

                        // Trend indicator
                        Image(systemName: trendIcon(item.rank))
                            .foregroundStyle(rankColor(item.rank))
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(item.rank == 1 ? Color.green.opacity(0.1) : Color.clear)
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }

    private func rankColor(_ rank: Int) -> Color {
        switch rank {
        case 1: return .green
        case 2: return .blue
        case 3: return .orange
        default: return .gray
        }
    }

    private func trendIcon(_ rank: Int) -> String {
        switch rank {
        case 1: return "arrow.up.circle.fill"
        case 2, 3: return "minus.circle.fill"
        default: return "arrow.down.circle.fill"
        }
    }

    private func formatValue(_ value: Double) -> String {
        switch metric {
        case .responseTime:
            return "\(Int(value))ms"
        case .cpuUsage, .memoryUsage, .diskUsage:
            return "\(Int(value))%"
        case .uptime:
            let days = Int(value / 86400)
            let hours = Int((value.truncatingRemainder(dividingBy: 86400)) / 3600)
            return "\(days)d \(hours)h"
        }
    }
}

#Preview {
    ServerComparisonView()
}
