//
//  Event.swift
//  macOS-Server-2026
//
//  Created on 2026-01-13.
//

import Foundation

enum EventLevel: String, Codable {
    case information = "Information"
    case warning = "Warning"
    case error = "Error"
    case critical = "Critical"
}

struct Event: Identifiable, Codable {
    let id: String
    var level: EventLevel
    var source: String
    var eventId: Int
    var message: String
    var time: String
}
