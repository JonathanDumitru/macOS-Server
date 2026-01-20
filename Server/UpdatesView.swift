//
//  UpdatesView.swift
//  Server
//
//  Created by Jonathan Hines Dumitru on 1/14/26.
//

import SwiftUI

struct UpdatesView: View {
    @Bindable var appModel: AppModel
    @State private var selectedUpdate: SystemUpdate?
    @State private var filterStatus: SystemUpdate.UpdateStatus?
    @State private var searchText = ""
    @State private var autoUpdateEnabled = true
    @State private var isChecking = false
    
    var filteredUpdates: [SystemUpdate] {
        var filtered = appModel.updates
        
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.id.localizedCaseInsensitiveContains(searchText) ||
                $0.title.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        if let status = filterStatus {
            filtered = filtered.filter { $0.status == status }
        }
        
        return filtered.sorted { $0.releaseDate > $1.releaseDate }
    }
    
    var availableCount: Int {
        appModel.updates.filter { $0.status == .available }.count
    }
    
    var pendingInstallCount: Int {
        appModel.updates.filter { $0.status == .downloaded }.count
    }
    
    var installedCount: Int {
        appModel.updates.filter { $0.status == .installed }.count
    }
    
    var lastCheckDate: String {
        "1 hour ago"
    }
    
    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                // Filter
                VStack(spacing: 8) {
                    Picker("Status", selection: $filterStatus) {
                        Text("All Updates").tag(nil as SystemUpdate.UpdateStatus?)
                        ForEach(SystemUpdate.UpdateStatus.allCases, id: \.self) { status in
                            Text(status.rawValue).tag(status as SystemUpdate.UpdateStatus?)
                        }
                    }
                }
                .padding()
                
                // List
                List(selection: $selectedUpdate) {
                    ForEach(filteredUpdates) { update in
                        UpdateListItemView(update: update)
                            .tag(update)
                    }
                }
                .searchable(text: $searchText, prompt: "Search updates")
            }
            .navigationTitle("Updates")
            .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 300)
            .toolbar {
                Button(action: { checkForUpdates() }) {
                    Label("Check for Updates", systemImage: "arrow.clockwise")
                }
                .disabled(isChecking)
            }
        } detail: {
            Group {
                if let update = selectedUpdate {
                    UpdateDetailView(update: update, appModel: appModel)
                } else {
                    UpdatesOverviewView(
                        availableCount: availableCount,
                        pendingInstallCount: pendingInstallCount,
                        installedCount: installedCount,
                        lastCheck: lastCheckDate,
                        autoUpdateEnabled: $autoUpdateEnabled,
                        updates: appModel.updates
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
    
    private func checkForUpdates() {
        isChecking = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            appModel.checkForUpdates()
            isChecking = false
        }
    }
}

// MARK: - Overview

struct UpdatesOverviewView: View {
    let availableCount: Int
    let pendingInstallCount: Int
    let installedCount: Int
    let lastCheck: String
    @Binding var autoUpdateEnabled: Bool
    let updates: [SystemUpdate]
    
    var body: some View {
        DetailPageContainer {
            VStack(alignment: .leading, spacing: 4) {
                Text("Windows Updates")
                    .font(.system(size: 28, weight: .bold))
                Text("Manage system updates and patches")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 180, maximum: 240), spacing: 12)
            ], spacing: 12) {
                SummaryCardView(
                    title: "Available",
                    value: "\(availableCount)",
                    icon: "arrow.down.circle.fill",
                    color: availableCount > 0 ? .blue : .green
                )
                SummaryCardView(
                    title: "Pending Install",
                    value: "\(pendingInstallCount)",
                    icon: "clock.fill",
                    color: pendingInstallCount > 0 ? .orange : .green
                )
                SummaryCardView(
                    title: "Installed",
                    value: "\(installedCount)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                SummaryCardView(
                    title: "Last Check",
                    value: lastCheck,
                    icon: "arrow.clockwise",
                    color: .purple
                )
                SummaryCardView(
                    title: "Auto-Update",
                    value: autoUpdateEnabled ? "On" : "Off",
                    icon: "gear",
                    color: autoUpdateEnabled ? .green : .orange
                )
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Update Settings")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Automatically download and install updates", isOn: $autoUpdateEnabled)
                    
                    if autoUpdateEnabled {
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(.blue)
                                .font(.system(size: 12))
                            Text("Updates will be downloaded and installed automatically during maintenance windows.")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(nsColor: .controlBackgroundColor))
                        .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 2)
                )
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Update Status")
                    .font(.headline)
                
                UpdateStatusDistributionView(updates: updates)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Recent Updates")
                    .font(.headline)
                
                VStack(spacing: 8) {
                    ForEach(updates.prefix(5)) { update in
                        UpdateCardView(update: update)
                    }
                }
            }
            
            if availableCount > 0 {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.system(size: 20))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Updates Available")
                            .font(.system(size: 14, weight: .semibold))
                        Text("There are \(availableCount) updates available for installation. Please review and install them to keep your system secure.")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.orange.opacity(0.1))
                )
            }
        }
    }
}

struct UpdateStatusDistributionView: View {
    let updates: [SystemUpdate]
    
    var statusCounts: [(status: String, count: Int, color: Color)] {
        [
            ("Available", updates.filter { $0.status == .available }.count, .blue),
            ("Downloaded", updates.filter { $0.status == .downloaded }.count, .orange),
            ("Installed", updates.filter { $0.status == .installed }.count, .green),
            ("Failed", updates.filter { $0.status == .failed }.count, .red)
        ]
    }
    
    var totalCount: Int {
        updates.count
    }
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(statusCounts, id: \.status) { item in
                HStack(spacing: 12) {
                    Text(item.status)
                        .font(.system(size: 13))
                        .frame(width: 80, alignment: .leading)
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(item.color.opacity(0.2))
                                .frame(height: 20)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(item.color)
                                .frame(width: totalCount > 0 ? geometry.size.width * CGFloat(item.count) / CGFloat(totalCount) : 0, height: 20)
                        }
                    }
                    .frame(height: 20)
                    
                    Text("\(item.count)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(item.color)
                        .frame(width: 30, alignment: .trailing)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 2)
        )
    }
}

struct UpdateCardView: View {
    let update: SystemUpdate
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: statusIcon)
                .font(.system(size: 16))
                .foregroundStyle(statusColor)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(statusColor.opacity(0.15))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(update.title)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(update.id)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.secondary)
                    
                    Text("•")
                        .foregroundStyle(.secondary)
                    
                    Text(formatSize(update.size))
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    
                    if update.requiresReboot {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 10))
                            .foregroundStyle(.orange)
                    }
                }
            }
            
            Spacer()
            
            Text(update.status.rawValue)
                .font(.system(size: 10))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(statusColor.opacity(0.2))
                )
                .foregroundStyle(statusColor)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }
    
    var statusIcon: String {
        switch update.status {
        case .available: return "arrow.down.circle"
        case .downloading: return "arrow.down.circle.dotted"
        case .downloaded: return "checkmark.circle"
        case .installing: return "gear"
        case .installed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        }
    }
    
    var statusColor: Color {
        switch update.status {
        case .available: return .blue
        case .downloading: return .cyan
        case .downloaded: return .orange
        case .installing: return .purple
        case .installed: return .green
        case .failed: return .red
        }
    }
    
    private func formatSize(_ size: Double) -> String {
        if size >= 1000 {
            return String(format: "%.1f GB", size / 1000)
        } else {
            return String(format: "%.0f MB", size)
        }
    }
}

// MARK: - List Item

struct UpdateListItemView: View {
    let update: SystemUpdate
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(update.id)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                Spacer()
                Image(systemName: statusIcon)
                    .foregroundStyle(statusColor)
                    .font(.system(size: 12))
            }
            
            Text(update.title)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .lineLimit(2)
            
            HStack(spacing: 8) {
                Text(formatSize(update.size))
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                
                if update.requiresReboot {
                    Label("Reboot", systemImage: "arrow.clockwise")
                        .font(.system(size: 10))
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    var statusIcon: String {
        switch update.status {
        case .available: return "arrow.down.circle"
        case .downloading: return "arrow.down.circle.dotted"
        case .downloaded: return "checkmark.circle"
        case .installing: return "gear"
        case .installed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        }
    }
    
    var statusColor: Color {
        switch update.status {
        case .available: return .blue
        case .downloading: return .cyan
        case .downloaded: return .orange
        case .installing: return .purple
        case .installed: return .green
        case .failed: return .red
        }
    }
    
    private func formatSize(_ size: Double) -> String {
        if size >= 1000 {
            return String(format: "%.1f GB", size / 1000)
        } else {
            return String(format: "%.0f MB", size)
        }
    }
}

// MARK: - Detail View

struct UpdateDetailView: View {
    let update: SystemUpdate
    let appModel: AppModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack(spacing: 12) {
                    Image(systemName: statusIcon)
                        .font(.system(size: 32))
                        .foregroundStyle(statusColor)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(update.id)
                            .font(.system(size: 22, weight: .bold, design: .monospaced))
                        
                        Label(update.status.rawValue, systemImage: "circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(statusColor)
                    }
                }
                .padding(20)
                
                Divider()
                
                // Title
                VStack(alignment: .leading, spacing: 8) {
                    Text("Update Title")
                        .font(.headline)
                    Text(update.title)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 20)
                
                // Description
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.headline)
                    Text(update.description)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 20)
                
                // Properties
                VStack(alignment: .leading, spacing: 12) {
                    Text("Update Information")
                        .font(.headline)
                    
                    VStack(spacing: 8) {
                        PropertyRow(label: "Size", value: formatSize(update.size))
                        PropertyRow(label: "Released", value: update.releaseDate.formatted(date: .long, time: .omitted))
                        PropertyRow(
                            label: "Restart Required",
                            value: update.requiresReboot ? "Yes" : "No",
                            color: update.requiresReboot ? .orange : .green
                        )
                        
                        if let installDate = update.installDate {
                            PropertyRow(label: "Installed", value: installDate.formatted(date: .long, time: .shortened))
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                // Actions
                if update.status == .available {
                    VStack(spacing: 8) {
                        Button(action: {
                            appModel.downloadUpdate(update)
                        }) {
                            Label("Download Update", systemImage: "arrow.down.circle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                    .padding(.horizontal, 20)
                } else if update.status == .downloaded {
                    VStack(spacing: 8) {
                        Button(action: {
                            appModel.installUpdate(update)
                        }) {
                            Label("Install Update", systemImage: "gear")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        
                        if update.requiresReboot {
                            HStack(spacing: 8) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundStyle(.orange)
                                Text("This update requires a system restart to complete installation.")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.orange.opacity(0.1))
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                } else if update.status == .installed {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("This update has been successfully installed.")
                            .font(.system(size: 13))
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.green.opacity(0.1))
                    )
                    .padding(.horizontal, 20)
                }
            }
            .padding(.bottom, 20)
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }
    
    var statusIcon: String {
        switch update.status {
        case .available: return "arrow.down.circle"
        case .downloading: return "arrow.down.circle.dotted"
        case .downloaded: return "checkmark.circle"
        case .installing: return "gear"
        case .installed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        }
    }
    
    var statusColor: Color {
        switch update.status {
        case .available: return .blue
        case .downloading: return .cyan
        case .downloaded: return .orange
        case .installing: return .purple
        case .installed: return .green
        case .failed: return .red
        }
    }
    
    private func formatSize(_ size: Double) -> String {
        if size >= 1000 {
            return String(format: "%.2f GB", size / 1000)
        } else {
            return String(format: "%.1f MB", size)
        }
    }
}
