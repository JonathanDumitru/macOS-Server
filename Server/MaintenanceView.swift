//
//  MaintenanceView.swift
//  Server
//
//  Created by Claude on 1/28/26.
//

import SwiftUI
import SwiftData

struct MaintenanceView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MaintenanceWindow.scheduledStart, order: .reverse) private var allWindows: [MaintenanceWindow]

    @State private var showScheduleSheet = false
    @State private var selectedWindow: MaintenanceWindow?
    @State private var filterStatus: MaintenanceStatus?

    var filteredWindows: [MaintenanceWindow] {
        if let status = filterStatus {
            return allWindows.filter { $0.status == status }
        }
        return allWindows
    }

    var activeWindows: [MaintenanceWindow] {
        allWindows.filter { $0.status == .inProgress }
    }

    var upcomingWindows: [MaintenanceWindow] {
        allWindows.filter { $0.status == .scheduled }
            .sorted { $0.scheduledStart < $1.scheduledStart }
    }

    var body: some View {
        HSplitView {
            // List
            VStack(spacing: 0) {
                // Header
                headerView

                Divider()

                // Filters
                filterBar

                Divider()

                // Content
                if filteredWindows.isEmpty {
                    emptyState
                } else {
                    maintenanceList
                }
            }
            .frame(minWidth: 350, idealWidth: 400)

            // Detail
            if let window = selectedWindow {
                MaintenanceDetailView(window: window)
            } else {
                noSelectionView
            }
        }
        .sheet(isPresented: $showScheduleSheet) {
            ScheduleMaintenanceSheet()
        }
        .sheet(item: $selectedWindow) { window in
            MaintenanceDetailView(window: window)
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Maintenance Windows")
                    .font(.headline)

                HStack(spacing: 12) {
                    if !activeWindows.isEmpty {
                        Label("\(activeWindows.count) active", systemImage: "wrench.and.screwdriver")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }

                    Label("\(upcomingWindows.count) scheduled", systemImage: "calendar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button {
                showScheduleSheet = true
            } label: {
                Label("Schedule", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    // MARK: - Filters

    private var filterBar: some View {
        HStack(spacing: 12) {
            Picker("Status", selection: $filterStatus) {
                Text("All").tag(nil as MaintenanceStatus?)
                ForEach(MaintenanceStatus.allCases, id: \.self) { status in
                    Label(status.rawValue, systemImage: status.icon).tag(status as MaintenanceStatus?)
                }
            }
            .frame(width: 150)

            Spacer()

            Text("\(filteredWindows.count) windows")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - List

    private var maintenanceList: some View {
        List(selection: $selectedWindow) {
            // Active Section
            if !activeWindows.isEmpty {
                Section("Active Now") {
                    ForEach(activeWindows) { window in
                        MaintenanceRowView(window: window)
                            .tag(window)
                    }
                }
            }

            // Upcoming Section
            let upcoming = filteredWindows.filter { $0.status == .scheduled }
            if !upcoming.isEmpty {
                Section("Upcoming") {
                    ForEach(upcoming.sorted { $0.scheduledStart < $1.scheduledStart }) { window in
                        MaintenanceRowView(window: window)
                            .tag(window)
                    }
                }
            }

            // Past Section
            let past = filteredWindows.filter { $0.status == .completed || $0.status == .cancelled }
            if !past.isEmpty {
                Section("Past") {
                    ForEach(past.prefix(20)) { window in
                        MaintenanceRowView(window: window)
                            .tag(window)
                    }
                }
            }
        }
        .listStyle(.sidebar)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No Maintenance Windows")
                .font(.title3.bold())

            Text("Schedule maintenance to suppress alerts\nduring planned downtime")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Schedule Maintenance") {
                showScheduleSheet = true
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var noSelectionView: some View {
        VStack(spacing: 12) {
            Image(systemName: "sidebar.right")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Select a Maintenance Window")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text("Choose a window from the list to view details")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Maintenance Row

struct MaintenanceRowView: View {
    let window: MaintenanceWindow
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            // Status icon
            Image(systemName: window.status.icon)
                .font(.system(size: 16))
                .foregroundStyle(statusColor)
                .frame(width: 24)

            // Info
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(window.title)
                        .font(.system(size: 13, weight: .medium))
                        .lineLimit(1)

                    if window.isRecurring {
                        Image(systemName: "repeat")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }

                Text(window.serverName)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Time info
            VStack(alignment: .trailing, spacing: 2) {
                if window.status == .scheduled {
                    if let timeUntil = window.formattedTimeUntilStart {
                        Text(timeUntil)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.blue)
                    } else {
                        Text(window.scheduledStart, style: .date)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                } else if window.status == .inProgress {
                    Text("In Progress")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.orange)
                } else {
                    Text(window.scheduledStart, style: .date)
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }

                Text(window.formattedDuration)
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private var statusColor: Color {
        switch window.status.color {
        case "blue": return .blue
        case "orange": return .orange
        case "green": return .green
        case "gray": return .gray
        default: return .secondary
        }
    }
}

// MARK: - Detail View

struct MaintenanceDetailView: View {
    @Bindable var window: MaintenanceWindow
    @Environment(\.modelContext) private var modelContext
    @State private var completionNotes = ""
    @State private var showCompleteSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                headerSection

                Divider()

                // Schedule
                scheduleSection

                Divider()

                // Details
                detailsSection

                // Actions
                if window.status == .scheduled || window.status == .inProgress {
                    Divider()
                    actionsSection
                }

                Spacer()
            }
            .padding(20)
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .sheet(isPresented: $showCompleteSheet) {
            completeSheet
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: window.status.icon)
                    .font(.system(size: 24))
                    .foregroundStyle(statusColor)

                Text(window.title)
                    .font(.title2.bold())

                Spacer()

                MaintenanceStatusBadge(status: window.status)
            }

            Text(window.serverName)
                .font(.headline)
                .foregroundStyle(.secondary)

            if window.isRecurring, let pattern = window.recurrencePattern {
                Label(pattern.description, systemImage: "repeat")
                    .font(.caption)
                    .foregroundStyle(.blue)
            }
        }
    }

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Schedule")
                .font(.headline)

            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Start")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(window.scheduledStart, style: .date)
                        .font(.system(size: 14))
                    Text(window.scheduledStart, style: .time)
                        .font(.system(size: 14, weight: .medium))
                }

                Image(systemName: "arrow.right")
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 4) {
                    Text("End")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(window.scheduledEnd, style: .date)
                        .font(.system(size: 14))
                    Text(window.scheduledEnd, style: .time)
                        .font(.system(size: 14, weight: .medium))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Duration")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(window.formattedDuration)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                }
            }

            if let actualStart = window.actualStart {
                Divider()

                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Actually Started")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(actualStart, style: .time)
                            .font(.system(size: 14, weight: .medium))
                    }

                    if let actualEnd = window.actualEnd {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Actually Ended")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(actualEnd, style: .time)
                                .font(.system(size: 14, weight: .medium))
                        }
                    }
                }
            }
        }
    }

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details")
                .font(.headline)

            if let description = window.description_, !description.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Description")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(description)
                        .font(.body)
                }
            }

            if let notes = window.notes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(notes)
                        .font(.body)
                }
            }

            if let completionNotes = window.completionNotes, !completionNotes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Completion Notes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(completionNotes)
                        .font(.body)
                }
            }

            HStack {
                Text("Created")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(window.createdAt, style: .date)
                    .font(.caption)
            }
        }
    }

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Actions")
                .font(.headline)

            HStack(spacing: 12) {
                if window.status == .scheduled {
                    Button("Start Now") {
                        MaintenanceService.shared.startMaintenance(window)
                    }
                    .buttonStyle(.bordered)

                    Button("Cancel", role: .destructive) {
                        MaintenanceService.shared.cancelMaintenance(window)
                    }
                    .buttonStyle(.bordered)
                }

                if window.status == .inProgress {
                    Button("Complete") {
                        showCompleteSheet = true
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Cancel", role: .destructive) {
                        MaintenanceService.shared.cancelMaintenance(window)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    private var completeSheet: some View {
        VStack(spacing: 20) {
            Text("Complete Maintenance")
                .font(.title2.bold())

            VStack(alignment: .leading, spacing: 8) {
                Text("Completion Notes (Optional)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextEditor(text: $completionNotes)
                    .frame(height: 100)
                    .border(Color.gray.opacity(0.3))
            }

            HStack {
                Button("Cancel") {
                    showCompleteSheet = false
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Complete") {
                    MaintenanceService.shared.completeMaintenance(
                        window,
                        notes: completionNotes.isEmpty ? nil : completionNotes
                    )
                    showCompleteSheet = false
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 400)
    }

    private var statusColor: Color {
        switch window.status.color {
        case "blue": return .blue
        case "orange": return .orange
        case "green": return .green
        case "gray": return .gray
        default: return .secondary
        }
    }
}

// MARK: - Schedule Sheet

struct ScheduleMaintenanceSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Server.name) private var servers: [Server]

    @State private var selectedServer: Server?
    @State private var title = ""
    @State private var description = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(3600) // 1 hour default
    @State private var isRecurring = false
    @State private var recurrencePattern: RecurrencePattern = .weekly
    @State private var recurrenceInterval = 1
    @State private var notifyBeforeMinutes = 30
    @State private var notes = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Schedule Maintenance")
                    .font(.headline)
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            .padding()

            Divider()

            // Form
            Form {
                Section("Server") {
                    Picker("Server", selection: $selectedServer) {
                        Text("Select a server").tag(nil as Server?)
                        ForEach(servers) { server in
                            Text(server.name).tag(server as Server?)
                        }
                    }
                }

                Section("Details") {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("Schedule") {
                    DatePicker("Start", selection: $startDate)
                    DatePicker("End", selection: $endDate)

                    Picker("Reminder", selection: $notifyBeforeMinutes) {
                        Text("No reminder").tag(0)
                        Text("15 minutes before").tag(15)
                        Text("30 minutes before").tag(30)
                        Text("1 hour before").tag(60)
                        Text("1 day before").tag(1440)
                    }
                }

                Section("Recurrence") {
                    Toggle("Recurring", isOn: $isRecurring)

                    if isRecurring {
                        Picker("Pattern", selection: $recurrencePattern) {
                            ForEach(RecurrencePattern.allCases, id: \.self) { pattern in
                                Text(pattern.rawValue).tag(pattern)
                            }
                        }

                        Stepper("Every \(recurrenceInterval) \(recurrencePattern.rawValue.lowercased())", value: $recurrenceInterval, in: 1...12)
                    }
                }

                Section("Notes") {
                    TextField("Additional notes", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)

            Divider()

            // Footer
            HStack {
                Spacer()

                Button("Schedule") {
                    scheduleMaintenance()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(selectedServer == nil || title.isEmpty)
            }
            .padding()
        }
        .frame(width: 500, height: 600)
    }

    private func scheduleMaintenance() {
        guard let server = selectedServer else { return }

        let window = MaintenanceService.shared.scheduleMaintenance(
            for: server,
            title: title,
            description: description.isEmpty ? nil : description,
            startDate: startDate,
            endDate: endDate,
            isRecurring: isRecurring,
            recurrencePattern: isRecurring ? recurrencePattern : nil,
            recurrenceInterval: recurrenceInterval
        )

        window.notifyBeforeMinutes = notifyBeforeMinutes
        window.notes = notes.isEmpty ? nil : notes
    }
}

// MARK: - Supporting Views

struct MaintenanceStatusBadge: View {
    let status: MaintenanceStatus

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
        switch status.color {
        case "blue": return .blue
        case "orange": return .orange
        case "green": return .green
        case "gray": return .gray
        default: return .secondary
        }
    }
}

#Preview {
    MaintenanceView()
}
