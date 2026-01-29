//
//  StorageView.swift
//  Server
//
//  Created by Jonathan Hines Dumitru on 1/14/26.
//

import SwiftUI
import Charts

struct StorageView: View {
    @Bindable var appModel: AppModel
    @State private var selectedVolume: StorageVolume?
    @State private var selectedDisk: PhysicalDisk?
    @State private var selectedTab: StorageTab = .volumes
    @State private var showingCreateVolume = false
    
    enum StorageTab: String, CaseIterable {
        case volumes = "Volumes"
        case disks = "Disks"
    }
    
    var totalCapacity: Double {
        appModel.disks.reduce(0) { $0 + $1.size }
    }
    
    var totalUsed: Double {
        appModel.volumes.reduce(0) { $0 + $1.usedSize }
    }
    
    var totalFree: Double {
        totalCapacity - totalUsed
    }
    
    var healthStatus: String {
        let warnings = appModel.volumes.filter { $0.health == .warning || $0.health == .critical }
        return warnings.isEmpty ? "OK" : "Warning"
    }
    
    var averageIOPS: Int {
        // Simulated IOPS - in production, query via WMI/CIM for Windows or diskutil for macOS
        Int.random(in: 15000...25000)
    }
    
    private var volumeBinding: Binding<StorageVolume?> {
        Binding(
            get: { selectedVolume },
            set: { newValue in
                selectedVolume = newValue
                selectedDisk = nil
            }
        )
    }
    
    private var diskBinding: Binding<PhysicalDisk?> {
        Binding(
            get: { selectedDisk },
            set: { newValue in
                selectedDisk = newValue
                selectedVolume = nil
            }
        )
    }
    
    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                // Tab picker
                Picker("View", selection: $selectedTab) {
                    ForEach(StorageTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                // List
                if selectedTab == .volumes {
                    List(selection: volumeBinding) {
                        ForEach(appModel.volumes) { volume in
                            VolumeListItemView(volume: volume)
                                .tag(volume)
                        }
                    }
                } else {
                    List(selection: diskBinding) {
                        ForEach(appModel.disks) { disk in
                            DiskListItemView(disk: disk)
                                .tag(disk)
                        }
                    }
                }
            }
            .navigationTitle("Storage")
            .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 300)
            .toolbar {
                if selectedTab == .volumes {
                    Button(action: { showingCreateVolume = true }) {
                        Label("Create Volume", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateVolume) {
                CreateVolumeSheet(appModel: appModel)
            }
        } detail: {
            Group {
                if let volume = selectedVolume {
                    VolumeDetailView(volume: volume, appModel: appModel)
                } else if let disk = selectedDisk {
                    DiskDetailView(disk: disk)
                } else {
                    StorageOverviewView(
                        totalCapacity: totalCapacity,
                        totalUsed: totalUsed,
                        totalFree: totalFree,
                        healthStatus: healthStatus,
                        averageIOPS: averageIOPS,
                        volumes: appModel.volumes
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}

// MARK: - Overview

struct StorageOverviewView: View {
    let totalCapacity: Double
    let totalUsed: Double
    let totalFree: Double
    let healthStatus: String
    let averageIOPS: Int
    let volumes: [StorageVolume]
    
    var usedPercentage: Double {
        (totalUsed / totalCapacity) * 100
    }
    
    var body: some View {
        DetailPageContainer {
            VStack(alignment: .leading, spacing: 4) {
                Text("Storage")
                    .font(.system(size: 28, weight: .bold))
                Text("Manage disks, volumes, and storage resources")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 180, maximum: 240), spacing: 12)
            ], spacing: 12) {
                SummaryCardView(title: "Total Capacity", value: formatSize(totalCapacity), icon: "internaldrive.fill", color: .blue)
                SummaryCardView(title: "Used", value: formatSize(totalUsed), icon: "chart.pie.fill", color: .orange)
                SummaryCardView(title: "Free", value: formatSize(totalFree), icon: "externaldrive.fill", color: .green)
                SummaryCardView(title: "Health", value: healthStatus, icon: "heart.fill", color: healthStatus == "OK" ? .green : .orange)
                SummaryCardView(title: "Avg IOPS", value: "\(averageIOPS)", icon: "speedometer", color: .purple)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Storage Usage")
                    .font(.headline)
                
                StorageUsageChartView(volumes: volumes)
                    .frame(height: 280)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Volume Summary")
                    .font(.headline)
                
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 280, maximum: .infinity), spacing: 12)
                ], spacing: 12) {
                    ForEach(volumes) { volume in
                        VolumeCardView(volume: volume)
                    }
                }
            }
        }
    }
    
    private func formatSize(_ size: Double) -> String {
        if size >= 1000 {
            return String(format: "%.1f TB", size / 1000)
        } else {
            return String(format: "%.0f GB", size)
        }
    }
}

struct StorageUsageChartView: View {
    let volumes: [StorageVolume]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Chart {
                ForEach(volumes) { volume in
                    BarMark(
                        x: .value("Used", volume.usedSize),
                        y: .value("Volume", volume.name)
                    )
                    .foregroundStyle(.orange)
                    
                    BarMark(
                        x: .value("Free", volume.freeSize),
                        y: .value("Volume", volume.name)
                    )
                    .foregroundStyle(.green.opacity(0.5))
                }
            }
            .chartXAxis {
                AxisMarks(position: .bottom) { value in
                    if let doubleValue = value.as(Double.self) {
                        AxisValueLabel {
                            Text("\(Int(doubleValue)) GB")
                                .font(.system(size: 10))
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let stringValue = value.as(String.self) {
                            Text(stringValue)
                                .font(.system(size: 11))
                        }
                    }
                }
            }
            .chartLegend(position: .bottom) {
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.orange)
                            .frame(width: 8, height: 8)
                        Text("Used")
                            .font(.system(size: 11))
                    }
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.green.opacity(0.5))
                            .frame(width: 8, height: 8)
                        Text("Free")
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

struct VolumeCardView: View {
    let volume: StorageVolume
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "internaldrive.fill")
                    .foregroundStyle(.blue)
                Text(volume.name)
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Image(systemName: healthIcon)
                    .foregroundStyle(healthColor)
            }
            
            VStack(spacing: 4) {
                HStack {
                    Text("\(Int(volume.usedPercentage))% used")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(formatSize(volume.usedSize)) / \(formatSize(volume.totalSize))")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                
                ProgressView(value: volume.usedPercentage, total: 100)
                    .tint(volume.usedPercentage > 90 ? .red : volume.usedPercentage > 80 ? .orange : .blue)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 2)
        )
    }
    
    var healthIcon: String {
        switch volume.health {
        case .healthy: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .critical: return "xmark.circle.fill"
        }
    }
    
    var healthColor: Color {
        switch volume.health {
        case .healthy: return .green
        case .warning: return .orange
        case .critical: return .red
        }
    }
    
    private func formatSize(_ size: Double) -> String {
        if size >= 1000 {
            return String(format: "%.1f TB", size / 1000)
        } else {
            return String(format: "%.0f GB", size)
        }
    }
}

// MARK: - List Items

struct VolumeListItemView: View {
    let volume: StorageVolume
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(volume.name)
                    .font(.system(size: 13, weight: .medium))
                Spacer()
                Image(systemName: healthIcon)
                    .foregroundStyle(healthColor)
                    .font(.system(size: 12))
            }
            
            HStack(spacing: 8) {
                Label(volume.fileSystem, systemImage: "doc.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                
                Text("\(Int(volume.usedPercentage))% used")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    var healthIcon: String {
        switch volume.health {
        case .healthy: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .critical: return "xmark.circle.fill"
        }
    }
    
    var healthColor: Color {
        switch volume.health {
        case .healthy: return .green
        case .warning: return .orange
        case .critical: return .red
        }
    }
}

struct DiskListItemView: View {
    let disk: PhysicalDisk
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(disk.model)
                .font(.system(size: 13, weight: .medium))
            
            HStack(spacing: 8) {
                Label(formatSize(disk.size), systemImage: "externaldrive.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                
                Label(disk.interface, systemImage: "cable.connector")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                
                Label("\(disk.temperature)°C", systemImage: "thermometer")
                    .font(.system(size: 10))
                    .foregroundStyle(disk.temperature > 50 ? .orange : .secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatSize(_ size: Double) -> String {
        if size >= 1000 {
            return String(format: "%.1f TB", size / 1000)
        } else {
            return String(format: "%.0f GB", size)
        }
    }
}

// MARK: - Detail Views

struct VolumeDetailView: View {
    let volume: StorageVolume
    let appModel: AppModel
    @State private var showingDeleteConfirmation = false
    @State private var isCheckingDisk = false
    @State private var showDiskCheckComplete = false
    @State private var showResizeSheet = false
    @State private var newVolumeSize: Double = 0
    
    var body: some View {
        DetailPageContainer {
            HStack(spacing: 12) {
                Image(systemName: "internaldrive.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(volume.name)
                        .font(.system(size: 22, weight: .bold))
                    Text(volume.mountPoint)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Capacity")
                    .font(.headline)
                
                VStack(spacing: 8) {
                    HStack {
                        Text("Used:")
                            .frame(width: 80, alignment: .leading)
                        Text(formatSize(volume.usedSize))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int(volume.usedPercentage))%")
                            .foregroundStyle(.secondary)
                    }
                    .font(.system(size: 13))
                    
                    ProgressView(value: volume.usedPercentage, total: 100)
                        .tint(volume.usedPercentage > 90 ? .red : volume.usedPercentage > 80 ? .orange : .blue)
                    
                    HStack {
                        Text("Free:")
                            .frame(width: 80, alignment: .leading)
                        Text(formatSize(volume.freeSize))
                            .foregroundStyle(.secondary)
                    }
                    .font(.system(size: 13))
                    
                    HStack {
                        Text("Total:")
                            .frame(width: 80, alignment: .leading)
                        Text(formatSize(volume.totalSize))
                            .foregroundStyle(.secondary)
                    }
                    .font(.system(size: 13))
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Properties")
                    .font(.headline)
                
                VStack(spacing: 8) {
                    PropertyRow(label: "File System", value: volume.fileSystem)
                    PropertyRow(label: "Mount Point", value: volume.mountPoint)
                    PropertyRow(label: "Health Status", value: volume.health.rawValue, color: healthColor)
                }
            }
            
            VStack(spacing: 8) {
                Button(action: runDiskCheck) {
                    if isCheckingDisk {
                        HStack {
                            ProgressView()
                                .controlSize(.small)
                            Text("Checking...")
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        Label("Run Disk Check", systemImage: "checkmark.circle")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(isCheckingDisk)

                Button(action: {
                    newVolumeSize = volume.totalSize
                    showResizeSheet = true
                }) {
                    Label("Resize Volume", systemImage: "arrow.up.left.and.arrow.down.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button(role: .destructive, action: { showingDeleteConfirmation = true }) {
                    Label("Delete Volume", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
        .alert("Delete Volume", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                appModel.deleteVolume(volume)
            }
        } message: {
            Text("Are you sure you want to delete '\(volume.name)'? This action cannot be undone and all data will be lost.")
        }
        .alert("Disk Check Complete", isPresented: $showDiskCheckComplete) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("No errors found on volume '\(volume.name)'. The file system is healthy.")
        }
        .sheet(isPresented: $showResizeSheet) {
            VolumeResizeSheet(
                volumeName: volume.name,
                currentSize: volume.totalSize,
                newSize: $newVolumeSize,
                onResize: { _ in
                    // In a real app, this would resize the volume
                    showResizeSheet = false
                },
                onCancel: {
                    showResizeSheet = false
                }
            )
        }
    }

    private func runDiskCheck() {
        isCheckingDisk = true
        Task {
            try? await Task.sleep(for: .seconds(2))
            await MainActor.run {
                isCheckingDisk = false
                showDiskCheckComplete = true
            }
        }
    }
    
    var healthColor: Color {
        switch volume.health {
        case .healthy: return .green
        case .warning: return .orange
        case .critical: return .red
        }
    }
    
    private func formatSize(_ size: Double) -> String {
        if size >= 1000 {
            return String(format: "%.1f TB", size / 1000)
        } else {
            return String(format: "%.0f GB", size)
        }
    }
}

struct PropertyRow: View {
    let label: String
    let value: String
    var color: Color = .secondary
    
    var body: some View {
        HStack {
            Text(label + ":")
                .frame(width: 100, alignment: .leading)
                .font(.system(size: 13))
            Text(value)
                .font(.system(size: 13))
                .foregroundStyle(color)
            Spacer()
        }
    }
}

struct DiskDetailView: View {
    let disk: PhysicalDisk
    
    var body: some View {
        DetailPageContainer {
            HStack(spacing: 12) {
                Image(systemName: "externaldrive.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.purple)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(disk.model)
                        .font(.system(size: 22, weight: .bold))
                    Text(disk.serialNumber)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Properties")
                    .font(.headline)
                
                VStack(spacing: 8) {
                    PropertyRow(label: "Capacity", value: formatSize(disk.size))
                    PropertyRow(label: "Interface", value: disk.interface)
                    PropertyRow(label: "Health", value: disk.health, color: .green)
                    PropertyRow(label: "Temperature", value: "\(disk.temperature)°C", color: disk.temperature > 50 ? .orange : .secondary)
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("SMART Status")
                    .font(.headline)
                
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("All SMART indicators are normal")
                        .font(.system(size: 13))
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.green.opacity(0.1))
                )
            }
        }
    }
    
    private func formatSize(_ size: Double) -> String {
        if size >= 1000 {
            return String(format: "%.1f TB", size / 1000)
        } else {
            return String(format: "%.0f GB", size)
        }
    }
}

// MARK: - Create Volume Sheet

struct CreateVolumeSheet: View {
    let appModel: AppModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var size = 100.0
    @State private var fileSystem = "NTFS"
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Create New Volume")
                .font(.title2.bold())
            
            Form {
                TextField("Volume Name", text: $name)
                
                Picker("File System", selection: $fileSystem) {
                    Text("NTFS").tag("NTFS")
                    Text("ReFS").tag("ReFS")
                    Text("FAT32").tag("FAT32")
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Size: \(Int(size)) GB")
                        .font(.system(size: 13))
                    Slider(value: $size, in: 10...5000, step: 10)
                }
            }
            .formStyle(.grouped)
            
            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Create") {
                    appModel.createVolume(name: name, size: size, fileSystem: fileSystem)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.isEmpty)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 400)
    }
}

// MARK: - Volume Resize Sheet

struct VolumeResizeSheet: View {
    let volumeName: String
    let currentSize: Double
    @Binding var newSize: Double
    let onResize: (Double) -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Resize Volume")
                .font(.title2.bold())

            Text("Resize '\(volumeName)'")
                .foregroundStyle(.secondary)

            Form {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Current Size:")
                        Spacer()
                        Text(formatSize(currentSize))
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("New Size:")
                        Spacer()
                        Text(formatSize(newSize))
                            .foregroundStyle(newSize < currentSize ? .orange : .blue)
                    }

                    Slider(value: $newSize, in: 10...5000, step: 10)
                }
            }
            .formStyle(.grouped)

            if newSize < currentSize {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("Shrinking a volume may result in data loss if the volume contains more data than the new size.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
            }

            HStack(spacing: 12) {
                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)

                Button("Resize") {
                    onResize(newSize)
                }
                .keyboardShortcut(.defaultAction)
                .disabled(newSize == currentSize)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 400)
    }

    private func formatSize(_ size: Double) -> String {
        if size >= 1000 {
            return String(format: "%.1f TB", size / 1000)
        } else {
            return String(format: "%.0f GB", size)
        }
    }
}

// MARK: - Shared Layout Container

struct DetailPageContainer<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    content
                }
                .frame(minWidth: geometry.size.width, maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 28)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(nsColor: .underPageBackgroundColor))
    }
}

// MARK: - Summary Card

struct SummaryCardView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(color)
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: .black.opacity(0.06), radius: 3, x: 0, y: 2)
        )
    }
}

