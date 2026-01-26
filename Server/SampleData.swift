//
//  SampleData.swift
//  Server
//
//  Created by Jonathan Hines Dumitru on 1/13/26.
//

import Foundation
import SwiftData

struct SampleData {
    static func createSampleServers(in context: ModelContext) {
        // Create sample groups first
        let productionGroup = ServerGroup(
            name: "Production",
            colorHex: "#34C759",
            icon: "server.rack",
            sortOrder: 0
        )

        let stagingGroup = ServerGroup(
            name: "Staging",
            colorHex: "#FF9500",
            icon: "flask.fill",
            sortOrder: 1
        )

        let developmentGroup = ServerGroup(
            name: "Development",
            colorHex: "#007AFF",
            icon: "wrench.and.screwdriver.fill",
            sortOrder: 2
        )

        context.insert(productionGroup)
        context.insert(stagingGroup)
        context.insert(developmentGroup)

        // Web Servers
        let webServer1 = Server(
            name: "Production Web Server",
            host: "prod.example.com",
            port: 443,
            serverType: .https,
            status: .online,
            lastChecked: Date(),
            responseTime: 45.2,
            uptime: 2592000, // 30 days
            notes: "Main production web server hosting the application frontend"
        )
        
        let webServer2 = Server(
            name: "Staging Server",
            host: "staging.example.com",
            port: 443,
            serverType: .https,
            status: .online,
            lastChecked: Date(),
            responseTime: 67.8,
            uptime: 864000, // 10 days
            notes: "Staging environment for testing new features"
        )
        
        // API Server
        let apiServer = Server(
            name: "API Server",
            host: "api.example.com",
            port: 8080,
            serverType: .http,
            status: .warning,
            lastChecked: Date(),
            responseTime: 234.5,
            uptime: 1728000, // 20 days
            notes: "REST API backend server - experiencing high latency"
        )
        
        // Database Server
        let dbServer = Server(
            name: "PostgreSQL Database",
            host: "db.example.com",
            port: 5432,
            serverType: .database,
            status: .online,
            lastChecked: Date(),
            responseTime: 12.3,
            uptime: 5184000, // 60 days
            notes: "Primary PostgreSQL database server"
        )
        
        // FTP Server
        let ftpServer = Server(
            name: "File Transfer Server",
            host: "ftp.example.com",
            port: 21,
            serverType: .ftp,
            status: .offline,
            lastChecked: Date(),
            responseTime: nil,
            notes: "FTP server for file uploads - currently down for maintenance"
        )
        
        // SSH Server
        let sshServer = Server(
            name: "SSH Gateway",
            host: "ssh.example.com",
            port: 22,
            serverType: .ssh,
            status: .online,
            lastChecked: Date(),
            responseTime: 89.1,
            uptime: 7776000, // 90 days
            notes: "SSH gateway for remote server access"
        )
        
        // Assign servers to groups
        webServer1.group = productionGroup
        apiServer.group = productionGroup
        dbServer.group = productionGroup

        webServer2.group = stagingGroup

        ftpServer.group = developmentGroup
        sshServer.group = developmentGroup

        context.insert(webServer1)
        context.insert(webServer2)
        context.insert(apiServer)
        context.insert(dbServer)
        context.insert(ftpServer)
        context.insert(sshServer)
        
        // Add sample metrics for online servers
        addSampleMetrics(to: webServer1, context: context)
        addSampleMetrics(to: webServer2, context: context)
        addSampleMetrics(to: apiServer, context: context)
        addSampleMetrics(to: dbServer, context: context)
        addSampleMetrics(to: sshServer, context: context)
        
        // Add sample logs
        addSampleLogs(to: webServer1, context: context)
        addSampleLogs(to: apiServer, context: context)
        addSampleLogs(to: ftpServer, context: context)
        
        try? context.save()
    }
    
    private static func addSampleMetrics(to server: Server, context: ModelContext) {
        let now = Date()
        
        // Create metrics for the last hour (every 5 minutes)
        for i in stride(from: 60, through: 0, by: -5) {
            let timestamp = now.addingTimeInterval(TimeInterval(-i * 60))
            
            let metric = ServerMetric(
                timestamp: timestamp,
                cpuUsage: Double.random(in: 20...85),
                memoryUsage: Double.random(in: 40...90),
                diskUsage: Double.random(in: 50...75),
                networkIn: Double.random(in: 10...150),
                networkOut: Double.random(in: 5...100),
                activeConnections: Int.random(in: 10...200)
            )
            
            metric.server = server
            context.insert(metric)
        }
    }
    
    private static func addSampleLogs(to server: Server, context: ModelContext) {
        let now = Date()
        
        let sampleMessages = [
            ("Server started successfully", LogLevel.info),
            ("Health check passed", LogLevel.info),
            ("High memory usage detected", LogLevel.warning),
            ("Database connection established", LogLevel.info),
            ("Slow response time detected", LogLevel.warning),
            ("Request timeout", LogLevel.error),
            ("Service restarted", LogLevel.info),
            ("SSL certificate expiring soon", LogLevel.warning),
            ("Disk space low", LogLevel.warning),
            ("Connection failed", LogLevel.error),
        ]
        
        for (index, (message, level)) in sampleMessages.enumerated() {
            let log = ServerLog(
                timestamp: now.addingTimeInterval(TimeInterval(-index * 300)), // 5 minutes apart
                message: message,
                level: level
            )
            log.server = server
            context.insert(log)
        }
    }
}
