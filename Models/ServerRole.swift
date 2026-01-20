//
//  ServerRole.swift
//  macOS-Server-2026
//
//  Created on 2026-01-13.
//

import Foundation
import SwiftUI

enum RoleStatus: String, Codable {
    case installed
    case available
    case installing
}

struct ServerRole: Identifiable, Codable {
    let id: String
    var name: String
    var status: RoleStatus
    var description: String
    var iconName: String
    var subFeatures: [String]?
    var lastUpdated: String?
}
