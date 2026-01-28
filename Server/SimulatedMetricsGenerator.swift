//
//  SimulatedMetricsGenerator.swift
//  Server
//
//  Created by Claude on 1/27/26.
//

import Foundation

/// Generates simulated server metrics for demonstration purposes.
/// In production, these would be replaced with real metrics from:
/// - SSH connections to Linux/macOS servers
/// - WinRM/PowerShell remoting for Windows servers
/// - SNMP for network devices
/// - Agent-based monitoring solutions
@MainActor
class SimulatedMetricsGenerator {
    static let shared = SimulatedMetricsGenerator()

    private var serverBaselines: [UUID: ServerBaseline] = [:]

    private struct ServerBaseline {
        var cpuBase: Double
        var memoryBase: Double
        var diskBase: Double
        var lastUpdate: Date
    }

    private init() {}

    /// Generate realistic metrics that trend naturally over time
    func generateMetrics(for serverId: UUID, isOnline: Bool) -> ServerMetricValues {
        if !isOnline {
            return ServerMetricValues(
                cpuUsage: 0,
                memoryUsage: 0,
                diskUsage: 0,
                networkIn: 0,
                networkOut: 0,
                activeConnections: 0
            )
        }

        // Get or create baseline for this server
        var baseline = serverBaselines[serverId] ?? createBaseline(for: serverId)

        // Gradually drift the baseline over time (simulates workload changes)
        let timeSinceUpdate = Date().timeIntervalSince(baseline.lastUpdate)
        if timeSinceUpdate > 60 {
            baseline.cpuBase = clamp(baseline.cpuBase + Double.random(in: -5...5), min: 10, max: 70)
            baseline.memoryBase = clamp(baseline.memoryBase + Double.random(in: -2...2), min: 30, max: 85)
            baseline.diskBase = clamp(baseline.diskBase + Double.random(in: 0...0.1), min: 40, max: 95)
            baseline.lastUpdate = Date()
            serverBaselines[serverId] = baseline
        }

        // Add short-term fluctuations around the baseline
        let cpuUsage = clamp(baseline.cpuBase + Double.random(in: -10...15), min: 1, max: 100)
        let memoryUsage = clamp(baseline.memoryBase + Double.random(in: -5...5), min: 10, max: 98)
        let diskUsage = baseline.diskBase // Disk usage changes slowly

        // Network activity correlates loosely with CPU usage
        let networkMultiplier = cpuUsage / 50.0
        let networkIn = Double.random(in: 10...100) * networkMultiplier
        let networkOut = Double.random(in: 5...80) * networkMultiplier

        // Active connections correlate with network activity
        let activeConnections = Int(Double.random(in: 5...30) * networkMultiplier)

        return ServerMetricValues(
            cpuUsage: cpuUsage,
            memoryUsage: memoryUsage,
            diskUsage: diskUsage,
            networkIn: networkIn,
            networkOut: networkOut,
            activeConnections: activeConnections
        )
    }

    private func createBaseline(for serverId: UUID) -> ServerBaseline {
        let baseline = ServerBaseline(
            cpuBase: Double.random(in: 15...50),
            memoryBase: Double.random(in: 40...70),
            diskBase: Double.random(in: 45...75),
            lastUpdate: Date()
        )
        serverBaselines[serverId] = baseline
        return baseline
    }

    private func clamp(_ value: Double, min: Double, max: Double) -> Double {
        return Swift.min(Swift.max(value, min), max)
    }

    /// Reset baseline for a server (e.g., after restart)
    func resetBaseline(for serverId: UUID) {
        serverBaselines.removeValue(forKey: serverId)
    }
}

/// Container for simulated metric values
struct ServerMetricValues {
    let cpuUsage: Double
    let memoryUsage: Double
    let diskUsage: Double
    let networkIn: Double
    let networkOut: Double
    let activeConnections: Int
}
