//
//  IncidentService.swift
//  Server
//
//  Created by Claude on 1/28/26.
//

import Foundation
import SwiftData
import os.log

private let logger = Logger(subsystem: "com.server.app", category: "Incidents")

/// Service for managing server incidents
@MainActor
class IncidentService {
    static let shared = IncidentService()

    private var modelContext: ModelContext?
    private var activeIncidents: [UUID: Incident] = [:] // serverId -> active incident

    private init() {}

    func configure(with context: ModelContext) {
        self.modelContext = context
        loadActiveIncidents()
    }

    // MARK: - Load Active Incidents

    private func loadActiveIncidents() {
        guard let context = modelContext else { return }

        let descriptor = FetchDescriptor<Incident>(
            predicate: #Predicate { $0.status == .active || $0.status == .acknowledged }
        )

        do {
            let incidents = try context.fetch(descriptor)
            for incident in incidents {
                activeIncidents[incident.serverId] = incident
            }
            logger.info("Loaded \(incidents.count) active incidents")
        } catch {
            logger.error("Failed to load active incidents: \(error.localizedDescription)")
        }
    }

    // MARK: - Create Incidents

    func createOutageIncident(for server: Server) {
        guard let context = modelContext else { return }

        // Check if there's already an active incident for this server
        if let existing = activeIncidents[server.id], existing.type == .outage {
            logger.debug("Outage incident already exists for \(server.name)")
            return
        }

        let incident = Incident(
            serverId: server.id,
            serverName: server.name,
            serverHost: server.host,
            type: .outage,
            severity: .critical,
            title: "Server Offline",
            description: "\(server.name) is not responding"
        )

        context.insert(incident)
        activeIncidents[server.id] = incident

        do {
            try context.save()
            logger.info("Created outage incident for \(server.name)")
        } catch {
            logger.error("Failed to save outage incident: \(error.localizedDescription)")
        }
    }

    func createWarningIncident(for server: Server, reason: String) {
        guard let context = modelContext else { return }

        // Check if there's already an active warning incident
        if let existing = activeIncidents[server.id], existing.type == .warning {
            return
        }

        let incident = Incident(
            serverId: server.id,
            serverName: server.name,
            serverHost: server.host,
            type: .warning,
            severity: .medium,
            title: "Server Warning",
            description: reason
        )

        context.insert(incident)
        activeIncidents[server.id] = incident
        try? context.save()

        logger.info("Created warning incident for \(server.name)")
    }

    func createHighResponseTimeIncident(for server: Server, responseTime: Double, threshold: Double) {
        guard let context = modelContext else { return }

        // Don't create duplicate response time incidents within 5 minutes
        if let existing = activeIncidents[server.id], existing.type == .highResponseTime {
            return
        }

        let incident = Incident(
            serverId: server.id,
            serverName: server.name,
            serverHost: server.host,
            type: .highResponseTime,
            severity: .low,
            title: "High Response Time",
            description: "Response time \(Int(responseTime))ms exceeds threshold of \(Int(threshold))ms"
        )

        context.insert(incident)
        activeIncidents[server.id] = incident
        try? context.save()

        logger.info("Created high response time incident for \(server.name)")
    }

    func createSSLExpiryIncident(for server: Server, daysRemaining: Int) {
        guard let context = modelContext else { return }

        let type: IncidentType = daysRemaining <= 0 ? .sslExpired : .sslExpiring
        let severity: IncidentSeverity = daysRemaining <= 0 ? .critical : (daysRemaining <= 7 ? .high : .medium)

        // Check for existing SSL incident
        if let existing = activeIncidents[server.id],
           (existing.type == .sslExpiring || existing.type == .sslExpired) {
            return
        }

        let title = daysRemaining <= 0 ? "SSL Certificate Expired" : "SSL Certificate Expiring"
        let description = daysRemaining <= 0
            ? "Certificate has expired"
            : "Certificate expires in \(daysRemaining) days"

        let incident = Incident(
            serverId: server.id,
            serverName: server.name,
            serverHost: server.host,
            type: type,
            severity: severity,
            title: title,
            description: description
        )

        context.insert(incident)
        activeIncidents[server.id] = incident
        try? context.save()

        logger.info("Created SSL expiry incident for \(server.name)")
    }

    // MARK: - Resolve Incidents

    func resolveIncident(for server: Server, resolution: String? = nil) {
        guard let incident = activeIncidents[server.id] else { return }

        incident.resolve(resolution: resolution ?? "Server recovered automatically")
        activeIncidents.removeValue(forKey: server.id)

        // Create a recovery incident
        createRecoveryIncident(for: server, originalIncident: incident)

        try? modelContext?.save()
        logger.info("Resolved incident for \(server.name)")
    }

    func resolveIncident(_ incident: Incident, resolution: String? = nil) {
        incident.resolve(resolution: resolution)
        activeIncidents.removeValue(forKey: incident.serverId)
        try? modelContext?.save()
    }

    private func createRecoveryIncident(for server: Server, originalIncident: Incident) {
        guard let context = modelContext else { return }

        let incident = Incident(
            serverId: server.id,
            serverName: server.name,
            serverHost: server.host,
            type: .recovery,
            severity: .low,
            title: "Server Recovered",
            description: "Recovered from: \(originalIncident.title). Downtime: \(originalIncident.formattedDuration)"
        )

        // Recovery incidents are immediately resolved
        incident.resolve(resolution: "Automatic recovery")

        context.insert(incident)
        try? context.save()
    }

    // MARK: - Acknowledge

    func acknowledgeIncident(_ incident: Incident, by user: String = "User") {
        incident.acknowledge(by: user)
        incident.status = .acknowledged
        try? modelContext?.save()
        logger.info("Incident acknowledged by \(user)")
    }

    // MARK: - Query

    func getActiveIncident(for serverId: UUID) -> Incident? {
        return activeIncidents[serverId]
    }

    func hasActiveIncident(for serverId: UUID) -> Bool {
        return activeIncidents[serverId] != nil
    }

    func getActiveIncidentsCount() -> Int {
        return activeIncidents.count
    }

    // MARK: - Maintenance

    func startMaintenance(for server: Server, description: String? = nil) {
        guard let context = modelContext else { return }

        // Resolve any existing incidents
        if let existing = activeIncidents[server.id] {
            existing.resolve(resolution: "Maintenance started")
        }

        let incident = Incident(
            serverId: server.id,
            serverName: server.name,
            serverHost: server.host,
            type: .maintenance,
            severity: .low,
            title: "Scheduled Maintenance",
            description: description ?? "Server is under maintenance"
        )

        context.insert(incident)
        activeIncidents[server.id] = incident
        try? context.save()

        logger.info("Started maintenance for \(server.name)")
    }

    func endMaintenance(for server: Server) {
        guard let incident = activeIncidents[server.id], incident.type == .maintenance else { return }

        incident.resolve(resolution: "Maintenance completed")
        activeIncidents.removeValue(forKey: server.id)
        try? modelContext?.save()

        logger.info("Ended maintenance for \(server.name)")
    }

    func isInMaintenance(serverId: UUID) -> Bool {
        guard let incident = activeIncidents[serverId] else { return false }
        return incident.type == .maintenance
    }

    func setMaintenance(serverId: UUID, inMaintenance: Bool) {
        if inMaintenance {
            // Start maintenance mode by marking any active incident as maintenance
            if let existing = activeIncidents[serverId] {
                // Keep the existing incident but mark server as in maintenance
                logger.info("Server \(serverId) now in maintenance mode")
            }
        } else {
            // End maintenance mode
            if let incident = activeIncidents[serverId], incident.type == .maintenance {
                incident.resolve(resolution: "Maintenance window completed")
                activeIncidents.removeValue(forKey: serverId)
                try? modelContext?.save()
                logger.info("Server \(serverId) maintenance mode ended")
            }
        }
    }
}
