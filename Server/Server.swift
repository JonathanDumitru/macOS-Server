//
//  Server.swift
//  Server
//
//  Created by Jonathan Hines Dumitru on 1/13/26.
//

import Foundation
import SwiftData

@Model
final class Server {
    var id: UUID
    var name: String
    var host: String
    var port: Int
    var serverType: ServerType
    var status: ServerStatus
    var lastChecked: Date?
    var responseTime: Double? // in milliseconds
    var uptime: TimeInterval?
    var notes: String
    
    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \ServerMetric.server)
    var metrics: [ServerMetric] = []

    @Relationship(deleteRule: .cascade, inverse: \ServerLog.server)
    var logs: [ServerLog] = []

    // Group relationship (optional - server may not belong to a group)
    var group: ServerGroup?
    
    init(
        id: UUID = UUID(),
        name: String,
        host: String,
        port: Int,
        serverType: ServerType = .http,
        status: ServerStatus = .unknown,
        lastChecked: Date? = nil,
        responseTime: Double? = nil,
        uptime: TimeInterval? = nil,
        notes: String = ""
    ) {
        self.id = id
        self.name = name
        self.host = host
        self.port = port
        self.serverType = serverType
        self.status = status
        self.lastChecked = lastChecked
        self.responseTime = responseTime
        self.uptime = uptime
        self.notes = notes
    }
}

enum ServerType: String, Codable, CaseIterable {
    case http = "HTTP"
    case https = "HTTPS"
    case ftp = "FTP"
    case ssh = "SSH"
    case database = "Database"
    case custom = "Custom"
    
    var iconName: String {
        switch self {
        case .http, .https: return "globe"
        case .ftp: return "folder.fill"
        case .ssh: return "terminal.fill"
        case .database: return "cylinder.fill"
        case .custom: return "server.rack"
        }
    }
}

enum ServerStatus: String, Codable {
    case online = "Online"
    case offline = "Offline"
    case warning = "Warning"
    case unknown = "Unknown"
    
    var color: String {
        switch self {
        case .online: return "green"
        case .offline: return "red"
        case .warning: return "orange"
        case .unknown: return "gray"
        }
    }
}
