//
//  ServerGroup.swift
//  Server
//
//  Created by Claude on 1/26/26.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class ServerGroup {
    var id: UUID
    var name: String
    var colorHex: String
    var icon: String
    var sortOrder: Int
    var createdAt: Date

    @Relationship(inverse: \Server.group)
    var servers: [Server] = []

    init(
        id: UUID = UUID(),
        name: String,
        colorHex: String = "#007AFF",
        icon: String = "folder.fill",
        sortOrder: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.icon = icon
        self.sortOrder = sortOrder
        self.createdAt = createdAt
    }

    var color: Color {
        Color(hex: colorHex) ?? .blue
    }
}

// MARK: - Predefined Group Colors

enum GroupColor: String, CaseIterable, Identifiable {
    case blue = "#007AFF"
    case green = "#34C759"
    case orange = "#FF9500"
    case red = "#FF3B30"
    case purple = "#AF52DE"
    case pink = "#FF2D55"
    case teal = "#5AC8FA"
    case indigo = "#5856D6"
    case mint = "#00C7BE"
    case brown = "#A2845E"

    var id: String { rawValue }

    var color: Color {
        Color(hex: rawValue) ?? .blue
    }

    var name: String {
        switch self {
        case .blue: return "Blue"
        case .green: return "Green"
        case .orange: return "Orange"
        case .red: return "Red"
        case .purple: return "Purple"
        case .pink: return "Pink"
        case .teal: return "Teal"
        case .indigo: return "Indigo"
        case .mint: return "Mint"
        case .brown: return "Brown"
        }
    }
}

// MARK: - Predefined Group Icons

enum GroupIcon: String, CaseIterable, Identifiable {
    case folder = "folder.fill"
    case server = "server.rack"
    case cloud = "cloud.fill"
    case globe = "globe"
    case building = "building.2.fill"
    case desktopcomputer = "desktopcomputer"
    case lock = "lock.fill"
    case wrench = "wrench.and.screwdriver.fill"
    case flask = "flask.fill"
    case star = "star.fill"

    var id: String { rawValue }

    var name: String {
        switch self {
        case .folder: return "Folder"
        case .server: return "Server"
        case .cloud: return "Cloud"
        case .globe: return "Globe"
        case .building: return "Building"
        case .desktopcomputer: return "Desktop"
        case .lock: return "Lock"
        case .wrench: return "Tools"
        case .flask: return "Flask"
        case .star: return "Star"
        }
    }
}
