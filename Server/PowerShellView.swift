//
//  PowerShellView.swift
//  Server
//
//  Created by Claude on 1/28/26.
//

import SwiftUI
import SwiftData

struct PowerShellView: View {
    @Query private var servers: [Server]
    @State private var selectedServer: Server?
    @State private var commandInput = ""
    @State private var outputHistory: [PowerShellOutput] = []
    @State private var isExecuting = false
    @State private var showCommandHistory = false
    @State private var commandHistory: [String] = []
    @State private var historyIndex: Int?

    var body: some View {
        HSplitView {
            // Server Selection
            VStack(spacing: 0) {
                HStack {
                    Text("Servers")
                        .font(.headline)
                    Spacer()
                }
                .padding()

                Divider()

                List(servers.filter { $0.status == .online }, selection: $selectedServer) { server in
                    HStack {
                        Circle()
                            .fill(Color(server.status.color))
                            .frame(width: 8, height: 8)
                        Text(server.name)
                            .font(.system(size: 13))
                    }
                    .tag(server)
                }
                .listStyle(.inset)

                Divider()

                // Quick Scripts
                VStack(alignment: .leading, spacing: 8) {
                    Text("Quick Scripts")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ForEach(QuickScript.allCases) { script in
                        QuickScriptButton(script: script) {
                            commandInput = script.command
                        }
                    }
                }
                .padding()
            }
            .frame(minWidth: 200, maxWidth: 260)

            // Terminal Area
            VStack(spacing: 0) {
                // Header
                HStack {
                    if let server = selectedServer {
                        Image(systemName: "terminal")
                            .foregroundStyle(.blue)
                        Text("PowerShell - \(server.name)")
                            .font(.headline)
                    } else {
                        Text("PowerShell")
                            .font(.headline)
                    }

                    Spacer()

                    Button {
                        outputHistory.removeAll()
                    } label: {
                        Label("Clear", systemImage: "trash")
                    }
                    .disabled(outputHistory.isEmpty)

                    Button {
                        showCommandHistory.toggle()
                    } label: {
                        Label("History", systemImage: "clock.arrow.circlepath")
                    }
                    .popover(isPresented: $showCommandHistory) {
                        CommandHistoryPopover(
                            history: commandHistory,
                            onSelect: { cmd in
                                commandInput = cmd
                                showCommandHistory = false
                            }
                        )
                    }
                }
                .padding()

                Divider()

                if selectedServer == nil {
                    noServerState
                } else {
                    // Output Area
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 0) {
                                ForEach(outputHistory) { output in
                                    OutputLineView(output: output)
                                        .id(output.id)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .background(Color(nsColor: .textBackgroundColor))
                        .onChange(of: outputHistory.count) { _, _ in
                            if let last = outputHistory.last {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }

                    Divider()

                    // Input Area
                    HStack(spacing: 8) {
                        Text("PS>")
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.blue)

                        TextField("Enter command...", text: $commandInput)
                            .textFieldStyle(.plain)
                            .font(.system(.body, design: .monospaced))
                            .onSubmit {
                                executeCommand()
                            }
                            .onKeyPress(.upArrow) {
                                navigateHistory(direction: .up)
                                return .handled
                            }
                            .onKeyPress(.downArrow) {
                                navigateHistory(direction: .down)
                                return .handled
                            }

                        if isExecuting {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Button {
                                executeCommand()
                            } label: {
                                Image(systemName: "return")
                            }
                            .buttonStyle(.plain)
                            .disabled(commandInput.isEmpty)
                        }
                    }
                    .padding()
                    .background(Color(nsColor: .controlBackgroundColor))
                }
            }
        }
    }

    private var noServerState: some View {
        VStack(spacing: 12) {
            Image(systemName: "terminal")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Select a Server")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text("Choose an online server to start a PowerShell session")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func executeCommand() {
        guard !commandInput.isEmpty, let server = selectedServer else { return }

        let command = commandInput.trimmingCharacters(in: .whitespacesAndNewlines)

        // Add to history
        if !command.isEmpty && (commandHistory.isEmpty || commandHistory.last != command) {
            commandHistory.append(command)
        }
        historyIndex = nil

        // Add command to output
        outputHistory.append(PowerShellOutput(
            type: .command,
            text: "PS \(server.host)> \(command)",
            timestamp: Date()
        ))

        commandInput = ""
        isExecuting = true

        // Simulate execution
        Task {
            try? await Task.sleep(for: .milliseconds(Int.random(in: 300...1200)))

            await MainActor.run {
                let result = simulateCommand(command, server: server)
                outputHistory.append(result)
                isExecuting = false
            }
        }
    }

    private func simulateCommand(_ command: String, server: Server) -> PowerShellOutput {
        let lowercased = command.lowercased()

        // Handle common commands
        if lowercased == "cls" || lowercased == "clear" {
            outputHistory.removeAll()
            return PowerShellOutput(type: .info, text: "", timestamp: Date())
        }

        if lowercased == "exit" || lowercased == "quit" {
            return PowerShellOutput(type: .info, text: "Session terminated.", timestamp: Date())
        }

        if lowercased == "help" || lowercased == "get-help" {
            return PowerShellOutput(type: .output, text: """
                PowerShell Help
                ===============

                Common Commands:
                  Get-Process      - List running processes
                  Get-Service      - List services
                  Get-EventLog     - View event logs
                  Get-ComputerInfo - System information
                  Get-Disk         - Disk information
                  Get-NetAdapter   - Network adapters
                  Restart-Service  - Restart a service
                  Test-Connection  - Ping a host

                Type 'Get-Command' for a full list of available commands.
                """, timestamp: Date())
        }

        if lowercased.starts(with: "get-process") {
            let cpu = server.metrics.last?.cpuUsage ?? 30
            return PowerShellOutput(type: .output, text: """
                Handles  NPM(K)    PM(K)      WS(K)   CPU(s)     Id  SI ProcessName
                -------  ------    -----      -----   ------     --  -- -----------
                    512      24    45632      52480    \(String(format: "%.2f", cpu * 0.3))   1234   1 nginx
                   1024      48   125440     156800    \(String(format: "%.2f", cpu * 0.4))   2345   1 mysqld
                    256      12    18432      22016    \(String(format: "%.2f", cpu * 0.1))   3456   1 redis-server
                    384      18    32768      38400    \(String(format: "%.2f", cpu * 0.15))   4567   1 node
                    128       8     8192      10240    \(String(format: "%.2f", cpu * 0.05))   5678   1 cron
                """, timestamp: Date())
        }

        if lowercased.starts(with: "get-service") {
            return PowerShellOutput(type: .output, text: """
                Status   Name               DisplayName
                ------   ----               -----------
                Running  nginx              NGINX HTTP Server
                Running  mysql              MySQL Database Server
                Running  redis              Redis Cache Server
                Running  docker             Docker Engine
                Stopped  apache2            Apache HTTP Server
                Running  ssh                OpenSSH Server
                Running  cron               Task Scheduler
                """, timestamp: Date())
        }

        if lowercased.starts(with: "get-computerinfo") || lowercased.starts(with: "systeminfo") {
            return PowerShellOutput(type: .output, text: """
                Host Name:                 \(server.host)
                OS Name:                   Ubuntu Server 22.04 LTS
                OS Version:                22.04.3 LTS
                System Type:               x64-based PC
                Processor:                 Intel Xeon E5-2680 v4 @ 2.40GHz
                Total Physical Memory:     32,768 MB
                Available Physical Memory: \(Int(32768 * (1 - (server.metrics.last?.memoryUsage ?? 50) / 100))) MB
                Virtual Memory: Max Size:  65,536 MB
                Network Card(s):           2 NIC(s) Installed
                """, timestamp: Date())
        }

        if lowercased.starts(with: "get-disk") {
            let disk = server.metrics.last?.diskUsage ?? 45
            return PowerShellOutput(type: .output, text: """
                Number Friendly Name    Size      Used     Free    Health
                ------ -------------    ----      ----     ----    ------
                0      NVMe SSD         256 GB    \(Int(256 * disk / 100)) GB    \(Int(256 * (100 - disk) / 100)) GB    Healthy
                1      SATA SSD         512 GB    234 GB   278 GB   Healthy
                2      HDD              2 TB      1.3 TB   700 GB   Healthy
                """, timestamp: Date())
        }

        if lowercased.starts(with: "get-netadapter") {
            return PowerShellOutput(type: .output, text: """
                Name           InterfaceDescription         Status     MacAddress         LinkSpeed
                ----           --------------------         ------     ----------         ---------
                Ethernet0      Intel I350 Gigabit           Up         00-50-56-C0-00-01  1 Gbps
                Ethernet1      Intel I350 Gigabit           Up         00-50-56-C0-00-02  1 Gbps
                """, timestamp: Date())
        }

        if lowercased.starts(with: "test-connection") {
            let parts = command.split(separator: " ")
            let target = parts.count > 1 ? String(parts[1]) : "localhost"
            return PowerShellOutput(type: .output, text: """
                Source        Destination     IPV4Address      Bytes    Time(ms)
                ------        -----------     -----------      -----    --------
                \(server.host)    \(target)    \(target)    32       \(Int.random(in: 1...50))
                \(server.host)    \(target)    \(target)    32       \(Int.random(in: 1...50))
                \(server.host)    \(target)    \(target)    32       \(Int.random(in: 1...50))
                \(server.host)    \(target)    \(target)    32       \(Int.random(in: 1...50))
                """, timestamp: Date())
        }

        if lowercased.starts(with: "get-date") {
            return PowerShellOutput(type: .output, text: Date().formatted(date: .complete, time: .complete), timestamp: Date())
        }

        if lowercased.starts(with: "whoami") {
            return PowerShellOutput(type: .output, text: "administrator", timestamp: Date())
        }

        if lowercased.starts(with: "hostname") {
            return PowerShellOutput(type: .output, text: server.host, timestamp: Date())
        }

        // Unknown command
        return PowerShellOutput(type: .error, text: "\(command.split(separator: " ").first ?? ""): The term '\(command.split(separator: " ").first ?? "")' is not recognized as the name of a cmdlet, function, script file, or operable program.\nCheck the spelling of the name, or if a path was included, verify that the path is correct and try again.", timestamp: Date())
    }

    enum HistoryDirection {
        case up, down
    }

    private func navigateHistory(direction: HistoryDirection) {
        guard !commandHistory.isEmpty else { return }

        switch direction {
        case .up:
            if let index = historyIndex {
                if index > 0 {
                    historyIndex = index - 1
                    commandInput = commandHistory[index - 1]
                }
            } else {
                historyIndex = commandHistory.count - 1
                commandInput = commandHistory[historyIndex!]
            }
        case .down:
            if let index = historyIndex {
                if index < commandHistory.count - 1 {
                    historyIndex = index + 1
                    commandInput = commandHistory[index + 1]
                } else {
                    historyIndex = nil
                    commandInput = ""
                }
            }
        }
    }
}

// MARK: - Output Models

struct PowerShellOutput: Identifiable {
    let id = UUID()
    let type: OutputType
    let text: String
    let timestamp: Date

    enum OutputType {
        case command
        case output
        case error
        case info
    }
}

struct OutputLineView: View {
    let output: PowerShellOutput

    var textColor: Color {
        switch output.type {
        case .command: return .blue
        case .output: return .primary
        case .error: return .red
        case .info: return .secondary
        }
    }

    var body: some View {
        if !output.text.isEmpty {
            Text(output.text)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(textColor)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Quick Scripts

enum QuickScript: String, CaseIterable, Identifiable {
    case systemInfo = "System Info"
    case processes = "Processes"
    case services = "Services"
    case diskInfo = "Disk Info"
    case networkInfo = "Network Info"
    case eventLogs = "Event Logs"

    var id: String { rawValue }

    var command: String {
        switch self {
        case .systemInfo: return "Get-ComputerInfo"
        case .processes: return "Get-Process | Sort-Object CPU -Descending | Select-Object -First 10"
        case .services: return "Get-Service | Where-Object {$_.Status -eq 'Running'}"
        case .diskInfo: return "Get-Disk"
        case .networkInfo: return "Get-NetAdapter"
        case .eventLogs: return "Get-EventLog -LogName System -Newest 20"
        }
    }

    var icon: String {
        switch self {
        case .systemInfo: return "info.circle"
        case .processes: return "cpu"
        case .services: return "gearshape.2"
        case .diskInfo: return "internaldrive"
        case .networkInfo: return "network"
        case .eventLogs: return "list.bullet.rectangle"
        }
    }
}

struct QuickScriptButton: View {
    let script: QuickScript
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: script.icon)
                    .font(.system(size: 11))
                    .foregroundStyle(.blue)
                    .frame(width: 16)
                Text(script.rawValue)
                    .font(.system(size: 11))
                Spacer()
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Command History Popover

struct CommandHistoryPopover: View {
    let history: [String]
    let onSelect: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Command History")
                .font(.headline)
                .padding()

            Divider()

            if history.isEmpty {
                Text("No command history")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(history.reversed(), id: \.self) { cmd in
                            Button {
                                onSelect(cmd)
                            } label: {
                                Text(cmd)
                                    .font(.system(.body, design: .monospaced))
                                    .lineLimit(1)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal)
                                    .padding(.vertical, 6)
                            }
                            .buttonStyle(.plain)

                            Divider()
                        }
                    }
                }
                .frame(maxHeight: 300)
            }
        }
        .frame(width: 350)
    }
}

#Preview {
    PowerShellView()
}
