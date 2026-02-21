//
//  ServerMetric.swift
//  Server
//
//  Created by Jonathan Hines Dumitru on 1/13/26.
//

import Foundation
import SwiftData

@Model
final class ServerMetric {
    var id: UUID
    var timestamp: Date
    var cpuUsage: Double? // percentage
    var memoryUsage: Double? // percentage
    var diskUsage: Double? // percentage
    var networkIn: Double? // MB/s
    var networkOut: Double? // MB/s
    var activeConnections: Int?
    var responseTime: Double? // milliseconds
    
    var server: Server?
    
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        cpuUsage: Double? = nil,
        memoryUsage: Double? = nil,
        diskUsage: Double? = nil,
        networkIn: Double? = nil,
        networkOut: Double? = nil,
        activeConnections: Int? = nil,
        responseTime: Double? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.cpuUsage = cpuUsage
        self.memoryUsage = memoryUsage
        self.diskUsage = diskUsage
        self.networkIn = networkIn
        self.networkOut = networkOut
        self.activeConnections = activeConnections
        self.responseTime = responseTime
    }
}
