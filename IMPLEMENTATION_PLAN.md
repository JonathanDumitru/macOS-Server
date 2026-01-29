# macOS Server Dashboard - Feature Implementation Plan

## Overview

This document outlines the implementation plan for 5 new features to enhance the macOS Server Management Dashboard.

### Implementation Priority Order

| Priority | Feature | Complexity | Dependencies |
|----------|---------|------------|--------------|
| 1 | Server Groups/Tags | Low | None |
| 2 | Uptime History & Trends | Medium | None |
| 3 | SSL Certificate Tracking | Medium | None |
| 4 | Notifications (macOS Native) | Medium | Benefits from #2, #3 |
| 5 | Menu Bar App | Medium | Benefits from all |

---

## Feature 1: Server Groups/Tags

**Goal:** Allow users to organize servers into groups (Production, Staging, Development) with color-coding and filtering.

### Data Model

```swift
// New file: Server/Models/ServerGroup.swift
@Model
final class ServerGroup {
    var id: UUID
    var name: String
    var colorHex: String      // "#007AFF"
    var icon: String          // SF Symbol name
    var sortOrder: Int
    var createdAt: Date

    @Relationship(inverse: \Server.group)
    var servers: [Server] = []
}

// Modify Server.swift - add:
var group: ServerGroup?
```

### New Files to Create

| File | Purpose |
|------|---------|
| `Server/Models/ServerGroup.swift` | SwiftData model |
| `Server/Views/ServerGroupBadge.swift` | Colored badge component |
| `Server/Views/GroupFilterBar.swift` | Horizontal filter buttons |
| `Server/Views/AddGroupView.swift` | Create/edit group sheet |
| `Server/Views/GroupManagementView.swift` | Settings section |
| `Server/Utilities/ColorExtension.swift` | Hex color parsing |

### Implementation Steps

1. Create `ServerGroup.swift` model
2. Add `group` property to `Server.swift`
3. Update schema in `ServerApp.swift`
4. Create `ColorExtension.swift` for hex colors
5. Build `ServerGroupBadge.swift` component
6. Add badge to `ServerListItemView`
7. Create `GroupFilterBar.swift`
8. Integrate filter into `DashboardView`
9. Create `AddGroupView.swift` form
10. Add group picker to `AddServerView`
11. Create `GroupManagementView.swift`
12. Add to Settings

### Key UI Components

```swift
// ServerGroupBadge.swift
struct ServerGroupBadge: View {
    let group: ServerGroup?

    var body: some View {
        if let group = group {
            HStack(spacing: 4) {
                Circle()
                    .fill(Color(hex: group.colorHex))
                    .frame(width: 8, height: 8)
                Text(group.name)
                    .font(.system(size: 10, weight: .medium))
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color(hex: group.colorHex).opacity(0.15), in: Capsule())
        }
    }
}
```

---

## Feature 2: Uptime History & Trends

**Goal:** Track uptime percentages, store historical data, and display trends over 24h/7d/30d/90d periods.

### Data Models

```swift
// New file: Server/Models/UptimeRecord.swift
@Model
final class UptimeRecord {
    var id: UUID
    var serverId: UUID
    var timestamp: Date
    var isOnline: Bool
    var responseTime: Double?
}

// New file: Server/Models/UptimeDaily.swift
@Model
final class UptimeDaily {
    var id: UUID
    var serverId: UUID
    var date: Date  // Start of day

    var totalChecks: Int
    var successfulChecks: Int
    var failedChecks: Int

    var averageResponseTime: Double
    var minResponseTime: Double
    var maxResponseTime: Double

    var uptimePercentage: Double {
        guard totalChecks > 0 else { return 0 }
        return Double(successfulChecks) / Double(totalChecks) * 100
    }
}
```

### New Files to Create

| File | Purpose |
|------|---------|
| `Server/Models/UptimeRecord.swift` | Individual check records |
| `Server/Models/UptimeDaily.swift` | Daily aggregates |
| `Server/Services/UptimeTrackingService.swift` | Core tracking logic |
| `Server/Views/UptimePercentageView.swift` | Circular gauge display |
| `Server/Views/UptimeTimelineChart.swift` | Historical bar chart |
| `Server/Views/UptimePeriodPicker.swift` | Period selector |
| `Server/Views/DowntimeIncidentsView.swift` | Outage list |

### Implementation Steps

1. Create `UptimeRecord.swift` model
2. Create `UptimeDaily.swift` aggregate model
3. Update schema in `ServerApp.swift`
4. Create `UptimeTrackingService.swift`
5. Integrate with `ServerMonitoringService.checkServer()`
6. Build `UptimePercentageView.swift` gauge
7. Create `UptimePeriodPicker.swift`
8. Build `UptimeTimelineChart.swift` using Swift Charts
9. Add uptime section to `ServerDetailView`
10. Create dashboard summary card
11. Implement data cleanup for old records
12. Add uptime badge to server list items

### Uptime Periods

```swift
enum UptimePeriod: String, CaseIterable {
    case day24h = "24 Hours"
    case week7d = "7 Days"
    case month30d = "30 Days"
    case quarter90d = "90 Days"

    var startDate: Date {
        let days: Int
        switch self {
        case .day24h: days = -1
        case .week7d: days = -7
        case .month30d: days = -30
        case .quarter90d: days = -90
        }
        return Calendar.current.date(byAdding: .day, value: days, to: Date())!
    }
}
```

---

## Feature 3: SSL Certificate Tracking

**Goal:** Check SSL certificate expiration for HTTPS servers, display certificate details, alert before expiry.

### Data Model

```swift
// New file: Server/Models/SSLCertificateInfo.swift
@Model
final class SSLCertificateInfo {
    var id: UUID
    var serverId: UUID

    var commonName: String?
    var issuer: String?
    var serialNumber: String?

    var validFrom: Date?
    var validUntil: Date?
    var isValid: Bool

    var lastChecked: Date
    var checkError: String?

    var daysUntilExpiry: Int? {
        guard let validUntil = validUntil else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: validUntil).day
    }

    var expiryStatus: ExpiryStatus {
        guard let days = daysUntilExpiry else { return .unknown }
        if days < 0 { return .expired }
        if days <= 7 { return .critical }
        if days <= 30 { return .warning }
        if days <= 90 { return .attention }
        return .healthy
    }
}

// Add to Server.swift:
@Relationship(deleteRule: .cascade)
var sslCertificate: SSLCertificateInfo?
```

### New Files to Create

| File | Purpose |
|------|---------|
| `Server/Models/SSLCertificateInfo.swift` | Certificate data model |
| `Server/Services/SSLCertificateService.swift` | Certificate checking |
| `Server/Views/SSLStatusBadge.swift` | Lock icon with expiry |
| `Server/Views/SSLCertificateView.swift` | Full certificate details |
| `Server/Views/SSLAlertSettingsView.swift` | Alert thresholds |

### Implementation Steps

1. Create `SSLCertificateInfo.swift` model
2. Add relationship to `Server.swift`
3. Update schema in `ServerApp.swift`
4. Create `SSLCertificateService.swift` with URLSession delegate
5. Integrate with `ServerMonitoringService` for HTTPS servers
6. Build `SSLStatusBadge.swift` component
7. Add badge to server list items (HTTPS only)
8. Create `SSLCertificateView.swift` detail view
9. Add SSL tab/section to `ServerDetailView`
10. Create dashboard card for expiring certificates
11. Integrate with notifications

### SSL Check Integration

```swift
// In ServerMonitoringService.checkServer()
if server.serverType == .https {
    do {
        let sslInfo = try await SSLCertificateService.shared.checkCertificate(
            host: server.host,
            port: server.port
        )
        server.sslCertificate = sslInfo
    } catch {
        // Log error
    }
}
```

---

## Feature 4: Notifications (macOS Native)

**Goal:** Alert users on status changes, response time thresholds, and SSL expiry using macOS notifications.

### Data Models

```swift
// New file: Server/Models/NotificationPreference.swift
@Model
final class NotificationPreference {
    var id: UUID
    var serverId: UUID?  // nil = global

    var notifyOnOffline: Bool = true
    var notifyOnOnline: Bool = true
    var notifyOnWarning: Bool = true
    var notifyOnResponseThreshold: Bool = false
    var responseThresholdMs: Double = 1000

    var playSound: Bool = true
    var quietHoursEnabled: Bool = false
    var quietHoursStart: Int = 22
    var quietHoursEnd: Int = 7
}
```

### New Files to Create

| File | Purpose |
|------|---------|
| `Server/Models/NotificationPreference.swift` | User preferences |
| `Server/Services/NotificationService.swift` | Core notification logic |
| `Server/Views/NotificationSettingsView.swift` | Global settings |
| `Server/Views/ServerNotificationSettingsView.swift` | Per-server overrides |

### Implementation Steps

1. Add User Notifications entitlement
2. Create `NotificationPreference.swift` model
3. Create `NotificationService.swift`
4. Request permissions on app launch
5. Track previous server states in monitoring service
6. Send notifications on status changes
7. Expand notification settings UI
8. Add per-server notification overrides
9. Implement quiet hours logic
10. Setup notification categories with actions
11. Implement notification delegate for actions

### Notification Service Core

```swift
@MainActor
class NotificationService: ObservableObject {
    static let shared = NotificationService()
    @Published var isAuthorized = false

    func requestAuthorization() async {
        let center = UNUserNotificationCenter.current()
        do {
            isAuthorized = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            print("Notification auth failed: \(error)")
        }
    }

    func sendNotification(title: String, body: String, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
```

---

## Feature 5: Menu Bar App

**Goal:** Always-visible status indicator in macOS menu bar with quick-glance server health and dropdown list.

### Architecture

```swift
// New file: Server/Services/MenuBarController.swift
@MainActor
class MenuBarController: ObservableObject {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?

    @Published var overallStatus: OverallStatus = .unknown

    enum OverallStatus {
        case allOnline      // Green
        case someWarning    // Orange
        case someOffline    // Red
        case allOffline     // Red
        case unknown        // Gray
    }

    func setup(modelContainer: ModelContainer) { ... }
    func updateStatus(servers: [Server]) { ... }
}
```

### New Files to Create

| File | Purpose |
|------|---------|
| `Server/Services/MenuBarController.swift` | Menu bar management |
| `Server/Views/MenuBar/MenuBarPopoverView.swift` | Popover content |
| `Server/Views/MenuBar/MenuBarServerRow.swift` | Compact server row |
| `Server/Views/MenuBar/MenuBarHeaderView.swift` | Summary header |

### Implementation Steps

1. Create `MenuBarController.swift`
2. Initialize in `ServerApp.swift`
3. Create `MenuBarPopoverView.swift`
4. Create `MenuBarServerRow.swift`
5. Create `MenuBarHeaderView.swift`
6. Connect to monitoring service updates
7. Add settings toggle for menu bar
8. Handle app lifecycle (keep running when window closes)
9. Add "Open in Dashboard" action
10. Add quick refresh action
11. Implement right-click menu alternative

### App Lifecycle

```swift
// In ServerApp.swift
@main
struct ServerApp: App {
    @StateObject private var menuBarController = MenuBarController()

    var body: some Scene {
        WindowGroup {
            DashboardView()
                .onAppear {
                    menuBarController.setup(modelContainer: sharedModelContainer)
                }
        }
    }
}
```

---

## Schema Update Summary

Update `ServerApp.swift`:

```swift
let schema = Schema([
    Server.self,
    ServerMetric.self,
    ServerLog.self,
    Item.self,
    // New models:
    ServerGroup.self,
    UptimeRecord.self,
    UptimeDaily.self,
    SSLCertificateInfo.self,
    NotificationPreference.self,
])
```

---

## Server Model Modifications

```swift
// Server.swift additions:
@Model
final class Server {
    // ... existing properties ...

    // Feature 1: Groups
    var group: ServerGroup?

    // Feature 3: SSL
    @Relationship(deleteRule: .cascade)
    var sslCertificate: SSLCertificateInfo?
}
```

---

## Estimated Effort

| Feature | Files | Complexity | Est. Lines of Code |
|---------|-------|------------|-------------------|
| Server Groups/Tags | 8 | Low | ~600 |
| Uptime History | 9 | Medium | ~900 |
| SSL Tracking | 6 | Medium | ~700 |
| Notifications | 5 | Medium | ~500 |
| Menu Bar App | 5 | Medium | ~600 |
| **Total** | **33** | - | **~3,300** |

---

## Next Steps

1. Start with **Server Groups/Tags** (no dependencies, immediate value)
2. Build **Uptime History** (provides data for dashboard)
3. Add **SSL Tracking** (independent, HTTPS-only)
4. Implement **Notifications** (leverages uptime/SSL data)
5. Complete with **Menu Bar App** (capstone feature)

Each feature can be developed and tested independently, then integrated into the main application.
