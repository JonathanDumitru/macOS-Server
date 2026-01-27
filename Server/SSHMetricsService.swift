//
//  SSHMetricsService.swift
//  Server
//
//  Created by Claude on 1/27/26.
//

import Foundation

// MARK: - Real Server Metrics

struct RealServerMetrics {
    let cpuUsage: Double?
    let memoryUsage: Double?
    let memoryTotal: UInt64?
    let memoryUsed: UInt64?
    let diskUsage: Double?
    let diskTotal: UInt64?
    let diskUsed: UInt64?
    let networkIn: Double?
    let networkOut: Double?
    let loadAverage: (one: Double, five: Double, fifteen: Double)?
    let uptime: TimeInterval?
    let processCount: Int?
    let timestamp: Date

    init(
        cpuUsage: Double? = nil,
        memoryUsage: Double? = nil,
        memoryTotal: UInt64? = nil,
        memoryUsed: UInt64? = nil,
        diskUsage: Double? = nil,
        diskTotal: UInt64? = nil,
        diskUsed: UInt64? = nil,
        networkIn: Double? = nil,
        networkOut: Double? = nil,
        loadAverage: (one: Double, five: Double, fifteen: Double)? = nil,
        uptime: TimeInterval? = nil,
        processCount: Int? = nil,
        timestamp: Date = Date()
    ) {
        self.cpuUsage = cpuUsage
        self.memoryUsage = memoryUsage
        self.memoryTotal = memoryTotal
        self.memoryUsed = memoryUsed
        self.diskUsage = diskUsage
        self.diskTotal = diskTotal
        self.diskUsed = diskUsed
        self.networkIn = networkIn
        self.networkOut = networkOut
        self.loadAverage = loadAverage
        self.uptime = uptime
        self.processCount = processCount
        self.timestamp = timestamp
    }
}

// MARK: - SSH Metrics Service

class SSHMetricsService {
    static let shared = SSHMetricsService()

    private init() {}

    // MARK: - Collect Metrics

    /// Collect metrics from a server via SSH
    func collectMetrics(
        host: String,
        port: Int,
        credentials: ServerCredentials
    ) async -> Result<RealServerMetrics, SSHMetricsError> {
        // Build the SSH command based on authentication type
        let sshArgs = buildSSHArguments(host: host, port: port, credentials: credentials)

        // Commands to run on the remote server
        let metricsCommands = buildMetricsCommands()

        return await executeSSHCommand(
            args: sshArgs,
            remoteCommand: metricsCommands,
            credentials: credentials
        )
    }

    // MARK: - Build SSH Arguments

    private func buildSSHArguments(host: String, port: Int, credentials: ServerCredentials) -> [String] {
        var args: [String] = [
            "-o", "StrictHostKeyChecking=no",
            "-o", "BatchMode=yes",
            "-o", "ConnectTimeout=10",
            "-p", "\(port)",
            "-l", credentials.username
        ]

        // Add key file if using key-based auth
        if credentials.authType != .password, let privateKey = credentials.privateKey {
            // Write key to temporary file
            let keyPath = writeTemporaryKeyFile(privateKey)
            if let keyPath = keyPath {
                args.append(contentsOf: ["-i", keyPath])
            }
        }

        args.append(host)

        return args
    }

    // MARK: - Build Metrics Commands

    private func buildMetricsCommands() -> String {
        // Combined command to gather all metrics in one SSH session
        // Works on Linux servers (most common for monitoring)
        return """
        echo "===CPU===" && \
        top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}' 2>/dev/null || \
        mpstat 1 1 | tail -1 | awk '{print 100 - $NF}' 2>/dev/null || \
        echo "N/A" && \
        echo "===MEMORY===" && \
        free -b | grep Mem | awk '{print $2, $3, $3/$2*100}' 2>/dev/null || \
        echo "N/A" && \
        echo "===DISK===" && \
        df -B1 / | tail -1 | awk '{print $2, $3, $5}' 2>/dev/null || \
        echo "N/A" && \
        echo "===LOAD===" && \
        cat /proc/loadavg | awk '{print $1, $2, $3}' 2>/dev/null || \
        uptime | awk -F'load average:' '{print $2}' | awk '{print $1, $2, $3}' 2>/dev/null || \
        echo "N/A" && \
        echo "===UPTIME===" && \
        cat /proc/uptime | awk '{print $1}' 2>/dev/null || \
        echo "N/A" && \
        echo "===PROCS===" && \
        ps aux | wc -l 2>/dev/null || \
        echo "N/A" && \
        echo "===NETWORK===" && \
        cat /proc/net/dev | grep -E 'eth0|ens|enp' | head -1 | awk '{print $2, $10}' 2>/dev/null || \
        echo "N/A" && \
        echo "===END==="
        """
    }

    // MARK: - Execute SSH Command

    private func executeSSHCommand(
        args: [String],
        remoteCommand: String,
        credentials: ServerCredentials
    ) async -> Result<RealServerMetrics, SSHMetricsError> {
        return await withCheckedContinuation { continuation in
            let process = Process()
            let outputPipe = Pipe()
            let errorPipe = Pipe()

            process.executableURL = URL(fileURLWithPath: "/usr/bin/ssh")
            process.arguments = args + [remoteCommand]
            process.standardOutput = outputPipe
            process.standardError = errorPipe

            // For password auth, we need to use sshpass or expect
            // This is a limitation - in production, use a proper SSH library
            if credentials.authType == .password {
                // Use sshpass if available, otherwise this won't work for password auth
                process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
                process.arguments = ["sshpass", "-p", credentials.password, "ssh"] + args + [remoteCommand]
            }

            var hasResumed = false
            let resumeOnce: (Result<RealServerMetrics, SSHMetricsError>) -> Void = { result in
                guard !hasResumed else { return }
                hasResumed = true
                continuation.resume(returning: result)
            }

            // Timeout handler
            let timeoutWork = DispatchWorkItem {
                process.terminate()
                resumeOnce(.failure(.timeout))
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + 30, execute: timeoutWork)

            process.terminationHandler = { process in
                timeoutWork.cancel()

                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

                let output = String(data: outputData, encoding: .utf8) ?? ""
                let errorOutput = String(data: errorData, encoding: .utf8) ?? ""

                if process.terminationStatus == 0 {
                    let metrics = self.parseMetricsOutput(output)
                    resumeOnce(.success(metrics))
                } else {
                    if errorOutput.contains("Permission denied") {
                        resumeOnce(.failure(.authenticationFailed))
                    } else if errorOutput.contains("Connection refused") {
                        resumeOnce(.failure(.connectionRefused))
                    } else if errorOutput.contains("No route to host") || errorOutput.contains("Network is unreachable") {
                        resumeOnce(.failure(.hostUnreachable))
                    } else {
                        resumeOnce(.failure(.commandFailed(errorOutput)))
                    }
                }

                // Cleanup temp key file
                self.cleanupTemporaryKeyFile()
            }

            do {
                try process.run()
            } catch {
                timeoutWork.cancel()
                resumeOnce(.failure(.sshNotAvailable))
            }
        }
    }

    // MARK: - Parse Metrics Output

    private func parseMetricsOutput(_ output: String) -> RealServerMetrics {
        var cpuUsage: Double?
        var memoryUsage: Double?
        var memoryTotal: UInt64?
        var memoryUsed: UInt64?
        var diskUsage: Double?
        var diskTotal: UInt64?
        var diskUsed: UInt64?
        var loadAverage: (Double, Double, Double)?
        var uptime: TimeInterval?
        var processCount: Int?

        // Parse each section
        let sections = output.components(separatedBy: "===")

        for i in stride(from: 0, to: sections.count - 1, by: 2) {
            let header = sections[i].trimmingCharacters(in: .whitespacesAndNewlines)
            let content = i + 1 < sections.count ? sections[i + 1].trimmingCharacters(in: .whitespacesAndNewlines) : ""

            switch header {
            case "CPU":
                cpuUsage = Double(content.components(separatedBy: .whitespaces).first ?? "")

            case "MEMORY":
                let parts = content.components(separatedBy: .whitespaces)
                if parts.count >= 3 {
                    memoryTotal = UInt64(parts[0])
                    memoryUsed = UInt64(parts[1])
                    memoryUsage = Double(parts[2])
                }

            case "DISK":
                let parts = content.components(separatedBy: .whitespaces)
                if parts.count >= 3 {
                    diskTotal = UInt64(parts[0])
                    diskUsed = UInt64(parts[1])
                    if let percentStr = parts[2].replacingOccurrences(of: "%", with: "") as String?,
                       let percent = Double(percentStr) {
                        diskUsage = percent
                    }
                }

            case "LOAD":
                let parts = content.replacingOccurrences(of: ",", with: "").components(separatedBy: .whitespaces)
                if parts.count >= 3,
                   let one = Double(parts[0]),
                   let five = Double(parts[1]),
                   let fifteen = Double(parts[2]) {
                    loadAverage = (one, five, fifteen)
                }

            case "UPTIME":
                uptime = TimeInterval(content) ?? nil

            case "PROCS":
                processCount = Int(content)

            default:
                break
            }
        }

        return RealServerMetrics(
            cpuUsage: cpuUsage,
            memoryUsage: memoryUsage,
            memoryTotal: memoryTotal,
            memoryUsed: memoryUsed,
            diskUsage: diskUsage,
            diskTotal: diskTotal,
            diskUsed: diskUsed,
            loadAverage: loadAverage,
            uptime: uptime,
            processCount: processCount
        )
    }

    // MARK: - Temporary Key File Management

    private var tempKeyPath: String?

    private func writeTemporaryKeyFile(_ privateKey: String) -> String? {
        let tempDir = FileManager.default.temporaryDirectory
        let keyPath = tempDir.appendingPathComponent("ssh_key_\(UUID().uuidString)").path

        do {
            try privateKey.write(toFile: keyPath, atomically: true, encoding: .utf8)
            // Set proper permissions (600)
            try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: keyPath)
            tempKeyPath = keyPath
            return keyPath
        } catch {
            return nil
        }
    }

    private func cleanupTemporaryKeyFile() {
        if let path = tempKeyPath {
            try? FileManager.default.removeItem(atPath: path)
            tempKeyPath = nil
        }
    }
}

// MARK: - SSH Metrics Errors

enum SSHMetricsError: LocalizedError {
    case sshNotAvailable
    case authenticationFailed
    case connectionRefused
    case hostUnreachable
    case timeout
    case commandFailed(String)
    case noCredentials

    var errorDescription: String? {
        switch self {
        case .sshNotAvailable:
            return "SSH command not available"
        case .authenticationFailed:
            return "Authentication failed - check credentials"
        case .connectionRefused:
            return "Connection refused"
        case .hostUnreachable:
            return "Host unreachable"
        case .timeout:
            return "Connection timed out"
        case .commandFailed(let message):
            return "Command failed: \(message)"
        case .noCredentials:
            return "No credentials configured"
        }
    }
}

// MARK: - Alternative: Simple Metrics Commands

extension SSHMetricsService {
    /// Run a single command and return output
    func runRemoteCommand(
        host: String,
        port: Int,
        credentials: ServerCredentials,
        command: String
    ) async -> Result<String, SSHMetricsError> {
        let sshArgs = buildSSHArguments(host: host, port: port, credentials: credentials)

        return await withCheckedContinuation { continuation in
            let process = Process()
            let outputPipe = Pipe()
            let errorPipe = Pipe()

            process.executableURL = URL(fileURLWithPath: "/usr/bin/ssh")
            process.arguments = sshArgs + [command]
            process.standardOutput = outputPipe
            process.standardError = errorPipe

            var hasResumed = false
            let resumeOnce: (Result<String, SSHMetricsError>) -> Void = { result in
                guard !hasResumed else { return }
                hasResumed = true
                continuation.resume(returning: result)
            }

            process.terminationHandler = { process in
                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: outputData, encoding: .utf8) ?? ""

                if process.terminationStatus == 0 {
                    resumeOnce(.success(output))
                } else {
                    let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                    let errorOutput = String(data: errorData, encoding: .utf8) ?? ""
                    resumeOnce(.failure(.commandFailed(errorOutput)))
                }

                self.cleanupTemporaryKeyFile()
            }

            do {
                try process.run()
            } catch {
                resumeOnce(.failure(.sshNotAvailable))
            }
        }
    }
}
