# New Features Documentation

This document details the 15 features implemented in Server Monitor Dashboard (9 advanced features + 6 quick wins + 4 medium effort features).

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

---

## Feature 10: Historical Charts

### Overview
Comprehensive metrics visualization with time range selection and trend analysis.

### Files Created
- `HistoricalChartsView.swift` - Main charting view

### Files Modified
- `ServerDetailView.swift` - Added History tab

### Time Ranges
| Range | Description |
|-------|-------------|
| 1H | Last hour |
| 6H | Last 6 hours |
| 24H | Last 24 hours |
| 7D | Last 7 days |
| 30D | Last 30 days |

### Metric Types
- Response Time (ms)
- CPU Usage (%)
- Memory Usage (%)
- Disk Usage (%)
- Uptime (%)

### Features
- Interactive Swift Charts visualization
- Stats summary (avg/min/max)
- Trend analysis and insights
- Color-coded data points
- Time-based filtering

### Usage
Navigate to Server Detail → History tab to view charts.

---

## Feature 11: Server Templates

### Overview
Predefined server configurations for quick setup with 20 built-in templates.

### Files Created
- `ServerTemplate.swift` - SwiftData model
- `ServerTemplatesView.swift` - Template selection UI

### Files Modified
- `AddServerView.swift` - Template selector integration
- `ServerApp.swift` - Schema registration

### Built-in Templates
| Category | Templates |
|----------|-----------|
| Web Servers | HTTP, HTTPS, Nginx, Apache |
| Databases | MySQL, PostgreSQL, MongoDB, Redis, Elasticsearch |
| Cache/Queue | Redis, Memcached, RabbitMQ, Kafka |
| Monitoring | Prometheus, Grafana, Zabbix |
| Other | SSH, FTP, SMTP, DNS, Docker, Kubernetes |

### Data Model
```swift
@Model
final class ServerTemplate {
    var id: UUID
    var name: String
    var serverType: ServerType
    var defaultPort: Int
    var iconName: String
    var colorHex: String
    var isBuiltIn: Bool
    var defaultTags: String
    var defaultNotes: String
}
```

### Usage
1. Open Add Server dialog
2. Select from Quick Start template grid
3. Template auto-fills port, type, and tags
4. Customize as needed

---

## Feature 12: Maintenance Windows

### Overview
Schedule alert silence periods for planned maintenance.

### Files Created
- `MaintenanceWindow.swift` - SwiftData model
- `MaintenanceWindowsView.swift` - Management UI

### Files Modified
- `ServerApp.swift` - Schema registration

### Recurrence Types
| Type | Schedule |
|------|----------|
| None | One-time window |
| Daily | Every day at same time |
| Weekdays | Monday through Friday |
| Weekends | Saturday and Sunday |
| Weekly | Same day each week |
| Monthly | Same day each month |

### Data Model
```swift
@Model
final class MaintenanceWindow {
    var id: UUID
    var name: String
    var windowDescription: String
    var startDate: Date
    var endDate: Date
    var isRecurring: Bool
    var recurrenceType: RecurrenceType
    var isEnabled: Bool
    var server: Server?  // nil = global/all servers
}
```

### Features
- Global or per-server scope
- Active/Scheduled/Recurring/Completed sections
- Enable/disable toggle
- Edit and delete support
- Duration display

### Usage
1. Navigate to Settings → Maintenance Windows
2. Click "Add Window"
3. Configure name, schedule, and scope
4. Enable recurring if needed

---

## Feature 13: Import from File

### Overview
Import servers from JSON, CSV, or SSH config files.

### Files Created
- `ImportView.swift` - Import UI with preview

### Files Modified
- `DashboardView.swift` - Import sheet integration
- `ServerApp.swift` - Menu item and notification

### Import Sources
| Source | Format |
|--------|--------|
| JSON | Server Monitor export format |
| CSV | Name, Host, Port, Type, Status columns |
| SSH Config | ~/.ssh/config file |

### Features
- Duplicate detection with skip option
- Preview imported servers before confirming
- Select/deselect individual servers
- SSH config parser for Host, HostName, Port, User

### Keyboard Shortcut
`⌘⇧I` - Open Import dialog

### CSV Format
```csv
Name,Host,Port,Type,Status
Production Web,prod.example.com,443,https,online
Database,db.example.com,5432,database,online
```

### SSH Config Parsing
```
Host myserver
    HostName 192.168.1.100
    Port 22
    User admin
```

### Usage
1. Press ⌘⇧I or use File → Import Servers
2. Select import source (JSON/CSV/SSH Config)
3. Choose file or load SSH config
4. Review and select servers to import
5. Click Import

---

## Quick Wins (Features 14-19)

### Feature 14: Server Search/Filter
- Search bar in dashboard sidebar
- Filter by name, host, tags, or group
- Real-time filtering

### Feature 15: Bulk Actions
- Select mode toggle
- Bulk delete with confirmation
- Bulk move to group
- Bulk export

### Feature 16: Dark/Light Theme Toggle
- Settings → General → Appearance
- System/Light/Dark options
- Persisted with @AppStorage

### Feature 17: Export Server List
- Export to JSON (pretty-printed)
- Export to CSV (spreadsheet-compatible)
- Export all or selected servers

### Feature 18: Keyboard Shortcuts
| Shortcut | Action |
|----------|--------|
| ⌘N | Add new server |
| ⌘R | Refresh all servers |
| ⌘⇧M | Toggle monitoring |
| ⌘⇧E | Export servers |
| ⌘⇧I | Import servers |
| ⌘F | Focus search |
| ⌘1-6 | Navigate sections |

### Feature 19: Quick Actions Context Menu
Right-click on server for:
- Check Now
- Copy Host / Copy Host:Port
- Open in Browser
- Open SSH in Terminal
- Export Server
- Delete
