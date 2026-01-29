//
//  DiskManagementView.swift
//  Server
//
//  Created by Claude on 1/28/26.
//

import SwiftUI
import SwiftData
import Charts

struct DiskManagementView: View {
    @Query private var servers: [Server]
    @State private var selectedServer: Server?
    @State private var showDiskDetails: DiskVolume?

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
                    ServerDiskRow(server: server)
                        .tag(server)
                }
                .listStyle(.inset)
            }
            .frame(minWidth: 220, maxWidth: 280)

            // Disk Details Panel
            if let server = selectedServer {
                DiskDetailsView(server: server, showDiskDetails: $showDiskDetails)
            } else {
                emptyState
            }
        }
        .sheet(item: $showDiskDetails) { volume in
            DiskVolumeDetailSheet(volume: volume)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "externaldrive")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Select a Server")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text("Choose a server to view and manage disk volumes")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Server Disk Row

struct ServerDiskRow: View {
    let server: Server

    var diskUsage: Double {
        server.metrics.last?.diskUsage ?? 0
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

            HStack {
                DiskUsageBar(usage: diskUsage)
                Text("\(Int(diskUsage))%")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(diskUsage > 90 ? .red : (diskUsage > 75 ? .orange : .secondary))
            }
        }
        .padding(.vertical, 4)
    }
}

struct DiskUsageBar: View {
    let usage: Double

    var color: Color {
        usage > 90 ? .red : (usage > 75 ? .orange : .green)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.secondary.opacity(0.2))

                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: geo.size.width * (usage / 100))
            }
        }
        .frame(height: 6)
    }
}

// MARK: - Disk Details View

struct DiskDetailsView: View {
    let server: Server
    @Binding var showDiskDetails: DiskVolume?

    // Simulated disk volumes
    var volumes: [DiskVolume] {
        DiskVolume.simulatedVolumes(for: server)
    }

    var totalCapacity: Double {
        volumes.reduce(0) { $0 + $1.totalGB }
    }

    var usedCapacity: Double {
        volumes.reduce(0) { $0 + $1.usedGB }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Disk Management")
                            .font(.title2.bold())
                        Text(server.name)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                // Overall Summary
                DiskSummaryCard(
                    totalCapacity: totalCapacity,
                    usedCapacity: usedCapacity,
                    volumeCount: volumes.count
                )

                // Volume List
                VStack(alignment: .leading, spacing: 12) {
                    Text("Volumes")
                        .font(.headline)

                    ForEach(volumes) { volume in
                        DiskVolumeCard(volume: volume) {
                            showDiskDetails = volume
                        }
                    }
                }

                // Disk Activity
                DiskActivityView(server: server)
            }
            .padding()
        }
    }
}

// MARK: - Disk Summary Card

struct DiskSummaryCard: View {
    let totalCapacity: Double
    let usedCapacity: Double
    let volumeCount: Int

    var freeCapacity: Double {
        totalCapacity - usedCapacity
    }

    var usagePercent: Double {
        totalCapacity > 0 ? (usedCapacity / totalCapacity) * 100 : 0
    }

    var body: some View {
        HStack(spacing: 20) {
            // Pie Chart
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 20)
                    .frame(width: 100, height: 100)

                Circle()
                    .trim(from: 0, to: usagePercent / 100)
                    .stroke(
                        usagePercent > 90 ? Color.red : (usagePercent > 75 ? Color.orange : Color.blue),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text("\(Int(usagePercent))%")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    Text("Used")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                SummaryStatRow(label: "Total Capacity", value: formatSize(totalCapacity), color: .primary)
                SummaryStatRow(label: "Used Space", value: formatSize(usedCapacity), color: .blue)
                SummaryStatRow(label: "Free Space", value: formatSize(freeCapacity), color: .green)
                SummaryStatRow(label: "Volumes", value: "\(volumeCount)", color: .purple)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }

    private func formatSize(_ gb: Double) -> String {
        if gb >= 1000 {
            return String(format: "%.2f TB", gb / 1000)
        }
        return String(format: "%.1f GB", gb)
    }
}

struct SummaryStatRow: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(color)
        }
    }
}

// MARK: - Disk Volume Card

struct DiskVolumeCard: View {
    let volume: DiskVolume
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Drive Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(volume.type.color.opacity(0.15))
                        .frame(width: 50, height: 50)

                    Image(systemName: volume.type.icon)
                        .font(.system(size: 20))
                        .foregroundStyle(volume.type.color)
                }

                // Volume Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(volume.name)
                            .font(.system(size: 14, weight: .semibold))

                        Text("(\(volume.driveLetter):)")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)

                        if volume.isSystem {
                            Text("SYSTEM")
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color.blue.opacity(0.2))
                                .foregroundStyle(.blue)
                                .clipShape(Capsule())
                        }
                    }

                    Text(volume.fileSystem)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)

                    HStack {
                        DiskUsageBar(usage: volume.usagePercent)
                            .frame(width: 150)

                        Text("\(formatSize(volume.usedGB)) / \(formatSize(volume.totalGB))")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Status
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(volume.health.color)
                            .frame(width: 8, height: 8)
                        Text(volume.health.rawValue)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }

                    Text("\(Int(volume.usagePercent))% used")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(volume.usagePercent > 90 ? .red : (volume.usagePercent > 75 ? .orange : .primary))
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
        }
        .buttonStyle(.plain)
    }

    private func formatSize(_ gb: Double) -> String {
        if gb >= 1000 {
            return String(format: "%.1f TB", gb / 1000)
        }
        return String(format: "%.0f GB", gb)
    }
}

// MARK: - Disk Activity View

struct DiskActivityView: View {
    let server: Server

    var recentMetrics: [ServerMetric] {
        Array(server.metrics
            .sorted { $0.timestamp > $1.timestamp }
            .prefix(20)
            .reversed())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Disk Activity")
                .font(.headline)

            if recentMetrics.isEmpty {
                Text("No activity data available")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                Chart {
                    ForEach(recentMetrics, id: \.timestamp) { metric in
                        if let disk = metric.diskUsage {
                            BarMark(
                                x: .value("Time", metric.timestamp),
                                y: .value("Usage", disk)
                            )
                            .foregroundStyle(disk > 90 ? .red : (disk > 75 ? .orange : .blue))
                        }
                    }
                }
                .chartYScale(domain: 0...100)
                .frame(height: 150)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }
}

// MARK: - Disk Volume Detail Sheet

struct DiskVolumeDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let volume: DiskVolume

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(volume.name)
                        .font(.title2.bold())
                    Text("Volume Details")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button("Done") {
                    dismiss()
                }
            }
            .padding()

            Divider()

            ScrollView {
                VStack(spacing: 20) {
                    // Volume Info
                    GroupBox("Volume Information") {
                        VStack(spacing: 12) {
                            DetailRow(label: "Drive Letter", value: "\(volume.driveLetter):")
                            DetailRow(label: "File System", value: volume.fileSystem)
                            DetailRow(label: "Volume Type", value: volume.type.rawValue)
                            DetailRow(label: "Total Capacity", value: formatSize(volume.totalGB))
                            DetailRow(label: "Used Space", value: formatSize(volume.usedGB))
                            DetailRow(label: "Free Space", value: formatSize(volume.totalGB - volume.usedGB))
                            DetailRow(label: "Usage", value: "\(Int(volume.usagePercent))%")
                        }
                    }

                    // Health Status
                    GroupBox("Health Status") {
                        VStack(spacing: 12) {
                            HStack {
                                Circle()
                                    .fill(volume.health.color)
                                    .frame(width: 12, height: 12)
                                Text(volume.health.rawValue)
                                    .font(.system(size: 14, weight: .medium))
                                Spacer()
                            }

                            DetailRow(label: "SMART Status", value: "Healthy")
                            DetailRow(label: "Last Checked", value: Date().formatted())
                        }
                    }

                    // Actions
                    GroupBox("Actions") {
                        VStack(spacing: 8) {
                            ActionButton(title: "Analyze Disk", icon: "magnifyingglass", color: .blue) { }
                            ActionButton(title: "Clean Up", icon: "trash", color: .orange) { }
                            ActionButton(title: "Defragment", icon: "rectangle.split.3x3", color: .purple) { }
                            ActionButton(title: "Check for Errors", icon: "checkmark.shield", color: .green) { }
                        }
                    }
                }
                .padding()
            }
        }
        .frame(width: 450, height: 550)
    }

    private func formatSize(_ gb: Double) -> String {
        if gb >= 1000 {
            return String(format: "%.2f TB", gb / 1000)
        }
        return String(format: "%.1f GB", gb)
    }
}

struct DetailRow: View {
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
        .font(.system(size: 13))
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Disk Volume Model

struct DiskVolume: Identifiable {
    let id = UUID()
    let name: String
    let driveLetter: String
    let fileSystem: String
    let type: VolumeType
    let totalGB: Double
    let usedGB: Double
    let isSystem: Bool
    let health: VolumeHealth

    var usagePercent: Double {
        totalGB > 0 ? (usedGB / totalGB) * 100 : 0
    }

    enum VolumeType: String {
        case ssd = "SSD"
        case hdd = "HDD"
        case nvme = "NVMe"
        case network = "Network"
        case removable = "Removable"

        var icon: String {
            switch self {
            case .ssd, .nvme: return "internaldrive.fill"
            case .hdd: return "internaldrive"
            case .network: return "externaldrive.connected.to.line.below"
            case .removable: return "externaldrive"
            }
        }

        var color: Color {
            switch self {
            case .ssd: return .blue
            case .hdd: return .gray
            case .nvme: return .purple
            case .network: return .green
            case .removable: return .orange
            }
        }
    }

    enum VolumeHealth: String {
        case healthy = "Healthy"
        case warning = "Warning"
        case critical = "Critical"
        case unknown = "Unknown"

        var color: Color {
            switch self {
            case .healthy: return .green
            case .warning: return .orange
            case .critical: return .red
            case .unknown: return .gray
            }
        }
    }

    static func simulatedVolumes(for server: Server) -> [DiskVolume] {
        let diskUsage = server.metrics.last?.diskUsage ?? 45

        return [
            DiskVolume(
                name: "Windows",
                driveLetter: "C",
                fileSystem: "NTFS",
                type: .nvme,
                totalGB: 256,
                usedGB: 256 * (diskUsage / 100),
                isSystem: true,
                health: .healthy
            ),
            DiskVolume(
                name: "Data",
                driveLetter: "D",
                fileSystem: "NTFS",
                type: .ssd,
                totalGB: 512,
                usedGB: 512 * ((diskUsage + 10) / 100),
                isSystem: false,
                health: .healthy
            ),
            DiskVolume(
                name: "Backup",
                driveLetter: "E",
                fileSystem: "NTFS",
                type: .hdd,
                totalGB: 2000,
                usedGB: 2000 * 0.65,
                isSystem: false,
                health: .healthy
            ),
            DiskVolume(
                name: "Logs",
                driveLetter: "F",
                fileSystem: "ReFS",
                type: .hdd,
                totalGB: 500,
                usedGB: 500 * 0.42,
                isSystem: false,
                health: .warning
            )
        ]
    }
}

#Preview {
    DiskManagementView()
}
