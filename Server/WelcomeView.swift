//
//  WelcomeView.swift
//  Server
//
//  Created by Jonathan Hines Dumitru on 1/13/26.
//

import SwiftUI
import SwiftData

struct WelcomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 30) {
            // App Icon
            ZStack {
                Circle()
                    .fill(.blue.gradient)
                    .frame(width: 120, height: 120)
                
                Image(systemName: "server.rack")
                    .font(.system(size: 60))
                    .foregroundStyle(.white)
            }
            
            VStack(spacing: 12) {
                Text("Welcome to Server Monitor")
                    .font(.system(size: 32, weight: .bold))
                
                Text("Monitor your web, file, and network servers in real-time")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Real-time Monitoring",
                    description: "Track server status, response times, and performance metrics"
                )
                
                FeatureRow(
                    icon: "bell.badge",
                    title: "Smart Alerts",
                    description: "Get notified when servers go offline or experience issues"
                )
                
                FeatureRow(
                    icon: "list.bullet.rectangle",
                    title: "Detailed Logs",
                    description: "View comprehensive logs and historical data for each server"
                )
            }
            .padding(.vertical)
            
            VStack(spacing: 12) {
                Button {
                    dismiss()
                } label: {
                    Text("Get Started")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                Button {
                    loadSampleData()
                    dismiss()
                } label: {
                    Text("Load Sample Data")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
        .padding(40)
        .frame(width: 600, height: 700)
    }
    
    private func loadSampleData() {
        SampleData.createSampleServers(in: modelContext)
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    WelcomeView()
        .modelContainer(for: Server.self, inMemory: true)
}
