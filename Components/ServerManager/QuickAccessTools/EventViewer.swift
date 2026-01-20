//
//  EventViewer.swift
//  macOS-Server-2026
//
//  Created on 2026-01-13.
//

import SwiftUI

struct EventViewer: View {
    let events: [Event] = [
        Event(id: "1", level: .information, source: "Microsoft-Windows-Security-Auditing", eventId: 4624, message: "An account was successfully logged on", time: "1/13/2026 10:45:23 AM"),
        Event(id: "2", level: .warning, source: "Microsoft-Windows-Disk", eventId: 51, message: "An error was detected on device \\Device\\Harddisk0\\DR0", time: "1/13/2026 10:30:15 AM"),
        Event(id: "3", level: .information, source: "Service Control Manager", eventId: 7036, message: "The Windows Update service entered the running state", time: "1/13/2026 10:15:42 AM"),
        Event(id: "4", level: .error, source: "Application Error", eventId: 1000, message: "Faulting application name: explorer.exe", time: "1/13/2026 9:58:11 AM"),
        Event(id: "5", level: .information, source: "Microsoft-Windows-Kernel-Power", eventId: 109, message: "The kernel power manager has initiated a shutdown transition", time: "1/13/2026 9:45:33 AM"),
        Event(id: "6", level: .warning, source: "Microsoft-Windows-WindowsUpdateClient", eventId: 20, message: "Installation Failure: Windows failed to install update", time: "1/13/2026 9:30:22 AM")
    ]
    
    var eventCounts: (information: Int, warning: Int, error: Int, critical: Int) {
        (
            information: events.filter { $0.level == .information }.count,
            warning: events.filter { $0.level == .warning }.count,
            error: events.filter { $0.level == .error }.count,
            critical: events.filter { $0.level == .critical }.count
        )
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            VStack(alignment: .leading, spacing: 16) {
                Text("Event Logs")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.zinc900)
                
                VStack(spacing: 4) {
                    ForEach(["Application", "Security", "Setup", "System", "Forwarded Events"], id: \.self) { log in
                        Button(action: {}) {
                            Text(log)
                                .font(.system(size: 13))
                                .foregroundColor(.zinc700)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Divider()
                    .padding(.vertical, 8)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("SUMMARY")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.zinc500)
                    
                    SummaryRow(color: .blue500, label: "Info", count: eventCounts.information)
                    SummaryRow(color: .yellow500, label: "Warning", count: eventCounts.warning)
                    SummaryRow(color: .red500, label: "Error", count: eventCounts.error)
                }
            }
            .padding(16)
            .frame(width: 200)
            .background(Color.zinc100.opacity(0.5))
            .overlay(
                Rectangle()
                    .frame(width: 1)
                    .foregroundColor(Color.zinc200.opacity(0.6)),
                alignment: .trailing
            )
            
            // Main Content
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("System Events")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.zinc900)
                        Text("\(events.count) events")
                            .font(.system(size: 12))
                            .foregroundColor(.zinc600)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Button(action: {}) {
                            Text("Refresh")
                                .font(.system(size: 13))
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
                        
                        Button(action: {}) {
                            Text("Filter")
                                .font(.system(size: 13))
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
                }
                .padding(16)
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color.zinc200.opacity(0.6)),
                    alignment: .bottom
                )
                
                // Events Table
                ScrollView {
                    VStack(spacing: 0) {
                        // Header Row
                        HStack(spacing: 16) {
                            Text("Level")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.zinc600)
                                .frame(width: 60)
                            
                            Text("Event ID")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.zinc600)
                                .frame(width: 100)
                            
                            Text("Source")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.zinc600)
                                .frame(width: 200)
                            
                            Text("Category")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.zinc600)
                                .frame(width: 80)
                            
                            Text("Message")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.zinc600)
                            
                            Text("Date and Time")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.zinc600)
                                .frame(width: 140)
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
                        
                        // Event Rows
                        ForEach(events) { event in
                            EventRow(event: event)
                        }
                    }
                }
            }
        }
    }
}

struct SummaryRow: View {
    let color: Color
    let label: String
    let count: Int
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.zinc700)
            
            Spacer()
            
            Text("\(count)")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.zinc900)
        }
    }
}

struct EventRow: View {
    let event: Event
    
    var levelIcon: (name: String, color: Color) {
        switch event.level {
        case .information:
            return ("info.circle.fill", .blue500)
        case .warning:
            return ("exclamationmark.triangle.fill", .yellow500)
        case .error:
            return ("xmark.circle.fill", .red500)
        case .critical:
            return ("exclamationmark.circle.fill", .red600)
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: levelIcon.name)
                .font(.system(size: 16))
                .foregroundColor(levelIcon.color)
                .frame(width: 60)
            
            Text("\(event.eventId)")
                .font(.system(size: 13))
                .foregroundColor(.zinc900)
                .frame(width: 100)
            
            Text(event.source)
                .font(.system(size: 13))
                .foregroundColor(.zinc700)
                .frame(width: 200)
                .lineLimit(1)
            
            Text("None")
                .font(.system(size: 13))
                .foregroundColor(.zinc700)
                .frame(width: 80)
            
            Text(event.message)
                .font(.system(size: 13))
                .foregroundColor(.zinc700)
                .lineLimit(1)
            
            Text(event.time)
                .font(.system(size: 13))
                .foregroundColor(.zinc600)
                .frame(width: 140)
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
    EventViewer()
        .frame(width: 1200, height: 800)
}
