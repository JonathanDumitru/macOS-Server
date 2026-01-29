//
//  HealthCheckView.swift
//  Server
//
//  Created by Claude on 1/28/26.
//

import SwiftUI
import SwiftData

struct HealthCheckView: View {
    let server: Server
    @Environment(\.modelContext) private var modelContext
    @Query private var healthChecks: [HealthCheck]

    @State private var showAddSheet = false
    @State private var selectedCheck: HealthCheck?
    @State private var isRunningAll = false

    init(server: Server) {
        self.server = server
        let serverId = server.id
        _healthChecks = Query(
            filter: #Predicate<HealthCheck> { $0.serverId == serverId },
            sort: [SortDescriptor(\HealthCheck.name)]
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()

            // Content
            if healthChecks.isEmpty {
                emptyState
            } else {
                checksList
            }
        }
        .sheet(isPresented: $showAddSheet) {
            HealthCheckEditSheet(server: server, healthCheck: nil)
        }
        .sheet(item: $selectedCheck) { check in
            HealthCheckEditSheet(server: server, healthCheck: check)
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Health Checks")
                    .font(.headline)
                Text("\(healthChecks.count) configured")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if !healthChecks.isEmpty {
                Button {
                    Task {
                        await runAllChecks()
                    }
                } label: {
                    if isRunningAll {
                        ProgressView()
                            .scaleEffect(0.7)
                            .frame(width: 16, height: 16)
                    } else {
                        Image(systemName: "play.fill")
                    }
                }
                .buttonStyle(.bordered)
                .disabled(isRunningAll)
                .help("Run all health checks")
            }

            Button {
                showAddSheet = true
            } label: {
                Image(systemName: "plus")
            }
            .buttonStyle(.bordered)
            .help("Add health check")
        }
        .padding()
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No Health Checks")
                .font(.title3.bold())

            Text("Add custom health checks to monitor\nspecific endpoints or services")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Add Health Check") {
                showAddSheet = true
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Checks List

    private var checksList: some View {
        List {
            ForEach(healthChecks) { check in
                HealthCheckRow(check: check) {
                    selectedCheck = check
                } onRun: {
                    Task {
                        await runCheck(check)
                    }
                } onDelete: {
                    deleteCheck(check)
                }
            }
        }
        .listStyle(.inset)
    }

    // MARK: - Actions

    private func runAllChecks() async {
        isRunningAll = true
        _ = await HealthCheckService.shared.runAllHealthChecks(for: server)
        isRunningAll = false
    }

    private func runCheck(_ check: HealthCheck) async {
        let result = await HealthCheckService.shared.runHealthCheck(check)
        check.recordResult(
            passed: result.passed,
            message: result.message,
            responseTime: result.responseTime
        )
        try? modelContext.save()
    }

    private func deleteCheck(_ check: HealthCheck) {
        modelContext.delete(check)
        try? modelContext.save()
    }
}

// MARK: - Health Check Row

struct HealthCheckRow: View {
    @Bindable var check: HealthCheck
    let onEdit: () -> Void
    let onRun: () -> Void
    let onDelete: () -> Void

    @State private var isRunning = false
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)

            // Icon
            Image(systemName: check.checkType.icon)
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
                .frame(width: 24)

            // Info
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(check.name)
                        .font(.system(size: 13, weight: .medium))

                    if !check.isEnabled {
                        Text("DISABLED")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.gray.opacity(0.3))
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                    }
                }

                HStack(spacing: 8) {
                    Text(check.checkType.rawValue)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)

                    if check.checkType == .httpStatus || check.checkType == .httpContent {
                        Text(check.httpPath)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Spacer()

            // Stats
            if let lastCheck = check.lastCheckTime {
                VStack(alignment: .trailing, spacing: 2) {
                    if let responseTime = check.lastResponseTime {
                        Text("\(Int(responseTime))ms")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(responseTime < 500 ? .green : responseTime < 1000 ? .orange : .red)
                    }

                    Text(lastCheck, style: .relative)
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
            }

            // Actions
            if isHovered {
                HStack(spacing: 4) {
                    Button {
                        Task {
                            isRunning = true
                            onRun()
                            try? await Task.sleep(for: .milliseconds(500))
                            isRunning = false
                        }
                    } label: {
                        if isRunning {
                            ProgressView()
                                .scaleEffect(0.6)
                                .frame(width: 16, height: 16)
                        } else {
                            Image(systemName: "play.fill")
                                .font(.system(size: 10))
                        }
                    }
                    .buttonStyle(.borderless)
                    .disabled(isRunning)

                    Button {
                        onEdit()
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 10))
                    }
                    .buttonStyle(.borderless)

                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 10))
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.red)
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private var statusColor: Color {
        guard check.isEnabled else { return .gray }

        if let passed = check.lastCheckPassed {
            return passed ? .green : .red
        }
        return .gray
    }
}

// MARK: - Edit Sheet

struct HealthCheckEditSheet: View {
    let server: Server
    let healthCheck: HealthCheck?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var checkType: HealthCheckType = .httpStatus
    @State private var isEnabled = true
    @State private var httpMethod = "GET"
    @State private var httpPath = "/"
    @State private var expectedStatusCode = "200"
    @State private var expectedContent = ""
    @State private var forbiddenContent = ""
    @State private var timeoutSeconds = "10"
    @State private var requestBody = ""

    var isEditing: Bool { healthCheck != nil }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(isEditing ? "Edit Health Check" : "Add Health Check")
                    .font(.headline)
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            .padding()

            Divider()

            // Form
            Form {
                Section("General") {
                    TextField("Name", text: $name)
                    Toggle("Enabled", isOn: $isEnabled)
                    Picker("Check Type", selection: $checkType) {
                        ForEach(HealthCheckType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon).tag(type)
                        }
                    }
                }

                if checkType == .httpStatus || checkType == .httpContent {
                    Section("HTTP Settings") {
                        Picker("Method", selection: $httpMethod) {
                            Text("GET").tag("GET")
                            Text("POST").tag("POST")
                            Text("HEAD").tag("HEAD")
                        }
                        .pickerStyle(.segmented)

                        TextField("Path", text: $httpPath)
                            .textFieldStyle(.roundedBorder)

                        TextField("Expected Status Code", text: $expectedStatusCode)
                            .textFieldStyle(.roundedBorder)

                        TextField("Timeout (seconds)", text: $timeoutSeconds)
                            .textFieldStyle(.roundedBorder)
                    }

                    if httpMethod == "POST" {
                        Section("Request Body") {
                            TextEditor(text: $requestBody)
                                .frame(height: 60)
                                .font(.system(.body, design: .monospaced))
                        }
                    }
                }

                if checkType == .httpContent {
                    Section("Content Validation") {
                        TextField("Response should contain", text: $expectedContent)
                            .textFieldStyle(.roundedBorder)

                        TextField("Response should NOT contain", text: $forbiddenContent)
                            .textFieldStyle(.roundedBorder)
                    }
                }

                if checkType == .tcpPort {
                    Section("TCP Settings") {
                        Text("Will check TCP connectivity to \(server.host):\(server.port)")
                            .foregroundStyle(.secondary)

                        TextField("Timeout (seconds)", text: $timeoutSeconds)
                            .textFieldStyle(.roundedBorder)
                    }
                }

                if checkType == .ping {
                    Section("Ping Settings") {
                        Text("Will send ICMP ping to \(server.host)")
                            .foregroundStyle(.secondary)

                        TextField("Timeout (seconds)", text: $timeoutSeconds)
                            .textFieldStyle(.roundedBorder)
                    }
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)

            Divider()

            // Footer
            HStack {
                if isEditing {
                    Button("Delete", role: .destructive) {
                        if let check = healthCheck {
                            modelContext.delete(check)
                            try? modelContext.save()
                        }
                        dismiss()
                    }
                }

                Spacer()

                Button(isEditing ? "Save" : "Add") {
                    saveCheck()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(name.isEmpty)
            }
            .padding()
        }
        .frame(width: 450, height: 500)
        .onAppear {
            if let check = healthCheck {
                name = check.name
                checkType = check.checkType
                isEnabled = check.isEnabled
                httpMethod = check.httpMethod
                httpPath = check.httpPath
                expectedStatusCode = check.expectedStatusCode.map { String($0) } ?? "200"
                expectedContent = check.expectedResponseContains ?? ""
                forbiddenContent = check.expectedResponseNotContains ?? ""
                timeoutSeconds = String(check.timeoutSeconds)
                requestBody = check.requestBody ?? ""
            }
        }
    }

    private func saveCheck() {
        let check: HealthCheck
        if let existing = healthCheck {
            check = existing
        } else {
            check = HealthCheck(serverId: server.id, name: name)
            modelContext.insert(check)
        }

        check.name = name
        check.checkType = checkType
        check.isEnabled = isEnabled
        check.httpMethod = httpMethod
        check.httpPath = httpPath
        check.expectedStatusCode = Int(expectedStatusCode)
        check.expectedResponseContains = expectedContent.isEmpty ? nil : expectedContent
        check.expectedResponseNotContains = forbiddenContent.isEmpty ? nil : forbiddenContent
        check.timeoutSeconds = Int(timeoutSeconds) ?? 10
        check.requestBody = requestBody.isEmpty ? nil : requestBody

        try? modelContext.save()
    }
}

// MARK: - Health Check Summary Card

struct HealthCheckSummaryCard: View {
    let server: Server
    @Query private var healthChecks: [HealthCheck]

    init(server: Server) {
        self.server = server
        let serverId = server.id
        _healthChecks = Query(
            filter: #Predicate<HealthCheck> { $0.serverId == serverId && $0.isEnabled }
        )
    }

    var passedCount: Int {
        healthChecks.filter { $0.lastCheckPassed == true }.count
    }

    var failedCount: Int {
        healthChecks.filter { $0.lastCheckPassed == false }.count
    }

    var body: some View {
        if !healthChecks.isEmpty {
            HStack(spacing: 16) {
                Image(systemName: "heart.text.square")
                    .font(.system(size: 20))
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Health Checks")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        if passedCount > 0 {
                            Label("\(passedCount) passing", systemImage: "checkmark.circle.fill")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.green)
                        }

                        if failedCount > 0 {
                            Label("\(failedCount) failing", systemImage: "xmark.circle.fill")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.red)
                        }

                        if passedCount == 0 && failedCount == 0 {
                            Text("\(healthChecks.count) configured")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()

                // Overall status indicator
                if failedCount > 0 {
                    Circle()
                        .fill(.red)
                        .frame(width: 12, height: 12)
                } else if passedCount > 0 {
                    Circle()
                        .fill(.green)
                        .frame(width: 12, height: 12)
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

#Preview {
    HealthCheckView(server: Server(name: "Test Server", host: "localhost", port: 443, serverType: .https))
}
