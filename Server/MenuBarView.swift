//
//  MenuBarView.swift
//  Server
//
//  Created by Claude on 1/27/26.
//

import SwiftUI
import SwiftData

struct MenuBarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var servers: [Server]
    @Environment(\.openWindow) private var openWindow

    @State private var isMonitoring = false
    @State private var lastRefresh = Date()

    var onlineCount: Int {
        servers.filter { $0.status == .online }.count
    }

    var offlineCount: Int {
        servers.filter { $0.status == .offline }.count
    }

    var warningCount: Int {
        servers.filter { $0.status == .warning }.count
    }

    var overallStatus: OverallServerStatus {
        if servers.isEmpty { return .unknown }
        if offlineCount > 0 { return .hasOffline }
        if warningCount > 0 { return .hasWarning }
        if onlineCount == servers.count { return .allOnline }
        return .unknown
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "server.rack")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.blue)

                Text("Server Monitor")
                    .font(.system(size: 13, weight: .semibold))

                Spacer()

                // Overall status indicator
                Circle()
                    .fill(overallStatus.color)
                    .frame(width: 10, height: 10)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            // Quick Stats
            HStack(spacing: 16) {
                QuickStatView(count: onlineCount, label: "Online", color: .green)
                QuickStatView(count: offlineCount, label: "Offline", color: .red)
                QuickStatView(count: warningCount, label: "Warning", color: .orange)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))

            Divider()

            // Server List
            if servers.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "server.rack")
                        .font(.system(size: 24))
                        .foregroundStyle(.tertiary)
                    Text("No servers configured")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ScrollView {
                    VStack(spacing: 1) {
                        ForEach(servers.sorted(by: { serverSortOrder($0) < serverSortOrder($1) }).prefix(10)) { server in
                            MenuBarServerRow(server: server)
                        }

                        if servers.count > 10 {
                            Text("+ \(servers.count - 10) more servers")
                                .font(.system(size: 10))
                                .foregroundStyle(.tertiary)
                                .padding(.vertical, 8)
                        }
                    }
                }
                .frame(maxHeight: 300)
            }

            Divider()

            // Footer Actions
            VStack(spacing: 8) {
                // Last refresh time
                HStack {
                    Text("Last updated:")
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                    Text(lastRefresh, style: .time)
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.top, 6)

                // Action buttons
                HStack(spacing: 8) {
                    Button {
                        openMainWindow()
                    } label: {
                        Label("Open Dashboard", systemImage: "rectangle.expand.vertical")
                            .font(.system(size: 11))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Button {
                        NSApp.terminate(nil)
                    } label: {
                        Label("Quit", systemImage: "power")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 10)
            }
        }
        .frame(width: 280)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            lastRefresh = Date()
        }
    }

    private func serverSortOrder(_ server: Server) -> Int {
        switch server.status {
        case .offline: return 0
        case .warning: return 1
        case .unknown: return 2
        case .online: return 3
        }
    }

    private func openMainWindow() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        // Find and focus the main window
        for window in NSApplication.shared.windows {
            if window.title.contains("SERVER") || window.contentView != nil {
                window.makeKeyAndOrderFront(nil)
                break
            }
        }
    }
}

// MARK: - Overall Server Status

enum OverallServerStatus {
    case allOnline
    case hasWarning
    case hasOffline
    case unknown

    var color: Color {
        switch self {
        case .allOnline: return .green
        case .hasWarning: return .orange
        case .hasOffline: return .red
        case .unknown: return .gray
        }
    }
}

// MARK: - Quick Stat View

struct QuickStatView: View {
    let count: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Menu Bar Server Row

struct MenuBarServerRow: View {
    let server: Server

    var body: some View {
        HStack(spacing: 10) {
            // Status indicator
            Circle()
                .fill(Color(server.status.color))
                .frame(width: 8, height: 8)

            // Server info
            VStack(alignment: .leading, spacing: 1) {
                Text(server.name)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(server.host)
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)

                    if let responseTime = server.responseTime {
                        Text("•")
                            .foregroundStyle(.tertiary)
                        Text("\(Int(responseTime))ms")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Spacer()

            // Status badge
            Text(server.status.rawValue)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(Color(server.status.color))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(Color(server.status.color).opacity(0.15))
                )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Color(nsColor: .controlBackgroundColor)
                .opacity(server.status == .offline ? 0.8 : 0.3)
        )
    }
}

// MARK: - Compact Menu Bar View (Alternative Style)

struct CompactMenuBarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var servers: [Server]

    var onlineCount: Int {
        servers.filter { $0.status == .online }.count
    }

    var offlineCount: Int {
        servers.filter { $0.status == .offline }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Status summary
            HStack {
                Label("\(onlineCount) Online", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Spacer()
            }

            if offlineCount > 0 {
                Label("\(offlineCount) Offline", systemImage: "xmark.circle.fill")
                    .foregroundStyle(.red)
            }

            Divider()

            // Offline servers (if any)
            ForEach(servers.filter { $0.status == .offline }) { server in
                HStack {
                    Circle()
                        .fill(.red)
                        .frame(width: 6, height: 6)
                    Text(server.name)
                        .font(.system(size: 12))
                    Spacer()
                }
            }

            Divider()

            Button("Open Dashboard") {
                NSApplication.shared.activate(ignoringOtherApps: true)
            }

            Button("Quit") {
                NSApp.terminate(nil)
            }
        }
        .padding(8)
        .frame(width: 200)
    }
}

#Preview {
    MenuBarView()
        .modelContainer(for: Server.self, inMemory: true)
}
