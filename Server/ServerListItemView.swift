//
//  ServerListItemView.swift
//  Server
//
//  Created by Jonathan Hines Dumitru on 1/13/26.
//

import SwiftUI
import SwiftData

struct ServerListItemView: View {
    let server: Server
    @Environment(\.modelContext) private var modelContext
    @State private var uptimePercentage: Double?

    var body: some View {
        HStack(spacing: 10) {
            // Server icon with status overlay
            ZStack(alignment: .bottomTrailing) {
                Image(systemName: server.serverType.iconName)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.primary)
                    .frame(width: 32, height: 32)
                    .background(Color(server.status.color).opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
                
                Circle()
                    .fill(Color(server.status.color))
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .stroke(Color(nsColor: .controlBackgroundColor), lineWidth: 1.5)
                    )
                    .offset(x: 2, y: 2)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(server.name)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)

                    if server.group != nil {
                        ServerGroupBadge(group: server.group, size: .small)
                    }
                }

                HStack(spacing: 6) {
                    Text("\(server.host):\(server.port)")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)

                    if let responseTime = server.responseTime {
                        Text("•")
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                        Text("\(Int(responseTime))ms")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer(minLength: 0)

            // SSL badge for HTTPS servers
            if server.serverType == .https {
                SSLStatusBadge(certificate: server.sslCertificate, showLabel: true, size: .small)
            }

            // Uptime badge
            if let uptime = uptimePercentage, uptime > 0 {
                UptimeBadge(percentage: uptime, showIcon: false)
            }

            // Last checked
            if let lastChecked = server.lastChecked {
                Text(lastChecked, style: .relative)
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 6)
        .onAppear {
            loadUptime()
        }
    }

    private func loadUptime() {
        let service = UptimeTrackingService(modelContext: modelContext)
        let percentage = service.calculateUptime(for: server, period: .week7d)
        if percentage > 0 {
            uptimePercentage = percentage
        }
    }
}
