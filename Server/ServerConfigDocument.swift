//
//  ServerConfigDocument.swift
//  Server
//
//  Created by Claude on 1/28/26.
//

import SwiftUI
import UniformTypeIdentifiers

/// Document type for exporting/importing server configurations
struct ServerConfigDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var servers: [ExportableServer]

    init(servers: [Server]) {
        self.servers = servers.map { ExportableServer(from: $0) }
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        servers = try decoder.decode([ExportableServer].self, from: data)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(servers)
        return FileWrapper(regularFileWithContents: data)
    }
}

/// Exportable representation of a Server
struct ExportableServer: Codable, Identifiable {
    var id: UUID
    var name: String
    var host: String
    var port: Int
    var serverType: String
    var notes: String?
    var groupName: String?
    var groupColor: String?
    var createdAt: Date

    init(from server: Server) {
        self.id = server.id
        self.name = server.name
        self.host = server.host
        self.port = server.port
        self.serverType = server.serverType.rawValue
        self.notes = server.notes
        self.groupName = server.group?.name
        self.groupColor = server.group?.color.rawValue
        self.createdAt = server.createdAt
    }

    func toServer() -> Server {
        let server = Server(
            name: name,
            host: host,
            port: port,
            serverType: ServerType(rawValue: serverType) ?? .https
        )
        server.notes = notes
        server.createdAt = createdAt
        return server
    }
}

// MARK: - Import Result

struct ImportResult {
    let imported: Int
    let skipped: Int
    let errors: [String]
}

// MARK: - Server Import/Export Service

@MainActor
class ServerImportExportService {
    static let shared = ServerImportExportService()

    private init() {}

    /// Import servers from JSON data
    func importServers(from data: Data, into context: ModelContext, existingServers: [Server]) throws -> ImportResult {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let exportedServers = try decoder.decode([ExportableServer].self, from: data)

        var imported = 0
        var skipped = 0
        var errors: [String] = []

        for exportedServer in exportedServers {
            // Check for duplicates by host:port combination
            let isDuplicate = existingServers.contains { existing in
                existing.host == exportedServer.host && existing.port == exportedServer.port
            }

            if isDuplicate {
                skipped += 1
                continue
            }

            do {
                let server = exportedServer.toServer()
                context.insert(server)
                imported += 1
            } catch {
                errors.append("Failed to import '\(exportedServer.name)': \(error.localizedDescription)")
            }
        }

        try context.save()

        return ImportResult(imported: imported, skipped: skipped, errors: errors)
    }

    /// Export servers to JSON data
    func exportServers(_ servers: [Server]) throws -> Data {
        let exportable = servers.map { ExportableServer(from: $0) }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        return try encoder.encode(exportable)
    }
}
