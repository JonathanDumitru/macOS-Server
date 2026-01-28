//
//  AlertRulesEngine.swift
//  Server
//
//  Created by Claude on 1/28/26.
//

import Foundation
import SwiftData
import os.log

private let logger = Logger(subsystem: "com.server.app", category: "AlertRules")

// MARK: - Alert Rule Model

@Model
final class AlertRule {
    var id: UUID
    var name: String
    var isEnabled: Bool
    var priority: AlertPriority
    var conditionType: AlertConditionType
    var threshold: Double
    var comparison: AlertComparison
    var cooldownMinutes: Int
    var lastTriggered: Date?
    var serverFilter: ServerFilterType
    var serverIds: [UUID] // Used when filter is .specific
    var actions: [AlertAction]
    var triggerCount: Int
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        isEnabled: Bool = true,
        priority: AlertPriority = .medium,
        conditionType: AlertConditionType,
        threshold: Double,
        comparison: AlertComparison = .greaterThan,
        cooldownMinutes: Int = 5,
        serverFilter: ServerFilterType = .all,
        serverIds: [UUID] = [],
        actions: [AlertAction] = [.notification]
    ) {
        self.id = id
        self.name = name
        self.isEnabled = isEnabled
        self.priority = priority
        self.conditionType = conditionType
        self.threshold = threshold
        self.comparison = comparison
        self.cooldownMinutes = cooldownMinutes
        self.lastTriggered = nil
        self.serverFilter = serverFilter
        self.serverIds = serverIds
        self.actions = actions
        self.triggerCount = 0
        self.createdAt = Date()
    }
}

// MARK: - Enums

enum AlertPriority: String, Codable, CaseIterable, Identifiable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"

    var id: String { rawValue }

    var color: String {
        switch self {
        case .low: return "gray"
        case .medium: return "blue"
        case .high: return "orange"
        case .critical: return "red"
        }
    }
}

enum AlertConditionType: String, Codable, CaseIterable, Identifiable {
    case serverOffline = "Server Offline"
    case highCPU = "High CPU Usage"
    case highMemory = "High Memory Usage"
    case highDisk = "High Disk Usage"
    case slowResponse = "Slow Response Time"
    case sslExpiring = "SSL Certificate Expiring"
    case consecutiveFailures = "Consecutive Failures"
    case lowUptime = "Low Uptime Percentage"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .serverOffline: return "xmark.circle"
        case .highCPU: return "cpu"
        case .highMemory: return "memorychip"
        case .highDisk: return "internaldrive"
        case .slowResponse: return "gauge.with.needle"
        case .sslExpiring: return "lock.shield"
        case .consecutiveFailures: return "exclamationmark.triangle"
        case .lowUptime: return "clock.arrow.circlepath"
        }
    }

    var defaultThreshold: Double {
        switch self {
        case .serverOffline: return 1 // Boolean
        case .highCPU: return 80
        case .highMemory: return 85
        case .highDisk: return 90
        case .slowResponse: return 1000 // ms
        case .sslExpiring: return 30 // days
        case .consecutiveFailures: return 3
        case .lowUptime: return 99 // percent
        }
    }

    var unit: String {
        switch self {
        case .serverOffline: return ""
        case .highCPU, .highMemory, .highDisk, .lowUptime: return "%"
        case .slowResponse: return "ms"
        case .sslExpiring: return "days"
        case .consecutiveFailures: return "failures"
        }
    }
}

enum AlertComparison: String, Codable, CaseIterable, Identifiable {
    case greaterThan = "Greater Than"
    case lessThan = "Less Than"
    case equals = "Equals"
    case notEquals = "Not Equals"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .greaterThan: return ">"
        case .lessThan: return "<"
        case .equals: return "="
        case .notEquals: return "!="
        }
    }
}

enum ServerFilterType: String, Codable, CaseIterable, Identifiable {
    case all = "All Servers"
    case online = "Online Servers"
    case favorites = "Favorites Only"
    case specific = "Specific Servers"

    var id: String { rawValue }
}

enum AlertAction: String, Codable, CaseIterable, Identifiable {
    case notification = "System Notification"
    case sound = "Play Sound"
    case webhook = "Webhook"
    case email = "Email"
    case createIncident = "Create Incident"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .notification: return "bell"
        case .sound: return "speaker.wave.3"
        case .webhook: return "arrow.up.forward.app"
        case .email: return "envelope"
        case .createIncident: return "exclamationmark.triangle"
        }
    }
}

// MARK: - Alert Rules Engine Service

@MainActor
class AlertRulesEngine {
    static let shared = AlertRulesEngine()

    private var modelContext: ModelContext?
    private var consecutiveFailures: [UUID: Int] = [:] // serverId -> failure count

    private init() {}

    func configure(with context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - Evaluate Rules

    func evaluateRules(for server: Server) async {
        guard let context = modelContext else { return }

        let descriptor = FetchDescriptor<AlertRule>(
            predicate: #Predicate { $0.isEnabled }
        )

        do {
            let rules = try context.fetch(descriptor)

            for rule in rules {
                // Check if rule applies to this server
                guard shouldApplyRule(rule, to: server) else { continue }

                // Check cooldown
                guard canTrigger(rule) else { continue }

                // Evaluate condition
                if await evaluateCondition(rule, for: server) {
                    triggerRule(rule, for: server)
                }
            }
        } catch {
            logger.error("Failed to fetch alert rules: \(error.localizedDescription)")
        }
    }

    private func shouldApplyRule(_ rule: AlertRule, to server: Server) -> Bool {
        switch rule.serverFilter {
        case .all:
            return true
        case .online:
            return server.status == .online
        case .favorites:
            return server.isFavorite
        case .specific:
            return rule.serverIds.contains(server.id)
        }
    }

    private func canTrigger(_ rule: AlertRule) -> Bool {
        guard let lastTriggered = rule.lastTriggered else { return true }
        let cooldown = TimeInterval(rule.cooldownMinutes * 60)
        return Date().timeIntervalSince(lastTriggered) >= cooldown
    }

    private func evaluateCondition(_ rule: AlertRule, for server: Server) async -> Bool {
        let currentValue: Double?

        switch rule.conditionType {
        case .serverOffline:
            return server.status == .offline

        case .highCPU:
            currentValue = server.metrics.last?.cpuUsage

        case .highMemory:
            currentValue = server.metrics.last?.memoryUsage

        case .highDisk:
            currentValue = server.metrics.last?.diskUsage

        case .slowResponse:
            currentValue = server.responseTime

        case .sslExpiring:
            if let cert = server.sslCertificate, let days = cert.daysUntilExpiry {
                currentValue = Double(days)
            } else {
                currentValue = nil
            }

        case .consecutiveFailures:
            let failures = consecutiveFailures[server.id] ?? 0
            currentValue = Double(failures)

        case .lowUptime:
            // This would need uptime tracking service
            currentValue = nil
        }

        guard let value = currentValue else { return false }

        return compareValue(value, with: rule.threshold, using: rule.comparison)
    }

    private func compareValue(_ value: Double, with threshold: Double, using comparison: AlertComparison) -> Bool {
        switch comparison {
        case .greaterThan: return value > threshold
        case .lessThan: return value < threshold
        case .equals: return abs(value - threshold) < 0.001
        case .notEquals: return abs(value - threshold) >= 0.001
        }
    }

    // MARK: - Trigger Actions

    private func triggerRule(_ rule: AlertRule, for server: Server) {
        logger.info("Alert rule triggered: \(rule.name) for server \(server.name)")

        // Update rule metadata
        rule.lastTriggered = Date()
        rule.triggerCount += 1

        // Execute actions
        for action in rule.actions {
            executeAction(action, rule: rule, server: server)
        }

        try? modelContext?.save()
    }

    private func executeAction(_ action: AlertAction, rule: AlertRule, server: Server) {
        switch action {
        case .notification:
            sendNotification(rule: rule, server: server)

        case .sound:
            SoundAlertService.shared.playAlert(for: .incidentCreated)

        case .webhook:
            WebhookService.shared.sendServerAlert(
                server: server,
                message: "Alert: \(rule.name) - \(rule.conditionType.rawValue)",
                isRecovery: false
            )

        case .email:
            // Email functionality would be implemented here
            logger.info("Email action not yet implemented")

        case .createIncident:
            createIncident(rule: rule, server: server)
        }
    }

    private func sendNotification(rule: AlertRule, server: Server) {
        let content = UNMutableNotificationContent()
        content.title = "Alert: \(rule.name)"
        content.body = "Server \(server.name): \(rule.conditionType.rawValue)"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "alert-\(rule.id.uuidString)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    private func createIncident(rule: AlertRule, server: Server) {
        let severity: IncidentSeverity
        switch rule.priority {
        case .low: severity = .low
        case .medium: severity = .medium
        case .high: severity = .high
        case .critical: severity = .critical
        }

        let incident = Incident(
            serverId: server.id,
            serverName: server.name,
            serverHost: server.host,
            type: .warning,
            severity: severity,
            title: rule.name,
            description: "Alert triggered: \(rule.conditionType.rawValue)"
        )

        modelContext?.insert(incident)
    }

    // MARK: - Failure Tracking

    func recordServerCheck(server: Server, success: Bool) {
        if success {
            consecutiveFailures[server.id] = 0
        } else {
            consecutiveFailures[server.id] = (consecutiveFailures[server.id] ?? 0) + 1
        }
    }

    func getConsecutiveFailures(for serverId: UUID) -> Int {
        return consecutiveFailures[serverId] ?? 0
    }
}

// MARK: - Alert Rules View

import SwiftUI

struct AlertRulesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \AlertRule.createdAt, order: .reverse) private var rules: [AlertRule]
    @State private var showingAddRule = false
    @State private var selectedRule: AlertRule?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Alert Rules")
                        .font(.title2.bold())
                    Text("\(rules.count) rules configured")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    showingAddRule = true
                } label: {
                    Label("Add Rule", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()

            Divider()

            // Rules List
            if rules.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(rules) { rule in
                        AlertRuleRow(rule: rule)
                            .onTapGesture {
                                selectedRule = rule
                            }
                    }
                    .onDelete(perform: deleteRules)
                }
                .listStyle(.inset)
            }
        }
        .sheet(isPresented: $showingAddRule) {
            AlertRuleEditorView(rule: nil)
        }
        .sheet(item: $selectedRule) { rule in
            AlertRuleEditorView(rule: rule)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "bell.badge")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No Alert Rules")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text("Create custom rules to get notified when server metrics exceed thresholds")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)

            Button {
                showingAddRule = true
            } label: {
                Label("Create First Rule", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func deleteRules(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(rules[index])
        }
    }
}

struct AlertRuleRow: View {
    let rule: AlertRule

    var body: some View {
        HStack(spacing: 12) {
            // Priority indicator
            Circle()
                .fill(Color(rule.priority.color))
                .frame(width: 10, height: 10)

            // Icon
            Image(systemName: rule.conditionType.icon)
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
                .frame(width: 24)

            // Content
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(rule.name)
                        .font(.system(size: 13, weight: .medium))

                    if !rule.isEnabled {
                        Text("DISABLED")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.gray.opacity(0.2))
                            .foregroundStyle(.secondary)
                            .clipShape(Capsule())
                    }
                }

                Text("\(rule.conditionType.rawValue) \(rule.comparison.symbol) \(Int(rule.threshold))\(rule.conditionType.unit)")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Stats
            VStack(alignment: .trailing, spacing: 2) {
                Text("Triggered \(rule.triggerCount)x")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)

                if let lastTriggered = rule.lastTriggered {
                    Text(lastTriggered, style: .relative)
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
            }

            // Toggle
            Toggle("", isOn: Binding(
                get: { rule.isEnabled },
                set: { rule.isEnabled = $0 }
            ))
            .labelsHidden()
        }
        .padding(.vertical, 4)
    }
}

struct AlertRuleEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var servers: [Server]

    let existingRule: AlertRule?

    @State private var name: String = ""
    @State private var isEnabled: Bool = true
    @State private var priority: AlertPriority = .medium
    @State private var conditionType: AlertConditionType = .highCPU
    @State private var threshold: Double = 80
    @State private var comparison: AlertComparison = .greaterThan
    @State private var cooldownMinutes: Int = 5
    @State private var serverFilter: ServerFilterType = .all
    @State private var selectedServerIds: Set<UUID> = []
    @State private var actions: Set<AlertAction> = [.notification]

    init(rule: AlertRule?) {
        self.existingRule = rule
        if let rule = rule {
            _name = State(initialValue: rule.name)
            _isEnabled = State(initialValue: rule.isEnabled)
            _priority = State(initialValue: rule.priority)
            _conditionType = State(initialValue: rule.conditionType)
            _threshold = State(initialValue: rule.threshold)
            _comparison = State(initialValue: rule.comparison)
            _cooldownMinutes = State(initialValue: rule.cooldownMinutes)
            _serverFilter = State(initialValue: rule.serverFilter)
            _selectedServerIds = State(initialValue: Set(rule.serverIds))
            _actions = State(initialValue: Set(rule.actions))
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") {
                    dismiss()
                }

                Spacer()

                Text(existingRule == nil ? "New Alert Rule" : "Edit Rule")
                    .font(.headline)

                Spacer()

                Button("Save") {
                    saveRule()
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.isEmpty)
            }
            .padding()

            Divider()

            Form {
                Section("Rule Info") {
                    TextField("Rule Name", text: $name)

                    Toggle("Enabled", isOn: $isEnabled)

                    Picker("Priority", selection: $priority) {
                        ForEach(AlertPriority.allCases) { p in
                            Text(p.rawValue).tag(p)
                        }
                    }
                }

                Section("Condition") {
                    Picker("Type", selection: $conditionType) {
                        ForEach(AlertConditionType.allCases) { type in
                            Label(type.rawValue, systemImage: type.icon).tag(type)
                        }
                    }
                    .onChange(of: conditionType) { _, newValue in
                        threshold = newValue.defaultThreshold
                    }

                    if conditionType != .serverOffline {
                        Picker("Comparison", selection: $comparison) {
                            ForEach(AlertComparison.allCases) { c in
                                Text("\(c.rawValue) (\(c.symbol))").tag(c)
                            }
                        }

                        HStack {
                            Text("Threshold")
                            Spacer()
                            TextField("", value: $threshold, format: .number)
                                .frame(width: 80)
                                .textFieldStyle(.roundedBorder)
                            Text(conditionType.unit)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Cooldown") {
                    Picker("Cooldown Period", selection: $cooldownMinutes) {
                        Text("1 minute").tag(1)
                        Text("5 minutes").tag(5)
                        Text("15 minutes").tag(15)
                        Text("30 minutes").tag(30)
                        Text("1 hour").tag(60)
                    }
                }

                Section("Servers") {
                    Picker("Apply To", selection: $serverFilter) {
                        ForEach(ServerFilterType.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }

                    if serverFilter == .specific {
                        ForEach(servers) { server in
                            Toggle(server.name, isOn: Binding(
                                get: { selectedServerIds.contains(server.id) },
                                set: { isSelected in
                                    if isSelected {
                                        selectedServerIds.insert(server.id)
                                    } else {
                                        selectedServerIds.remove(server.id)
                                    }
                                }
                            ))
                        }
                    }
                }

                Section("Actions") {
                    ForEach(AlertAction.allCases) { action in
                        Toggle(isOn: Binding(
                            get: { actions.contains(action) },
                            set: { isSelected in
                                if isSelected {
                                    actions.insert(action)
                                } else {
                                    actions.remove(action)
                                }
                            }
                        )) {
                            Label(action.rawValue, systemImage: action.icon)
                        }
                    }
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 450, height: 600)
    }

    private func saveRule() {
        if let rule = existingRule {
            // Update existing rule
            rule.name = name
            rule.isEnabled = isEnabled
            rule.priority = priority
            rule.conditionType = conditionType
            rule.threshold = threshold
            rule.comparison = comparison
            rule.cooldownMinutes = cooldownMinutes
            rule.serverFilter = serverFilter
            rule.serverIds = Array(selectedServerIds)
            rule.actions = Array(actions)
        } else {
            // Create new rule
            let rule = AlertRule(
                name: name,
                isEnabled: isEnabled,
                priority: priority,
                conditionType: conditionType,
                threshold: threshold,
                comparison: comparison,
                cooldownMinutes: cooldownMinutes,
                serverFilter: serverFilter,
                serverIds: Array(selectedServerIds),
                actions: Array(actions)
            )
            modelContext.insert(rule)
        }

        try? modelContext.save()
        dismiss()
    }
}

import UserNotifications

#Preview {
    AlertRulesView()
}
