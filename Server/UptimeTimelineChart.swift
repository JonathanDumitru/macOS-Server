//
//  UptimeTimelineChart.swift
//  Server
//
//  Created by Claude on 1/27/26.
//

import SwiftUI
import Charts

struct UptimeTimelineChart: View {
    let dailyData: [UptimeDaily]
    var height: CGFloat = 200

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if dailyData.isEmpty {
                ContentUnavailableView(
                    "No Uptime Data",
                    systemImage: "chart.bar.xaxis",
                    description: Text("Uptime data will appear as the server is monitored")
                )
                .frame(height: height)
            } else {
                Chart(dailyData, id: \.id) { daily in
                    BarMark(
                        x: .value("Date", daily.date, unit: .day),
                        y: .value("Uptime", daily.uptimePercentage)
                    )
                    .foregroundStyle(barColor(for: daily.uptimePercentage))
                    .cornerRadius(3)
                }
                .chartYScale(domain: 0...100)
                .chartYAxis {
                    AxisMarks(values: [0, 50, 90, 99, 100]) { value in
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
                    AxisMarks(values: .stride(by: .day, count: xAxisStride)) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(date, format: .dateTime.month(.abbreviated).day())
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .frame(height: height)
            }
        }
    }

    private var xAxisStride: Int {
        switch dailyData.count {
        case 0...7: return 1
        case 8...30: return 7
        default: return 14
        }
    }

    private func barColor(for percentage: Double) -> Color {
        UptimeStatus.from(percentage: percentage).color
    }
}

// MARK: - Response Time Chart

struct ResponseTimeChart: View {
    let dailyData: [UptimeDaily]
    var height: CGFloat = 150

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if dailyData.isEmpty || dailyData.allSatisfy({ $0.averageResponseTime == 0 }) {
                ContentUnavailableView(
                    "No Response Data",
                    systemImage: "clock",
                    description: Text("Response time data will appear as the server is monitored")
                )
                .frame(height: height)
            } else {
                Chart(dailyData.filter { $0.averageResponseTime > 0 }, id: \.id) { daily in
                    LineMark(
                        x: .value("Date", daily.date, unit: .day),
                        y: .value("Response Time", daily.averageResponseTime)
                    )
                    .foregroundStyle(.blue)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Date", daily.date, unit: .day),
                        y: .value("Response Time", daily.averageResponseTime)
                    )
                    .foregroundStyle(.blue.opacity(0.1))
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Date", daily.date, unit: .day),
                        y: .value("Response Time", daily.averageResponseTime)
                    )
                    .foregroundStyle(.blue)
                    .symbolSize(30)
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let intValue = value.as(Int.self) {
                                Text("\(intValue)ms")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                            .foregroundStyle(Color.primary.opacity(0.1))
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: xAxisStride)) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(date, format: .dateTime.month(.abbreviated).day())
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .frame(height: height)
            }
        }
    }

    private var xAxisStride: Int {
        switch dailyData.count {
        case 0...7: return 1
        case 8...30: return 7
        default: return 14
        }
    }
}

// MARK: - Downtime Incidents List

struct DowntimeIncidentsList: View {
    let incidents: [DowntimeIncident]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if incidents.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("No downtime incidents in this period")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            } else {
                ForEach(incidents) { incident in
                    DowntimeIncidentRow(incident: incident)
                }
            }
        }
    }
}

struct DowntimeIncidentRow: View {
    let incident: DowntimeIncident

    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(incident.isOngoing ? Color.red : Color.orange)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(incident.startTime, format: .dateTime.month().day().hour().minute())
                        .font(.system(size: 12, weight: .medium))

                    if let endTime = incident.endTime {
                        Text("-")
                            .foregroundStyle(.tertiary)
                        Text(endTime, format: .dateTime.hour().minute())
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    } else {
                        Text("- Ongoing")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.red)
                    }
                }

                if let error = incident.errorMessage {
                    Text(error)
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Duration
            Text(incident.formattedDuration)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(incident.isOngoing ? .red : .secondary)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }
}

// MARK: - Uptime Summary Card

struct UptimeSummaryCard: View {
    let uptime: Double
    let period: UptimePeriod
    let averageResponseTime: Double?
    let incidentCount: Int

    var body: some View {
        HStack(spacing: 20) {
            // Uptime gauge
            UptimePercentageView(
                percentage: uptime,
                period: period,
                size: .regular,
                showStatus: false
            )

            // Stats
            VStack(alignment: .leading, spacing: 12) {
                StatRow(
                    label: "Status",
                    value: UptimeStatus.from(percentage: uptime).rawValue,
                    color: UptimeStatus.from(percentage: uptime).color
                )

                StatRow(
                    label: "Avg Response",
                    value: averageResponseTime.map { String(format: "%.0fms", $0) } ?? "N/A",
                    color: .blue
                )

                StatRow(
                    label: "Incidents",
                    value: "\(incidentCount)",
                    color: incidentCount > 0 ? .orange : .green
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        )
    }
}

private struct StatRow: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(color)
        }
    }
}

// MARK: - Preview

#Preview("Uptime Chart") {
    let sampleData = (0..<30).map { day -> UptimeDaily in
        let daily = UptimeDaily(
            serverId: UUID(),
            date: Calendar.current.date(byAdding: .day, value: -day, to: Date())!
        )
        daily.totalChecks = 288
        daily.successfulChecks = Int.random(in: 280...288)
        daily.failedChecks = 288 - daily.successfulChecks
        daily.averageResponseTime = Double.random(in: 50...150)
        return daily
    }

    return VStack(spacing: 20) {
        Text("Uptime History")
            .font(.headline)

        UptimeTimelineChart(dailyData: sampleData)
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(12)

        Text("Response Time")
            .font(.headline)

        ResponseTimeChart(dailyData: sampleData)
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(12)
    }
    .padding()
    .frame(width: 600)
}

#Preview("Summary Card") {
    UptimeSummaryCard(
        uptime: 99.87,
        period: .month30d,
        averageResponseTime: 87.5,
        incidentCount: 2
    )
    .padding()
    .frame(width: 400)
}
