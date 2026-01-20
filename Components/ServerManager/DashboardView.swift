//
//  DashboardView.swift
//  macOS-Server-2026
//
//  Created on 2026-01-13.
//

import SwiftUI
import Charts

struct DashboardView: View {
    @ObservedObject var viewModel: ServerManagerViewModel
    
    let serverStats = [
        StatItem(label: "Uptime", value: "15 days, 7 hrs", status: .normal, icon: "clock.fill", color: .blue),
        StatItem(label: "Active Users", value: "247", status: .normal, icon: "person.3.fill", color: .green),
        StatItem(label: "Running Services", value: "87 / 124", status: .normal, icon: "gearshape.fill", color: .purple),
        StatItem(label: "Security Alerts", value: "0", status: .good, icon: "shield.fill", color: .green),
        StatItem(label: "Failed Logins", value: "3", status: .warning, icon: "exclamationmark.triangle.fill", color: .yellow),
        StatItem(label: "Disk Space", value: "42% Used", status: .normal, icon: "externaldrive.fill", color: .orange),
        StatItem(label: "Network Traffic", value: "2.4 Gbps", status: .normal, icon: "chart.line.uptrend.xyaxis", color: .blue),
        StatItem(label: "Pending Updates", value: "12", status: .warning, icon: "arrow.down.circle.fill", color: .orange)
    ]
    
    let recentEvents = [
        EventItem(level: .information, source: "Active Directory Domain Services", id: "4662", message: "An operation was performed on an object", time: "11:45 AM", date: "Today"),
        EventItem(level: .information, source: "Service Control Manager", id: "7036", message: "The DNS Server service entered the running state", time: "11:30 AM", date: "Today"),
        EventItem(level: .warning, source: "Microsoft-Windows-Security-SPP", id: "1058", message: "Windows could not verify certificate", time: "10:15 AM", date: "Today"),
        EventItem(level: .error, source: "Disk", id: "51", message: "An error was detected on device", time: "9:45 AM", date: "Today"),
        EventItem(level: .information, source: "Microsoft-Windows-Security-Auditing", id: "4624", message: "An account was successfully logged on", time: "9:30 AM", date: "Today")
    ]
    
    var cpuData: [(time: Int, value: Int)] {
        (0..<30).map { (time: $0, value: Int.random(in: 15...55)) }
    }
    
    var memoryData: [(time: Int, value: Int)] {
        (0..<30).map { (time: $0, value: Int.random(in: 45...65)) }
    }
    
    var networkData: [(time: String, download: Int, upload: Int)] {
        (0..<20).map { (time: "\($0)s", download: Int.random(in: 50...150), upload: Int.random(in: 20...70)) }
    }
    
    let roleDistribution = [
        (name: "Active Directory", value: 35, color: Color.blue500),
        (name: "DNS", value: 20, color: Color.green400),
        (name: "File Services", value: 25, color: Color.orange500),
        (name: "Web Services", value: 15, color: Color.purple500),
        (name: "Other", value: 5, color: Color.red500)
    ]
    
    struct StatItem {
        let label: String
        let value: String
        let status: Status
        let icon: String
        let color: Color
        
        enum Status {
            case normal, good, warning
        }
    }
    
    struct EventItem {
        let level: EventLevel
        let source: String
        let id: String
        let message: String
        let time: String
        let date: String
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Server Dashboard")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.zinc900)
                Text("Monitor server health, performance, and status")
                    .font(.system(size: 13))
                    .foregroundColor(.zinc600)
            }
            .padding(24)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Stats Grid
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 4), spacing: 16) {
                        ForEach(Array(serverStats.enumerated()), id: \.offset) { _, stat in
                            StatCard(stat: stat)
                        }
                    }
                    
                    // Charts Row
                    HStack(spacing: 16) {
                        // CPU Chart
                        ChartCard(title: "CPU Usage") {
                            Chart {
                                ForEach(cpuData, id: \.time) { data in
                                    AreaMark(
                                        x: .value("Time", data.time),
                                        y: .value("Usage", data.value)
                                    )
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color.blue500.opacity(0.3), Color.blue500.opacity(0)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    LineMark(
                                        x: .value("Time", data.time),
                                        y: .value("Usage", data.value)
                                    )
                                    .foregroundStyle(Color.blue500)
                                }
                            }
                            .chartXAxis {
                                AxisMarks(values: .automatic(desiredCount: 5))
                            }
                            .chartYAxis {
                                AxisMarks(values: .automatic(desiredCount: 5))
                            }
                            .frame(height: 200)
                        }
                        
                        // Memory Chart
                        ChartCard(title: "Memory Usage") {
                            Chart {
                                ForEach(memoryData, id: \.time) { data in
                                    AreaMark(
                                        x: .value("Time", data.time),
                                        y: .value("Usage", data.value)
                                    )
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color.green400.opacity(0.3), Color.green400.opacity(0)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    LineMark(
                                        x: .value("Time", data.time),
                                        y: .value("Usage", data.value)
                                    )
                                    .foregroundStyle(Color.green400)
                                }
                            }
                            .chartXAxis {
                                AxisMarks(values: .automatic(desiredCount: 5))
                            }
                            .chartYAxis {
                                AxisMarks(values: .automatic(desiredCount: 5))
                            }
                            .frame(height: 200)
                        }
                    }
                    
                    // Bottom Row
                    HStack(spacing: 16) {
                        // Network Traffic
                        ChartCard(title: "Network Traffic") {
                            Chart {
                                ForEach(networkData, id: \.time) { data in
                                    BarMark(
                                        x: .value("Time", data.time),
                                        y: .value("Download", data.download)
                                    )
                                    .foregroundStyle(Color.blue500)
                                    
                                    BarMark(
                                        x: .value("Time", data.time),
                                        y: .value("Upload", data.upload)
                                    )
                                    .foregroundStyle(Color.green400)
                                }
                            }
                            .chartXAxis {
                                AxisMarks(values: .automatic(desiredCount: 5))
                            }
                            .chartYAxis {
                                AxisMarks(values: .automatic(desiredCount: 5))
                            }
                            .frame(height: 180)
                        }
                        
                        // Role Distribution
                        ChartCard(title: "Role Distribution") {
                            Chart {
                                ForEach(roleDistribution, id: \.name) { item in
                                    SectorMark(
                                        angle: .value("Value", item.value),
                                        innerRadius: .ratio(0.5),
                                        angularInset: 2
                                    )
                                    .foregroundStyle(item.color)
                                }
                            }
                            .frame(height: 180)
                            
                            HStack(spacing: 16) {
                                ForEach(roleDistribution, id: \.name) { item in
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(item.color)
                                            .frame(width: 8, height: 8)
                                        Text(item.name)
                                            .font(.system(size: 11))
                                            .foregroundColor(.zinc600)
                                    }
                                }
                            }
                            .padding(.top, 12)
                        }
                        
                        // Recent Events
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Recent Events")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.zinc900)
                            
                            ScrollView {
                                VStack(spacing: 8) {
                                    ForEach(Array(recentEvents.enumerated()), id: \.offset) { _, event in
                                        EventRow(event: event)
                                    }
                                }
                            }
                            .frame(maxHeight: 220)
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.zinc200.opacity(0.6), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }
}

struct StatCard: View {
    let stat: DashboardView.StatItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: stat.icon)
                    .font(.system(size: 20))
                    .foregroundColor(stat.color)
                    .frame(width: 40, height: 40)
                    .background(stat.color.opacity(0.1))
                    .cornerRadius(8)
                
                Spacer()
                
                if stat.status == .good {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green500)
                        .font(.system(size: 16))
                } else if stat.status == .warning {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.yellow500)
                        .font(.system(size: 16))
                }
            }
            
            Text(stat.label)
                .font(.system(size: 12))
                .foregroundColor(.zinc600)
            
            Text(stat.value)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.zinc900)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.zinc200.opacity(0.6), lineWidth: 1)
        )
    }
}

struct ChartCard<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.zinc900)
            
            content
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.zinc200.opacity(0.6), lineWidth: 1)
        )
    }
}

struct EventRow: View {
    let event: DashboardView.EventItem
    
    var levelColor: Color {
        switch event.level {
        case .information: return .blue500
        case .warning: return .yellow500
        case .error: return .red500
        case .critical: return .red600
        }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(levelColor)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(event.source)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.zinc900)
                    .lineLimit(1)
                
                Text(event.time)
                    .font(.system(size: 11))
                    .foregroundColor(.zinc600)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.zinc50.opacity(0.6))
        .cornerRadius(6)
    }
}

#Preview {
    DashboardView(viewModel: ServerManagerViewModel())
        .frame(width: 1200, height: 800)
}
