//
//  ServerLog.swift
//  Server
//
//  Created by Jonathan Hines Dumitru on 1/13/26.
//

import Foundation
import SwiftData

@Model
final class ServerLog {
    var id: UUID
    var timestamp: Date
    var message: String
    var level: LogLevel
    
    var server: Server?
    
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        message: String,
        level: LogLevel = .info
    ) {
        self.id = id
        self.timestamp = timestamp
        self.message = message
        self.level = level
    }
}

enum LogLevel: String, Codable, CaseIterable {
    case info = "Info"
    case warning = "Warning"
    case error = "Error"
    case critical = "Critical"
    
    var iconName: String {
        switch self {
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        case .critical: return "exclamationmark.octagon.fill"
        }
    }
    
    var color: String {
        switch self {
        case .info: return "blue"
        case .warning: return "orange"
        case .error: return "red"
        case .critical: return "purple"
        }
    }
}
