//
//  SecurityView.swift
//  Server
//
//  Created by Jonathan Hines Dumitru on 1/14/26.
//

import SwiftUI

struct SecurityView: View {
    @Bindable var appModel: AppModel
    @State private var selectedAlert: SecurityAlert?
    @State private var filterSeverity: SecurityAlert.Severity?
    @State private var filterStatus: SecurityAlert.AlertStatus?
    @State private var searchText = ""
    @State private var firewallEnabled = true
    
    var filteredAlerts: [SecurityAlert] {
        var filtered = appModel.securityAlerts
        
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        if let severity = filterSeverity {
            filtered = filtered.filter { $0.severity == severity }
        }
        
        if let status = filterStatus {
            filtered = filtered.filter { $0.status == status }
        }
        
        return filtered.sorted { $0.timestamp > $1.timestamp }
    }
    
    var openAlertsCount: Int {
        appModel.securityAlerts.filter { $0.status == .open }.count
    }
    
    var criticalAlertsCount: Int {
        appModel.securityAlerts.filter { $0.severity == .critical && $0.status == .open }.count
    }
    
    var failedLoginsCount: Int {
        appModel.securityAlerts.filter { $0.category == .authentication && $0.timestamp > Date().addingTimeInterval(-86400) }.count
    }
    
    var lastScanDate: String {
        "2 hours ago"
    }
    
    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                // Filters
                VStack(spacing: 8) {
                    Picker("Severity", selection: $filterSeverity) {
                        Text("All Severities").tag(nil as SecurityAlert.Severity?)
                        ForEach(SecurityAlert.Severity.allCases, id: \.self) { severity in
                            Text(severity.rawValue).tag(severity as SecurityAlert.Severity?)
                        }
                    }
                    
                    Picker("Status", selection: $filterStatus) {
                        Text("All Statuses").tag(nil as SecurityAlert.AlertStatus?)
                        ForEach(SecurityAlert.AlertStatus.allCases, id: \.self) { status in
                            Text(status.rawValue).tag(status as SecurityAlert.AlertStatus?)
                        }
                    }
                }
                .padding()
                
                // List
                List(selection: $selectedAlert) {
                    ForEach(filteredAlerts) { alert in
                        SecurityAlertListItemView(alert: alert)
                            .tag(alert)
                    }
                }
                .searchable(text: $searchText, prompt: "Search alerts")
            }
            .navigationTitle("Security")
            .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 300)
            .toolbar {
                Button(action: {}) {
                    Label("Run Scan", systemImage: "magnifyingglass")
                }
            }
        } detail: {
            Group {
                if let alert = selectedAlert {
                    SecurityAlertDetailView(alert: alert, appModel: appModel)
                } else {
                    SecurityOverviewView(
                        openAlerts: openAlertsCount,
                        criticalAlerts: criticalAlertsCount,
                        failedLogins: failedLoginsCount,
                        firewallEnabled: firewallEnabled,
                        lastScan: lastScanDate,
                        alerts: appModel.securityAlerts
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}

// MARK: - Overview

struct SecurityOverviewView: View {
    let openAlerts: Int
    let criticalAlerts: Int
    let failedLogins: Int
    let firewallEnabled: Bool
    let lastScan: String
    let alerts: [SecurityAlert]
    
    var body: some View {
        DetailPageContainer {
            VStack(alignment: .leading, spacing: 4) {
                Text("Security")
                    .font(.system(size: 28, weight: .bold))
                Text("Monitor security alerts and system protection")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 180, maximum: 240), spacing: 12)
            ], spacing: 12) {
                SummaryCardView(
                    title: "Alerts Open",
                    value: "\(openAlerts)",
                    icon: "exclamationmark.triangle.fill",
                    color: openAlerts > 0 ? .orange : .green
                )
                SummaryCardView(
                    title: "Critical",
                    value: "\(criticalAlerts)",
                    icon: "exclamationmark.shield.fill",
                    color: criticalAlerts > 0 ? .red : .green
                )
                SummaryCardView(
                    title: "Failed Logins 24h",
                    value: "\(failedLogins)",
                    icon: "lock.slash.fill",
                    color: failedLogins > 0 ? .red : .green
                )
                SummaryCardView(
                    title: "Firewall",
                    value: firewallEnabled ? "Active" : "Inactive",
                    icon: "shield.fill",
                    color: firewallEnabled ? .green : .red
                )
                SummaryCardView(
                    title: "Last Scan",
                    value: lastScan,
                    icon: "clock.fill",
                    color: .blue
                )
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Alert Distribution")
                    .font(.headline)
                
                SecurityAlertDistributionView(alerts: alerts)
                    .frame(height: 200)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Recent Security Alerts")
                    .font(.headline)
                
                VStack(spacing: 8) {
                    ForEach(alerts.prefix(5)) { alert in
                        SecurityAlertCardView(alert: alert)
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Security Recommendations")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 8) {
                    RecommendationRow(
                        icon: "checkmark.shield.fill",
                        title: "Enable Two-Factor Authentication",
                        priority: .high
                    )
                    RecommendationRow(
                        icon: "lock.rotation",
                        title: "Rotate Administrator Passwords",
                        priority: .medium
                    )
                    RecommendationRow(
                        icon: "arrow.down.circle.fill",
                        title: "Install Pending Security Updates",
                        priority: .high
                    )
                    RecommendationRow(
                        icon: "network",
                        title: "Review Firewall Rules",
                        priority: .low
                    )
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

struct SecurityAlertDistributionView: View {
    let alerts: [SecurityAlert]
    
    var severityCounts: [(severity: String, count: Int, color: Color)] {
        let critical = alerts.filter { $0.severity == .critical }.count
        let high = alerts.filter { $0.severity == .high }.count
        let medium = alerts.filter { $0.severity == .medium }.count
        let low = alerts.filter { $0.severity == .low }.count
        let info = alerts.filter { $0.severity == .info }.count
        
        return [
            ("Critical", critical, .red),
            ("High", high, .orange),
            ("Medium", medium, .yellow),
            ("Low", low, .blue),
            ("Info", info, .green)
        ]
    }
    
    var body: some View {
        HStack(spacing: 16) {
            ForEach(severityCounts, id: \.severity) { item in
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .stroke(item.color.opacity(0.2), lineWidth: 8)
                            .frame(width: 80, height: 80)
                        
                        Text("\(item.count)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(item.color)
                    }
                    
                    Text(item.severity)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
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

struct SecurityAlertCardView: View {
    let alert: SecurityAlert
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: severityIcon)
                .font(.system(size: 16))
                .foregroundStyle(severityColor)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(severityColor.opacity(0.15))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(alert.title)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Label(alert.category.rawValue, systemImage: "tag.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    
                    Text(alert.timestamp, style: .relative)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Text(alert.status.rawValue)
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
    
    var severityIcon: String {
        switch alert.severity {
        case .critical: return "exclamationmark.triangle.fill"
        case .high: return "exclamationmark.circle.fill"
        case .medium: return "info.circle.fill"
        case .low: return "checkmark.circle.fill"
        case .info: return "info.circle"
        }
    }
    
    var severityColor: Color {
        switch alert.severity {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .blue
        case .info: return .green
        }
    }
    
    var statusColor: Color {
        switch alert.status {
        case .open: return .orange
        case .acknowledged: return .blue
        case .resolved: return .green
        }
    }
}

struct RecommendationRow: View {
    let icon: String
    let title: String
    let priority: Priority
    
    enum Priority {
        case high, medium, low
        
        var color: Color {
            switch self {
            case .high: return .red
            case .medium: return .orange
            case .low: return .blue
            }
        }
        
        var label: String {
            switch self {
            case .high: return "High"
            case .medium: return "Medium"
            case .low: return "Low"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(priority.color)
                .font(.system(size: 14))
                .frame(width: 24)
            
            Text(title)
                .font(.system(size: 13))
            
            Spacer()
            
            Text(priority.label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(priority.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(priority.color.opacity(0.15))
                )
        }
    }
}

// MARK: - List Item

struct SecurityAlertListItemView: View {
    let alert: SecurityAlert
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: severityIcon)
                    .foregroundStyle(severityColor)
                    .font(.system(size: 12))
                    .frame(width: 16)
                
                Text(alert.title)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
            }
            
            HStack(spacing: 8) {
                Label(alert.severity.rawValue, systemImage: "circle.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(severityColor)
                
                Label(alert.category.rawValue, systemImage: "tag")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                
                Text(alert.timestamp, style: .relative)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    var severityIcon: String {
        switch alert.severity {
        case .critical: return "exclamationmark.triangle.fill"
        case .high: return "exclamationmark.circle.fill"
        case .medium: return "info.circle.fill"
        case .low: return "checkmark.circle.fill"
        case .info: return "info.circle"
        }
    }
    
    var severityColor: Color {
        switch alert.severity {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .blue
        case .info: return .green
        }
    }
}

// MARK: - Detail View

struct SecurityAlertDetailView: View {
    let alert: SecurityAlert
    let appModel: AppModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack(spacing: 12) {
                    Image(systemName: severityIcon)
                        .font(.system(size: 32))
                        .foregroundStyle(severityColor)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(alert.title)
                            .font(.system(size: 22, weight: .bold))
                        
                        HStack(spacing: 12) {
                            Label(alert.severity.rawValue, systemImage: "circle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(severityColor)
                            
                            Label(alert.category.rawValue, systemImage: "tag")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                            
                            Label(alert.status.rawValue, systemImage: "circle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(statusColor)
                        }
                    }
                }
                .padding(20)
                
                Divider()
                
                // Timestamp
                VStack(alignment: .leading, spacing: 8) {
                    Text("Detected")
                        .font(.headline)
                    Text(alert.timestamp, style: .date)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    Text(alert.timestamp, style: .time)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 20)
                
                // Description
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.headline)
                    Text(alert.description)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 20)
                
                // Affected Resource
                VStack(alignment: .leading, spacing: 8) {
                    Text("Affected Resource")
                        .font(.headline)
                    
                    HStack {
                        Image(systemName: "server.rack")
                            .foregroundStyle(.blue)
                        Text(alert.affectedResource)
                            .font(.system(size: 13))
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.1))
                    )
                }
                .padding(.horizontal, 20)
                
                // Remediation
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recommended Action")
                        .font(.headline)
                    
                    Text(alert.remediation)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(nsColor: .textBackgroundColor))
                        )
                }
                .padding(.horizontal, 20)
                
                // Actions
                if alert.status == .open {
                    VStack(spacing: 8) {
                        Button(action: {
                            appModel.acknowledgeAlert(alert)
                        }) {
                            Label("Acknowledge Alert", systemImage: "checkmark.circle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        
                        Button(action: {
                            appModel.resolveAlert(alert)
                        }) {
                            Label("Mark as Resolved", systemImage: "checkmark.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                    .padding(.horizontal, 20)
                } else if alert.status == .acknowledged {
                    Button(action: {
                        appModel.resolveAlert(alert)
                    }) {
                        Label("Mark as Resolved", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.horizontal, 20)
                }
            }
            .padding(.bottom, 20)
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }
    
    var severityIcon: String {
        switch alert.severity {
        case .critical: return "exclamationmark.triangle.fill"
        case .high: return "exclamationmark.circle.fill"
        case .medium: return "info.circle.fill"
        case .low: return "checkmark.circle.fill"
        case .info: return "info.circle"
        }
    }
    
    var severityColor: Color {
        switch alert.severity {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .blue
        case .info: return .green
        }
    }
    
    var statusColor: Color {
        switch alert.status {
        case .open: return .orange
        case .acknowledged: return .blue
        case .resolved: return .green
        }
    }
}
