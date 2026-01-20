//
//  Service.swift
//  macOS-Server-2026
//
//  Created on 2026-01-13.
//

import Foundation

enum ServiceStatus: String, Codable {
    case running = "Running"
    case stopped = "Stopped"
}

enum StartupType: String, Codable {
    case automatic = "Automatic"
    case manual = "Manual"
    case disabled = "Disabled"
}

struct Service: Identifiable, Codable {
    let id: String
    var name: String
    var displayName: String
    var status: ServiceStatus
    var startupType: StartupType
    var description: String
}
