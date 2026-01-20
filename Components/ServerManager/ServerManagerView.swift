//
//  ServerManagerView.swift
//  macOS-Server-2026
//
//  Created on 2026-01-13.
//

import SwiftUI

struct ServerManagerView: View {
    @StateObject private var viewModel = ServerManagerViewModel()
    
    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            SidebarView(viewModel: viewModel)
                .frame(width: 240)
                .background(Color.zinc100.opacity(0.5))
            
            Divider()
                .background(Color.zinc200.opacity(0.6))
            
            // Main Content
            ScrollView {
                Group {
                    switch viewModel.activeTab {
                    case .dashboard:
                        DashboardView(viewModel: viewModel)
                    case .roles:
                        RolesView(viewModel: viewModel)
                    case .storage:
                        StorageView(viewModel: viewModel)
                    case .network:
                        NetworkView(viewModel: viewModel)
                    case .security:
                        SecurityView(viewModel: viewModel)
                    case .updates:
                        UpdatesView(viewModel: viewModel)
                    case .tools:
                        if let tool = viewModel.activeQuickAccessTool {
                            QuickAccessToolsView(activeTool: tool, viewModel: viewModel)
                        } else {
                            Text("Select a tool from Quick Access")
                                .foregroundColor(.zinc400)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color.zinc50)
        }
        .background(Color.zinc50)
        .sheet(isPresented: $viewModel.addRoleDialogOpen) {
            AddRoleDialog(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.configureRoleDialogOpen) {
            ConfigureRoleDialog(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.removeRoleDialogOpen) {
            RemoveRoleDialog(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.newVolumeDialogOpen) {
            NewVolumeDialog(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.volumePropertiesDialogOpen) {
            VolumePropertiesDialog(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.extendVolumeDialogOpen) {
            ExtendVolumeDialog(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.networkConfigDialogOpen) {
            NetworkConfigDialog(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.customizeQuickAccessOpen) {
            CustomizeQuickAccessDialog(viewModel: viewModel)
        }
    }
}

struct SidebarView: View {
    @ObservedObject var viewModel: ServerManagerViewModel
    
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
        VStack(spacing: 0) {
            // Server Info Header
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: "server.rack")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(
                            LinearGradient(
                                colors: [Color.blue500, Color.blue600],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(8)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("SERVER-2025")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.zinc900)
                        Text("Datacenter Edition")
                            .font(.system(size: 11))
                            .foregroundColor(.zinc600)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.clear)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.zinc200.opacity(0.6)),
                alignment: .bottom
            )
            
            ScrollView {
                VStack(spacing: 4) {
                    // Main Navigation
                    SidebarButton(
                        title: "Dashboard",
                        icon: "chart.bar.fill",
                        isSelected: viewModel.activeTab == .dashboard
                    ) {
                        viewModel.activeTab = .dashboard
                    }
                    
                    SidebarButton(
                        title: "Roles & Features",
                        icon: "gearshape.fill",
                        isSelected: viewModel.activeTab == .roles
                    ) {
                        viewModel.activeTab = .roles
                    }
                    
                    SidebarButton(
                        title: "Storage",
                        icon: "externaldrive.fill",
                        isSelected: viewModel.activeTab == .storage
                    ) {
                        viewModel.activeTab = .storage
                    }
                    
                    SidebarButton(
                        title: "Networking",
                        icon: "network",
                        isSelected: viewModel.activeTab == .network
                    ) {
                        viewModel.activeTab = .network
                    }
                    
                    SidebarButton(
                        title: "Security",
                        icon: "shield.fill",
                        isSelected: viewModel.activeTab == .security
                    ) {
                        viewModel.activeTab = .security
                    }
                    
                    SidebarButton(
                        title: "Updates",
                        icon: "arrow.down.circle.fill",
                        isSelected: viewModel.activeTab == .updates,
                        badge: "12"
                    ) {
                        viewModel.activeTab = .updates
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 16)
                
                Divider()
                    .padding(.vertical, 16)
                    .background(Color.zinc200.opacity(0.6))
                
                // Quick Access Section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("QUICK ACCESS")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.zinc500)
                        Spacer()
                        Button(action: {
                            viewModel.customizeQuickAccessOpen = true
                        }) {
                            Image(systemName: "pencil")
                                .font(.system(size: 12))
                                .foregroundColor(.zinc500)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 12)
                    
                    VStack(spacing: 4) {
                        ForEach(viewModel.quickAccessTools, id: \.self) { toolId in
                            if let tool = allTools.first(where: { $0.id == toolId }) {
                                SidebarButton(
                                    title: tool.name,
                                    icon: tool.icon,
                                    isSelected: viewModel.activeTab == .tools && viewModel.activeQuickAccessTool == tool.name,
                                    fontSize: 13
                                ) {
                                    viewModel.handleOpenQuickAccessTool(toolId)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                }
            }
            
            Spacer()
            
            // Footer
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Build:")
                        .font(.system(size: 11))
                        .foregroundColor(.zinc600)
                    Spacer()
                    Text("26100.2608")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.zinc900)
                }
                HStack {
                    Text("License:")
                        .font(.system(size: 11))
                        .foregroundColor(.zinc600)
                    Spacer()
                    Text("Active")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.green500)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.clear)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.zinc200.opacity(0.6)),
                alignment: .top
            )
        }
        .background(Color.zinc100.opacity(0.5))
    }
}

struct SidebarButton: View {
    let title: String
    let icon: String
    var isSelected: Bool = false
    var badge: String? = nil
    var fontSize: CGFloat = 13
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .frame(width: 16)
                
                Text(title)
                    .font(.system(size: fontSize))
                
                if let badge = badge {
                    Spacer()
                    Text(badge)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange500)
                        .cornerRadius(8)
                }
            }
            .foregroundColor(isSelected ? .white : .zinc700)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Color.blue500 : Color.clear)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ServerManagerView()
        .frame(width: 1200, height: 800)
}
