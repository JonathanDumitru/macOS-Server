//
//  UpdatesView.swift
//  macOS-Server-2026
//
//  Created on 2026-01-13.
//

import SwiftUI

struct UpdatesView: View {
    @ObservedObject var viewModel: ServerManagerViewModel
    
    let availableUpdates = [
        UpdateItem(
            title: "2026-01 Cumulative Update for Windows Server 2025",
            kb: "KB5048685",
            size: "487 MB",
            type: "Security Update",
            priority: .critical
        ),
        UpdateItem(
            title: "Security Update for Microsoft Defender",
            kb: "KB5048123",
            size: "12 MB",
            type: "Security Update",
            priority: .important
        ),
        UpdateItem(
            title: "Update for .NET Framework 4.8",
            kb: "KB5047891",
            size: "64 MB",
            type: "Security Update",
            priority: .important
        ),
        UpdateItem(
            title: "Windows Malicious Software Removal Tool",
            kb: "KB890830",
            size: "78 MB",
            type: "Security Update",
            priority: .important
        )
    ]
    
    let updateHistory = [
        HistoryItem(date: "1/10/2026", name: "2025-12 Cumulative Update", status: "Success"),
        HistoryItem(date: "12/15/2025", name: "Security Update for SQL Server", status: "Success"),
        HistoryItem(date: "12/10/2025", name: "Windows Defender Update", status: "Success")
    ]
    
    struct UpdateItem {
        let title: String
        let kb: String
        let size: String
        let type: String
        let priority: Priority
        
        enum Priority {
            case critical, important
        }
    }
    
    struct HistoryItem {
        let date: String
        let name: String
        let status: String
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Windows Updates")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.zinc900)
                Text("Manage server updates and patches")
                    .font(.system(size: 13))
                    .foregroundColor(.zinc600)
            }
            .padding(24)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Alert Banner
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.orange500)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("12 Updates Available")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.orange900)
                            
                            Text("Important security updates are available for your server. Install them to keep your server secure.")
                                .font(.system(size: 13))
                                .foregroundColor(.orange700)
                            
                            HStack(spacing: 8) {
                                Button(action: {}) {
                                    Text("Install All Updates")
                                        .font(.system(size: 13))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color.orange500)
                                        .cornerRadius(6)
                                }
                                .buttonStyle(.plain)
                                
                                Button(action: {}) {
                                    Text("Schedule Installation")
                                        .font(.system(size: 13))
                                        .foregroundColor(.zinc900)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
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
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange50.opacity(0.5))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.orange200.opacity(0.6), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)
                    
                    // Available Updates
                    VStack(spacing: 12) {
                        ForEach(Array(availableUpdates.enumerated()), id: \.offset) { _, update in
                            UpdateRow(update: update)
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Update History
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Update History")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.zinc900)
                        
                        VStack(spacing: 8) {
                            ForEach(Array(updateHistory.enumerated()), id: \.offset) { _, item in
                                HistoryRow(item: item)
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

struct UpdateRow: View {
    let update: UpdatesView.UpdateItem
    
    var priorityColor: Color {
        update.priority == .critical ? .red500 : .orange500
    }
    
    var priorityBackground: Color {
        update.priority == .critical ? Color.red500.opacity(0.1) : Color.orange500.opacity(0.1)
    }
    
    var priorityText: String {
        update.priority == .critical ? "Critical" : "Important"
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(update.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.zinc900)
                    
                    Text(priorityText)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(priorityColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(priorityBackground)
                        .cornerRadius(12)
                }
                
                Text("\(update.kb) • \(update.type) • \(update.size)")
                    .font(.system(size: 12))
                    .foregroundColor(.zinc600)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Button(action: {}) {
                    Text("Install")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue500)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
                
                Button(action: {}) {
                    Text("Details")
                        .font(.system(size: 12))
                        .foregroundColor(.zinc900)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.zinc100)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.zinc200.opacity(0.6), lineWidth: 1)
        )
    }
}

struct HistoryRow: View {
    let item: UpdatesView.HistoryItem
    
    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(.green500)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.zinc900)
                Text("Installed on \(item.date)")
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
    UpdatesView(viewModel: ServerManagerViewModel())
        .frame(width: 1200, height: 800)
}
