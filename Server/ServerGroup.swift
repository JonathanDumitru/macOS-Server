//
//  ServerGroup.swift
//  Server
//
//  Created by Claude on 1/27/26.
//

import Foundation
import SwiftData
import SwiftUI

/// A group for organizing servers (e.g., Production, Staging, Development)
@Model
final class ServerGroup {
    var id: UUID
    var name: String
    var colorHex: String // Stored as hex string for SwiftData compatibility
    var iconName: String
    var sortOrder: Int
    var createdAt: Date

    // Relationship - servers in this group
    @Relationship(inverse: \Server.group)
    var servers: [Server] = []

    init(
        id: UUID = UUID(),
        name: String,
        colorHex: String = "007AFF", // Default blue
        iconName: String = "folder.fill",
        sortOrder: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.iconName = iconName
        self.sortOrder = sortOrder
        self.createdAt = createdAt
    }

    // Computed property for SwiftUI Color
    var color: Color {
        Color(hex: colorHex) ?? .blue
    }

    // Statistics
    var serverCount: Int {
        servers.count
    }

    var onlineCount: Int {
        servers.filter { $0.status == .online }.count
    }

    var offlineCount: Int {
        servers.filter { $0.status == .offline }.count
    }

    var warningCount: Int {
        servers.filter { $0.status == .warning }.count
    }

    var overallStatus: ServerStatus {
        if servers.isEmpty { return .unknown }
        if offlineCount > 0 { return .offline }
        if warningCount > 0 { return .warning }
        if onlineCount == servers.count { return .online }
        return .unknown
    }
}

/// A tag for labeling servers (more flexible than groups)
@Model
final class ServerTag {
    var id: UUID
    var name: String
    var colorHex: String

    init(
        id: UUID = UUID(),
        name: String,
        colorHex: String = "8E8E93" // Default gray
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
    }

    var color: Color {
        Color(hex: colorHex) ?? .gray
    }
}

// MARK: - Predefined Groups
extension ServerGroup {
    static func createDefaultGroups() -> [ServerGroup] {
        [
            ServerGroup(name: "Production", colorHex: "FF3B30", iconName: "server.rack", sortOrder: 0),
            ServerGroup(name: "Staging", colorHex: "FF9500", iconName: "testtube.2", sortOrder: 1),
            ServerGroup(name: "Development", colorHex: "34C759", iconName: "hammer.fill", sortOrder: 2),
            ServerGroup(name: "Internal", colorHex: "007AFF", iconName: "building.2.fill", sortOrder: 3)
        ]
    }
}

// MARK: - Predefined Tags
extension ServerTag {
    static func createDefaultTags() -> [ServerTag] {
        [
            ServerTag(name: "Critical", colorHex: "FF3B30"),
            ServerTag(name: "Database", colorHex: "5856D6"),
            ServerTag(name: "Web", colorHex: "007AFF"),
            ServerTag(name: "API", colorHex: "34C759"),
            ServerTag(name: "Cache", colorHex: "FF9500"),
            ServerTag(name: "Load Balancer", colorHex: "AF52DE")
        ]
    }
}

// MARK: - Color Extension for Hex Support
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        guard hexSanitized.count == 6 else { return nil }

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }

    func toHex() -> String? {
        guard let components = NSColor(self).cgColor.components, components.count >= 3 else {
            return nil
        }

        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)

        return String(format: "%02X%02X%02X", r, g, b)
    }
}
