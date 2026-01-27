//
//  ExportService.swift
//  Server
//
//  Export servers to JSON/CSV formats
//

import Foundation
import AppKit

enum ExportFormat: String, CaseIterable {
    case json = "JSON"
    case csv = "CSV"

    var fileExtension: String {
        switch self {
        case .json: return "json"
        case .csv: return "csv"
        }
    }

    var contentType: String {
        switch self {
        case .json: return "application/json"
        case .csv: return "text/csv"
        }
    }
}

struct ExportableServer: Codable {
    let name: String
    let host: String
    let port: Int
    let serverType: String
    let status: String
    let responseTime: Double?
    let lastChecked: Date?
    let notes: String
    let tags: String
    let groupName: String?
    let uptimePercentage: Double?
}

class ExportService {
    static let shared = ExportService()

    private init() {}

    // MARK: - Export Methods

    func exportServers(_ servers: [Server], format: ExportFormat, includeCredentials: Bool = false) -> Data? {
        switch format {
        case .json:
            return exportToJSON(servers)
        case .csv:
            return exportToCSV(servers)
        }
    }

    func exportToJSON(_ servers: [Server]) -> Data? {
        let exportable = servers.map { server in
            ExportableServer(
                name: server.name,
                host: server.host,
                port: server.port,
                serverType: server.serverType.rawValue,
                status: server.status.rawValue,
                responseTime: server.responseTime,
                lastChecked: server.lastChecked,
                notes: server.notes,
                tags: server.tags,
                groupName: server.group?.name,
                uptimePercentage: server.uptimePercentage
            )
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        return try? encoder.encode(exportable)
    }

    func exportToCSV(_ servers: [Server]) -> Data? {
        var csv = "Name,Host,Port,Type,Status,Response Time (ms),Last Checked,Tags,Group,Uptime %,Notes\n"

        let dateFormatter = ISO8601DateFormatter()

        for server in servers {
            let responseTime = server.responseTime.map { String(format: "%.0f", $0) } ?? ""
            let lastChecked = server.lastChecked.map { dateFormatter.string(from: $0) } ?? ""
            let uptime = server.uptimePercentage.map { String(format: "%.2f", $0) } ?? ""

            // Escape fields that might contain commas or quotes
            let escapedName = escapeCSVField(server.name)
            let escapedHost = escapeCSVField(server.host)
            let escapedNotes = escapeCSVField(server.notes)
            let escapedTags = escapeCSVField(server.tags)
            let escapedGroup = escapeCSVField(server.group?.name ?? "")

            csv += "\(escapedName),\(escapedHost),\(server.port),\(server.serverType.rawValue),\(server.status.rawValue),\(responseTime),\(lastChecked),\(escapedTags),\(escapedGroup),\(uptime),\(escapedNotes)\n"
        }

        return csv.data(using: .utf8)
    }

    private func escapeCSVField(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return field
    }

    // MARK: - Save to File

    func saveToFile(_ data: Data, format: ExportFormat, defaultName: String = "servers") {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.init(filenameExtension: format.fileExtension)!]
        savePanel.nameFieldStringValue = "\(defaultName).\(format.fileExtension)"
        savePanel.title = "Export Servers"
        savePanel.message = "Choose where to save the exported servers"

        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    try data.write(to: url)
                } catch {
                    print("Failed to save export: \(error)")
                }
            }
        }
    }

    // MARK: - Import Methods

    func importFromJSON(_ data: Data) -> [ExportableServer]? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode([ExportableServer].self, from: data)
    }

    func importFromCSV(_ data: Data) -> [ExportableServer]? {
        guard let csvString = String(data: data, encoding: .utf8) else { return nil }

        var servers: [ExportableServer] = []
        let lines = csvString.components(separatedBy: .newlines).filter { !$0.isEmpty }

        // Skip header
        for line in lines.dropFirst() {
            let fields = parseCSVLine(line)
            guard fields.count >= 5 else { continue }

            let server = ExportableServer(
                name: fields[0],
                host: fields[1],
                port: Int(fields[2]) ?? 80,
                serverType: fields[3],
                status: fields[4],
                responseTime: fields.count > 5 ? Double(fields[5]) : nil,
                lastChecked: fields.count > 6 ? ISO8601DateFormatter().date(from: fields[6]) : nil,
                notes: fields.count > 10 ? fields[10] : "",
                tags: fields.count > 7 ? fields[7] : "",
                groupName: fields.count > 8 && !fields[8].isEmpty ? fields[8] : nil,
                uptimePercentage: fields.count > 9 ? Double(fields[9]) : nil
            )
            servers.append(server)
        }

        return servers
    }

    private func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var currentField = ""
        var inQuotes = false

        for char in line {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                fields.append(currentField)
                currentField = ""
            } else {
                currentField.append(char)
            }
        }
        fields.append(currentField)

        return fields
    }
}
