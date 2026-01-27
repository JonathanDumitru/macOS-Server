# New Features Documentation

This document details the 9 advanced features implemented in Server Monitor Dashboard.

---

## Feature 1: Real Ping/Connectivity Checks

### Overview
Replaced simulated connectivity checks with real Network framework-based TCP connections for accurate server status monitoring.

### Files Modified
- `ServerMonitoringService.swift` - Core implementation

### How It Works
```swift
// Uses Apple's Network framework for true TCP connectivity
let connection = NWConnection(host: NWEndpoint.Host(host), port: NWEndpoint.Port(integerLiteral: UInt16(port)), using: .tcp)

// Measures actual connection time for response latency
let responseTime = Date().timeIntervalSince(startTime) * 1000 // milliseconds
```

### Benefits
- True connectivity verification (not simulated)
- Accurate response time measurement
- Works with any TCP-based service
- Timeout handling (10 seconds default)

### Usage
Automatic - all server checks now use real connectivity. No user action required.

---

## Feature 2: macOS Notifications

### Overview
Native macOS notification center integration for server status alerts.

### Files Created
- `NotificationService.swift` - Notification management service

### Files Modified
- `ServerMonitoringService.swift` - Integration points
- `SettingsView.swift` - Permission & preference UI

### Notification Types
1. **Status Change** - Server goes online/offline/warning
2. **Error Alerts** - Connection failures, timeouts
3. **Threshold Exceeded** - CPU/memory/disk over limits
4. **SSL Expiry** - Certificate expiration warnings

### Settings Options
| Setting | Description |
|---------|-------------|
| Enable Notifications | Master toggle |
| Status Changes | Alert on online/offline transitions |
| Errors | Alert on connection failures |

### Permission Flow
1. App requests notification permission on first launch
2. User can grant/deny in system dialog
3. Settings shows current permission status
4. "Open System Settings" button if denied

### Usage
```swift
// Example: Send status change notification
await notificationService.notifyServerStatusChange(
    serverName: "Production Web",
    previousStatus: .online,
    newStatus: .offline,
    errorMessage: "Connection refused"
)
```

---

## Feature 3: Uptime Tracking

### Overview
Historical status recording for calculating uptime percentages and tracking downtime.

### Files Created
- `UptimeRecord.swift` - SwiftData model for status history

### Files Modified
- `Server.swift` - Added uptime fields
- `ServerMonitoringService.swift` - Record creation
- `ServerDetailView.swift` - Uptime display

### Data Model
```swift
@Model
final class UptimeRecord {
    var id: UUID
    var timestamp: Date
    var status: ServerStatus  // online, offline, warning, unknown
    var durationSeconds: Double?
    var server: Server?
}
```

### Server Fields Added
| Field | Type | Description |
|-------|------|-------------|
| `totalOnlineSeconds` | Double | Cumulative online time |
| `totalOfflineSeconds` | Double | Cumulative offline time |
| `lastStatusChangeDate` | Date? | When status last changed |
| `monitoringStartDate` | Date? | When tracking began |

### Calculations
```swift
// Uptime percentage
var uptimePercentage: Double {
    let total = totalOnlineSeconds + totalOfflineSeconds
    guard total > 0 else { return 100.0 }
    return (totalOnlineSeconds / total) * 100
}
```

### Display
- Shown in Server Detail → Overview tab
- Format: "99.95% uptime"
- Color-coded: Green (>99%), Orange (95-99%), Red (<95%)

---

## Feature 4: Server Groups & Tags

### Overview
Organize servers with custom groups featuring colors and icons, plus flexible tagging.

### Files Created
- `ServerGroup.swift` - Group model
- `GroupManagementView.swift` - Group management UI

### Files Modified
- `Server.swift` - Group relationship and tags field
- `AddServerView.swift` - Group/tag selection
- `DashboardView.swift` - Group filtering
- `ServerApp.swift` - Schema registration

### Data Model
```swift
@Model
final class ServerGroup {
    var id: UUID
    var name: String
    var colorHex: String
    var iconName: String
    var createdAt: Date
    var servers: [Server] = []
}
```

### Server Tags
```swift
// Stored as comma-separated string
var tags: String  // e.g., "production,web,critical"

// Computed property for array access
var tagList: [String] {
    tags.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
}
```

### Features
- Custom group colors (color picker)
- SF Symbol icons for groups
- Filter dashboard by group
- Assign multiple tags per server
- Tags shown as badges

### Usage
1. Settings → Groups → Add Group
2. Choose name, color, icon
3. When adding/editing server, select group
4. Use dashboard filter to show specific groups

---

## Feature 5: Custom Alert Thresholds

### Overview
Per-server configurable thresholds for metrics with severity levels and cooldown periods.

### Files Created
- `AlertThreshold.swift` - Threshold model and enums
- `AlertThresholdsView.swift` - Configuration UI

### Files Modified
- `ServerMonitoringService.swift` - Threshold checking
- `SettingsView.swift` - Alerts settings tab

### Data Model
```swift
@Model
final class AlertThreshold {
    var id: UUID
    var metricType: AlertMetricType
    var thresholdValue: Double
    var comparison: ThresholdComparison  // greaterThan, lessThan, equals
    var severity: AlertSeverity  // info, warning, critical
    var isEnabled: Bool
    var cooldownMinutes: Int  // Prevent alert spam
    var lastTriggeredAt: Date?
    var server: Server?
}
```

### Metric Types
| Type | Unit | Default Threshold |
|------|------|-------------------|
| CPU Usage | % | 80% |
| Memory Usage | % | 85% |
| Disk Usage | % | 90% |
| Response Time | ms | 5000ms |
| Network In | bytes/s | - |
| Network Out | bytes/s | - |

### Severity Levels
| Level | Icon | Color | Use Case |
|-------|------|-------|----------|
| Info | info.circle | Blue | FYI alerts |
| Warning | exclamationmark.triangle | Orange | Attention needed |
| Critical | exclamationmark.octagon | Red | Immediate action |

### Cooldown
Prevents repeated notifications for the same threshold breach:
- Default: 15 minutes
- Configurable per threshold
- Resets when metric returns to normal

---

## Feature 6: SSL Certificate Monitoring

### Overview
Automatic SSL/TLS certificate discovery, validation, and expiry tracking for HTTPS servers.

### Files Created
- `SSLCertificateService.swift` - Certificate checking service

### Files Modified
- `Server.swift` - SSL info storage
- `ServerMonitoringService.swift` - SSL check integration
- `ServerDetailView.swift` - SSL tab

### Data Structure
```swift
struct SSLCertificateInfo: Codable {
    let commonName: String?
    let issuer: String?
    let validFrom: Date
    let validUntil: Date
    let serialNumber: String?
    let signatureAlgorithm: String?

    var daysUntilExpiry: Int
    var isExpired: Bool
    var expiryStatus: SSLExpiryStatus
}

enum SSLExpiryStatus {
    case valid       // > 30 days
    case expiringSoon // 7-30 days
    case critical    // < 7 days
    case expired     // Past expiry
}
```

### Check Process
1. Create HTTPS URLSession request
2. Use URLSessionDelegate to capture certificate
3. Extract certificate details from SecTrust
4. Parse expiry dates and issuer info
5. Store as JSON in Server model

### Display (SSL Tab)
- Certificate common name
- Issuer organization
- Valid from/until dates
- Days until expiry (color-coded)
- Last check timestamp
- Refresh button

### Notifications
- Warning at 30 days before expiry
- Critical at 7 days before expiry

---

## Feature 7: Menu Bar Quick Access

### Overview
System tray (menu bar) icon providing quick server status overview without opening the main app.

### Files Created
- `MenuBarView.swift` - Menu bar popover UI

### Files Modified
- `ServerApp.swift` - MenuBarExtra configuration
- `SettingsView.swift` - Visibility toggle

### Features
| Feature | Description |
|---------|-------------|
| Status Overview | Online/Offline/Warning counts |
| Server List | Top 10 servers (sorted by status) |
| Status Badges | Color-coded status for each server |
| Response Times | Show latency for each server |
| Quick Actions | Open Dashboard, Quit |
| Last Updated | Timestamp of last refresh |

### Component Hierarchy
```
MenuBarView
├── Header (Logo + Overall Status Dot)
├── QuickStatView × 3 (Online/Offline/Warning)
├── Server List
│   └── MenuBarServerRow × n
└── Footer (Last Updated + Actions)
```

### Overall Status Logic
- Green: All servers online
- Orange: At least one warning
- Red: At least one offline
- Gray: No servers or unknown

### Settings
Toggle "Show in Menu Bar" in Settings → General

---

## Feature 8: Secure Credential Management

### Overview
macOS Keychain integration for storing SSH credentials securely.

### Files Created
- `KeychainService.swift` - Keychain wrapper
- `CredentialsView.swift` - Credential management UI

### Files Modified
- `Server.swift` - Credential helper methods
- `ServerDetailView.swift` - Credentials section

### Authentication Types
| Type | Fields Required |
|------|-----------------|
| Password | Username, Password |
| Private Key | Username, Private Key content |
| Private Key + Passphrase | Username, Private Key, Passphrase |

### Data Structure
```swift
struct ServerCredentials: Codable {
    var username: String
    var password: String
    var privateKey: String?
    var privateKeyPassphrase: String?
    var authType: AuthenticationType
}
```

### Keychain Storage
```swift
// Service identifier
let serviceName = "com.servermonitor.credentials"

// Each server's credentials stored with server ID as account
func saveCredentials(_ credentials: ServerCredentials, forServerID serverID: String)
```

### Security Features
- Stored in macOS Keychain (encrypted)
- `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`
- Never stored in SwiftData
- Passwords hidden by default (show/hide toggle)
- Private key file import support

### UI Components
| Component | Purpose |
|-----------|---------|
| CredentialsEditorView | Full credential editor sheet |
| CredentialsSummaryView | Inline summary with edit button |
| CredentialsBadge | Small indicator for credential status |

---

## Feature 9: Real Metrics via SSH

### Overview
Collect actual CPU, memory, disk, and other metrics from servers using SSH connections.

### Files Created
- `SSHMetricsService.swift` - SSH metrics collection

### Files Modified
- `ServerMonitoringService.swift` - Metrics integration
- `SettingsView.swift` - Enable/disable toggle

### Metrics Collected
| Metric | Source Command | Unit |
|--------|----------------|------|
| CPU Usage | `top -bn1` or `mpstat` | % |
| Memory Usage | `free -b` | bytes/% |
| Disk Usage | `df -B1 /` | bytes/% |
| Load Average | `/proc/loadavg` | 1/5/15 min |
| Uptime | `/proc/uptime` | seconds |
| Process Count | `ps aux \| wc -l` | count |
| Network I/O | `/proc/net/dev` | bytes |

### Data Structure
```swift
struct RealServerMetrics {
    let cpuUsage: Double?
    let memoryUsage: Double?
    let memoryTotal: UInt64?
    let memoryUsed: UInt64?
    let diskUsage: Double?
    let diskTotal: UInt64?
    let diskUsed: UInt64?
    let networkIn: Double?
    let networkOut: Double?
    let loadAverage: (one: Double, five: Double, fifteen: Double)?
    let uptime: TimeInterval?
    let processCount: Int?
    let timestamp: Date
}
```

### SSH Command Flow
1. Build SSH arguments (host, port, key/password)
2. Execute combined metrics command
3. Parse sectioned output (===CPU===, ===MEMORY===, etc.)
4. Return structured metrics object

### Authentication Support
| Type | Method |
|------|--------|
| Private Key | `-i /path/to/key` |
| Password | `sshpass -p password ssh` |
| Key + Passphrase | Key file with ssh-agent |

### Error Handling
| Error | Cause |
|-------|-------|
| `sshNotAvailable` | SSH command not found |
| `authenticationFailed` | Wrong credentials |
| `connectionRefused` | SSH port closed |
| `hostUnreachable` | Network issue |
| `timeout` | Connection took > 30s |
| `commandFailed` | Remote command error |

### Settings
Toggle "Collect Real Metrics via SSH" in Settings → General

### Requirements
- Server must have stored credentials
- SSH access enabled on target server
- For password auth: `sshpass` utility installed

---

## Integration Summary

All 9 features work together seamlessly:

```
Server Check Cycle:
    ↓
1. Real Ping (Network Framework)
    ↓
2. SSL Certificate Check (if HTTPS)
    ↓
3. Real Metrics via SSH (if credentials)
    ↓
4. Uptime Record Creation
    ↓
5. Threshold Checking
    ↓
6. Notification Dispatch (if needed)
    ↓
7. UI Updates (Dashboard + Menu Bar)
```

---

## Migration Notes

### SwiftData Schema
The schema version was updated to include new models:
```swift
static var schema: Schema {
    Schema([
        Server.self,
        ServerMetric.self,
        ServerLog.self,
        ServerGroup.self,      // NEW
        AlertThreshold.self,   // NEW
        UptimeRecord.self      // NEW
    ])
}
```

### Existing Data
- Existing servers are preserved
- New fields have sensible defaults
- No data migration required
- New features activate automatically

---

## Testing Checklist

- [ ] Real ping to known hosts (google.com, etc.)
- [ ] Notifications appear in Notification Center
- [ ] Uptime percentage calculates correctly
- [ ] Groups filter dashboard properly
- [ ] Thresholds trigger notifications
- [ ] SSL certificates display in SSL tab
- [ ] Menu bar shows correct counts
- [ ] Credentials save to Keychain
- [ ] SSH metrics collect (if sshpass available)
