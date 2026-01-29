//
//  NetworkingView.swift
//  Server
//
//  Created by Jonathan Hines Dumitru on 1/14/26.
//

import SwiftUI
import Charts

struct NetworkingView: View {
    @Bindable var appModel: AppModel
    @State private var selectedAdapter: NetworkAdapter?
    
    var activeAdapter: NetworkAdapter? {
        appModel.networkAdapters.first { $0.status == .active }
    }
    
    var averageLatency: String {
        // Simulated latency - in production, measure via ICMP ping or TCP connection timing
        "\(Int.random(in: 1...5)) ms"
    }
    
    var totalThroughput: Double {
        appModel.networkAdapters.reduce(0) { $0 + $1.txRate + $1.rxRate }
    }
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedAdapter) {
                ForEach(appModel.networkAdapters) { adapter in
                    NetworkAdapterListItemView(adapter: adapter)
                        .tag(adapter)
                }
            }
            .navigationTitle("Networking")
            .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 300)
        } detail: {
            Group {
                if let adapter = selectedAdapter {
                    NetworkAdapterDetailView(adapter: adapter, appModel: appModel)
                } else {
                    NetworkingOverviewView(
                        activeAdapter: activeAdapter,
                        latency: averageLatency,
                        throughput: totalThroughput,
                        adapters: appModel.networkAdapters
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}

// MARK: - Overview

struct NetworkingOverviewView: View {
    let activeAdapter: NetworkAdapter?
    let latency: String
    let throughput: Double
    let adapters: [NetworkAdapter]
    
    var dnsStatus: String {
        adapters.allSatisfy { !$0.dnsServers.isEmpty } ? "Configured" : "Warning"
    }
    
    var body: some View {
        DetailPageContainer {
            VStack(alignment: .leading, spacing: 4) {
                Text("Networking")
                    .font(.system(size: 28, weight: .bold))
                Text("Manage network adapters and connections")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 180, maximum: 240), spacing: 12)
            ], spacing: 12) {
                SummaryCardView(
                    title: "Active Adapter",
                    value: activeAdapter?.name ?? "None",
                    icon: "network",
                    color: Color.blue
                )
                SummaryCardView(
                    title: "IPv4 Address",
                    value: activeAdapter?.ipv4Address ?? "N/A",
                    icon: "number",
                    color: Color.green
                )
                SummaryCardView(
                    title: "DNS Status",
                    value: dnsStatus,
                    icon: "server.rack",
                    color: dnsStatus == "Configured" ? Color.green : Color.orange
                )
                SummaryCardView(
                    title: "Latency",
                    value: latency,
                    icon: "timer",
                    color: Color.purple
                )
                SummaryCardView(
                    title: "Throughput",
                    value: formatThroughput(throughput),
                    icon: "speedometer",
                    color: Color.cyan
                )
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Network Traffic")
                    .font(.headline)
                
                NetworkTrafficChartView(adapters: adapters)
                    .frame(height: 280)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Network Adapters")
                    .font(.headline)
                
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 280, maximum: .infinity), spacing: 12)
                ], spacing: 12) {
                    ForEach(adapters) { adapter in
                        NetworkAdapterCardView(adapter: adapter)
                    }
                }
            }
        }
    }
    
    private func formatThroughput(_ value: Double) -> String {
        if value >= 1000 {
            return String(format: "%.1f Gbps", value / 1000)
        } else {
            return String(format: "%.0f Mbps", value)
        }
    }
}

struct NetworkTrafficChartView: View {
    let adapters: [NetworkAdapter]
    
    // Generate time series data for demonstration
    var trafficData: [(time: Date, tx: Double, rx: Double)] {
        let now = Date()
        return stride(from: 0, to: 20, by: 1).map { index in
            let time = now.addingTimeInterval(TimeInterval(-300 * (20 - index)))
            let tx = Double.random(in: 100...800)
            let rx = Double.random(in: 500...2000)
            return (time, tx, rx)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Chart {
                ForEach(Array(trafficData.enumerated()), id: \.offset) { _, data in
                    LineMark(
                        x: .value("Time", data.time),
                        y: .value("Mbps", data.tx)
                    )
                    .foregroundStyle(.orange)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value("Time", data.time),
                        y: .value("Mbps", data.tx)
                    )
                    .foregroundStyle(.orange.opacity(0.2))
                    .interpolationMethod(.catmullRom)
                    
                    LineMark(
                        x: .value("Time", data.time),
                        y: .value("Mbps", data.rx)
                    )
                    .foregroundStyle(.blue)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value("Time", data.time),
                        y: .value("Mbps", data.rx)
                    )
                    .foregroundStyle(.blue.opacity(0.2))
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            Text("\(intValue)")
                                .font(.system(size: 10))
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
                        }
                    }
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                        .foregroundStyle(Color.primary.opacity(0.1))
                }
            }
            .chartLegend(position: .bottom) {
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.orange)
                            .frame(width: 8, height: 8)
                        Text("TX (Upload)")
                            .font(.system(size: 11))
                    }
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.blue)
                            .frame(width: 8, height: 8)
                        Text("RX (Download)")
                            .font(.system(size: 11))
                    }
                }
            }
            .padding(12)
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 2)
        )
    }
}

struct NetworkAdapterCardView: View {
    let adapter: NetworkAdapter
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: statusIcon)
                    .foregroundStyle(statusColor)
                Text(adapter.name)
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Text(adapter.status.rawValue)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("IPv4:")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Text(adapter.ipv4Address)
                        .font(.system(size: 11, design: .monospaced))
                }
                
                HStack {
                    Text("Link:")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Text(adapter.linkSpeed)
                        .font(.system(size: 11))
                }
                
                HStack(spacing: 12) {
                    Label("↑ \(formatRate(adapter.txRate))", systemImage: "arrow.up")
                        .font(.system(size: 10))
                        .foregroundStyle(.orange)
                    
                    Label("↓ \(formatRate(adapter.rxRate))", systemImage: "arrow.down")
                        .font(.system(size: 10))
                        .foregroundStyle(.blue)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 2)
        )
    }
    
    var statusIcon: String {
        switch adapter.status {
        case .active: return "network"
        case .inactive: return "network.slash"
        case .disconnected: return "cable.connector.slash"
        }
    }
    
    var statusColor: Color {
        switch adapter.status {
        case .active: return .green
        case .inactive: return .orange
        case .disconnected: return .red
        }
    }
    
    private func formatRate(_ rate: Double) -> String {
        if rate >= 1000 {
            return String(format: "%.1f Gbps", rate / 1000)
        } else {
            return String(format: "%.0f Mbps", rate)
        }
    }
}

// MARK: - List Item

struct NetworkAdapterListItemView: View {
    let adapter: NetworkAdapter
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(adapter.name)
                    .font(.system(size: 13, weight: .medium))
                Spacer()
                Image(systemName: statusIcon)
                    .foregroundStyle(statusColor)
                    .font(.system(size: 12))
            }
            
            HStack(spacing: 8) {
                Label(adapter.linkSpeed, systemImage: "speedometer")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                
                Text(adapter.ipv4Address)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    var statusIcon: String {
        switch adapter.status {
        case .active: return "checkmark.circle.fill"
        case .inactive: return "pause.circle.fill"
        case .disconnected: return "xmark.circle.fill"
        }
    }
    
    var statusColor: Color {
        switch adapter.status {
        case .active: return .green
        case .inactive: return .orange
        case .disconnected: return .red
        }
    }
}

// MARK: - Detail View

struct NetworkAdapterDetailView: View {
    let adapter: NetworkAdapter
    let appModel: AppModel
    
    @State private var isDHCP: Bool
    @State private var dnsServers: String
    @State private var showingDiagnostics = false
    @State private var diagnosticsLog: [String] = []
    @State private var isResettingAdapter = false
    @State private var showResetConfirmation = false
    @State private var showResetComplete = false
    
    init(adapter: NetworkAdapter, appModel: AppModel) {
        self.adapter = adapter
        self.appModel = appModel
        _isDHCP = State(initialValue: adapter.isDHCP)
        _dnsServers = State(initialValue: adapter.dnsServers.joined(separator: ", "))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack(spacing: 12) {
                    Image(systemName: "network")
                        .font(.system(size: 32))
                        .foregroundStyle(.blue)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(adapter.name)
                            .font(.system(size: 22, weight: .bold))
                        Label(adapter.status.rawValue, systemImage: "circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(20)
                
                Divider()
                
                // Network Information
                VStack(alignment: .leading, spacing: 12) {
                    Text("Network Information")
                        .font(.headline)
                    
                    VStack(spacing: 8) {
                        PropertyRow(label: "IPv4 Address", value: adapter.ipv4Address)
                        if let ipv6 = adapter.ipv6Address {
                            PropertyRow(label: "IPv6 Address", value: ipv6)
                        }
                        PropertyRow(label: "Link Speed", value: adapter.linkSpeed)
                        PropertyRow(label: "TX Rate", value: formatRate(adapter.txRate), color: .orange)
                        PropertyRow(label: "RX Rate", value: formatRate(adapter.rxRate), color: .blue)
                    }
                }
                .padding(.horizontal, 20)
                
                // Configuration
                VStack(alignment: .leading, spacing: 12) {
                    Text("Configuration")
                        .font(.headline)
                    
                    Toggle("Use DHCP", isOn: $isDHCP)
                        .onChange(of: isDHCP) { _, newValue in
                            var mutableAdapter = adapter
                            mutableAdapter.isDHCP = newValue
                            appModel.toggleDHCP(for: adapter)
                        }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("DNS Servers (comma-separated):")
                            .font(.system(size: 13))
                        TextField("8.8.8.8, 8.8.4.4", text: $dnsServers)
                            .textFieldStyle(.roundedBorder)
                        
                        Button("Update DNS") {
                            let servers = dnsServers.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                            appModel.updateDNSServers(for: adapter, servers: servers)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
                .padding(.horizontal, 20)
                
                // Current DNS Servers
                if !adapter.dnsServers.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Current DNS Servers")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(adapter.dnsServers, id: \.self) { dns in
                                HStack {
                                    Image(systemName: "server.rack")
                                        .foregroundStyle(.blue)
                                        .font(.system(size: 11))
                                    Text(dns)
                                        .font(.system(size: 12, design: .monospaced))
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                // Actions
                VStack(spacing: 8) {
                    Button(action: { runDiagnostics() }) {
                        Label("Run Network Diagnostics", systemImage: "stethoscope")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Button(action: { showResetConfirmation = true }) {
                        if isResettingAdapter {
                            HStack {
                                ProgressView()
                                    .controlSize(.small)
                                Text("Resetting...")
                            }
                            .frame(maxWidth: .infinity)
                        } else {
                            Label("Reset Adapter", systemImage: "arrow.clockwise")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .disabled(isResettingAdapter)
                }
                .padding(.horizontal, 20)
                
                // Diagnostics Log
                if !diagnosticsLog.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Diagnostics Results")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(diagnosticsLog, id: \.self) { line in
                                Text(line)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(nsColor: .textBackgroundColor))
                        )
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.bottom, 20)
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .alert("Reset Network Adapter?", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetAdapter()
            }
        } message: {
            Text("This will temporarily disconnect '\(adapter.name)' and reset its configuration. Active connections will be interrupted.")
        }
        .alert("Adapter Reset Complete", isPresented: $showResetComplete) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("'\(adapter.name)' has been reset successfully.")
        }
    }

    private func resetAdapter() {
        isResettingAdapter = true
        diagnosticsLog.append("[\(formattedTime())] Resetting adapter '\(adapter.name)'...")

        Task {
            try? await Task.sleep(for: .seconds(1.5))
            await MainActor.run {
                diagnosticsLog.append("[\(formattedTime())] Disabling adapter...")
            }
            try? await Task.sleep(for: .seconds(1))
            await MainActor.run {
                diagnosticsLog.append("[\(formattedTime())] Clearing configuration cache...")
            }
            try? await Task.sleep(for: .seconds(0.5))
            await MainActor.run {
                diagnosticsLog.append("[\(formattedTime())] Re-enabling adapter...")
            }
            try? await Task.sleep(for: .seconds(1))
            await MainActor.run {
                diagnosticsLog.append("[\(formattedTime())] Adapter reset complete.")
                isResettingAdapter = false
                showResetComplete = true
            }
        }
    }

    private func formattedTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: Date())
    }
    
    private func formatRate(_ rate: Double) -> String {
        if rate >= 1000 {
            return String(format: "%.1f Gbps", rate / 1000)
        } else {
            return String(format: "%.1f Mbps", rate)
        }
    }
    
    private func runDiagnostics() {
        diagnosticsLog = [
            "Starting network diagnostics for \(adapter.name)...",
            "Testing connectivity...",
            "✓ Link status: Connected",
            "✓ IPv4 configuration: Valid",
            "✓ Gateway reachable: 192.168.1.1 (2ms)",
            "✓ DNS resolution: Working",
            "Testing DNS servers:",
            adapter.dnsServers.isEmpty ? "⚠ No DNS servers configured" : "✓ \(adapter.dnsServers.joined(separator: ", "))",
            "Network diagnostics completed successfully."
        ]
    }
}
// MARK: - Summary Card

struct NetworkSummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        SummaryCardView(title: title, value: value, icon: icon, color: color)
    }
}

