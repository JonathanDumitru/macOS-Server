//
//  PerformanceMonitor.swift
//  macOS-Server-2026
//
//  Created on 2026-01-13.
//

import SwiftUI
import Charts

struct PerformanceMonitor: View {
    let metrics = [
        Metric(name: "CPU", value: 23, icon: "cpu.fill", color: .blue500),
        Metric(name: "Memory", value: 47, icon: "chart.line.uptrend.xyaxis", color: .green400),
        Metric(name: "Disk", value: 12, icon: "externaldrive.fill", color: .purple500),
        Metric(name: "Network", value: 8, icon: "network", color: .orange500)
    ]
    
    struct Metric {
        let name: String
        let value: Int
        let icon: String
        let color: Color
    }
    
    var cpuData: [(time: Int, value: Int)] {
        (0..<60).map { (time: $0, value: Int.random(in: 20...100)) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Performance Monitor")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.zinc900)
                Text("Real-time system performance metrics")
                    .font(.system(size: 13))
                    .foregroundColor(.zinc600)
            }
            .padding(24)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Metrics Grid
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                        ForEach(metrics, id: \.name) { metric in
                            MetricCard(metric: metric)
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // CPU Chart
                    VStack(alignment: .leading, spacing: 16) {
                        Text("CPU Usage (Last 60 seconds)")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.zinc900)
                        
                        Chart {
                            ForEach(cpuData, id: \.time) { data in
                                BarMark(
                                    x: .value("Time", data.time),
                                    y: .value("Usage", data.value)
                                )
                                .foregroundStyle(Color.blue500)
                            }
                        }
                        .chartXAxis {
                            AxisMarks(values: .automatic(desiredCount: 6))
                        }
                        .chartYAxis {
                            AxisMarks(values: .automatic(desiredCount: 5))
                        }
                        .frame(height: 200)
                    }
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.zinc200.opacity(0.6), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)
                    
                    // System Info
                    HStack(spacing: 32) {
                        InfoItem(label: "Processes", value: "247")
                        InfoItem(label: "Threads", value: "3,892")
                        InfoItem(label: "Handles", value: "124,567")
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.zinc200.opacity(0.6), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
        }
    }
}

struct MetricCard: View {
    let metric: PerformanceMonitor.Metric
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: metric.icon)
                    .font(.system(size: 20))
                    .foregroundColor(metric.color)
                    .frame(width: 40, height: 40)
                    .background(metric.color.opacity(0.1))
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(metric.name)
                        .font(.system(size: 13))
                        .foregroundColor(.zinc600)
                    Text("\(metric.value)%")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.zinc900)
                }
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.zinc200)
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(metric.color)
                        .frame(width: geometry.size.width * CGFloat(metric.value) / 100, height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.zinc200.opacity(0.6), lineWidth: 1)
        )
    }
}

struct InfoItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.zinc600)
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.zinc900)
        }
    }
}

#Preview {
    PerformanceMonitor()
        .frame(width: 1200, height: 800)
}
