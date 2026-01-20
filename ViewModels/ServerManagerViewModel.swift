//
//  ServerManagerViewModel.swift
//  macOS-Server-2026
//
//  Created on 2026-01-13.
//

import Foundation
import SwiftUI
import Combine

class ServerManagerViewModel: ObservableObject {
    @Published var activeTab: Tab = .dashboard
    @Published var selectedRole: String? = nil
    @Published var activeQuickAccessTool: String? = nil
    
    // Dialog states
    @Published var addRoleDialogOpen = false
    @Published var configureRoleDialogOpen = false
    @Published var removeRoleDialogOpen = false
    @Published var selectedRoleForAction: ServerRole? = nil
    
    @Published var newVolumeDialogOpen = false
    @Published var volumePropertiesDialogOpen = false
    @Published var extendVolumeDialogOpen = false
    @Published var selectedVolume: StorageVolume? = nil
    
    @Published var networkConfigDialogOpen = false
    @Published var selectedAdapter: NetworkAdapter? = nil
    
    @Published var customizeQuickAccessOpen = false
    
    // Data
    @Published var roles: [ServerRole] = []
    @Published var volumes: [StorageVolume] = []
    @Published var adapters: [NetworkAdapter] = []
    @Published var quickAccessTools: [String] = []
    
    // Form states
    @Published var newVolumeName = ""
    @Published var newVolumeSize = ""
    @Published var newVolumeType = "NTFS"
    @Published var extendVolumeAmount = ""
    @Published var adapterIP = ""
    @Published var adapterDHCP = false
    
    enum Tab: String {
        case dashboard
        case roles
        case storage
        case network
        case security
        case updates
        case tools
    }
    
    init() {
        loadInitialData()
    }
    
    func loadInitialData() {
        // Load roles
        roles = [
            ServerRole(
                id: "1",
                name: "Active Directory Domain Services",
                status: .installed,
                description: "Stores information about network objects and enables administrators to manage users and resources",
                iconName: "person.3.fill",
                subFeatures: [
                    "Domain Controller",
                    "DNS Server",
                    "Global Catalog",
                    "LDAP Server",
                    "Kerberos Authentication",
                    "Group Policy Management"
                ],
                lastUpdated: "1/10/2026"
            ),
            ServerRole(
                id: "2",
                name: "DNS Server",
                status: .installed,
                description: "Provides domain name resolution services for TCP/IP networks",
                iconName: "network",
                subFeatures: [
                    "Forward Lookup Zones",
                    "Reverse Lookup Zones",
                    "Conditional Forwarders",
                    "DNSSEC",
                    "DNS Policy"
                ],
                lastUpdated: "1/10/2026"
            ),
            ServerRole(
                id: "3",
                name: "File and Storage Services",
                status: .installed,
                description: "Manages file servers, storage spaces, and provides sharing capabilities",
                iconName: "externaldrive.fill",
                subFeatures: [
                    "File Server",
                    "Storage Spaces",
                    "Data Deduplication",
                    "DFS Namespace",
                    "DFS Replication",
                    "File Server VSS Agent",
                    "iSCSI Target Server"
                ],
                lastUpdated: "1/12/2026"
            ),
            ServerRole(
                id: "4",
                name: "Web Server (IIS)",
                status: .available,
                description: "Provides reliable, manageable web server infrastructure with support for ASP.NET",
                iconName: "globe",
                subFeatures: [
                    "HTTP Activation",
                    "Application Development",
                    "Security Features",
                    "Performance Features",
                    "Management Tools",
                    "FTP Server"
                ]
            ),
            ServerRole(
                id: "5",
                name: "Remote Desktop Services",
                status: .available,
                description: "Enables users to connect to virtual desktops, RemoteApp programs, and session-based desktops",
                iconName: "server.rack",
                subFeatures: [
                    "RD Session Host",
                    "RD Connection Broker",
                    "RD Gateway",
                    "RD Licensing",
                    "RD Web Access"
                ]
            ),
            ServerRole(
                id: "6",
                name: "Hyper-V",
                status: .installing,
                description: "Creates and manages virtual machines with hardware virtualization",
                iconName: "square.stack.3d.up.fill",
                subFeatures: [
                    "Virtual Machine Management",
                    "Virtual Switch Manager",
                    "Virtual SAN",
                    "Replica",
                    "Live Migration"
                ]
            ),
            ServerRole(
                id: "7",
                name: "DHCP Server",
                status: .available,
                description: "Automatically assigns IP addresses to client computers",
                iconName: "wifi",
                subFeatures: [
                    "IPv4 Support",
                    "IPv6 Support",
                    "Failover",
                    "Policy-based Assignment"
                ]
            ),
            ServerRole(
                id: "8",
                name: "Windows Server Update Services",
                status: .available,
                description: "Manages and distributes updates released through Microsoft Update",
                iconName: "arrow.down.circle.fill",
                subFeatures: [
                    "Update Synchronization",
                    "Approval Rules",
                    "Computer Groups",
                    "Reporting"
                ]
            )
        ]
        
        // Load volumes
        volumes = [
            StorageVolume(name: "C:\\ (System)", total: 500, used: 234, type: "NTFS"),
            StorageVolume(name: "D:\\ (Data)", total: 2000, used: 876, type: "NTFS"),
            StorageVolume(name: "E:\\ (Backup)", total: 4000, used: 3200, type: "ReFS")
        ]
        
        // Load adapters
        adapters = [
            NetworkAdapter(name: "Ethernet 1", ip: "192.168.1.100", status: .connected, speed: "10 Gbps"),
            NetworkAdapter(name: "Ethernet 2", ip: "10.0.0.50", status: .connected, speed: "10 Gbps"),
            NetworkAdapter(name: "Wi-Fi", ip: "Not assigned", status: .disconnected, speed: "N/A")
        ]
        
        // Load quick access tools
        quickAccessTools = [
            "event-viewer",
            "services",
            "performance",
            "disk",
            "task",
            "powershell"
        ]
    }
    
    func handleAddRole(roleId: String) {
        if let index = roles.firstIndex(where: { $0.id == roleId }) {
            roles[index].status = .installing
            roles[index].lastUpdated = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
        }
        addRoleDialogOpen = false
        
        // Simulate installation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if let index = self.roles.firstIndex(where: { $0.id == roleId }) {
                self.roles[index].status = .installed
            }
        }
    }
    
    func handleRemoveRole() {
        if let role = selectedRoleForAction,
           let index = roles.firstIndex(where: { $0.id == role.id }) {
            roles[index].status = .available
            roles[index].lastUpdated = nil
        }
        removeRoleDialogOpen = false
        selectedRoleForAction = nil
    }
    
    func handleToggleAdapter(_ adapterName: String) {
        if let index = adapters.firstIndex(where: { $0.name == adapterName }) {
            adapters[index].status = adapters[index].status == .connected ? .disconnected : .connected
        }
    }
    
    func handleSaveNetworkConfig() {
        if let adapter = selectedAdapter,
           let index = adapters.firstIndex(where: { $0.id == adapter.id }) {
            adapters[index].ip = adapterDHCP ? "Not assigned" : adapterIP
        }
        networkConfigDialogOpen = false
    }
    
    func handleCreateVolume() {
        guard !newVolumeName.isEmpty,
              let size = Int(newVolumeSize) else { return }
        
        let newVolume = StorageVolume(
            name: newVolumeName,
            total: size,
            used: 0,
            type: newVolumeType
        )
        volumes.append(newVolume)
        newVolumeDialogOpen = false
        newVolumeName = ""
        newVolumeSize = ""
        newVolumeType = "NTFS"
    }
    
    func handleExtendVolume() {
        guard let volume = selectedVolume,
              let amount = Int(extendVolumeAmount),
              let index = volumes.firstIndex(where: { $0.id == volume.id }) else { return }
        
        volumes[index].total += amount
        extendVolumeDialogOpen = false
        extendVolumeAmount = ""
    }
    
    func handleDeleteVolume(_ volumeName: String) {
        volumes.removeAll { $0.name == volumeName }
        volumePropertiesDialogOpen = false
    }
    
    func handleOpenQuickAccessTool(_ toolId: String) {
        let toolNames: [String: String] = [
            "event-viewer": "Event Viewer",
            "services": "Services",
            "performance": "Performance Monitor",
            "disk": "Disk Management",
            "task": "Task Manager",
            "powershell": "PowerShell"
        ]
        
        if let toolName = toolNames[toolId] {
            activeQuickAccessTool = toolName
            activeTab = .tools
        }
    }
    
    func handleToggleQuickAccessTool(_ toolId: String) {
        if quickAccessTools.contains(toolId) {
            quickAccessTools.removeAll { $0 == toolId }
        } else {
            quickAccessTools.append(toolId)
        }
    }
}
