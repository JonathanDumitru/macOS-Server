//
//  ServerTemplate.swift
//  Server
//
//  Predefined server configurations for quick setup
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class ServerTemplate {
    var id: UUID
    var name: String
    var templateDescription: String
    var serverType: ServerType
    var defaultPort: Int
    var iconName: String
    var colorHex: String
    var isBuiltIn: Bool
    var createdAt: Date

    // Optional default settings
    var defaultTags: String
    var defaultNotes: String

    init(
        name: String,
        templateDescription: String,
        serverType: ServerType,
        defaultPort: Int,
        iconName: String = "server.rack",
        colorHex: String = "007AFF",
        isBuiltIn: Bool = false,
        defaultTags: String = "",
        defaultNotes: String = ""
    ) {
        self.id = UUID()
        self.name = name
        self.templateDescription = templateDescription
        self.serverType = serverType
        self.defaultPort = defaultPort
        self.iconName = iconName
        self.colorHex = colorHex
        self.isBuiltIn = isBuiltIn
        self.defaultTags = defaultTags
        self.defaultNotes = defaultNotes
        self.createdAt = Date()
    }

    var color: Color {
        Color(hex: colorHex) ?? .blue
    }
}

// MARK: - Built-in Templates

extension ServerTemplate {
    static var builtInTemplates: [ServerTemplate] {
        [
            ServerTemplate(
                name: "Web Server (HTTP)",
                templateDescription: "Standard HTTP web server",
                serverType: .http,
                defaultPort: 80,
                iconName: "globe",
                colorHex: "34C759",
                isBuiltIn: true,
                defaultTags: "web",
                defaultNotes: "HTTP web server"
            ),
            ServerTemplate(
                name: "Web Server (HTTPS)",
                templateDescription: "Secure HTTPS web server with SSL",
                serverType: .https,
                defaultPort: 443,
                iconName: "lock.shield",
                colorHex: "007AFF",
                isBuiltIn: true,
                defaultTags: "web,secure",
                defaultNotes: "HTTPS web server with SSL certificate"
            ),
            ServerTemplate(
                name: "SSH Server",
                templateDescription: "Secure Shell server for remote access",
                serverType: .ssh,
                defaultPort: 22,
                iconName: "terminal",
                colorHex: "5856D6",
                isBuiltIn: true,
                defaultTags: "ssh,remote",
                defaultNotes: "SSH remote access"
            ),
            ServerTemplate(
                name: "MySQL Database",
                templateDescription: "MySQL database server",
                serverType: .database,
                defaultPort: 3306,
                iconName: "cylinder",
                colorHex: "FF9500",
                isBuiltIn: true,
                defaultTags: "database,mysql",
                defaultNotes: "MySQL database server"
            ),
            ServerTemplate(
                name: "PostgreSQL Database",
                templateDescription: "PostgreSQL database server",
                serverType: .database,
                defaultPort: 5432,
                iconName: "cylinder.fill",
                colorHex: "336791",
                isBuiltIn: true,
                defaultTags: "database,postgresql",
                defaultNotes: "PostgreSQL database server"
            ),
            ServerTemplate(
                name: "MongoDB",
                templateDescription: "MongoDB NoSQL database",
                serverType: .database,
                defaultPort: 27017,
                iconName: "leaf",
                colorHex: "4DB33D",
                isBuiltIn: true,
                defaultTags: "database,mongodb,nosql",
                defaultNotes: "MongoDB NoSQL database"
            ),
            ServerTemplate(
                name: "Redis Cache",
                templateDescription: "Redis in-memory data store",
                serverType: .database,
                defaultPort: 6379,
                iconName: "bolt.fill",
                colorHex: "DC382D",
                isBuiltIn: true,
                defaultTags: "cache,redis",
                defaultNotes: "Redis cache server"
            ),
            ServerTemplate(
                name: "FTP Server",
                templateDescription: "File Transfer Protocol server",
                serverType: .ftp,
                defaultPort: 21,
                iconName: "folder",
                colorHex: "FF3B30",
                isBuiltIn: true,
                defaultTags: "ftp,files",
                defaultNotes: "FTP file server"
            ),
            ServerTemplate(
                name: "SFTP Server",
                templateDescription: "Secure FTP over SSH",
                serverType: .ssh,
                defaultPort: 22,
                iconName: "folder.badge.gearshape",
                colorHex: "AF52DE",
                isBuiltIn: true,
                defaultTags: "sftp,secure,files",
                defaultNotes: "Secure FTP server"
            ),
            ServerTemplate(
                name: "Mail Server (SMTP)",
                templateDescription: "SMTP mail server",
                serverType: .custom,
                defaultPort: 587,
                iconName: "envelope",
                colorHex: "5AC8FA",
                isBuiltIn: true,
                defaultTags: "mail,smtp",
                defaultNotes: "SMTP mail server"
            ),
            ServerTemplate(
                name: "DNS Server",
                templateDescription: "Domain Name System server",
                serverType: .custom,
                defaultPort: 53,
                iconName: "network",
                colorHex: "64D2FF",
                isBuiltIn: true,
                defaultTags: "dns",
                defaultNotes: "DNS server"
            ),
            ServerTemplate(
                name: "Docker Registry",
                templateDescription: "Docker container registry",
                serverType: .https,
                defaultPort: 5000,
                iconName: "shippingbox",
                colorHex: "2496ED",
                isBuiltIn: true,
                defaultTags: "docker,registry",
                defaultNotes: "Docker container registry"
            ),
            ServerTemplate(
                name: "Kubernetes API",
                templateDescription: "Kubernetes API server",
                serverType: .https,
                defaultPort: 6443,
                iconName: "helm",
                colorHex: "326CE5",
                isBuiltIn: true,
                defaultTags: "kubernetes,k8s",
                defaultNotes: "Kubernetes API server"
            ),
            ServerTemplate(
                name: "Elasticsearch",
                templateDescription: "Elasticsearch search engine",
                serverType: .http,
                defaultPort: 9200,
                iconName: "magnifyingglass",
                colorHex: "FEC514",
                isBuiltIn: true,
                defaultTags: "search,elasticsearch",
                defaultNotes: "Elasticsearch server"
            ),
            ServerTemplate(
                name: "RabbitMQ",
                templateDescription: "RabbitMQ message broker",
                serverType: .custom,
                defaultPort: 5672,
                iconName: "message",
                colorHex: "FF6600",
                isBuiltIn: true,
                defaultTags: "queue,rabbitmq",
                defaultNotes: "RabbitMQ message broker"
            ),
            ServerTemplate(
                name: "Grafana",
                templateDescription: "Grafana monitoring dashboard",
                serverType: .http,
                defaultPort: 3000,
                iconName: "chart.bar",
                colorHex: "F46800",
                isBuiltIn: true,
                defaultTags: "monitoring,grafana",
                defaultNotes: "Grafana dashboard"
            ),
            ServerTemplate(
                name: "Prometheus",
                templateDescription: "Prometheus metrics server",
                serverType: .http,
                defaultPort: 9090,
                iconName: "flame",
                colorHex: "E6522C",
                isBuiltIn: true,
                defaultTags: "monitoring,prometheus",
                defaultNotes: "Prometheus metrics"
            ),
            ServerTemplate(
                name: "Jenkins",
                templateDescription: "Jenkins CI/CD server",
                serverType: .http,
                defaultPort: 8080,
                iconName: "hammer",
                colorHex: "D24939",
                isBuiltIn: true,
                defaultTags: "ci,jenkins",
                defaultNotes: "Jenkins CI/CD"
            ),
            ServerTemplate(
                name: "GitLab",
                templateDescription: "GitLab server",
                serverType: .https,
                defaultPort: 443,
                iconName: "chevron.left.forwardslash.chevron.right",
                colorHex: "FC6D26",
                isBuiltIn: true,
                defaultTags: "git,gitlab",
                defaultNotes: "GitLab server"
            ),
            ServerTemplate(
                name: "Nginx Proxy",
                templateDescription: "Nginx reverse proxy",
                serverType: .http,
                defaultPort: 80,
                iconName: "arrow.triangle.branch",
                colorHex: "009639",
                isBuiltIn: true,
                defaultTags: "proxy,nginx",
                defaultNotes: "Nginx reverse proxy"
            )
        ]
    }
}

// MARK: - Color Extension

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }

    var hexString: String {
        guard let components = NSColor(self).cgColor.components, components.count >= 3 else {
            return "007AFF"
        }
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        return String(format: "%02X%02X%02X", r, g, b)
    }
}
