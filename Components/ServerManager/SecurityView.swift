//
//  SecurityView.swift
//  macOS-Server-2026
//
//  Created on 2026-01-13.
//

import SwiftUI

struct SecurityView: View {
    @ObservedObject var viewModel: ServerManagerViewModel
    
    let securityRecommendations = [
        SecurityRecommendation(title: "Enable Windows Defender Credential Guard", severity: .high, status: .pending),
        SecurityRecommendation(title: "Configure BitLocker for system drives", severity: .high, status: .pending),
        SecurityRecommendation(title: "Update TLS to version 1.3", severity: .medium, status: .inProgress),
        SecurityRecommendation(title: "Enable SMB encryption", severity: .medium, status: .completed),
        SecurityRecommendation(title: "Configure Windows Firewall rules", severity: .low, status: .completed)
    ]
    
    let recentSecurityEvents = [
        SecurityEvent(type: "Login Success", user: "Administrator", time: "2 minutes ago", icon: "checkmark.circle.fill", color: .green),
        SecurityEvent(type: "Failed Login Attempt", user: "Unknown", time: "15 minutes ago", icon: "exclamationmark.circle.fill", color: .red),
        SecurityEvent(type: "Group Policy Update", user: "System", time: "1 hour ago", icon: "gearshape.fill", color: .blue)
    ]
    
    struct SecurityRecommendation {
        let title: String
        let severity: Severity
        let status: Status
        
        enum Severity {
            case high, medium, low
        }
        
        enum Status {
            case pending, inProgress, completed
        }
    }
    
    struct SecurityEvent {
        let type: String
        let user: String
        let time: String
        let icon: String
        let color: Color
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Security Center")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.zinc900)
                Text("Monitor and manage server security settings")
                    .font(.system(size: 13))
                    .foregroundColor(.zinc600)
            }
            .padding(24)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Security Status Cards
                    HStack(spacing: 16) {
                        SecurityStatusCard(
                            icon: "shield.fill",
                            title: "Windows Defender",
                            status: "Active • Real-time protection on",
                            color: .green500
                        )
                        
                        SecurityStatusCard(
                            icon: "lock.fill",
                            title: "BitLocker",
                            status: "Partially configured",
                            color: .yellow500
                        )
                        
                        SecurityStatusCard(
                            icon: "shield.fill",
                            title: "Firewall",
                            status: "Enabled on all profiles",
                            color: .green500
                        )
                    }
                    .padding(.horizontal, 24)
                    
                    // Security Recommendations
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Security Recommendations")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.zinc900)
                        
                        VStack(spacing: 12) {
                            ForEach(Array(securityRecommendations.enumerated()), id: \.offset) { _, rec in
                                RecommendationRow(recommendation: rec)
                            }
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.zinc200.opacity(0.6), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)
                    
                    // Recent Security Events
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recent Security Events")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.zinc900)
                        
                        VStack(spacing: 8) {
                            ForEach(Array(recentSecurityEvents.enumerated()), id: \.offset) { _, event in
                                SecurityEventRow(event: event)
                            }
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.zinc200.opacity(0.6), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
        }
    }
}

struct SecurityStatusCard: View {
    let icon: String
    let title: String
    let status: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.zinc900)
            }
            
            Text(status)
                .font(.system(size: 11))
                .foregroundColor(color)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.zinc200.opacity(0.6), lineWidth: 1)
        )
    }
}

struct RecommendationRow: View {
    let recommendation: SecurityView.SecurityRecommendation
    
    var severityColor: Color {
        switch recommendation.severity {
        case .high: return .red500
        case .medium: return .yellow500
        case .low: return .blue500
        }
    }
    
    var statusColor: Color {
        switch recommendation.status {
        case .completed: return .green500
        case .inProgress: return .blue500
        case .pending: return .zinc400
        }
    }
    
    var statusBackground: Color {
        switch recommendation.status {
        case .completed: return Color.green500.opacity(0.1)
        case .inProgress: return Color.blue500.opacity(0.1)
        case .pending: return Color.zinc200.opacity(0.5)
        }
    }
    
    var statusText: String {
        switch recommendation.status {
        case .completed: return "Completed"
        case .inProgress: return "In Progress"
        case .pending: return "Pending"
        }
    }
    
    var body: some View {
        HStack {
            Circle()
                .fill(severityColor)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(recommendation.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.zinc900)
                Text("Severity: \(recommendation.severity == .high ? "High" : recommendation.severity == .medium ? "Medium" : "Low")")
                    .font(.system(size: 11))
                    .foregroundColor(.zinc600)
            }
            
            Spacer()
            
            Text(statusText)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(statusColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusBackground)
                .cornerRadius(12)
        }
        .padding(12)
        .background(Color.zinc50.opacity(0.3))
        .cornerRadius(8)
    }
}

struct SecurityEventRow: View {
    let event: SecurityView.SecurityEvent
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: event.icon)
                .font(.system(size: 16))
                .foregroundColor(event.color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event.type)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.zinc900)
                Text("\(event.user) • \(event.time)")
                    .font(.system(size: 11))
                    .foregroundColor(.zinc600)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.zinc50.opacity(0.6))
        .cornerRadius(6)
    }
}

#Preview {
    SecurityView(viewModel: ServerManagerViewModel())
        .frame(width: 1200, height: 800)
}
