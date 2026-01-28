//
//  IncidentTimelineView.swift
//  Server
//
//  Created by Claude on 1/28/26.
//

import SwiftUI
import SwiftData

struct IncidentTimelineView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Incident.startedAt, order: .reverse) private var incidents: [Incident]

    @State private var filterType: IncidentType?
    @State private var filterStatus: IncidentStatus?
    @State private var filterServer: UUID?
    @State private var dateRange: DateRange = .week
    @State private var selectedIncident: Incident?

    enum DateRange: String, CaseIterable {
        case day = "24 Hours"
        case week = "7 Days"
        case month = "30 Days"
        case all = "All Time"

        var date: Date? {
            switch self {
            case .day: return Calendar.current.date(byAdding: .day, value: -1, to: Date())
            case .week: return Calendar.current.date(byAdding: .day, value: -7, to: Date())
            case .month: return Calendar.current.date(byAdding: .day, value: -30, to: Date())
            case .all: return nil
            }
        }
    }

    var filteredIncidents: [Incident] {
        incidents.filter { incident in
            // Date filter
            if let startDate = dateRange.date, incident.startedAt < startDate {
                return false
            }

            // Type filter
            if let type = filterType, incident.type != type {
                return false
            }

            // Status filter
            if let status = filterStatus, incident.status != status {
                return false
            }

            // Server filter
            if let serverId = filterServer, incident.serverId != serverId {
                return false
            }

            return true
        }
    }

    var activeCount: Int {
        incidents.filter { $0.status == .active }.count
    }

    var resolvedToday: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return incidents.filter { incident in
            guard let resolved = incident.resolvedAt else { return false }
            return resolved >= today
        }.count
    }

    var body: some View {
        HSplitView {
            // Timeline List
            VStack(spacing: 0) {
                // Stats Header
                statsHeader

                Divider()

                // Filters
                filtersBar

                Divider()

                // Timeline
                if filteredIncidents.isEmpty {
                    emptyState
                } else {
                    timelineList
                }
            }
            .frame(minWidth: 350, idealWidth: 400)

            // Detail View
            if let incident = selectedIncident {
                IncidentDetailView(incident: incident)
            } else {
                noSelectionView
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - Stats Header

    private var statsHeader: some View {
        HStack(spacing: 20) {
            StatBox(
                title: "Active",
                value: "\(activeCount)",
                color: activeCount > 0 ? .red : .green
            )

            StatBox(
                title: "Resolved Today",
                value: "\(resolvedToday)",
                color: .blue
            )

            StatBox(
                title: "Total",
                value: "\(filteredIncidents.count)",
                color: .secondary
            )

            Spacer()
        }
        .padding()
    }

    // MARK: - Filters

    private var filtersBar: some View {
        HStack(spacing: 12) {
            Picker("Time", selection: $dateRange) {
                ForEach(DateRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .frame(width: 100)

            Picker("Type", selection: $filterType) {
                Text("All Types").tag(nil as IncidentType?)
                ForEach(IncidentType.allCases, id: \.self) { type in
                    Label(type.rawValue, systemImage: type.icon).tag(type as IncidentType?)
                }
            }
            .frame(width: 150)

            Picker("Status", selection: $filterStatus) {
                Text("All Statuses").tag(nil as IncidentStatus?)
                ForEach(IncidentStatus.allCases, id: \.self) { status in
                    Text(status.rawValue).tag(status as IncidentStatus?)
                }
            }
            .frame(width: 120)

            Spacer()

            Button("Clear Filters") {
                filterType = nil
                filterStatus = nil
                filterServer = nil
                dateRange = .week
            }
            .buttonStyle(.plain)
            .foregroundStyle(.blue)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - Timeline List

    private var timelineList: some View {
        List(selection: $selectedIncident) {
            ForEach(groupedByDate, id: \.date) { group in
                Section {
                    ForEach(group.incidents) { incident in
                        IncidentRowView(incident: incident)
                            .tag(incident)
                    }
                } header: {
                    Text(group.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .listStyle(.sidebar)
    }

    private var groupedByDate: [(date: Date, title: String, incidents: [Incident])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredIncidents) { incident in
            calendar.startOfDay(for: incident.startedAt)
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium

        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        return grouped.map { (date, incidents) in
            let title: String
            if date == today {
                title = "Today"
            } else if date == yesterday {
                title = "Yesterday"
            } else {
                title = formatter.string(from: date)
            }
            return (date: date, title: title, incidents: incidents.sorted { $0.startedAt > $1.startedAt })
        }.sorted { $0.date > $1.date }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.shield")
                .font(.system(size: 48))
                .foregroundStyle(.green)

            Text("No Incidents")
                .font(.title2.bold())

            Text("All systems operating normally")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var noSelectionView: some View {
        VStack(spacing: 12) {
            Image(systemName: "sidebar.right")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Select an Incident")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text("Choose an incident from the list to view details")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Incident Row

struct IncidentRowView: View {
    let incident: Incident
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)

            // Icon
            Image(systemName: incident.type.icon)
                .font(.system(size: 16))
                .foregroundStyle(typeColor)
                .frame(width: 24)

            // Content
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(incident.title)
                        .font(.system(size: 13, weight: .medium))
                        .lineLimit(1)

                    if incident.status == .active {
                        Text("ACTIVE")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.red)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                    }
                }

                Text(incident.serverName)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Time and duration
            VStack(alignment: .trailing, spacing: 2) {
                Text(incident.startedAt, style: .time)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)

                if incident.status != .resolved {
                    Text(incident.formattedDuration)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.orange)
                } else {
                    Text(incident.formattedDuration)
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 4)
        .background(isHovered ? Color.primary.opacity(0.05) : Color.clear)
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private var statusColor: Color {
        switch incident.status {
        case .active: return .red
        case .acknowledged: return .orange
        case .resolved: return .green
        }
    }

    private var typeColor: Color {
        switch incident.type.color {
        case "red": return .red
        case "orange": return .orange
        case "green": return .green
        case "blue": return .blue
        default: return .gray
        }
    }
}

// MARK: - Incident Detail View

struct IncidentDetailView: View {
    @Bindable var incident: Incident
    @Environment(\.modelContext) private var modelContext
    @State private var resolutionNote = ""
    @State private var showResolveSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                headerSection

                Divider()

                // Timeline
                timelineSection

                Divider()

                // Details
                detailsSection

                // Actions
                if incident.status != .resolved {
                    Divider()
                    actionsSection
                }

                Spacer()
            }
            .padding(20)
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .sheet(isPresented: $showResolveSheet) {
            resolveSheet
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: incident.type.icon)
                    .font(.system(size: 24))
                    .foregroundStyle(typeColor)

                Text(incident.title)
                    .font(.title2.bold())

                Spacer()

                StatusBadge(status: incident.status)
            }

            Text(incident.serverName)
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(incident.serverHost)
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
    }

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Timeline")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                TimelineItem(
                    icon: "exclamationmark.circle.fill",
                    color: .red,
                    title: "Started",
                    time: incident.startedAt
                )

                if let ackTime = incident.acknowledgedAt {
                    TimelineItem(
                        icon: "eye.fill",
                        color: .orange,
                        title: "Acknowledged by \(incident.acknowledgedBy ?? "User")",
                        time: ackTime
                    )
                }

                if let resolveTime = incident.resolvedAt {
                    TimelineItem(
                        icon: "checkmark.circle.fill",
                        color: .green,
                        title: "Resolved",
                        time: resolveTime
                    )
                }
            }
        }
    }

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details")
                .font(.headline)

            DetailRow(label: "Type", value: incident.type.rawValue)
            DetailRow(label: "Severity", value: incident.severity.rawValue)
            DetailRow(label: "Duration", value: incident.formattedDuration)

            if let description = incident.incidentDescription {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Description")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(description)
                        .font(.body)
                }
            }

            if let resolution = incident.resolution {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Resolution")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(resolution)
                        .font(.body)
                }
            }
        }
    }

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Actions")
                .font(.headline)

            HStack(spacing: 12) {
                if incident.status == .active {
                    Button("Acknowledge") {
                        IncidentService.shared.acknowledgeIncident(incident)
                    }
                    .buttonStyle(.bordered)
                }

                Button("Resolve") {
                    showResolveSheet = true
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private var resolveSheet: some View {
        VStack(spacing: 20) {
            Text("Resolve Incident")
                .font(.title2.bold())

            VStack(alignment: .leading, spacing: 8) {
                Text("Resolution Note")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextEditor(text: $resolutionNote)
                    .frame(height: 100)
                    .border(Color.gray.opacity(0.3))
            }

            HStack {
                Button("Cancel") {
                    showResolveSheet = false
                }
                .keyboardShortcut(.cancelAction)

                Button("Resolve") {
                    IncidentService.shared.resolveIncident(incident, resolution: resolutionNote.isEmpty ? nil : resolutionNote)
                    showResolveSheet = false
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 400)
    }

    private var typeColor: Color {
        switch incident.type.color {
        case "red": return .red
        case "orange": return .orange
        case "green": return .green
        case "blue": return .blue
        default: return .gray
        }
    }
}

// MARK: - Supporting Views

struct StatBox: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
    }
}

struct StatusBadge: View {
    let status: IncidentStatus

    var body: some View {
        Text(status.rawValue)
            .font(.system(size: 11, weight: .semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .foregroundStyle(.white)
            .clipShape(Capsule())
    }

    private var backgroundColor: Color {
        switch status {
        case .active: return .red
        case .acknowledged: return .orange
        case .resolved: return .green
        }
    }
}

struct TimelineItem: View {
    let icon: String
    let color: Color
    let title: String
    let time: Date

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13))
                Text(time, style: .date) + Text(" at ") + Text(time, style: .time)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .leading)
            Text(value)
                .font(.system(size: 13))
        }
    }
}

#Preview {
    IncidentTimelineView()
}
