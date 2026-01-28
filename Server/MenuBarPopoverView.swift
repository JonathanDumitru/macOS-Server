//
//  MenuBarPopoverView.swift
//  Server
//
//  Created by Claude on 1/27/26.
//

import SwiftUI
import SwiftData

struct MenuBarPopoverView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Server.name) private var servers: [Server]
    @State private var isRefreshing = false

    let modelContainer: ModelContainer

    var onlineServers: [Server] {
        servers.filter { $0.status == .online }
    }

    var offlineServers: [Server] {
        servers.filter { $0.status == .offline }
    }

    var warningServers: [Server] {
        servers.filter { $0.status == .warning }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
                .padding()

            Divider()

            // Server List
            if servers.isEmpty {
                emptyStateView
            } else {
                serverListView
            }

            Divider()

            // Footer
            footerView
                .padding(.horizontal)
                .padding(.vertical, 8)
        }
        .frame(width: 320, height: 400)
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Server Status")
                    .font(.system(size: 14, weight: .bold))

                Text(statusSummary)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Refresh button
            Button {
                refreshServers()
            } label: {
                Image(systemName: isRefreshing ? "arrow.triangle.2.circlepath" : "arrow.clockwise")
                    .font(.system(size: 14))
                    .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                    .animation(isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isRefreshing)
            }
            .buttonStyle(.plain)
            .disabled(isRefreshing)
        }
    }

    private var statusSummary: String {
        if servers.isEmpty {
            return "No servers configured"
        }

        var parts: [String] = []
        if !onlineServers.isEmpty {
            parts.append("\(onlineServers.count) online")
        }
        if !warningServers.isEmpty {
            parts.append("\(warningServers.count) warning")
        }
        if !offlineServers.isEmpty {
            parts.append("\(offlineServers.count) offline")
        }

        return parts.joined(separator: " • ")
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "server.rack")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)

            Text("No Servers")
                .font(.system(size: 14, weight: .medium))

            Text("Open the dashboard to add servers")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            Button("Open Dashboard") {
                openDashboard()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Server List

    private var serverListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Show offline servers first (most important)
                if !offlineServers.isEmpty {
                    sectionHeader(title: "Offline", count: offlineServers.count, color: .red)
                    ForEach(offlineServers) { server in
                        MenuBarServerRow(server: server)
                    }
                }

                // Then warning servers
                if !warningServers.isEmpty {
                    sectionHeader(title: "Warning", count: warningServers.count, color: .yellow)
                    ForEach(warningServers) { server in
                        MenuBarServerRow(server: server)
                    }
                }

                // Then online servers
                if !onlineServers.isEmpty {
                    sectionHeader(title: "Online", count: onlineServers.count, color: .green)
                    ForEach(onlineServers) { server in
                        MenuBarServerRow(server: server)
                    }
                }
            }
        }
    }

    private func sectionHeader(title: String, count: Int, color: Color) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)

            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)

            Text("(\(count))")
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.primary.opacity(0.03))
    }

    // MARK: - Footer

    private var footerView: some View {
        HStack {
            Button("Dashboard") {
                openDashboard()
            }
            .buttonStyle(.plain)
            .font(.system(size: 11))

            Spacer()

            if let lastChecked = servers.compactMap({ $0.lastChecked }).max() {
                Text("Updated \(lastChecked, style: .relative)")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: - Actions

    private func refreshServers() {
        isRefreshing = true
        NotificationCenter.default.post(name: .refreshAllServers, object: nil)

        // Reset the refreshing state after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isRefreshing = false
        }
    }

    private func openDashboard() {
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first(where: { $0.title.contains("Server") || $0.isMainWindow }) {
            window.makeKeyAndOrderFront(nil)
        }
    }
}

// MARK: - Server Row

struct MenuBarServerRow: View {
    let server: Server
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 10) {
            // Status indicator
            Circle()
                .fill(Color(server.status.color))
                .frame(width: 8, height: 8)

            // Server info
            VStack(alignment: .leading, spacing: 2) {
                Text(server.name)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)

                Text("\(server.host):\(server.port)")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Response time or status
            if let responseTime = server.responseTime, server.status == .online {
                Text("\(Int(responseTime))ms")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            } else if server.status == .offline {
                Text("Offline")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.red)
            } else if server.status == .warning {
                Text("Warning")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.yellow)
            }

            // SSL badge for HTTPS servers
            if server.serverType == .https {
                if let cert = server.sslCertificate {
                    Image(systemName: cert.expiryStatus.iconName)
                        .font(.system(size: 10))
                        .foregroundStyle(Color(cert.expiryStatus.color))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isHovered ? Color.primary.opacity(0.05) : Color.clear)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Preview

#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Server.self, configurations: config)
        return MenuBarPopoverView(modelContainer: container)
            .modelContainer(container)
    } catch {
        return Text("Preview Error: \(error.localizedDescription)")
            .foregroundStyle(.red)
            .frame(width: 280, height: 400)
    }
}
