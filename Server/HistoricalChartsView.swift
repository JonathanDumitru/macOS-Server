//
//  HistoricalChartsView.swift
//  Server
//
//  Enhanced metrics visualization with time range selection
//

import SwiftUI
import SwiftData
import Charts

enum TimeRange: String, CaseIterable {
    case hour1 = "1H"
    case hours6 = "6H"
    case hours24 = "24H"
    case days7 = "7D"
    case days30 = "30D"

    var displayName: String {
        switch self {
        case .hour1: return "Last Hour"
        case .hours6: return "Last 6 Hours"
        case .hours24: return "Last 24 Hours"
        case .days7: return "Last 7 Days"
        case .days30: return "Last 30 Days"
        }
    }

    var seconds: TimeInterval {
        switch self {
        case .hour1: return 3600
        case .hours6: return 3600 * 6
        case .hours24: return 3600 * 24
        case .days7: return 3600 * 24 * 7
        case .days30: return 3600 * 24 * 30
        }
    }

    var dateFormat: Date.FormatStyle {
        switch self {
        case .hour1, .hours6:
            return .dateTime.hour().minute()
        case .hours24:
            return .dateTime.hour()
        case .days7, .days30:
            return .dateTime.month().day()
        }
    }
}

struct HistoricalChartsView: View {
    let server: Server
    @State private var selectedTimeRange: TimeRange = .hours24
    @State private var selectedMetric: HistoricalMetricType = .responseTime

    enum HistoricalMetricType: String, CaseIterable {
        case responseTime = "Response Time"
        case cpu = "CPU"
        case memory = "Memory"
        case disk = "Disk"
        case uptime = "Uptime"

        var icon: String {
            switch self {
            case .responseTime: return "timer"
            case .cpu: return "cpu"
            case .memory: return "memorychip"
            case .disk: return "internaldrive"
            case .uptime: return "clock"
            }
        }

        var color: Color {
            switch self {
            case .responseTime: return .blue
            case .cpu: return .orange
            case .memory: return .purple
            case .disk: return .green
            case .uptime: return .cyan
            }
        }

        var unit: String {
            switch self {
            case .responseTime: return "ms"
            case .cpu, .memory, .disk, .uptime: return "%"
            }
        }
    }

    var filteredMetrics: [ServerMetric] {
        let cutoff = Date().addingTimeInterval(-selectedTimeRange.seconds)
        return server.metrics
            .filter { $0.timestamp >= cutoff }
            .sorted { $0.timestamp < $1.timestamp }
    }

    var filteredUptimeRecords: [UptimeRecord] {
        let cutoff = Date().addingTimeInterval(-selectedTimeRange.seconds)
        return server.uptimeRecords
            .filter { $0.timestamp >= cutoff }
            .sorted { $0.timestamp < $1.timestamp }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with time range and metric selector
            HStack {
                // Time Range Picker
                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 300)

                Spacer()

                // Metric Type Picker
                Picker("Metric", selection: $selectedMetric) {
                    ForEach(HistoricalMetricType.allCases, id: \.self) { metric in
                        Label(metric.rawValue, systemImage: metric.icon).tag(metric)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 160)
            }
            .padding()

            Divider()

            // Chart
            if filteredMetrics.isEmpty && selectedMetric != .uptime {
                ContentUnavailableView(
                    "No Historical Data",
                    systemImage: "chart.xyaxis.line",
                    description: Text("Metrics for \(selectedTimeRange.displayName.lowercased()) will appear here once collected")
                )
            } else if selectedMetric == .uptime && filteredUptimeRecords.isEmpty {
                ContentUnavailableView(
                    "No Uptime Data",
                    systemImage: "clock",
                    description: Text("Uptime records will appear here once monitoring begins")
                )
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    // Stats Summary
                    StatsSummaryView(
                        metrics: filteredMetrics,
                        uptimeRecords: filteredUptimeRecords,
                        metricType: selectedMetric,
                        timeRange: selectedTimeRange
                    )

                    // Main Chart
                    chartContent
                        .frame(height: 300)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(nsColor: .controlBackgroundColor))
                        )
                        .padding(.horizontal)

                    // Additional insights
                    InsightsView(
                        metrics: filteredMetrics,
                        metricType: selectedMetric,
                        timeRange: selectedTimeRange
                    )
                }
                .padding(.vertical)
            }

            Spacer()
        }
    }

    @ViewBuilder
    private var chartContent: some View {
        switch selectedMetric {
        case .responseTime:
            ResponseTimeChart(metrics: filteredMetrics, timeRange: selectedTimeRange)
        case .cpu:
            CPUChart(metrics: filteredMetrics, timeRange: selectedTimeRange)
        case .memory:
            MemoryChart(metrics: filteredMetrics, timeRange: selectedTimeRange)
        case .disk:
            DiskChart(metrics: filteredMetrics, timeRange: selectedTimeRange)
        case .uptime:
            UptimeChart(records: filteredUptimeRecords, timeRange: selectedTimeRange)
        }
    }
}

// MARK: - Stats Summary View

struct StatsSummaryView: View {
    let metrics: [ServerMetric]
    let uptimeRecords: [UptimeRecord]
    let metricType: HistoricalChartsView.HistoricalMetricType
    let timeRange: TimeRange

    var body: some View {
        HStack(spacing: 16) {
            StatCard(
                title: "Average",
                value: averageValue,
                unit: metricType.unit,
                color: metricType.color
            )

            StatCard(
                title: "Min",
                value: minValue,
                unit: metricType.unit,
                color: .green
            )

            StatCard(
                title: "Max",
                value: maxValue,
                unit: metricType.unit,
                color: .red
            )

            StatCard(
                title: "Data Points",
                value: String(dataPointCount),
                unit: "",
                color: .secondary
            )
        }
        .padding(.horizontal)
    }

    private var values: [Double] {
        switch metricType {
        case .responseTime:
            return metrics.compactMap { $0.responseTime }
        case .cpu:
            return metrics.compactMap { $0.cpuUsage }
        case .memory:
            return metrics.compactMap { $0.memoryUsage }
        case .disk:
            return metrics.compactMap { $0.diskUsage }
        case .uptime:
            let online = uptimeRecords.filter { $0.status == .online }.count
            let total = uptimeRecords.count
            return total > 0 ? [Double(online) / Double(total) * 100] : []
        }
    }

    private var averageValue: String {
        guard !values.isEmpty else { return "N/A" }
        let avg = values.reduce(0, +) / Double(values.count)
        return String(format: "%.1f", avg)
    }

    private var minValue: String {
        guard let min = values.min() else { return "N/A" }
        return String(format: "%.1f", min)
    }

    private var maxValue: String {
        guard let max = values.max() else { return "N/A" }
        return String(format: "%.1f", max)
    }

    private var dataPointCount: Int {
        metricType == .uptime ? uptimeRecords.count : metrics.count
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(color)

                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }
}

// MARK: - Individual Charts

struct ResponseTimeChart: View {
    let metrics: [ServerMetric]
    let timeRange: TimeRange

    var data: [(date: Date, value: Double)] {
        metrics.compactMap { metric in
            guard let rt = metric.responseTime else { return nil }
            return (metric.timestamp, rt)
        }
    }

    var body: some View {
        Chart(data, id: \.date) { item in
            LineMark(
                x: .value("Time", item.date),
                y: .value("Response Time", item.value)
            )
            .foregroundStyle(.blue.gradient)
            .interpolationMethod(.catmullRom)

            AreaMark(
                x: .value("Time", item.date),
                y: .value("Response Time", item.value)
            )
            .foregroundStyle(.blue.opacity(0.1))
            .interpolationMethod(.catmullRom)
        }
        .chartYAxisLabel("Response Time (ms)")
        .chartXAxis {
            AxisMarks { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(date, format: timeRange.dateFormat)
                            .font(.caption2)
                    }
                }
                AxisGridLine()
            }
        }
    }
}

struct CPUChart: View {
    let metrics: [ServerMetric]
    let timeRange: TimeRange

    var data: [(date: Date, value: Double)] {
        metrics.compactMap { metric in
            guard let cpu = metric.cpuUsage else { return nil }
            return (metric.timestamp, cpu)
        }
    }

    var body: some View {
        Chart(data, id: \.date) { item in
            LineMark(
                x: .value("Time", item.date),
                y: .value("CPU", item.value)
            )
            .foregroundStyle(.orange.gradient)
            .interpolationMethod(.catmullRom)

            AreaMark(
                x: .value("Time", item.date),
                y: .value("CPU", item.value)
            )
            .foregroundStyle(.orange.opacity(0.1))
            .interpolationMethod(.catmullRom)
        }
        .chartYScale(domain: 0...100)
        .chartYAxisLabel("CPU Usage (%)")
        .chartXAxis {
            AxisMarks { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(date, format: timeRange.dateFormat)
                            .font(.caption2)
                    }
                }
                AxisGridLine()
            }
        }
    }
}

struct MemoryChart: View {
    let metrics: [ServerMetric]
    let timeRange: TimeRange

    var data: [(date: Date, value: Double)] {
        metrics.compactMap { metric in
            guard let memory = metric.memoryUsage else { return nil }
            return (metric.timestamp, memory)
        }
    }

    var body: some View {
        Chart(data, id: \.date) { item in
            LineMark(
                x: .value("Time", item.date),
                y: .value("Memory", item.value)
            )
            .foregroundStyle(.purple.gradient)
            .interpolationMethod(.catmullRom)

            AreaMark(
                x: .value("Time", item.date),
                y: .value("Memory", item.value)
            )
            .foregroundStyle(.purple.opacity(0.1))
            .interpolationMethod(.catmullRom)
        }
        .chartYScale(domain: 0...100)
        .chartYAxisLabel("Memory Usage (%)")
        .chartXAxis {
            AxisMarks { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(date, format: timeRange.dateFormat)
                            .font(.caption2)
                    }
                }
                AxisGridLine()
            }
        }
    }
}

struct DiskChart: View {
    let metrics: [ServerMetric]
    let timeRange: TimeRange

    var data: [(date: Date, value: Double)] {
        metrics.compactMap { metric in
            guard let disk = metric.diskUsage else { return nil }
            return (metric.timestamp, disk)
        }
    }

    var body: some View {
        Chart(data, id: \.date) { item in
            LineMark(
                x: .value("Time", item.date),
                y: .value("Disk", item.value)
            )
            .foregroundStyle(.green.gradient)
            .interpolationMethod(.catmullRom)

            AreaMark(
                x: .value("Time", item.date),
                y: .value("Disk", item.value)
            )
            .foregroundStyle(.green.opacity(0.1))
            .interpolationMethod(.catmullRom)
        }
        .chartYScale(domain: 0...100)
        .chartYAxisLabel("Disk Usage (%)")
        .chartXAxis {
            AxisMarks { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(date, format: timeRange.dateFormat)
                            .font(.caption2)
                    }
                }
                AxisGridLine()
            }
        }
    }
}

struct UptimeChart: View {
    let records: [UptimeRecord]
    let timeRange: TimeRange

    var data: [(date: Date, status: Int)] {
        records.map { record in
            let statusValue: Int
            switch record.status {
            case .online: statusValue = 2
            case .warning: statusValue = 1
            case .offline, .unknown: statusValue = 0
            }
            return (record.timestamp, statusValue)
        }
    }

    var body: some View {
        Chart(data, id: \.date) { item in
            PointMark(
                x: .value("Time", item.date),
                y: .value("Status", item.status)
            )
            .foregroundStyle(colorForStatus(item.status))
            .symbolSize(30)

            LineMark(
                x: .value("Time", item.date),
                y: .value("Status", item.status)
            )
            .foregroundStyle(.gray.opacity(0.3))
            .interpolationMethod(.stepEnd)
        }
        .chartYScale(domain: -0.5...2.5)
        .chartYAxis {
            AxisMarks(values: [0, 1, 2]) { value in
                AxisValueLabel {
                    if let intValue = value.as(Int.self) {
                        Text(statusLabel(intValue))
                            .font(.caption)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(date, format: timeRange.dateFormat)
                            .font(.caption2)
                    }
                }
                AxisGridLine()
            }
        }
    }

    private func colorForStatus(_ status: Int) -> Color {
        switch status {
        case 2: return .green
        case 1: return .orange
        default: return .red
        }
    }

    private func statusLabel(_ status: Int) -> String {
        switch status {
        case 2: return "Online"
        case 1: return "Warning"
        default: return "Offline"
        }
    }
}

// MARK: - Insights View

struct InsightsView: View {
    let metrics: [ServerMetric]
    let metricType: HistoricalChartsView.HistoricalMetricType
    let timeRange: TimeRange

    var insights: [String] {
        var result: [String] = []

        switch metricType {
        case .responseTime:
            if let avg = averageResponseTime {
                if avg > 1000 {
                    result.append("Average response time is high (\(Int(avg))ms). Consider investigating server performance.")
                } else if avg < 100 {
                    result.append("Excellent response times averaging \(Int(avg))ms.")
                }
            }
            if let trend = calculateTrend(values: metrics.compactMap { $0.responseTime }) {
                if trend > 10 {
                    result.append("Response times are trending upward. Monitor for potential issues.")
                } else if trend < -10 {
                    result.append("Response times are improving over the selected period.")
                }
            }

        case .cpu:
            if let avg = averageCPU {
                if avg > 80 {
                    result.append("High CPU usage detected (avg \(Int(avg))%). Consider scaling or optimization.")
                } else if avg < 20 {
                    result.append("Low CPU utilization suggests resources may be over-provisioned.")
                }
            }

        case .memory:
            if let avg = averageMemory {
                if avg > 85 {
                    result.append("Memory usage is high (avg \(Int(avg))%). Consider adding RAM or optimizing applications.")
                }
            }

        case .disk:
            if let latest = metrics.last?.diskUsage {
                if latest > 90 {
                    result.append("Disk usage critical (\(Int(latest))%). Immediate cleanup recommended.")
                } else if latest > 75 {
                    result.append("Disk usage elevated (\(Int(latest))%). Plan for cleanup or expansion.")
                }
            }

        case .uptime:
            break
        }

        if result.isEmpty {
            result.append("No significant insights for the selected time period.")
        }

        return result
    }

    private var averageResponseTime: Double? {
        let values = metrics.compactMap { $0.responseTime }
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    private var averageCPU: Double? {
        let values = metrics.compactMap { $0.cpuUsage }
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    private var averageMemory: Double? {
        let values = metrics.compactMap { $0.memoryUsage }
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    private func calculateTrend(values: [Double]) -> Double? {
        guard values.count >= 10 else { return nil }
        let firstHalf = Array(values.prefix(values.count / 2))
        let secondHalf = Array(values.suffix(values.count / 2))

        let firstAvg = firstHalf.reduce(0, +) / Double(firstHalf.count)
        let secondAvg = secondHalf.reduce(0, +) / Double(secondHalf.count)

        return ((secondAvg - firstAvg) / firstAvg) * 100
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Insights")
                .font(.headline)
                .padding(.horizontal)

            ForEach(insights, id: \.self) { insight in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(.yellow)
                        .font(.caption)

                    Text(insight)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
    }
}
