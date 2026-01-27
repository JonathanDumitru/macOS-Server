//
//  MenuBarController.swift
//  Server
//
//  Created by Claude on 1/27/26.
//

import AppKit
import SwiftUI
import SwiftData
import Combine

@MainActor
class MenuBarController: ObservableObject {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var eventMonitor: Any?

    @Published var isVisible = false
    @Published var serverStatus: OverallStatus = .allOnline

    private var modelContainer: ModelContainer
    private var cancellables = Set<AnyCancellable>()

    enum OverallStatus {
        case allOnline
        case someWarning
        case someOffline
        case allOffline
        case unknown

        var iconName: String {
            switch self {
            case .allOnline: return "server.rack"
            case .someWarning: return "exclamationmark.triangle.fill"
            case .someOffline, .allOffline: return "xmark.circle.fill"
            case .unknown: return "questionmark.circle"
            }
        }

        var iconColor: NSColor {
            switch self {
            case .allOnline: return .systemGreen
            case .someWarning: return .systemYellow
            case .someOffline, .allOffline: return .systemRed
            case .unknown: return .systemGray
            }
        }
    }

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func setup() {
        // Create the status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            updateStatusIcon()
            button.action = #selector(togglePopover)
            button.target = self
        }

        // Create the popover
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 320, height: 400)
        popover?.behavior = .transient
        popover?.animates = true

        let contentView = MenuBarPopoverView(modelContainer: modelContainer)
            .modelContainer(modelContainer)

        popover?.contentViewController = NSHostingController(rootView: contentView)

        // Setup event monitor to close popover when clicking outside
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            if let popover = self?.popover, popover.isShown {
                popover.performClose(nil)
            }
        }

        // Start monitoring server status for icon updates
        startStatusMonitoring()
    }

    func teardown() {
        if let eventMonitor = eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
            self.eventMonitor = nil
        }

        statusItem = nil
        popover = nil
    }

    @objc private func togglePopover() {
        if let popover = popover {
            if popover.isShown {
                popover.performClose(nil)
                isVisible = false
            } else {
                if let button = statusItem?.button {
                    popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                    isVisible = true
                }
            }
        }
    }

    func showPopover() {
        if let popover = popover, !popover.isShown {
            if let button = statusItem?.button {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                isVisible = true
            }
        }
    }

    func hidePopover() {
        if let popover = popover, popover.isShown {
            popover.performClose(nil)
            isVisible = false
        }
    }

    private func updateStatusIcon() {
        guard let button = statusItem?.button else { return }

        let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        let image = NSImage(systemSymbolName: serverStatus.iconName, accessibilityDescription: "Server Status")?
            .withSymbolConfiguration(config)

        button.image = image
        button.contentTintColor = serverStatus.iconColor
    }

    private func startStatusMonitoring() {
        // Periodic status check
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refreshServerStatus()
            }
            .store(in: &cancellables)

        // Initial check
        refreshServerStatus()
    }

    func refreshServerStatus() {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<Server>()

        do {
            let servers = try context.fetch(descriptor)

            if servers.isEmpty {
                serverStatus = .unknown
            } else {
                let offlineCount = servers.filter { $0.status == .offline }.count
                let warningCount = servers.filter { $0.status == .warning }.count
                let onlineCount = servers.filter { $0.status == .online }.count

                if offlineCount == servers.count {
                    serverStatus = .allOffline
                } else if offlineCount > 0 {
                    serverStatus = .someOffline
                } else if warningCount > 0 {
                    serverStatus = .someWarning
                } else if onlineCount == servers.count {
                    serverStatus = .allOnline
                } else {
                    serverStatus = .unknown
                }
            }

            updateStatusIcon()
        } catch {
            serverStatus = .unknown
            updateStatusIcon()
        }
    }
}

// MARK: - Menu Bar Quick Actions

extension MenuBarController {
    func createContextMenu() -> NSMenu {
        let menu = NSMenu()

        // Status summary
        let statusItem = NSMenuItem(title: statusSummary(), action: nil, keyEquivalent: "")
        statusItem.isEnabled = false
        menu.addItem(statusItem)

        menu.addItem(NSMenuItem.separator())

        // Quick actions
        let refreshItem = NSMenuItem(title: "Refresh All Servers", action: #selector(refreshAllServers), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)

        menu.addItem(NSMenuItem.separator())

        // Open main window
        let openItem = NSMenuItem(title: "Open Server Dashboard", action: #selector(openMainWindow), keyEquivalent: "o")
        openItem.target = self
        menu.addItem(openItem)

        menu.addItem(NSMenuItem.separator())

        // Quit
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        return menu
    }

    private func statusSummary() -> String {
        switch serverStatus {
        case .allOnline:
            return "All servers online"
        case .someWarning:
            return "Some servers have warnings"
        case .someOffline:
            return "Some servers are offline"
        case .allOffline:
            return "All servers offline"
        case .unknown:
            return "Server status unknown"
        }
    }

    @objc private func refreshAllServers() {
        NotificationCenter.default.post(name: .refreshAllServers, object: nil)
    }

    @objc private func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)

        // Find and focus the main window
        if let window = NSApp.windows.first(where: { $0.title.contains("Server") || $0.isMainWindow }) {
            window.makeKeyAndOrderFront(nil)
        }
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let refreshAllServers = Notification.Name("refreshAllServers")
    static let menuBarVisibilityChanged = Notification.Name("menuBarVisibilityChanged")
}
