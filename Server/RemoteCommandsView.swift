//
//  RemoteCommandsView.swift
//  Server
//
//  Created by Claude on 1/28/26.
//

import SwiftUI
import SwiftData

// MARK: - Command Template Model

@Model
final class CommandTemplate {
    var id: UUID
    var name: String
    var command: String
    var commandDescription: String
    var category: CommandCategory
    var isFavorite: Bool
    var usageCount: Int
    var lastUsed: Date?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        command: String,
        commandDescription: String = "",
        category: CommandCategory = .custom,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.name = name
        self.command = command
        self.commandDescription = commandDescription
        self.category = category
        self.isFavorite = isFavorite
        self.usageCount = 0
        self.lastUsed = nil
        self.createdAt = Date()
    }
}

enum CommandCategory: String, Codable, CaseIterable, Identifiable {
    case system = "System"
    case network = "Network"
    case disk = "Disk"
    case process = "Process"
    case service = "Service"
    case security = "Security"
    case custom = "Custom"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .system: return "desktopcomputer"
        case .network: return "network"
        case .disk: return "internaldrive"
        case .process: return "cpu"
        case .service: return "gearshape.2"
        case .security: return "lock.shield"
        case .custom: return "terminal"
        }
    }
}

// MARK: - Command Execution Result

struct CommandResult: Identifiable {
    let id = UUID()
    let serverId: UUID
    let serverName: String
    let command: String
    let output: String
    let exitCode: Int
    let startTime: Date
    let endTime: Date
    let isSuccess: Bool

    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
}

// MARK: - Command History

@Model
final class CommandHistory {
    var id: UUID
    var serverId: UUID
    var serverName: String
    var command: String
    var output: String
    var exitCode: Int
    var isSuccess: Bool
    var executedAt: Date
    var duration: Double

    init(
        id: UUID = UUID(),
        serverId: UUID,
        serverName: String,
        command: String,
        output: String,
        exitCode: Int,
        isSuccess: Bool,
        duration: Double
    ) {
        self.id = id
        self.serverId = serverId
        self.serverName = serverName
        self.command = command
        self.output = output
        self.exitCode = exitCode
        self.isSuccess = isSuccess
        self.executedAt = Date()
        self.duration = duration
    }
}

// MARK: - Remote Commands View

struct RemoteCommandsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var servers: [Server]
    @Query(sort: \CommandTemplate.usageCount, order: .reverse) private var templates: [CommandTemplate]
    @Query(sort: \CommandHistory.executedAt, order: .reverse) private var history: [CommandHistory]

    @State private var selectedServer: Server?
    @State private var command: String = ""
    @State private var isExecuting = false
    @State private var lastResult: CommandResult?
    @State private var showTemplateSheet = false
    @State private var selectedCategory: CommandCategory?

    var filteredTemplates: [CommandTemplate] {
        if let category = selectedCategory {
            return templates.filter { $0.category == category }
        }
        return templates
    }

    var body: some View {
        HSplitView {
            // Left Panel: Servers and Templates
            VStack(spacing: 0) {
                // Server Selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Target Server")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Picker("Server", selection: $selectedServer) {
                        Text("Select a server...").tag(nil as Server?)
                        ForEach(servers.filter { $0.status == .online }) { server in
                            HStack {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)
                                Text(server.name)
                            }
                            .tag(server as Server?)
                        }
                    }
                }
                .padding()

                Divider()

                // Command Templates
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Templates")
                            .font(.headline)
                        Spacer()
                        Button {
                            showTemplateSheet = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)
                    .padding(.top)

                    // Category filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            CategoryChip(
                                title: "All",
                                isSelected: selectedCategory == nil,
                                action: { selectedCategory = nil }
                            )

                            ForEach(CommandCategory.allCases) { category in
                                CategoryChip(
                                    title: category.rawValue,
                                    icon: category.icon,
                                    isSelected: selectedCategory == category,
                                    action: { selectedCategory = category }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                // Template List
                List {
                    ForEach(filteredTemplates) { template in
                        TemplateRow(template: template)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                command = template.command
                            }
                    }
                    .onDelete(perform: deleteTemplates)
                }
                .listStyle(.inset)
            }
            .frame(minWidth: 280, maxWidth: 350)

            // Right Panel: Command Execution
            VStack(spacing: 0) {
                // Command Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Command")
                        .font(.headline)

                    HStack {
                        Image(systemName: "terminal")
                            .foregroundStyle(.secondary)

                        TextField("Enter command...", text: $command, axis: .vertical)
                            .textFieldStyle(.plain)
                            .font(.system(.body, design: .monospaced))
                            .lineLimit(3)

                        Button {
                            executeCommand()
                        } label: {
                            Label("Execute", systemImage: "play.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(selectedServer == nil || command.isEmpty || isExecuting)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(nsColor: .textBackgroundColor))
                    )

                    HStack {
                        if isExecuting {
                            ProgressView()
                                .scaleEffect(0.7)
                            Text("Executing...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Menu("Quick Commands") {
                            Button("System Info") { command = "uname -a" }
                            Button("Disk Usage") { command = "df -h" }
                            Button("Memory Info") { command = "free -h" }
                            Button("CPU Info") { command = "lscpu" }
                            Button("Network Interfaces") { command = "ip addr" }
                            Button("Running Processes") { command = "ps aux | head -20" }
                            Button("Uptime") { command = "uptime" }
                        }
                    }
                }
                .padding()

                Divider()

                // Output Area
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Output")
                            .font(.headline)

                        Spacer()

                        if let result = lastResult {
                            HStack(spacing: 8) {
                                Image(systemName: result.isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundStyle(result.isSuccess ? .green : .red)
                                Text("Exit: \(result.exitCode)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(String(format: "%.2fs", result.duration))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    ScrollView {
                        if let result = lastResult {
                            Text(result.output)
                                .font(.system(.body, design: .monospaced))
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Text("Execute a command to see output here")
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(nsColor: .textBackgroundColor))
                    )
                }
                .padding()

                Divider()

                // History
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent Commands")
                        .font(.headline)

                    if history.isEmpty {
                        Text("No command history")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(history.prefix(10)) { item in
                                    HistoryChip(history: item) {
                                        command = item.command
                                        if let server = servers.first(where: { $0.id == item.serverId }) {
                                            selectedServer = server
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .sheet(isPresented: $showTemplateSheet) {
            AddTemplateSheet()
        }
    }

    private func executeCommand() {
        guard let server = selectedServer else { return }

        isExecuting = true
        let startTime = Date()
        let commandToExecute = command

        // Simulate command execution (in production, this would use SSH)
        Task {
            // Simulate network delay
            try? await Task.sleep(for: .seconds(Double.random(in: 0.5...2.0)))

            let result = await simulateCommandExecution(command: commandToExecute, server: server)

            await MainActor.run {
                let endTime = Date()
                lastResult = CommandResult(
                    serverId: server.id,
                    serverName: server.name,
                    command: commandToExecute,
                    output: result.output,
                    exitCode: result.exitCode,
                    startTime: startTime,
                    endTime: endTime,
                    isSuccess: result.exitCode == 0
                )

                // Save to history
                let historyItem = CommandHistory(
                    serverId: server.id,
                    serverName: server.name,
                    command: commandToExecute,
                    output: result.output,
                    exitCode: result.exitCode,
                    isSuccess: result.exitCode == 0,
                    duration: endTime.timeIntervalSince(startTime)
                )
                modelContext.insert(historyItem)

                isExecuting = false
            }
        }
    }

    private func simulateCommandExecution(command: String, server: Server) async -> (output: String, exitCode: Int) {
        // Simulated responses for demo purposes
        let simulations: [String: (String, Int)] = [
            "uname -a": ("Linux \(server.host) 5.15.0-91-generic #101-Ubuntu SMP x86_64 GNU/Linux", 0),
            "uptime": (" 14:32:45 up 45 days,  3:22,  2 users,  load average: 0.12, 0.08, 0.05", 0),
            "df -h": ("""
                Filesystem      Size  Used Avail Use% Mounted on
                /dev/sda1       100G   45G   55G  45% /
                /dev/sdb1       500G  234G  266G  47% /data
                tmpfs           16G   1.2G  15G   8% /dev/shm
                """, 0),
            "free -h": ("""
                              total        used        free      shared  buff/cache   available
                Mem:           32Gi       8.2Gi       4.1Gi       1.0Gi        20Gi        22Gi
                Swap:          8.0Gi       0.2Gi       7.8Gi
                """, 0),
            "ps aux | head -20": ("""
                USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
                root         1  0.0  0.0 168356  8844 ?        Ss   Jan10   0:15 /sbin/init
                root         2  0.0  0.0      0     0 ?        S    Jan10   0:00 [kthreadd]
                www-data  1234  0.2  1.5 458324 58432 ?        S    14:00   0:05 nginx: worker
                mysql     2345  2.1  5.2 1250000 210000 ?      Sl   Jan10  45:32 mysqld
                """, 0),
        ]

        if let result = simulations.first(where: { command.contains($0.key) }) {
            return result.value
        }

        // Generic response
        return ("Command executed successfully on \(server.name)\n\n[Simulated output for: \(command)]", 0)
    }

    private func deleteTemplates(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredTemplates[index])
        }
    }
}

// MARK: - Category Chip

struct CategoryChip: View {
    let title: String
    var icon: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 10))
                }
                Text(title)
                    .font(.system(size: 11, weight: .medium))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isSelected ? Color.blue : Color(nsColor: .controlBackgroundColor))
            )
            .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Template Row

struct TemplateRow: View {
    let template: CommandTemplate

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: template.category.icon)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(template.name)
                        .font(.system(size: 12, weight: .medium))

                    if template.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(.yellow)
                    }
                }

                Text(template.command)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if template.usageCount > 0 {
                Text("\(template.usageCount)x")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - History Chip

struct HistoryChip: View {
    let history: CommandHistory
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Circle()
                        .fill(history.isSuccess ? Color.green : Color.red)
                        .frame(width: 6, height: 6)
                    Text(history.serverName)
                        .font(.system(size: 10, weight: .medium))
                }

                Text(history.command)
                    .font(.system(size: 9, design: .monospaced))
                    .lineLimit(1)
                    .foregroundStyle(.secondary)

                Text(history.executedAt, style: .relative)
                    .font(.system(size: 8))
                    .foregroundStyle(.tertiary)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Add Template Sheet

struct AddTemplateSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var command: String = ""
    @State private var description: String = ""
    @State private var category: CommandCategory = .custom
    @State private var isFavorite: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Cancel") {
                    dismiss()
                }

                Spacer()

                Text("New Command Template")
                    .font(.headline)

                Spacer()

                Button("Save") {
                    saveTemplate()
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.isEmpty || command.isEmpty)
            }
            .padding()

            Divider()

            Form {
                Section("Template Info") {
                    TextField("Name", text: $name)
                    TextField("Description", text: $description)

                    Picker("Category", selection: $category) {
                        ForEach(CommandCategory.allCases) { cat in
                            Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                        }
                    }

                    Toggle("Favorite", isOn: $isFavorite)
                }

                Section("Command") {
                    TextEditor(text: $command)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 80)
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 450, height: 400)
    }

    private func saveTemplate() {
        let template = CommandTemplate(
            name: name,
            command: command,
            commandDescription: description,
            category: category,
            isFavorite: isFavorite
        )
        modelContext.insert(template)
        dismiss()
    }
}

// MARK: - Default Templates

extension CommandTemplate {
    static let defaultTemplates: [CommandTemplate] = [
        CommandTemplate(name: "System Info", command: "uname -a", commandDescription: "Display system information", category: .system),
        CommandTemplate(name: "Uptime", command: "uptime", commandDescription: "Show how long the system has been running", category: .system),
        CommandTemplate(name: "Disk Usage", command: "df -h", commandDescription: "Show disk space usage", category: .disk),
        CommandTemplate(name: "Memory Usage", command: "free -h", commandDescription: "Display memory usage", category: .system),
        CommandTemplate(name: "Top Processes", command: "ps aux --sort=-%cpu | head -10", commandDescription: "Show top CPU-consuming processes", category: .process),
        CommandTemplate(name: "Network Connections", command: "netstat -tuln", commandDescription: "Show active network connections", category: .network),
        CommandTemplate(name: "List Services", command: "systemctl list-units --type=service --state=running", commandDescription: "List running services", category: .service),
        CommandTemplate(name: "System Logs", command: "journalctl -n 50 --no-pager", commandDescription: "View recent system logs", category: .system),
        CommandTemplate(name: "Failed Services", command: "systemctl --failed", commandDescription: "List failed services", category: .service),
        CommandTemplate(name: "Last Logins", command: "last -n 10", commandDescription: "Show recent login activity", category: .security),
    ]
}

#Preview {
    RemoteCommandsView()
}
