//
//  ServicesView.swift
//  Server
//
//  Created by Claude on 1/28/26.
//

import SwiftUI

struct ServicesView: View {
    @State private var services: [ServiceItem] = ServiceItem.demoData
    @State private var selectedService: ServiceItem?
    @State private var searchText = ""
    @State private var statusFilter: ServiceStatus?

    var filteredServices: [ServiceItem] {
        var result = services

        if let status = statusFilter {
            result = result.filter { $0.status == status }
        }

        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.displayName.localizedCaseInsensitiveContains(searchText)
            }
        }

        return result.sorted { $0.displayName < $1.displayName }
    }

    var statusCounts: (running: Int, stopped: Int, disabled: Int) {
        let running = services.filter { $0.status == .running }.count
        let stopped = services.filter { $0.status == .stopped }.count
        let disabled = services.filter { $0.status == .disabled }.count
        return (running, stopped, disabled)
    }

    var body: some View {
        HSplitView {
            // Service List
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    HStack {
                        Text("Services")
                            .font(.title2.bold())
                        Spacer()
                        Text("\(filteredServices.count) services")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Status summary
                    HStack(spacing: 12) {
                        ServiceStatusCard(title: "Running", count: statusCounts.running, color: .green, isSelected: statusFilter == .running) {
                            statusFilter = statusFilter == .running ? nil : .running
                        }
                        ServiceStatusCard(title: "Stopped", count: statusCounts.stopped, color: .red, isSelected: statusFilter == .stopped) {
                            statusFilter = statusFilter == .stopped ? nil : .stopped
                        }
                        ServiceStatusCard(title: "Disabled", count: statusCounts.disabled, color: .gray, isSelected: statusFilter == .disabled) {
                            statusFilter = statusFilter == .disabled ? nil : .disabled
                        }
                    }
                }
                .padding()

                Divider()

                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search services...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                .background(Color(nsColor: .controlBackgroundColor))

                Divider()

                // Service list
                List(selection: $selectedService) {
                    ForEach(filteredServices) { service in
                        ServiceRow(service: service)
                            .tag(service)
                    }
                }
                .listStyle(.inset)
            }
            .frame(minWidth: 350, idealWidth: 400)

            // Detail Panel
            if let service = selectedService {
                ServiceDetailView(service: binding(for: service))
            } else {
                noSelectionView
            }
        }
    }

    private func binding(for service: ServiceItem) -> Binding<ServiceItem> {
        guard let index = services.firstIndex(where: { $0.id == service.id }) else {
            return .constant(service)
        }
        return $services[index]
    }

    private var noSelectionView: some View {
        VStack(spacing: 12) {
            Image(systemName: "gearshape.2")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Select a Service")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text("Choose a service to view details and manage")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Service Status Card

struct ServiceStatusCard: View {
    let title: String
    let count: Int
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("\(count)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(color)

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? color.opacity(0.15) : Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Service Row

struct ServiceRow: View {
    let service: ServiceItem

    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)

            // Icon
            Image(systemName: "gearshape.fill")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .frame(width: 20)

            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(service.displayName)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)

                Text(service.name)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            // Status badge
            Text(service.status.rawValue)
                .font(.system(size: 10, weight: .medium))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(statusColor.opacity(0.2))
                .foregroundStyle(statusColor)
                .clipShape(Capsule())
        }
        .padding(.vertical, 4)
    }

    private var statusColor: Color {
        switch service.status {
        case .running: return .green
        case .stopped: return .red
        case .starting, .stopping: return .orange
        case .disabled: return .gray
        }
    }
}

// MARK: - Service Detail View

struct ServiceDetailView: View {
    @Binding var service: ServiceItem
    @State private var isPerformingAction = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(statusColor.opacity(0.2))
                            .frame(width: 48, height: 48)

                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(statusColor)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(service.displayName)
                            .font(.title2.bold())

                        Text(service.name)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    ServiceStatusBadge(status: service.status)
                }

                Divider()

                // Description
                VStack(alignment: .leading, spacing: 4) {
                    Text("Description")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(service.description)
                        .font(.system(size: 13))
                }

                // Startup Type
                VStack(alignment: .leading, spacing: 4) {
                    Text("Startup Type")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Picker("Startup Type", selection: $service.startupType) {
                        ForEach(StartupType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 150)
                }

                // Dependencies
                if !service.dependencies.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Dependencies")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        ForEach(service.dependencies, id: \.self) { dep in
                            Label(dep, systemImage: "arrow.right.circle")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Divider()

                // Actions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Actions")
                        .font(.headline)

                    HStack(spacing: 12) {
                        if service.status == .running {
                            Button {
                                performAction(.stop)
                            } label: {
                                Label("Stop", systemImage: "stop.fill")
                            }
                            .buttonStyle(.bordered)
                            .disabled(isPerformingAction)

                            Button {
                                performAction(.restart)
                            } label: {
                                Label("Restart", systemImage: "arrow.clockwise")
                            }
                            .buttonStyle(.bordered)
                            .disabled(isPerformingAction)
                        } else if service.status == .stopped {
                            Button {
                                performAction(.start)
                            } label: {
                                Label("Start", systemImage: "play.fill")
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(isPerformingAction || service.status == .disabled)
                        }

                        if isPerformingAction {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }

                    if service.status == .disabled {
                        Text("Enable the service by changing the startup type to start it.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }
            .padding(20)
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var statusColor: Color {
        switch service.status {
        case .running: return .green
        case .stopped: return .red
        case .starting, .stopping: return .orange
        case .disabled: return .gray
        }
    }

    private func performAction(_ action: ServiceAction) {
        isPerformingAction = true

        // Simulate the action
        switch action {
        case .start:
            service.status = .starting
        case .stop:
            service.status = .stopping
        case .restart:
            service.status = .stopping
        }

        Task {
            try? await Task.sleep(for: .seconds(1.5))

            await MainActor.run {
                switch action {
                case .start:
                    service.status = .running
                case .stop:
                    service.status = .stopped
                case .restart:
                    service.status = .running
                }
                isPerformingAction = false
            }
        }
    }

    enum ServiceAction {
        case start, stop, restart
    }
}

// MARK: - Service Status Badge

struct ServiceStatusBadge: View {
    let status: ServiceStatus

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            Text(status.rawValue)
                .font(.system(size: 12, weight: .medium))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(statusColor.opacity(0.15))
        .clipShape(Capsule())
    }

    private var statusColor: Color {
        switch status {
        case .running: return .green
        case .stopped: return .red
        case .starting, .stopping: return .orange
        case .disabled: return .gray
        }
    }
}

// MARK: - Models

struct ServiceItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let displayName: String
    let description: String
    var status: ServiceStatus
    var startupType: StartupType
    let dependencies: [String]

    static let demoData: [ServiceItem] = [
        ServiceItem(name: "W3SVC", displayName: "World Wide Web Publishing Service", description: "Provides Web connectivity and administration through the Internet Information Services Manager.", status: .running, startupType: .automatic, dependencies: ["HTTP", "WAS"]),
        ServiceItem(name: "MSSQLSERVER", displayName: "SQL Server (MSSQLSERVER)", description: "Provides storage, processing and controlled access of data.", status: .running, startupType: .automatic, dependencies: []),
        ServiceItem(name: "WinRM", displayName: "Windows Remote Management", description: "Implements the WS-Management protocol for remote management.", status: .running, startupType: .automatic, dependencies: ["HTTP"]),
        ServiceItem(name: "DNS", displayName: "DNS Server", description: "Enables DNS name resolution for DNS clients.", status: .running, startupType: .automatic, dependencies: []),
        ServiceItem(name: "DHCP", displayName: "DHCP Server", description: "Performs TCP/IP configuration for DHCP clients.", status: .stopped, startupType: .manual, dependencies: []),
        ServiceItem(name: "Spooler", displayName: "Print Spooler", description: "Loads files to memory for later printing.", status: .running, startupType: .automatic, dependencies: []),
        ServiceItem(name: "TermService", displayName: "Remote Desktop Services", description: "Allows users to connect interactively to a remote computer.", status: .running, startupType: .automatic, dependencies: []),
        ServiceItem(name: "WSearch", displayName: "Windows Search", description: "Provides content indexing and property caching for file, email, and other content.", status: .stopped, startupType: .automatic, dependencies: []),
        ServiceItem(name: "BITS", displayName: "Background Intelligent Transfer Service", description: "Transfers files in the background using idle network bandwidth.", status: .running, startupType: .automatic, dependencies: []),
        ServiceItem(name: "Telnet", displayName: "Telnet", description: "Allows a remote user to log on to this computer and run programs.", status: .disabled, startupType: .disabled, dependencies: []),
        ServiceItem(name: "FTP", displayName: "FTP Publishing Service", description: "Enables FTP connections and administration.", status: .stopped, startupType: .manual, dependencies: ["W3SVC"]),
        ServiceItem(name: "SNMP", displayName: "SNMP Service", description: "Processes SNMP requests for this computer.", status: .disabled, startupType: .disabled, dependencies: []),
    ]
}

enum ServiceStatus: String, CaseIterable {
    case running = "Running"
    case stopped = "Stopped"
    case starting = "Starting"
    case stopping = "Stopping"
    case disabled = "Disabled"
}

enum StartupType: String, CaseIterable {
    case automatic = "Automatic"
    case manual = "Manual"
    case disabled = "Disabled"
}

#Preview {
    ServicesView()
}
