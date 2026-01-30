//
//  ImportView.swift
//  Server
//
//  Import servers from JSON, CSV, or SSH config files
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

enum ImportSource: String, CaseIterable {
    case json = "JSON"
    case csv = "CSV"
    case sshConfig = "SSH Config"

    var icon: String {
        switch self {
        case .json: return "doc.text"
        case .csv: return "tablecells"
        case .sshConfig: return "terminal"
        }
    }

    var fileDescription: String {
        switch self {
        case .json: return "Import from JSON file exported by Server Monitor"
        case .csv: return "Import from CSV spreadsheet"
        case .sshConfig: return "Import hosts from SSH config file (~/.ssh/config)"
        }
    }

    var allowedContentTypes: [UTType] {
        switch self {
        case .json: return [.json]
        case .csv: return [.commaSeparatedText]
        case .sshConfig: return [.plainText, .data]
        }
    }
}

struct ImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var existingServers: [Server]

    @State private var selectedSource: ImportSource = .json
    @State private var importedServers: [ImportedServer] = []
    @State private var selectedServers: Set<UUID> = []
    @State private var showingFilePicker = false
    @State private var importError: String?
    @State private var isImporting = false
    @State private var skipDuplicates = true

    var duplicateCount: Int {
        importedServers.filter { imported in
            existingServers.contains { $0.host == imported.host && $0.port == imported.port }
        }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "square.and.arrow.down")
                    .font(.title2)
                    .foregroundStyle(.blue)
                Text("Import Servers")
                    .font(.title2.bold())
                Spacer()
            }
            .padding()

            Divider()

            if importedServers.isEmpty {
                // Source Selection
                VStack(spacing: 20) {
                    Text("Select Import Source")
                        .font(.headline)

                    ForEach(ImportSource.allCases, id: \.self) { source in
                        ImportSourceButton(
                            source: source,
                            isSelected: selectedSource == source
                        ) {
                            selectedSource = source
                        }
                    }

                    if let error = importError {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            Text(error)
                                .foregroundStyle(.red)
                        }
                        .font(.caption)
                        .padding()
                        .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                    }

                    Spacer()

                    Button {
                        if selectedSource == .sshConfig {
                            loadSSHConfig()
                        } else {
                            showingFilePicker = true
                        }
                    } label: {
                        Label(
                            selectedSource == .sshConfig ? "Load SSH Config" : "Choose File",
                            systemImage: selectedSource == .sshConfig ? "terminal" : "folder"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.horizontal)
                }
                .padding()
            } else {
                // Import Preview
                VStack(spacing: 12) {
                    // Stats bar
                    HStack {
                        Label("\(importedServers.count) servers found", systemImage: "server.rack")
                            .font(.subheadline)

                        Spacer()

                        if duplicateCount > 0 {
                            Label("\(duplicateCount) duplicates", systemImage: "doc.on.doc")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }

                        Toggle("Skip duplicates", isOn: $skipDuplicates)
                            .toggleStyle(.checkbox)
                            .font(.caption)
                    }
                    .padding(.horizontal)

                    // Selection controls
                    HStack {
                        Button {
                            selectedServers = Set(importedServers.map { $0.id })
                        } label: {
                            Text("Select All")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                        Button {
                            selectedServers.removeAll()
                        } label: {
                            Text("Select None")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                        Spacer()

                        Text("\(selectedServers.count) selected")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)

                    Divider()

                    // Server list
                    List(importedServers, selection: $selectedServers) { server in
                        ImportedServerRow(
                            server: server,
                            isDuplicate: existingServers.contains { $0.host == server.host && $0.port == server.port }
                        )
                    }
                    .listStyle(.plain)
                }
            }

            Divider()

            // Actions
            HStack {
                if !importedServers.isEmpty {
                    Button("Back") {
                        importedServers.removeAll()
                        selectedServers.removeAll()
                        importError = nil
                    }
                }

                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)

                Spacer()

                if !importedServers.isEmpty {
                    Button {
                        performImport()
                    } label: {
                        if isImporting {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Text("Import \(selectedServers.count) Servers")
                        }
                    }
                    .keyboardShortcut(.return)
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedServers.isEmpty || isImporting)
                }
            }
            .padding()
        }
        .frame(width: 550, height: 500)
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: selectedSource.allowedContentTypes,
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
    }

    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            // Security-scoped resource access
            guard url.startAccessingSecurityScopedResource() else {
                importError = "Unable to access the selected file"
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }

            do {
                let data = try Data(contentsOf: url)
                parseFile(data: data, source: selectedSource)
            } catch {
                importError = "Failed to read file: \(error.localizedDescription)"
            }

        case .failure(let error):
            importError = "File selection failed: \(error.localizedDescription)"
        }
    }

    private func parseFile(data: Data, source: ImportSource) {
        importError = nil

        switch source {
        case .json:
            parseJSON(data)
        case .csv:
            parseCSV(data)
        case .sshConfig:
            // Not used for file picker
            break
        }
    }

    private func parseJSON(_ data: Data) {
        guard let servers = ExportService.shared.importFromJSON(data) else {
            importError = "Invalid JSON format. Make sure the file was exported from Server Monitor."
            return
        }

        importedServers = servers.map { ImportedServer(from: $0) }
        selectedServers = Set(importedServers.map { $0.id })
    }

    private func parseCSV(_ data: Data) {
        guard let servers = ExportService.shared.importFromCSV(data) else {
            importError = "Invalid CSV format. Expected columns: Name, Host, Port, Type, Status"
            return
        }

        importedServers = servers.map { ImportedServer(from: $0) }
        selectedServers = Set(importedServers.map { $0.id })
    }

    private func loadSSHConfig() {
        let configPath = NSHomeDirectory() + "/.ssh/config"
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: configPath) else {
            importError = "SSH config file not found at ~/.ssh/config"
            return
        }

        do {
            let content = try String(contentsOfFile: configPath, encoding: .utf8)
            parseSSHConfig(content)
        } catch {
            importError = "Failed to read SSH config: \(error.localizedDescription)"
        }
    }

    private func parseSSHConfig(_ content: String) {
        var servers: [ImportedServer] = []
        var currentHost: String?
        var currentHostname: String?
        var currentPort: Int = 22
        var currentUser: String?

        let lines = content.components(separatedBy: .newlines)

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Skip comments and empty lines
            guard !trimmed.isEmpty && !trimmed.hasPrefix("#") else { continue }

            let parts = trimmed.split(separator: " ", maxSplits: 1).map { String($0) }
            guard parts.count == 2 else { continue }

            let key = parts[0].lowercased()
            let value = parts[1].trimmingCharacters(in: .whitespaces)

            switch key {
            case "host":
                // Save previous host if exists
                if let host = currentHost {
                    let server = ImportedServer(
                        name: host,
                        host: currentHostname ?? host,
                        port: currentPort,
                        serverType: .ssh,
                        tags: "ssh,imported"
                    )
                    servers.append(server)
                }

                // Start new host
                currentHost = value
                currentHostname = nil
                currentPort = 22
                currentUser = nil

            case "hostname":
                currentHostname = value

            case "port":
                currentPort = Int(value) ?? 22

            case "user":
                currentUser = value

            default:
                break
            }
        }

        // Don't forget the last host
        if let host = currentHost {
            let server = ImportedServer(
                name: host,
                host: currentHostname ?? host,
                port: currentPort,
                serverType: .ssh,
                tags: "ssh,imported"
            )
            servers.append(server)
        }

        if servers.isEmpty {
            importError = "No hosts found in SSH config"
            return
        }

        importedServers = servers
        selectedServers = Set(servers.map { $0.id })
    }

    private func performImport() {
        isImporting = true

        let serversToImport = importedServers.filter { selectedServers.contains($0.id) }

        for imported in serversToImport {
            // Skip duplicates if option is enabled
            if skipDuplicates {
                let isDuplicate = existingServers.contains {
                    $0.host == imported.host && $0.port == imported.port
                }
                if isDuplicate { continue }
            }

            let server = Server(
                name: imported.name,
                host: imported.host,
                port: imported.port,
                serverType: imported.serverType
            )
            server.notes = imported.notes
            server.tags = imported.tags

            modelContext.insert(server)
        }

        isImporting = false
        dismiss()
    }
}

// MARK: - Import Source Button

struct ImportSourceButton: View {
    let source: ImportSource
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                Image(systemName: source.icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .white : .blue)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(source.rawValue)
                        .font(.headline)
                        .foregroundStyle(isSelected ? .white : .primary)

                    Text(source.fileDescription)
                        .font(.caption)
                        .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.blue : Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.clear : Color.secondary.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Imported Server Model

struct ImportedServer: Identifiable {
    let id = UUID()
    var name: String
    var host: String
    var port: Int
    var serverType: ServerType
    var notes: String
    var tags: String

    init(
        name: String,
        host: String,
        port: Int,
        serverType: ServerType,
        notes: String = "",
        tags: String = ""
    ) {
        self.name = name
        self.host = host
        self.port = port
        self.serverType = serverType
        self.notes = notes
        self.tags = tags
    }

    init(from exportable: ExportableServer) {
        self.name = exportable.name
        self.host = exportable.host
        self.port = exportable.port
        self.serverType = ServerType(rawValue: exportable.serverType) ?? .custom
        self.notes = exportable.notes
        self.tags = exportable.tags
    }
}

// MARK: - Imported Server Row

struct ImportedServerRow: View {
    let server: ImportedServer
    let isDuplicate: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: server.serverType.iconName)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(server.name)
                        .font(.subheadline.bold())

                    if isDuplicate {
                        Text("Duplicate")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.15), in: Capsule())
                    }
                }

                Text("\(server.host):\(server.port)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(server.serverType.rawValue)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
