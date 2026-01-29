//
//  WebhookService.swift
//  Server
//
//  Created by Claude on 1/28/26.
//

import Foundation
import os.log

private let logger = Logger(subsystem: "com.server.app", category: "Webhooks")

/// Service for sending notifications to external webhook endpoints (Slack, Discord, etc.)
@MainActor
class WebhookService: ObservableObject {
    static let shared = WebhookService()

    @Published var lastError: String?

    // MARK: - Preference Accessors

    private var isEnabled: Bool {
        UserDefaults.standard.object(forKey: "webhooksEnabled") as? Bool ?? false
    }

    private var slackWebhookURL: String? {
        UserDefaults.standard.string(forKey: "slackWebhookURL")
    }

    private var discordWebhookURL: String? {
        UserDefaults.standard.string(forKey: "discordWebhookURL")
    }

    private var customWebhookURL: String? {
        UserDefaults.standard.string(forKey: "customWebhookURL")
    }

    private var webhookOnOffline: Bool {
        UserDefaults.standard.object(forKey: "webhookOnOffline") as? Bool ?? true
    }

    private var webhookOnOnline: Bool {
        UserDefaults.standard.object(forKey: "webhookOnOnline") as? Bool ?? true
    }

    private var webhookOnSSLExpiry: Bool {
        UserDefaults.standard.object(forKey: "webhookOnSSLExpiry") as? Bool ?? true
    }

    private init() {}

    // MARK: - Server Status Webhooks

    func sendServerOfflineWebhook(server: Server) {
        guard isEnabled && webhookOnOffline else { return }

        let message = WebhookMessage(
            title: "Server Offline",
            description: "\(server.name) is now offline",
            color: .red,
            fields: [
                WebhookField(name: "Host", value: server.host, inline: true),
                WebhookField(name: "Port", value: "\(server.port)", inline: true),
                WebhookField(name: "Type", value: server.serverType.rawValue.uppercased(), inline: true),
                WebhookField(name: "Time", value: formattedDate(Date()), inline: false)
            ]
        )

        sendToAllWebhooks(message)
    }

    func sendServerOnlineWebhook(server: Server) {
        guard isEnabled && webhookOnOnline else { return }

        let message = WebhookMessage(
            title: "Server Back Online",
            description: "\(server.name) is now online",
            color: .green,
            fields: [
                WebhookField(name: "Host", value: server.host, inline: true),
                WebhookField(name: "Port", value: "\(server.port)", inline: true),
                WebhookField(name: "Response Time", value: server.responseTime.map { "\(Int($0))ms" } ?? "N/A", inline: true),
                WebhookField(name: "Time", value: formattedDate(Date()), inline: false)
            ]
        )

        sendToAllWebhooks(message)
    }

    func sendSSLExpiryWebhook(server: Server, daysRemaining: Int) {
        guard isEnabled && webhookOnSSLExpiry else { return }

        let urgency: String
        let color: WebhookColor

        if daysRemaining <= 0 {
            urgency = "has expired"
            color = .red
        } else if daysRemaining <= 7 {
            urgency = "expires in \(daysRemaining) day\(daysRemaining == 1 ? "" : "s")"
            color = .red
        } else {
            urgency = "expires in \(daysRemaining) days"
            color = .yellow
        }

        let message = WebhookMessage(
            title: "SSL Certificate Warning",
            description: "\(server.name) certificate \(urgency)",
            color: color,
            fields: [
                WebhookField(name: "Host", value: server.host, inline: true),
                WebhookField(name: "Days Remaining", value: "\(daysRemaining)", inline: true),
                WebhookField(name: "Time", value: formattedDate(Date()), inline: false)
            ]
        )

        sendToAllWebhooks(message)
    }

    // MARK: - Send to Webhooks

    private func sendToAllWebhooks(_ message: WebhookMessage) {
        if let slackURL = slackWebhookURL, !slackURL.isEmpty {
            sendToSlack(message, url: slackURL)
        }

        if let discordURL = discordWebhookURL, !discordURL.isEmpty {
            sendToDiscord(message, url: discordURL)
        }

        if let customURL = customWebhookURL, !customURL.isEmpty {
            sendToCustomWebhook(message, url: customURL)
        }
    }

    // MARK: - Slack

    private func sendToSlack(_ message: WebhookMessage, url: String) {
        guard let webhookURL = URL(string: url) else {
            logger.error("Invalid Slack webhook URL")
            return
        }

        let slackPayload: [String: Any] = [
            "attachments": [
                [
                    "color": message.color.slackColor,
                    "title": message.title,
                    "text": message.description,
                    "fields": message.fields.map { field in
                        [
                            "title": field.name,
                            "value": field.value,
                            "short": field.inline
                        ]
                    },
                    "footer": "Server Monitor",
                    "ts": Int(Date().timeIntervalSince1970)
                ]
            ]
        ]

        sendWebhookRequest(to: webhookURL, payload: slackPayload, service: "Slack")
    }

    // MARK: - Discord

    private func sendToDiscord(_ message: WebhookMessage, url: String) {
        guard let webhookURL = URL(string: url) else {
            logger.error("Invalid Discord webhook URL")
            return
        }

        let discordPayload: [String: Any] = [
            "embeds": [
                [
                    "title": message.title,
                    "description": message.description,
                    "color": message.color.discordColor,
                    "fields": message.fields.map { field in
                        [
                            "name": field.name,
                            "value": field.value,
                            "inline": field.inline
                        ]
                    },
                    "footer": [
                        "text": "Server Monitor"
                    ],
                    "timestamp": ISO8601DateFormatter().string(from: Date())
                ]
            ]
        ]

        sendWebhookRequest(to: webhookURL, payload: discordPayload, service: "Discord")
    }

    // MARK: - Custom Webhook

    private func sendToCustomWebhook(_ message: WebhookMessage, url: String) {
        guard let webhookURL = URL(string: url) else {
            logger.error("Invalid custom webhook URL")
            return
        }

        let payload: [String: Any] = [
            "event": message.title.lowercased().replacingOccurrences(of: " ", with: "_"),
            "title": message.title,
            "message": message.description,
            "severity": message.color.rawValue,
            "fields": Dictionary(uniqueKeysWithValues: message.fields.map { ($0.name, $0.value) }),
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]

        sendWebhookRequest(to: webhookURL, payload: payload, service: "Custom")
    }

    // MARK: - HTTP Request

    private func sendWebhookRequest(to url: URL, payload: [String: Any], service: String) {
        Task {
            do {
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try JSONSerialization.data(withJSONObject: payload)
                request.timeoutInterval = 10

                let (_, response) = try await URLSession.shared.data(for: request)

                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                        logger.info("\(service) webhook sent successfully")
                    } else {
                        logger.warning("\(service) webhook returned status \(httpResponse.statusCode)")
                        await MainActor.run {
                            self.lastError = "\(service) webhook failed with status \(httpResponse.statusCode)"
                        }
                    }
                }
            } catch {
                logger.error("\(service) webhook failed: \(error.localizedDescription)")
                await MainActor.run {
                    self.lastError = "\(service): \(error.localizedDescription)"
                }
            }
        }
    }

    // MARK: - Test Webhooks

    func sendTestWebhook() {
        let message = WebhookMessage(
            title: "Test Notification",
            description: "This is a test message from Server Monitor",
            color: .blue,
            fields: [
                WebhookField(name: "Status", value: "Test", inline: true),
                WebhookField(name: "Time", value: formattedDate(Date()), inline: true)
            ]
        )

        sendToAllWebhooks(message)
    }

    // MARK: - Helpers

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Webhook Models

struct WebhookMessage {
    let title: String
    let description: String
    let color: WebhookColor
    let fields: [WebhookField]
}

struct WebhookField {
    let name: String
    let value: String
    let inline: Bool
}

enum WebhookColor: String {
    case red
    case green
    case yellow
    case blue
    case gray

    var slackColor: String {
        switch self {
        case .red: return "#dc3545"
        case .green: return "#28a745"
        case .yellow: return "#ffc107"
        case .blue: return "#007bff"
        case .gray: return "#6c757d"
        }
    }

    var discordColor: Int {
        switch self {
        case .red: return 0xDC3545
        case .green: return 0x28A745
        case .yellow: return 0xFFC107
        case .blue: return 0x007BFF
        case .gray: return 0x6C757D
        }
    }
}
