//
//  RolesAndFeaturesView.swift
//  Server
//
//  Created by Jonathan Hines Dumitru on 1/14/26.
//

import SwiftUI

struct RolesAndFeaturesView: View {
    @Bindable var appModel: AppModel
    @State private var selectedRole: ServerRole?
    @State private var selectedFeature: ServerFeature?
    @State private var filterMode: FilterMode = .all
    @State private var searchText = ""
    
    enum FilterMode: String, CaseIterable {
        case all = "All"
        case roles = "Roles"
        case features = "Features"
        case installed = "Installed"
        case notInstalled = "Not Installed"
        case pending = "Pending"
    }
    
    var filteredRoles: [ServerRole] {
        var filtered = appModel.roles
        
        if !searchText.isEmpty {
            filtered = filtered.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        switch filterMode {
        case .all, .roles:
            return filtered
        case .installed:
            return filtered.filter { $0.status == .installed }
        case .notInstalled:
            return filtered.filter { $0.status == .notInstalled }
        case .pending:
            return filtered.filter { $0.status == .pending || $0.status == .pendingInstall }
        case .features:
            return []
        }
    }
    
    var filteredFeatures: [ServerFeature] {
        var filtered = appModel.features
        
        if !searchText.isEmpty {
            filtered = filtered.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        switch filterMode {
        case .all, .features:
            return filtered
        case .installed:
            return filtered.filter { $0.isInstalled }
        case .notInstalled:
            return filtered.filter { !$0.isInstalled }
        case .pending:
            return []
        case .roles:
            return []
        }
    }
    
    var installedRolesCount: Int {
        appModel.roles.filter { $0.status == .installed }.count
    }
    
    var availableRolesCount: Int {
        appModel.roles.filter { $0.status == .notInstalled }.count
    }
    
    var pendingChangesCount: Int {
        appModel.roles.filter { $0.status == .pending || $0.status == .pendingInstall }.count
    }
    
    var requiresReboot: Bool {
        appModel.roles.contains { ($0.status == .pending || $0.status == .pendingInstall) && $0.requiresReboot }
    }
    
    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                // Content list
                List(selection: Binding(
                    get: { selectedRole },
                    set: { newValue in
                        selectedRole = newValue
                        if newValue != nil {
                            selectedFeature = nil
                        }
                    }
                )) {
                    if filterMode == .all || filterMode == .roles || filterMode == .installed || filterMode == .notInstalled || filterMode == .pending {
                        Section("Roles") {
                            ForEach(filteredRoles) { role in
                                RoleListItemView(role: role)
                                    .tag(role)
                            }
                        }
                    }
                    
                    if filterMode == .all || filterMode == .features || filterMode == .installed || filterMode == .notInstalled {
                        Section("Features") {
                            ForEach(filteredFeatures) { feature in
                                FeatureListItemView(feature: feature)
                                    .tag(feature as ServerFeature?)
                                    .onTapGesture {
                                        selectedFeature = feature
                                        selectedRole = nil
                                    }
                            }
                        }
                    }
                }
                .searchable(text: $searchText, prompt: "Search roles and features")
            }
            .navigationTitle("Roles & Features")
            .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 300)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Picker("Filter", selection: $filterMode) {
                        ForEach(FilterMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 450)
                }
            }
        } detail: {
            Group {
                if let role = selectedRole {
                    RoleDetailView(role: role, appModel: appModel)
                } else if let feature = selectedFeature {
                    FeatureDetailView(feature: feature, appModel: appModel)
                } else {
                    RolesOverviewView(
                        installedCount: installedRolesCount,
                        availableCount: availableRolesCount,
                        pendingCount: pendingChangesCount,
                        requiresReboot: requiresReboot
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}

// MARK: - Overview

struct RolesOverviewView: View {
    let installedCount: Int
    let availableCount: Int
    let pendingCount: Int
    let requiresReboot: Bool
    
    var body: some View {
        DetailPageContainer {
            VStack(alignment: .leading, spacing: 4) {
                Text("Roles & Features")
                    .font(.system(size: 28, weight: .bold))
                Text("Manage server roles and optional features")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 180, maximum: 240), spacing: 12)
            ], spacing: 12) {
                SummaryCardView(title: "Installed Roles", value: "\(installedCount)", icon: "checkmark.circle.fill", color: .green)
                SummaryCardView(title: "Available Roles", value: "\(availableCount)", icon: "cube.box", color: .blue)
                SummaryCardView(title: "Pending Changes", value: "\(pendingCount)", icon: "clock.fill", color: .orange)
                SummaryCardView(title: "Reboot Required", value: requiresReboot ? "Yes" : "No", icon: "arrow.clockwise", color: requiresReboot ? .red : .green)
                SummaryCardView(title: "Last Change", value: "2 days ago", icon: "calendar", color: .purple)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Getting Started")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 8) {
                    GettingStartedRow(icon: "1.circle.fill", text: "Select a role or feature from the list", color: .blue)
                    GettingStartedRow(icon: "2.circle.fill", text: "Review dependencies and system impact", color: .blue)
                    GettingStartedRow(icon: "3.circle.fill", text: "Click Install or Remove to make changes", color: .blue)
                    GettingStartedRow(icon: "4.circle.fill", text: "Restart server if required to complete installation", color: .blue)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(nsColor: .controlBackgroundColor))
                        .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 2)
                )
            }
        }
    }
}

struct GettingStartedRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.system(size: 14))
            Text(text)
                .font(.system(size: 13))
        }
    }
}

// MARK: - List Items

struct RoleListItemView: View {
    let role: ServerRole
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: statusIcon)
                .foregroundStyle(statusColor)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(role.name)
                    .font(.system(size: 13))
                
                HStack(spacing: 8) {
                    Label(role.status.rawValue, systemImage: "circle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    
                    Label(role.impact.rawValue, systemImage: impactIcon)
                        .font(.system(size: 10))
                        .foregroundStyle(impactColor)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    var statusIcon: String {
        switch role.status {
        case .installed: return "checkmark.circle.fill"
        case .notInstalled: return "circle"
        case .pending, .pendingInstall: return "clock.fill"
        }
    }
    
    var statusColor: Color {
        switch role.status {
        case .installed: return .green
        case .notInstalled: return .secondary
        case .pending, .pendingInstall: return .orange
        }
    }
    
    var impactIcon: String {
        switch role.impact {
        case .low: return "minus.circle"
        case .medium: return "exclamationmark.circle"
        case .high: return "exclamationmark.triangle.fill"
        }
    }
    
    var impactColor: Color {
        switch role.impact {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
}

struct FeatureListItemView: View {
    let feature: ServerFeature
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: feature.isInstalled ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(feature.isInstalled ? .green : .secondary)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(feature.name)
                    .font(.system(size: 13))
                
                Label(feature.impact.rawValue + " Impact", systemImage: "circle.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Detail Views

struct RoleDetailView: View {
    let role: ServerRole
    let appModel: AppModel
    
    var body: some View {
        DetailPageContainer {
            HStack(spacing: 12) {
                Image(systemName: "cube.box.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(role.name)
                        .font(.system(size: 22, weight: .bold))
                    
                    HStack(spacing: 12) {
                        Label(role.status.rawValue, systemImage: "circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        
                        Label(role.impact.rawValue + " Impact", systemImage: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.headline)
                Text(role.description)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            
            if !role.dependencies.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Dependencies")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(role.dependencies, id: \.self) { dep in
                            Label(dep, systemImage: "arrow.right.circle")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Services Affected")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(role.services, id: \.self) { service in
                        Label(service, systemImage: "gearshape.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Requirements")
                    .font(.headline)
                
                HStack(spacing: 6) {
                    Image(systemName: role.requiresReboot ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(role.requiresReboot ? .orange : .green)
                    Text(role.requiresReboot ? "Requires system restart" : "No restart required")
                        .font(.system(size: 12))
                }
            }
            
            Button(action: {
                appModel.toggleRole(role)
            }) {
                Label(
                    role.status == .installed ? "Remove Role" : "Install Role",
                    systemImage: role.status == .installed ? "minus.circle.fill" : "plus.circle.fill"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            if role.status == .pending || role.status == .pendingInstall {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.orange)
                    Text("Changes will take effect after applying configuration")
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
    }
}

struct FeatureDetailView: View {
    let feature: ServerFeature
    let appModel: AppModel
    
    var body: some View {
        DetailPageContainer {
            HStack(spacing: 12) {
                Image(systemName: "puzzlepiece.extension.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.purple)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(feature.name)
                        .font(.system(size: 22, weight: .bold))
                    
                    Label(feature.isInstalled ? "Installed" : "Not Installed", systemImage: "circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.headline)
                Text(feature.description)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("System Impact")
                    .font(.headline)
                
                Label(feature.impact.rawValue, systemImage: "gauge.with.dots.needle.bottom.50percent")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            
            Button(action: {
                appModel.toggleFeature(feature)
            }) {
                Label(
                    feature.isInstalled ? "Remove Feature" : "Install Feature",
                    systemImage: feature.isInstalled ? "minus.circle.fill" : "plus.circle.fill"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }
}
