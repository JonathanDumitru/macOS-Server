//
//  AppModel.swift
//  Server
//
//  Created by Jonathan Hines Dumitru on 1/14/26.
//

import SwiftUI
import Observation

@Observable
class AppModel {
    var selectedSection: NavigationSection = .dashboard
    var quickAccessItems: [QuickAccessItem]
    
    // Section-specific datasets
    var roles: [ServerRole] = ServerRole.demoData
    var features: [ServerFeature] = ServerFeature.demoData
    var volumes: [StorageVolume] = StorageVolume.demoData
    var disks: [PhysicalDisk] = PhysicalDisk.demoData
    var networkAdapters: [NetworkAdapter] = NetworkAdapter.demoData
    var securityAlerts: [SecurityAlert] = SecurityAlert.demoData
    var updates: [SystemUpdate] = SystemUpdate.demoData
    
    init() {
        // Load persisted Quick Access items or use defaults
        if let data = UserDefaults.standard.data(forKey: "quickAccessItems"),
           let decoded = try? JSONDecoder().decode([QuickAccessItem].self, from: data) {
            self.quickAccessItems = decoded
        } else {
            self.quickAccessItems = QuickAccessItem.defaultItems
        }
    }
    
    func saveQuickAccessItems() {
        if let encoded = try? JSONEncoder().encode(quickAccessItems) {
            UserDefaults.standard.set(encoded, forKey: "quickAccessItems")
        }
    }
    
    // MARK: - Roles & Features Actions
    
    func toggleRole(_ role: ServerRole) {
        if let index = roles.firstIndex(where: { $0.id == role.id }) {
            roles[index].status = roles[index].status == .installed ? .pending : .pendingInstall
            if roles[index].requiresReboot {
                // Mark that reboot is required
            }
        }
    }
    
    func toggleFeature(_ feature: ServerFeature) {
        if let index = features.firstIndex(where: { $0.id == feature.id }) {
            features[index].isInstalled.toggle()
        }
    }
    
    // MARK: - Storage Actions
    
    func createVolume(name: String, size: Double, fileSystem: String) {
        let newVolume = StorageVolume(
            name: name,
            mountPoint: "/Volumes/\(name)",
            fileSystem: fileSystem,
            totalSize: size,
            usedSize: 0,
            health: .healthy
        )
        volumes.append(newVolume)
    }
    
    func deleteVolume(_ volume: StorageVolume) {
        volumes.removeAll { $0.id == volume.id }
    }
    
    // MARK: - Networking Actions
    
    func updateDNSServers(for adapter: NetworkAdapter, servers: [String]) {
        if let index = networkAdapters.firstIndex(where: { $0.id == adapter.id }) {
            networkAdapters[index].dnsServers = servers
        }
    }
    
    func toggleDHCP(for adapter: NetworkAdapter) {
        if let index = networkAdapters.firstIndex(where: { $0.id == adapter.id }) {
            networkAdapters[index].isDHCP.toggle()
        }
    }
    
    // MARK: - Security Actions
    
    func acknowledgeAlert(_ alert: SecurityAlert) {
        if let index = securityAlerts.firstIndex(where: { $0.id == alert.id }) {
            securityAlerts[index].status = .acknowledged
        }
    }
    
    func resolveAlert(_ alert: SecurityAlert) {
        if let index = securityAlerts.firstIndex(where: { $0.id == alert.id }) {
            securityAlerts[index].status = .resolved
        }
    }
    
    // MARK: - Updates Actions

    @ObservationIgnored private var downloadTasks: [String: Task<Void, Never>] = [:]
    @ObservationIgnored private var installTasks: [String: Task<Void, Never>] = [:]

    func checkForUpdates() {
        // Simulate checking for updates with a delay
        Task { @MainActor in
            // Generate 0-3 new updates
            let updateCount = Int.random(in: 0...3)

            if updateCount == 0 {
                // No new updates found
                return
            }

            let updateTypes = [
                ("Security Update", "This update addresses security vulnerabilities and includes critical patches.", true),
                ("Cumulative Update", "Monthly rollup of quality improvements and bug fixes.", true),
                ("Feature Update", "New features and enhancements for the operating system.", true),
                ("Driver Update", "Updated device drivers for improved compatibility.", false),
                ("Definition Update", "Latest virus and malware definitions.", false),
                (".NET Framework Update", "Security and reliability improvements for .NET Framework.", true),
                ("Servicing Stack Update", "Improvements to the servicing stack reliability.", false)
            ]

            for _ in 0..<updateCount {
                let typeInfo = updateTypes.randomElement()!
                let kbNumber = Int.random(in: 5000000...5999999)
                let monthYear = Date().formatted(.dateTime.year().month())

                // Avoid duplicate KB numbers
                let kbId = "KB\(kbNumber)"
                guard !updates.contains(where: { $0.id == kbId }) else { continue }

                let newUpdate = SystemUpdate(
                    id: kbId,
                    title: "\(monthYear) \(typeInfo.0)",
                    description: typeInfo.1,
                    size: Double.random(in: 15...600),
                    requiresReboot: typeInfo.2,
                    status: .available,
                    releaseDate: Date().addingTimeInterval(-Double.random(in: 0...86400 * 7))
                )
                updates.insert(newUpdate, at: 0)
            }
        }
    }

    func downloadUpdate(_ update: SystemUpdate) {
        guard let index = updates.firstIndex(where: { $0.id == update.id }) else { return }
        guard updates[index].status == .available else { return }

        updates[index].status = .downloading
        updates[index].downloadProgress = 0

        // Simulate download progress
        let updateId = update.id
        downloadTasks[updateId] = Task { @MainActor in
            let totalSteps = 20
            for step in 1...totalSteps {
                try? await Task.sleep(for: .milliseconds(Int.random(in: 100...300)))

                if Task.isCancelled { return }

                if let idx = updates.firstIndex(where: { $0.id == updateId }) {
                    updates[idx].downloadProgress = Double(step) / Double(totalSteps)
                }
            }

            // Download complete
            if let idx = updates.firstIndex(where: { $0.id == updateId }) {
                updates[idx].status = .downloaded
                updates[idx].downloadProgress = 1.0
            }

            downloadTasks.removeValue(forKey: updateId)
        }
    }

    func cancelDownload(_ update: SystemUpdate) {
        downloadTasks[update.id]?.cancel()
        downloadTasks.removeValue(forKey: update.id)

        if let index = updates.firstIndex(where: { $0.id == update.id }) {
            updates[index].status = .available
            updates[index].downloadProgress = 0
        }
    }

    func installUpdate(_ update: SystemUpdate) {
        guard let index = updates.firstIndex(where: { $0.id == update.id }) else { return }
        guard updates[index].status == .downloaded else { return }

        updates[index].status = .installing
        updates[index].installProgress = 0

        // Simulate installation progress
        let updateId = update.id
        installTasks[updateId] = Task { @MainActor in
            let totalSteps = 15

            for step in 1...totalSteps {
                try? await Task.sleep(for: .milliseconds(Int.random(in: 200...500)))

                if Task.isCancelled { return }

                if let idx = updates.firstIndex(where: { $0.id == updateId }) {
                    updates[idx].installProgress = Double(step) / Double(totalSteps)
                }
            }

            // Installation complete (with small chance of failure for realism)
            if let idx = updates.firstIndex(where: { $0.id == updateId }) {
                if Double.random(in: 0...1) < 0.95 {
                    updates[idx].status = .installed
                    updates[idx].installDate = Date()
                    updates[idx].installProgress = 1.0
                } else {
                    updates[idx].status = .failed
                    updates[idx].installProgress = 0
                }
            }

            installTasks.removeValue(forKey: updateId)
        }
    }

    func retryUpdate(_ update: SystemUpdate) {
        if let index = updates.firstIndex(where: { $0.id == update.id }) {
            updates[index].status = .available
            updates[index].downloadProgress = 0
            updates[index].installProgress = 0
        }
    }
}

// MARK: - Quick Access Item

struct QuickAccessItem: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let icon: String
    let destination: NavigationSection
    var isPinned: Bool
    var order: Int
    
    static let defaultItems: [QuickAccessItem] = [
        QuickAccessItem(id: "eventViewer", title: "Event Viewer", icon: "list.bullet.rectangle", destination: .eventViewer, isPinned: true, order: 0),
        QuickAccessItem(id: "services", title: "Services", icon: "gearshape.2", destination: .services, isPinned: true, order: 1),
        QuickAccessItem(id: "perfMonitor", title: "Performance Monitor", icon: "chart.xyaxis.line", destination: .performanceMonitor, isPinned: true, order: 2),
        QuickAccessItem(id: "diskMgmt", title: "Disk Management", icon: "externaldrive", destination: .diskManagement, isPinned: true, order: 3),
        QuickAccessItem(id: "taskMgr", title: "Task Manager", icon: "list.bullet.clipboard", destination: .taskManager, isPinned: true, order: 4),
        QuickAccessItem(id: "powershell", title: "PowerShell", icon: "terminal", destination: .powershell, isPinned: true, order: 5),
    ]
}

// MARK: - Server Role

struct ServerRole: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let description: String
    var status: RoleStatus
    let impact: Impact
    let requiresReboot: Bool
    let dependencies: [String]
    let services: [String]
    
    enum RoleStatus: String, CaseIterable {
        case installed = "Installed"
        case notInstalled = "Not Installed"
        case pending = "Pending Removal"
        case pendingInstall = "Pending Install"
    }
    
    enum Impact: String {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
    }
    
    static let demoData: [ServerRole] = [
        ServerRole(name: "Active Directory Domain Services", description: "Stores directory information and manages user logon processes, authentication, and directory searches.", status: .installed, impact: .high, requiresReboot: true, dependencies: ["DNS Server"], services: ["NTDS", "Kerberos"]),
        ServerRole(name: "DNS Server", description: "Provides name resolution services for TCP/IP networks.", status: .installed, impact: .high, requiresReboot: false, dependencies: [], services: ["DNS"]),
        ServerRole(name: "DHCP Server", description: "Automatically assigns IP addresses to client computers on the network.", status: .installed, impact: .medium, requiresReboot: false, dependencies: [], services: ["DHCP"]),
        ServerRole(name: "File and Storage Services", description: "Provides technologies for storage management, file replication, distributed namespace management, and more.", status: .installed, impact: .high, requiresReboot: false, dependencies: [], services: ["LanmanServer"]),
        ServerRole(name: "Web Server (IIS)", description: "Provides a reliable, manageable, and scalable web application infrastructure.", status: .notInstalled, impact: .medium, requiresReboot: true, dependencies: [], services: ["W3SVC", "WAS"]),
        ServerRole(name: "Remote Desktop Services", description: "Allows users to connect to virtual desktops, session-based desktops, and RemoteApp programs.", status: .notInstalled, impact: .medium, requiresReboot: true, dependencies: [], services: ["TermService"]),
        ServerRole(name: "Hyper-V", description: "Provides services to create and manage virtual machines and their resources.", status: .installed, impact: .high, requiresReboot: true, dependencies: [], services: ["vmms", "vmcompute"]),
        ServerRole(name: "Windows Server Update Services", description: "Enables administrators to manage the distribution of updates released through Microsoft Update.", status: .notInstalled, impact: .low, requiresReboot: false, dependencies: ["IIS"], services: ["WsusService"]),
    ]
}

// MARK: - Server Feature

struct ServerFeature: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let description: String
    var isInstalled: Bool
    let impact: ServerRole.Impact
    
    static let demoData: [ServerFeature] = [
        ServerFeature(name: ".NET Framework 4.8", description: "Programming model for building applications.", isInstalled: true, impact: .low),
        ServerFeature(name: "BitLocker Drive Encryption", description: "Provides full volume encryption to protect data.", isInstalled: true, impact: .medium),
        ServerFeature(name: "Failover Clustering", description: "Enables servers to work together to provide high availability.", isInstalled: false, impact: .high),
        ServerFeature(name: "Network Load Balancing", description: "Distributes network traffic across multiple servers.", isInstalled: false, impact: .medium),
        ServerFeature(name: "Remote Server Administration Tools", description: "Tools for managing remote servers.", isInstalled: true, impact: .low),
        ServerFeature(name: "Telnet Client", description: "Connects to remote computers running Telnet service.", isInstalled: false, impact: .low),
        ServerFeature(name: "Windows PowerShell 5.1", description: "Command-line shell and scripting language.", isInstalled: true, impact: .low),
        ServerFeature(name: "Windows Subsystem for Linux", description: "Runs Linux binary executables natively on Windows.", isInstalled: false, impact: .low),
    ]
}

// MARK: - Storage Models

struct StorageVolume: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let mountPoint: String
    let fileSystem: String
    let totalSize: Double // GB
    let usedSize: Double // GB
    let health: HealthStatus
    
    var freeSize: Double { totalSize - usedSize }
    var usedPercentage: Double { (usedSize / totalSize) * 100 }
    
    enum HealthStatus: String {
        case healthy = "Healthy"
        case warning = "Warning"
        case critical = "Critical"
    }
    
    static let demoData: [StorageVolume] = [
        StorageVolume(name: "System", mountPoint: "/", fileSystem: "NTFS", totalSize: 500, usedSize: 245, health: .healthy),
        StorageVolume(name: "Data", mountPoint: "/Volumes/Data", fileSystem: "NTFS", totalSize: 2000, usedSize: 1650, health: .warning),
        StorageVolume(name: "Backup", mountPoint: "/Volumes/Backup", fileSystem: "NTFS", totalSize: 4000, usedSize: 2800, health: .healthy),
        StorageVolume(name: "VMs", mountPoint: "/Volumes/VMs", fileSystem: "ReFS", totalSize: 8000, usedSize: 5200, health: .healthy),
    ]
}

struct PhysicalDisk: Identifiable, Hashable {
    let id = UUID()
    let model: String
    let size: Double // GB
    let interface: String
    let health: String
    let temperature: Int // Celsius
    let serialNumber: String
    
    static let demoData: [PhysicalDisk] = [
        PhysicalDisk(model: "Samsung 870 EVO", size: 500, interface: "SATA III", health: "OK", temperature: 35, serialNumber: "S5H2NS0N123456"),
        PhysicalDisk(model: "WD Red Pro", size: 4000, interface: "SATA III", health: "OK", temperature: 38, serialNumber: "WD-WCC7K1234567"),
        PhysicalDisk(model: "Seagate IronWolf", size: 8000, interface: "SATA III", health: "OK", temperature: 40, serialNumber: "ZA123456"),
        PhysicalDisk(model: "Intel Optane P5800X", size: 1600, interface: "NVMe", health: "OK", temperature: 42, serialNumber: "PHLN123456789ABC"),
    ]
}

// MARK: - Network Models

struct NetworkAdapter: Identifiable, Hashable {
    let id = UUID()
    let name: String
    var status: AdapterStatus
    let linkSpeed: String
    var ipv4Address: String
    var ipv6Address: String?
    var isDHCP: Bool
    var dnsServers: [String]
    let txRate: Double // Mbps
    let rxRate: Double // Mbps
    
    enum AdapterStatus: String {
        case active = "Active"
        case inactive = "Inactive"
        case disconnected = "Disconnected"
    }
    
    static let demoData: [NetworkAdapter] = [
        NetworkAdapter(name: "Ethernet 1", status: .active, linkSpeed: "10 Gbps", ipv4Address: "192.168.1.100", ipv6Address: "fe80::1", isDHCP: false, dnsServers: ["8.8.8.8", "8.8.4.4"], txRate: 245.5, rxRate: 1205.8),
        NetworkAdapter(name: "Ethernet 2", status: .active, linkSpeed: "10 Gbps", ipv4Address: "10.0.0.50", ipv6Address: nil, isDHCP: false, dnsServers: ["1.1.1.1", "1.0.0.1"], txRate: 89.2, rxRate: 432.1),
        NetworkAdapter(name: "Management", status: .active, linkSpeed: "1 Gbps", ipv4Address: "192.168.100.10", ipv6Address: nil, isDHCP: true, dnsServers: ["192.168.100.1"], txRate: 2.3, rxRate: 5.1),
        NetworkAdapter(name: "Ethernet 3", status: .disconnected, linkSpeed: "N/A", ipv4Address: "N/A", ipv6Address: nil, isDHCP: true, dnsServers: [], txRate: 0, rxRate: 0),
    ]
}

// MARK: - Security Models

struct SecurityAlert: Identifiable, Hashable {
    let id = UUID()
    let severity: Severity
    let category: Category
    let title: String
    let description: String
    let affectedResource: String
    let remediation: String
    let timestamp: Date
    var status: AlertStatus
    
    enum Severity: String, CaseIterable {
        case critical = "Critical"
        case high = "High"
        case medium = "Medium"
        case low = "Low"
        case info = "Info"
    }
    
    enum Category: String, CaseIterable {
        case authentication = "Authentication"
        case firewall = "Firewall"
        case malware = "Malware"
        case policy = "Policy"
        case update = "Update"
        case configuration = "Configuration"
    }
    
    enum AlertStatus: String, CaseIterable {
        case open = "Open"
        case acknowledged = "Acknowledged"
        case resolved = "Resolved"
    }
    
    static let demoData: [SecurityAlert] = [
        SecurityAlert(severity: .critical, category: .authentication, title: "Multiple Failed Login Attempts", description: "User account 'administrator' has experienced 15 failed login attempts from IP 203.0.113.45 in the last hour.", affectedResource: "DC01", remediation: "Verify the source IP address, enable account lockout policies, and review security logs for additional suspicious activity.", timestamp: Date().addingTimeInterval(-3600), status: .open),
        SecurityAlert(severity: .high, category: .firewall, title: "Firewall Rule Disabled", description: "A critical firewall rule blocking inbound RDP from external networks has been disabled.", affectedResource: "Firewall - WAN Interface", remediation: "Re-enable the firewall rule immediately and investigate who made the change.", timestamp: Date().addingTimeInterval(-7200), status: .open),
        SecurityAlert(severity: .medium, category: .update, title: "Security Updates Pending", description: "5 critical security updates have been available for more than 7 days.", affectedResource: "All Servers", remediation: "Schedule maintenance window to install pending security updates.", timestamp: Date().addingTimeInterval(-604800), status: .acknowledged),
        SecurityAlert(severity: .low, category: .policy, title: "Password Policy Non-Compliance", description: "3 user accounts have passwords that don't meet complexity requirements.", affectedResource: "Active Directory", remediation: "Force password reset for affected accounts and enforce strong password policy.", timestamp: Date().addingTimeInterval(-86400), status: .acknowledged),
        SecurityAlert(severity: .critical, category: .malware, title: "Potential Malware Detected", description: "Windows Defender has detected suspicious behavior from process 'svchost.exe' (PID 4892).", affectedResource: "APP01", remediation: "Isolate the affected server, run full antimalware scan, and analyze the suspicious process.", timestamp: Date().addingTimeInterval(-1800), status: .open),
        SecurityAlert(severity: .info, category: .configuration, title: "TLS 1.0 Still Enabled", description: "Legacy TLS 1.0 protocol is still enabled on web servers.", affectedResource: "WEB01, WEB02", remediation: "Disable TLS 1.0 and enable only TLS 1.2 and 1.3.", timestamp: Date().addingTimeInterval(-259200), status: .resolved),
    ]
}

// MARK: - Update Models

struct SystemUpdate: Identifiable, Hashable {
    let id: String // KB number
    let title: String
    let description: String
    let size: Double // MB
    let requiresReboot: Bool
    var status: UpdateStatus
    let releaseDate: Date
    var installDate: Date?
    var downloadProgress: Double = 0
    var installProgress: Double = 0

    var formattedSize: String {
        if size >= 1000 {
            return String(format: "%.1f GB", size / 1000)
        }
        return String(format: "%.1f MB", size)
    }

    enum UpdateStatus: String, CaseIterable {
        case available = "Available"
        case downloading = "Downloading"
        case downloaded = "Downloaded"
        case installing = "Installing"
        case installed = "Installed"
        case failed = "Failed"

        var color: Color {
            switch self {
            case .available: return .blue
            case .downloading, .installing: return .orange
            case .downloaded: return .cyan
            case .installed: return .green
            case .failed: return .red
            }
        }
    }
    
    static let demoData: [SystemUpdate] = [
        SystemUpdate(id: "KB5034441", title: "2026-01 Cumulative Update for Windows Server 2025", description: "This security update includes quality improvements. Key changes include addressing security vulnerabilities and improving system stability.", size: 485.2, requiresReboot: true, status: .available, releaseDate: Date().addingTimeInterval(-86400)),
        SystemUpdate(id: "KB5034129", title: "2026-01 Security Update for .NET Framework", description: "Security update for .NET Framework 4.8.1 to address remote code execution vulnerability.", size: 125.6, requiresReboot: true, status: .available, releaseDate: Date().addingTimeInterval(-172800)),
        SystemUpdate(id: "KB5033918", title: "Update for Windows Defender Definitions", description: "Latest virus and malware definitions for Windows Defender.", size: 42.8, requiresReboot: false, status: .downloaded, releaseDate: Date().addingTimeInterval(-43200)),
        SystemUpdate(id: "KB5032392", title: "2025-12 Cumulative Update for Windows Server 2025", description: "Monthly quality and security update rollup.", size: 502.1, requiresReboot: true, status: .installed, releaseDate: Date().addingTimeInterval(-2592000), installDate: Date().addingTimeInterval(-2505600)),
        SystemUpdate(id: "KB5031984", title: "Servicing Stack Update", description: "Update to improve the servicing stack reliability.", size: 15.3, requiresReboot: false, status: .installed, releaseDate: Date().addingTimeInterval(-3024000), installDate: Date().addingTimeInterval(-2937600)),
    ]
}
