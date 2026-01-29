//
//  UptimeTrackingService.swift
//  Server
//
//  Created by Claude on 1/27/26.
//

import Foundation
import SwiftData

@MainActor
class UptimeTrackingService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Record Check

    func recordCheck(
        server: Server,
        isOnline: Bool,
        responseTime: Double?,
        statusCode: Int? = nil,
        errorMessage: String? = nil
    ) {
        // Create individual record
        let record = UptimeRecord(
            serverId: server.id,
            isOnline: isOnline,
            responseTime: responseTime,
            statusCode: statusCode,
            errorMessage: errorMessage
        )
        modelContext.insert(record)

        // Update daily aggregate
        updateDailyAggregate(for: server, with: record)
    }

    // MARK: - Daily Aggregate

    private func updateDailyAggregate(for server: Server, with record: UptimeRecord) {
        let today = Calendar.current.startOfDay(for: Date())

        // Find or create today's aggregate
        let daily = findOrCreateDailyAggregate(serverId: server.id, date: today)

        // Update counts
        daily.totalChecks += 1
        if record.isOnline {
            daily.successfulChecks += 1
        } else {
            daily.failedChecks += 1
        }

        // Update response time stats
        if let responseTime = record.responseTime {
            let n = Double(daily.totalChecks)
            daily.averageResponseTime = ((n - 1) * daily.averageResponseTime + responseTime) / n
            daily.minResponseTime = min(daily.minResponseTime, responseTime)
            daily.maxResponseTime = max(daily.maxResponseTime, responseTime)
        }
    }

    private func findOrCreateDailyAggregate(serverId: UUID, date: Date) -> UptimeDaily {
        let startOfDay = Calendar.current.startOfDay(for: date)

        let descriptor = FetchDescriptor<UptimeDaily>(
            predicate: #Predicate { daily in
                daily.serverId == serverId && daily.date == startOfDay
            }
        )

        if let existing = try? modelContext.fetch(descriptor).first {
            return existing
        }

        let daily = UptimeDaily(serverId: serverId, date: startOfDay)
        modelContext.insert(daily)
        return daily
    }

    // MARK: - Calculate Uptime

    func calculateUptime(for server: Server, period: UptimePeriod) -> Double {
        let startDate = period.startDate

        let descriptor = FetchDescriptor<UptimeDaily>(
            predicate: #Predicate { daily in
                daily.serverId == server.id && daily.date >= startDate
            }
        )

        guard let dailyRecords = try? modelContext.fetch(descriptor),
              !dailyRecords.isEmpty else { return 0 }

        let totalChecks = dailyRecords.reduce(0) { $0 + $1.totalChecks }
        let successfulChecks = dailyRecords.reduce(0) { $0 + $1.successfulChecks }

        guard totalChecks > 0 else { return 0 }
        return Double(successfulChecks) / Double(totalChecks) * 100
    }

    func calculateAverageResponseTime(for server: Server, period: UptimePeriod) -> Double? {
        let startDate = period.startDate

        let descriptor = FetchDescriptor<UptimeDaily>(
            predicate: #Predicate { daily in
                daily.serverId == server.id && daily.date >= startDate
            }
        )

        guard let dailyRecords = try? modelContext.fetch(descriptor),
              !dailyRecords.isEmpty else { return nil }

        let totalResponseTime = dailyRecords.reduce(0.0) { $0 + $1.averageResponseTime }
        let count = dailyRecords.filter { $0.averageResponseTime > 0 }.count

        guard count > 0 else { return nil }
        return totalResponseTime / Double(count)
    }

    // MARK: - Get Chart Data

    func getDailyData(for server: Server, period: UptimePeriod) -> [UptimeDaily] {
        let startDate = period.startDate

        let descriptor = FetchDescriptor<UptimeDaily>(
            predicate: #Predicate { daily in
                daily.serverId == server.id && daily.date >= startDate
            },
            sortBy: [SortDescriptor(\.date)]
        )

        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func getRecentRecords(for server: Server, limit: Int = 100) -> [UptimeRecord] {
        let descriptor = FetchDescriptor<UptimeRecord>(
            predicate: #Predicate { record in
                record.serverId == server.id
            },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        var limitedDescriptor = descriptor
        limitedDescriptor.fetchLimit = limit

        return (try? modelContext.fetch(limitedDescriptor)) ?? []
    }

    // MARK: - Downtime Incidents

    func getDowntimeIncidents(for server: Server, period: UptimePeriod) -> [DowntimeIncident] {
        let records = getRecentRecords(for: server, limit: 1000)
            .filter { $0.timestamp >= period.startDate }
            .sorted { $0.timestamp < $1.timestamp }

        var incidents: [DowntimeIncident] = []
        var currentIncident: DowntimeIncident?

        for record in records {
            if !record.isOnline {
                if currentIncident == nil {
                    currentIncident = DowntimeIncident(
                        startTime: record.timestamp,
                        errorMessage: record.errorMessage
                    )
                }
            } else {
                if var incident = currentIncident {
                    incident.endTime = record.timestamp
                    incidents.append(incident)
                    currentIncident = nil
                }
            }
        }

        // If still in downtime
        if let incident = currentIncident {
            incidents.append(incident)
        }

        return incidents
    }

    // MARK: - Cleanup

    func cleanupOldRecords(keepDays: Int = 90) {
        guard let cutoffDate = Calendar.current.date(byAdding: .day, value: -keepDays, to: Date()) else {
            return
        }

        // Delete old individual records
        let recordDescriptor = FetchDescriptor<UptimeRecord>(
            predicate: #Predicate { record in
                record.timestamp < cutoffDate
            }
        )

        if let oldRecords = try? modelContext.fetch(recordDescriptor) {
            for record in oldRecords {
                modelContext.delete(record)
            }
        }

        // Delete old daily aggregates (keep longer - 1 year)
        guard let dailyCutoff = Calendar.current.date(byAdding: .day, value: -365, to: Date()) else {
            return
        }

        let dailyDescriptor = FetchDescriptor<UptimeDaily>(
            predicate: #Predicate { daily in
                daily.date < dailyCutoff
            }
        )

        if let oldDaily = try? modelContext.fetch(dailyDescriptor) {
            for daily in oldDaily {
                modelContext.delete(daily)
            }
        }
    }
}

// MARK: - Downtime Incident

struct DowntimeIncident: Identifiable {
    let id = UUID()
    let startTime: Date
    var endTime: Date?
    let errorMessage: String?

    var duration: TimeInterval {
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime)
    }

    var isOngoing: Bool {
        endTime == nil
    }

    var formattedDuration: String {
        let totalSeconds = Int(duration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else if minutes > 0 {
            return String(format: "%dm %ds", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }
}
