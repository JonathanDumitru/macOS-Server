//
//  EventViewerView.swift
//  Server
//
//  Created by Claude on 1/28/26.
//

import SwiftUI
import SwiftData

struct EventViewerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ServerLog.timestamp, order: .reverse) private var allLogs: [ServerLog]

    @State private var selectedLevel: ServerLog.LogLevel?
    @State private var selectedServer: Server?
    @State private var searchText = ""
    @State private var selectedLog: ServerLog?
    @State private var dateFilter: DateFilter = .all

    enum DateFilter: String, CaseIterable {
        case all = "All Time"
        case today = "Today"
        case week = "This Week"
        case month = "This Month"

        var startDate: Date? {
            let calendar = Calendar.current
            switch self {
            case .all: return nil
            case .today: return calendar.startOfDay(for: Date())
            case .week: return calendar.date(byAdding: .day, value: -7, to: Date())
            case .month: return calendar.date(byAdding: .month, value: -1, to: Date())
            }
        }
    }

    var filteredLogs: [ServerLog] {
        var logs = allLogs

        // Filter by level
        if let level = selectedLevel {
            logs = logs.filter { $0.level == level }
        }

        // Filter by server
        if let server = selectedServer {
            logs = logs.filter { $0.server?.id == server.id }
        }

        // Filter by date
        if let startDate = dateFilter.startDate {
            logs = logs.filter { $0.timestamp >= startDate }
        }

        // Filter by search text
        if !searchText.isEmpty {
            logs = logs.filter {
                $0.message.localizedCaseInsensitiveContains(searchText) ||
                ($0.server?.name.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        return logs
    }

    var logCounts: (info: Int, warning: Int, error: Int) {
        let info = allLogs.filter { $0.level == .info }.count
        let warning = allLogs.filter { $0.level == .warning }.count
        let error = allLogs.filter { $0.level == .error }.count
        return (info, warning, error)
    }

    @Query private var servers: [Server]

    var body: some View {
        HSplitView {
            // Log List
            VStack(spacing: 0) {
                // Header with filters
                VStack(spacing: 12) {
                    HStack {
                        Text("Event Viewer")
                            .font(.title2.bold())
                        Spacer()
                        Text("\(filteredLogs.count) events")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Summary cards
                    HStack(spacing: 12) {
                        EventCountCard(title: "Info", count: logCounts.info, color: .blue, isSelected: selectedLevel == .info) {
                            selectedLevel = selectedLevel == .info ? nil : .info
                        }
                        EventCountCard(title: "Warning", count: logCounts.warning, color: .orange, isSelected: selectedLevel == .warning) {
                            selectedLevel = selectedLevel == .warning ? nil : .warning
                        }
                        EventCountCard(title: "Error", count: logCounts.error, color: .red, isSelected: selectedLevel == .error) {
                            selectedLevel = selectedLevel == .error ? nil : .error
                        }
                    }

                    // Filter bar
                    HStack(spacing: 12) {
                        Picker("Time", selection: $dateFilter) {
                            ForEach(DateFilter.allCases, id: \.self) { filter in
                                Text(filter.rawValue).tag(filter)
                            }
                        }
                        .frame(width: 120)

                        Picker("Server", selection: $selectedServer) {
                            Text("All Servers").tag(nil as Server?)
                            ForEach(servers) { server in
                                Text(server.name).tag(server as Server?)
                            }
                        }
                        .frame(width: 150)

                        Spacer()
                    }
                }
                .padding()

                Divider()

                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search events...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                .background(Color(nsColor: .controlBackgroundColor))

                Divider()

                // Log list
                if filteredLogs.isEmpty {
                    emptyState
                } else {
                    List(selection: $selectedLog) {
                        ForEach(filteredLogs) { log in
                            EventLogRow(log: log)
                                .tag(log)
                        }
                    }
                    .listStyle(.inset)
                }
            }
            .frame(minWidth: 400, idealWidth: 500)

            // Detail Panel
            if let log = selectedLog {
                EventDetailView(log: log)
            } else {
                noSelectionView
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No Events Found")
                .font(.title3.bold())

            Text("Adjust your filters or wait for\nnew events to be logged")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if selectedLevel != nil || selectedServer != nil || !searchText.isEmpty {
                Button("Clear Filters") {
                    selectedLevel = nil
                    selectedServer = nil
                    searchText = ""
                    dateFilter = .all
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var noSelectionView: some View {
        VStack(spacing: 12) {
            Image(systemName: "sidebar.right")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Select an Event")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text("Choose an event to view details")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Event Count Card

struct EventCountCard: View {
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

// MARK: - Event Log Row

struct EventLogRow: View {
    let log: ServerLog

    var body: some View {
        HStack(spacing: 12) {
            // Level indicator
            Circle()
                .fill(levelColor)
                .frame(width: 10, height: 10)

            // Icon
            Image(systemName: levelIcon)
                .font(.system(size: 14))
                .foregroundStyle(levelColor)
                .frame(width: 20)

            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(log.message)
                    .font(.system(size: 12))
                    .lineLimit(2)

                HStack(spacing: 8) {
                    if let server = log.server {
                        Text(server.name)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.blue)
                    }

                    Text(log.timestamp, style: .relative)
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var levelColor: Color {
        switch log.level {
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        }
    }

    private var levelIcon: String {
        switch log.level {
        case .info: return "info.circle"
        case .warning: return "exclamationmark.triangle"
        case .error: return "xmark.circle"
        }
    }
}

// MARK: - Event Detail View

struct EventDetailView: View {
    let log: ServerLog

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack(spacing: 12) {
                    Image(systemName: levelIcon)
                        .font(.system(size: 28))
                        .foregroundStyle(levelColor)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(log.level.rawValue.capitalized)
                            .font(.title2.bold())

                        if let server = log.server {
                            Text(server.name)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()
                }

                Divider()

                // Timestamp
                VStack(alignment: .leading, spacing: 4) {
                    Text("Timestamp")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(log.timestamp.formatted(date: .complete, time: .complete))
                        .font(.system(size: 13))
                }

                // Message
                VStack(alignment: .leading, spacing: 4) {
                    Text("Message")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(log.message)
                        .font(.system(size: 13))
                        .textSelection(.enabled)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                // Server Info
                if let server = log.server {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Server")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack {
                            Text(server.name)
                            Spacer()
                            Text("\(server.host):\(server.port)")
                                .foregroundStyle(.secondary)
                        }
                        .font(.system(size: 13))
                    }
                }

                Spacer()
            }
            .padding(20)
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var levelColor: Color {
        switch log.level {
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        }
    }

    private var levelIcon: String {
        switch log.level {
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        }
    }
}

#Preview {
    EventViewerView()
}
