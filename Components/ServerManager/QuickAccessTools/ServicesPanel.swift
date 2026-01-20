//
//  ServicesPanel.swift
//  macOS-Server-2026
//
//  Created on 2026-01-13.
//

import SwiftUI

struct ServicesPanel: View {
    let services: [Service] = [
        Service(id: "1", name: "DNS", displayName: "DNS Server", status: .running, startupType: .automatic, description: "Provides domain name resolution services"),
        Service(id: "2", name: "NTDS", displayName: "Active Directory Domain Services", status: .running, startupType: .automatic, description: "Provides data storage and retrieval for directory services"),
        Service(id: "3", name: "W3SVC", displayName: "World Wide Web Publishing Service", status: .running, startupType: .automatic, description: "Provides web connectivity and administration"),
        Service(id: "4", name: "EventLog", displayName: "Windows Event Log", status: .running, startupType: .automatic, description: "Manages events and event logs"),
        Service(id: "5", name: "Spooler", displayName: "Print Spooler", status: .running, startupType: .automatic, description: "Loads files to memory for later printing"),
        Service(id: "6", name: "RemoteRegistry", displayName: "Remote Registry", status: .stopped, startupType: .disabled, description: "Enables remote users to modify registry settings"),
        Service(id: "7", name: "WSearch", displayName: "Windows Search", status: .running, startupType: .automatic, description: "Provides content indexing and property caching"),
        Service(id: "8", name: "BITS", displayName: "Background Intelligent Transfer Service", status: .running, startupType: .manual, description: "Transfers files in the background using idle network bandwidth")
    ]
    
    var runningCount: Int {
        services.filter { $0.status == .running }.count
    }
    
    var stoppedCount: Int {
        services.filter { $0.status == .stopped }.count
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Services")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.zinc900)
                    Text("\(runningCount) running, \(stoppedCount) stopped")
                        .font(.system(size: 12))
                        .foregroundColor(.zinc600)
                }
                
                Spacer()
                
                Button(action: {}) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14))
                        Text("Refresh")
                            .font(.system(size: 13))
                    }
                    .foregroundColor(.zinc900)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.zinc200.opacity(0.6), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.zinc200.opacity(0.6)),
                alignment: .bottom
            )
            
            // Action Buttons
            HStack(spacing: 8) {
                Button(action: {}) {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 14))
                        Text("Start")
                            .font(.system(size: 13))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green500)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                
                Button(action: {}) {
                    HStack(spacing: 8) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 14))
                        Text("Stop")
                            .font(.system(size: 13))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.red500)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                
                Button(action: {}) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14))
                        Text("Restart")
                            .font(.system(size: 13))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue500)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.zinc200.opacity(0.6)),
                alignment: .bottom
            )
            
            // Services Table
            ScrollView {
                VStack(spacing: 0) {
                    // Header Row
                    HStack(spacing: 16) {
                        Spacer()
                            .frame(width: 40)
                        
                        Text("Name")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.zinc600)
                            .frame(width: 250, alignment: .leading)
                        
                        Text("Status")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.zinc600)
                            .frame(width: 120, alignment: .leading)
                        
                        Text("Startup Type")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.zinc600)
                            .frame(width: 120, alignment: .leading)
                        
                        Text("Description")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.zinc600)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.zinc50.opacity(0.5))
                    .overlay(
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(Color.zinc200.opacity(0.6)),
                        alignment: .bottom
                    )
                    
                    // Service Rows
                    ForEach(services) { service in
                        ServiceRow(service: service)
                    }
                }
            }
        }
    }
}

struct ServiceRow: View {
    let service: Service
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: service.status == .running ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 16))
                .foregroundColor(service.status == .running ? .green500 : .zinc400)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(service.displayName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.zinc900)
                Text(service.name)
                    .font(.system(size: 11))
                    .foregroundColor(.zinc500)
            }
            .frame(width: 250, alignment: .leading)
            
            Text(service.status.rawValue)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(service.status == .running ? .green500 : .zinc400)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(service.status == .running ? Color.green500.opacity(0.1) : Color.zinc200.opacity(0.5))
                .cornerRadius(12)
                .frame(width: 120, alignment: .leading)
            
            Text(service.startupType.rawValue)
                .font(.system(size: 13))
                .foregroundColor(.zinc700)
                .frame(width: 120, alignment: .leading)
            
            Text(service.description)
                .font(.system(size: 13))
                .foregroundColor(.zinc600)
                .lineLimit(1)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.zinc200.opacity(0.6)),
            alignment: .bottom
        )
    }
}

#Preview {
    ServicesPanel()
        .frame(width: 1200, height: 800)
}
