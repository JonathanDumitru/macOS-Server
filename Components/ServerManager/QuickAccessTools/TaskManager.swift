//
//  TaskManager.swift
//  macOS-Server-2026
//
//  Created on 2026-01-13.
//

import SwiftUI

struct TaskManager: View {
    let processes = [
        ProcessInfo(name: "System", cpu: "0.1%", memory: "142 MB", disk: "0 MB/s", network: "0 Mbps"),
        ProcessInfo(name: "svchost.exe", cpu: "0.3%", memory: "48 MB", disk: "0.1 MB/s", network: "0 Mbps"),
        ProcessInfo(name: "explorer.exe", cpu: "1.2%", memory: "89 MB", disk: "0 MB/s", network: "0.2 Mbps"),
        ProcessInfo(name: "chrome.exe", cpu: "4.5%", memory: "324 MB", disk: "0.5 MB/s", network: "1.2 Mbps"),
        ProcessInfo(name: "sqlservr.exe", cpu: "2.1%", memory: "512 MB", disk: "2.3 MB/s", network: "0.1 Mbps")
    ]
    
    struct ProcessInfo {
        let name: String
        let cpu: String
        let memory: String
        let disk: String
        let network: String
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Task Manager")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.zinc900)
                Text("Monitor running processes and resource usage")
                    .font(.system(size: 13))
                    .foregroundColor(.zinc600)
            }
            .padding(24)
            
            ScrollView {
                VStack(spacing: 0) {
                    // Header Row
                    HStack(spacing: 16) {
                        Text("Name")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.zinc600)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("CPU")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.zinc600)
                            .frame(width: 100, alignment: .leading)
                        
                        Text("Memory")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.zinc600)
                            .frame(width: 100, alignment: .leading)
                        
                        Text("Disk")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.zinc600)
                            .frame(width: 100, alignment: .leading)
                        
                        Text("Network")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.zinc600)
                            .frame(width: 100, alignment: .leading)
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
                    
                    // Process Rows
                    ForEach(Array(processes.enumerated()), id: \.offset) { _, process in
                        ProcessRow(process: process)
                    }
                }
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

struct ProcessRow: View {
    let process: TaskManager.ProcessInfo
    
    var body: some View {
        HStack(spacing: 16) {
            Text(process.name)
                .font(.system(size: 13))
                .foregroundColor(.zinc900)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(process.cpu)
                .font(.system(size: 13))
                .foregroundColor(.zinc700)
                .frame(width: 100, alignment: .leading)
            
            Text(process.memory)
                .font(.system(size: 13))
                .foregroundColor(.zinc700)
                .frame(width: 100, alignment: .leading)
            
            Text(process.disk)
                .font(.system(size: 13))
                .foregroundColor(.zinc700)
                .frame(width: 100, alignment: .leading)
            
            Text(process.network)
                .font(.system(size: 13))
                .foregroundColor(.zinc700)
                .frame(width: 100, alignment: .leading)
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
    TaskManager()
        .frame(width: 1200, height: 800)
}
