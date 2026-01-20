//
//  QuickAccessToolsView.swift
//  macOS-Server-2026
//
//  Created on 2026-01-13.
//

import SwiftUI

struct QuickAccessToolsView: View {
    let activeTool: String
    @ObservedObject var viewModel: ServerManagerViewModel
    
    var body: some View {
        Group {
            switch activeTool {
            case "Event Viewer":
                EventViewer()
            case "Services":
                ServicesPanel()
            case "Performance Monitor":
                PerformanceMonitor()
            case "Disk Management":
                DiskManagement()
            case "Task Manager":
                TaskManager()
            case "PowerShell":
                PowerShellConsole()
            default:
                Text("Tool not found")
                    .foregroundColor(.zinc400)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

struct CustomizeQuickAccessDialog: View {
    @ObservedObject var viewModel: ServerManagerViewModel
    @Environment(\.dismiss) var dismiss
    
    let allTools: [(id: String, name: String, icon: String)] = [
        ("event-viewer", "Event Viewer", "doc.text.fill"),
        ("services", "Services", "gearshape.fill"),
        ("performance", "Performance Monitor", "chart.line.uptrend.xyaxis"),
        ("disk", "Disk Management", "externaldrive.fill"),
        ("task", "Task Manager", "cpu.fill"),
        ("powershell", "PowerShell", "terminal.fill"),
        ("firewall", "Windows Firewall", "shield.fill"),
        ("certificates", "Certificate Manager", "lock.fill"),
        ("registry", "Registry Editor", "cylinder.fill"),
        ("group-policy", "Group Policy Editor", "person.3.fill")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Customize Quick Access")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.zinc900)
            
            Text("Select which tools appear in your Quick Access menu")
                .font(.system(size: 13))
                .foregroundColor(.zinc600)
            
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(allTools, id: \.id) { tool in
                        let isSelected = viewModel.quickAccessTools.contains(tool.id)
                        
                        Button(action: {
                            viewModel.handleToggleQuickAccessTool(tool.id)
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: tool.icon)
                                    .font(.system(size: 16))
                                    .foregroundColor(isSelected ? .blue500 : .zinc600)
                                    .frame(width: 32, height: 32)
                                    .background(isSelected ? Color.blue500.opacity(0.1) : Color.zinc100)
                                    .cornerRadius(8)
                                
                                Text(tool.name)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.zinc900)
                                
                                Spacer()
                                
                                if isSelected {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.blue500)
                                }
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(isSelected ? Color.blue500.opacity(0.05) : Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isSelected ? Color.blue500.opacity(0.5) : Color.zinc200.opacity(0.6), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxHeight: 400)
            
            HStack {
                Button("Select All") {
                    viewModel.quickAccessTools = allTools.map { $0.id }
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 600)
    }
}

#Preview {
    QuickAccessToolsView(activeTool: "Event Viewer", viewModel: ServerManagerViewModel())
        .frame(width: 1200, height: 800)
}
