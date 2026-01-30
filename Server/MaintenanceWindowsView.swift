//
//  MaintenanceWindowsView.swift
//  Server
//
//  UI for managing maintenance windows
//

import SwiftUI
import SwiftData

struct MaintenanceWindowsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MaintenanceWindow.startDate) private var windows: [MaintenanceWindow]
    @Query private var servers: [Server]

    @State private var showingAddWindow = false
    @State private var selectedWindow: MaintenanceWindow?

    var activeWindows: [MaintenanceWindow] {
        windows.filter { $0.isActive }
    }

    var scheduledWindows: [MaintenanceWindow] {
        windows.filter { !$0.isActive && $0.isEnabled && Date() < $0.startDate }
    }

    var pastWindows: [MaintenanceWindow] {
        windows.filter { !$0.isActive && !$0.isRecurring && Date() > $0.endDate }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("Maintenance Windows")
                        .font(.title2.bold())
                    Text("Schedule periods when alerts are silenced")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    showingAddWindow = true
                } label: {
                    Label("Add Window", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()

            Divider()

            if windows.isEmpty {
                ContentUnavailableView(
                    "No Maintenance Windows",
                    systemImage: "calendar.badge.clock",
                    description: Text("Create a maintenance window to silence alerts during planned downtime")
                )
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Active Windows
                        if !activeWindows.isEmpty {
                            WindowSection(
                                title: "Active Now",
                                icon: "exclamationmark.circle.fill",
                                color: .orange,
                                windows: activeWindows,
                                onEdit: { selectedWindow = $0 },
                                onDelete: deleteWindow
                            )
                        }

                        // Scheduled Windows
                        if !scheduledWindows.isEmpty {
                            WindowSection(
                                title: "Scheduled",
                                icon: "calendar.badge.clock",
                                color: .blue,
                                windows: scheduledWindows,
                                onEdit: { selectedWindow = $0 },
                                onDelete: deleteWindow
                            )
                        }

                        // Past/Recurring Windows
                        let recurringWindows = windows.filter { $0.isRecurring && !$0.isActive }
                        if !recurringWindows.isEmpty {
                            WindowSection(
                                title: "Recurring",
                                icon: "arrow.clockwise",
                                color: .purple,
                                windows: recurringWindows,
                                onEdit: { selectedWindow = $0 },
                                onDelete: deleteWindow
                            )
                        }

                        // Past Windows (non-recurring, completed)
                        if !pastWindows.isEmpty {
                            WindowSection(
                                title: "Completed",
                                icon: "checkmark.circle",
                                color: .green,
                                windows: pastWindows,
                                onEdit: { selectedWindow = $0 },
                                onDelete: deleteWindow
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showingAddWindow) {
            AddMaintenanceWindowView(servers: servers)
        }
        .sheet(item: $selectedWindow) { window in
            EditMaintenanceWindowView(window: window, servers: servers)
        }
    }

    private func deleteWindow(_ window: MaintenanceWindow) {
        modelContext.delete(window)
    }
}

// MARK: - Window Section

struct WindowSection: View {
    let title: String
    let icon: String
    let color: Color
    let windows: [MaintenanceWindow]
    let onEdit: (MaintenanceWindow) -> Void
    let onDelete: (MaintenanceWindow) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.headline)
                Text("(\(windows.count))")
                    .foregroundStyle(.secondary)
            }

            ForEach(windows) { window in
                MaintenanceWindowCard(
                    window: window,
                    onEdit: { onEdit(window) },
                    onDelete: { onDelete(window) }
                )
            }
        }
    }
}

// MARK: - Window Card

struct MaintenanceWindowCard: View {
    let window: MaintenanceWindow
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var showingDeleteConfirm = false

    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(window.statusColor)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(window.name)
                        .font(.subheadline.bold())

                    if window.isRecurring {
                        Label(window.recurrenceType.rawValue, systemImage: window.recurrenceType.icon)
                            .font(.caption)
                            .foregroundStyle(.purple)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.purple.opacity(0.1), in: Capsule())
                    }

                    Spacer()

                    Text(window.statusText)
                        .font(.caption)
                        .foregroundStyle(window.statusColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(window.statusColor.opacity(0.1), in: Capsule())
                }

                HStack {
                    if let server = window.server {
                        Label(server.name, systemImage: "server.rack")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Label("All Servers", systemImage: "globe")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }

                    Text("•")
                        .foregroundStyle(.tertiary)

                    Text(window.durationText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Image(systemName: "clock")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    if window.isRecurring {
                        Text("\(window.startDate.formatted(date: .omitted, time: .shortened)) - \(window.endDate.formatted(date: .omitted, time: .shortened))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("\(window.startDate.formatted()) - \(window.endDate.formatted())")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Actions
            HStack(spacing: 8) {
                Button {
                    onEdit()
                } label: {
                    Image(systemName: "pencil")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button {
                    showingDeleteConfirm = true
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(.red)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .alert("Delete Maintenance Window?", isPresented: $showingDeleteConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("This will permanently delete \"\(window.name)\".")
        }
    }
}

// MARK: - Add Maintenance Window

struct AddMaintenanceWindowView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let servers: [Server]

    @State private var name = ""
    @State private var windowDescription = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(3600) // 1 hour from now
    @State private var isRecurring = false
    @State private var recurrenceType: RecurrenceType = .daily
    @State private var selectedServer: Server?
    @State private var isGlobal = true

    var isValid: Bool {
        !name.isEmpty && endDate > startDate
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "calendar.badge.plus")
                    .font(.title2)
                    .foregroundStyle(.blue)
                Text("Add Maintenance Window")
                    .font(.title2.bold())
                Spacer()
            }
            .padding()

            Divider()

            Form {
                Section("Window Details") {
                    TextField("Name", text: $name)
                    TextField("Description (optional)", text: $windowDescription)
                }

                Section("Schedule") {
                    DatePicker("Start", selection: $startDate)
                    DatePicker("End", selection: $endDate)

                    if endDate <= startDate {
                        Text("End time must be after start time")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                Section("Recurrence") {
                    Toggle("Recurring", isOn: $isRecurring)

                    if isRecurring {
                        Picker("Repeat", selection: $recurrenceType) {
                            ForEach(RecurrenceType.allCases.filter { $0 != .none }, id: \.self) { type in
                                Label(type.rawValue, systemImage: type.icon).tag(type)
                            }
                        }
                    }
                }

                Section("Scope") {
                    Toggle("Apply to all servers", isOn: $isGlobal)

                    if !isGlobal {
                        Picker("Server", selection: $selectedServer) {
                            Text("Select a server").tag(nil as Server?)
                            ForEach(servers) { server in
                                Text(server.name).tag(server as Server?)
                            }
                        }
                    }
                }
            }
            .formStyle(.grouped)

            Divider()

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)

                Spacer()

                Button("Add Window") {
                    addWindow()
                }
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
                .disabled(!isValid)
            }
            .padding()
        }
        .frame(width: 450, height: 550)
    }

    private func addWindow() {
        let window = MaintenanceWindow(
            name: name,
            windowDescription: windowDescription,
            startDate: startDate,
            endDate: endDate,
            isRecurring: isRecurring,
            recurrenceType: isRecurring ? recurrenceType : .none,
            server: isGlobal ? nil : selectedServer
        )
        modelContext.insert(window)
        dismiss()
    }
}

// MARK: - Edit Maintenance Window

struct EditMaintenanceWindowView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var window: MaintenanceWindow
    let servers: [Server]

    @State private var isGlobal: Bool
    @State private var selectedServer: Server?

    init(window: MaintenanceWindow, servers: [Server]) {
        self.window = window
        self.servers = servers
        self._isGlobal = State(initialValue: window.server == nil)
        self._selectedServer = State(initialValue: window.server)
    }

    var isValid: Bool {
        !window.name.isEmpty && window.endDate > window.startDate
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .font(.title2)
                    .foregroundStyle(.blue)
                Text("Edit Maintenance Window")
                    .font(.title2.bold())
                Spacer()
            }
            .padding()

            Divider()

            Form {
                Section("Window Details") {
                    TextField("Name", text: $window.name)
                    TextField("Description", text: $window.windowDescription)

                    Toggle("Enabled", isOn: $window.isEnabled)
                }

                Section("Schedule") {
                    DatePicker("Start", selection: $window.startDate)
                    DatePicker("End", selection: $window.endDate)

                    if window.endDate <= window.startDate {
                        Text("End time must be after start time")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                Section("Recurrence") {
                    Toggle("Recurring", isOn: $window.isRecurring)

                    if window.isRecurring {
                        Picker("Repeat", selection: $window.recurrenceType) {
                            ForEach(RecurrenceType.allCases.filter { $0 != .none }, id: \.self) { type in
                                Label(type.rawValue, systemImage: type.icon).tag(type)
                            }
                        }
                    }
                }

                Section("Scope") {
                    Toggle("Apply to all servers", isOn: $isGlobal)
                        .onChange(of: isGlobal) { _, newValue in
                            window.server = newValue ? nil : selectedServer
                        }

                    if !isGlobal {
                        Picker("Server", selection: $selectedServer) {
                            Text("Select a server").tag(nil as Server?)
                            ForEach(servers) { server in
                                Text(server.name).tag(server as Server?)
                            }
                        }
                        .onChange(of: selectedServer) { _, newValue in
                            window.server = newValue
                        }
                    }
                }
            }
            .formStyle(.grouped)

            Divider()

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)

                Spacer()

                Button("Save Changes") {
                    dismiss()
                }
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
                .disabled(!isValid)
            }
            .padding()
        }
        .frame(width: 450, height: 550)
    }
}
