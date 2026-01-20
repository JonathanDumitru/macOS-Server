//
//  NetworkAdapter.swift
//  macOS-Server-2026
//
//  Created on 2026-01-13.
//

import Foundation

enum AdapterStatus: String, Codable {
    case connected = "Connected"
    case disconnected = "Disconnected"
}

struct NetworkAdapter: Identifiable, Codable {
    let id = UUID()
    var name: String
    var ip: String
    var status: AdapterStatus
    var speed: String
}
