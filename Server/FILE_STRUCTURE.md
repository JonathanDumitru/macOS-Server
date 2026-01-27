# 📁 Project File Structure

## Complete File Inventory

```
Server/
├── App Entry
│   └── ServerApp.swift                    ✅ Main app with SwiftData + MenuBarExtra
│
├── Models (SwiftData)
│   ├── Server.swift                       ✅ Server entity with uptime & SSL
│   ├── ServerMetric.swift                 ✅ Performance metrics
│   ├── ServerLog.swift                    ✅ Log entries
│   ├── ServerGroup.swift                  ✅ Server groups/tags
│   ├── AlertThreshold.swift               ✅ Custom alert thresholds
│   ├── UptimeRecord.swift                 ✅ Historical uptime records
│   ├── ServerTemplate.swift               ✅ NEW - Server templates
│   ├── MaintenanceWindow.swift            ✅ NEW - Maintenance windows
│   ├── AppModel.swift                     📦 App state model
│   └── Item.swift                         📦 Legacy - Template model
│
├── Views
│   ├── DashboardView.swift                ✅ Main dashboard with search, bulk actions
│   ├── ServerListItemView.swift           ✅ Server row component
│   ├── ServerDetailView.swift             ✅ Detail with 5 tabs (Overview/Metrics/History/SSL/Logs)
│   ├── AddServerView.swift                ✅ Add server form with templates
│   ├── SettingsView.swift                 ✅ Settings with theme toggle
│   ├── WelcomeView.swift                  ✅ First launch screen
│   ├── GroupManagementView.swift          ✅ Group/tag management
│   ├── AlertThresholdsView.swift          ✅ Threshold configuration
│   ├── CredentialsView.swift              ✅ SSH credential management
│   ├── MenuBarView.swift                  ✅ Menu bar popover
│   ├── HistoricalChartsView.swift         ✅ NEW - Historical metrics charts
│   ├── ServerTemplatesView.swift          ✅ NEW - Template selection UI
│   ├── MaintenanceWindowsView.swift       ✅ NEW - Maintenance window management
│   ├── ImportView.swift                   ✅ NEW - Server import UI
│   ├── NetworkingView.swift               ✅ Network settings view
│   ├── RolesAndFeaturesView.swift         ✅ Roles configuration
│   ├── SecurityView.swift                 ✅ Security settings
│   ├── StorageView.swift                  ✅ Storage overview
│   ├── UpdatesView.swift                  ✅ Update management
│   ├── QuickAccessCustomizationView.swift ✅ Quick access customization
│   └── ContentView.swift                  📦 Legacy - Old template
│
├── Services
│   ├── ServerMonitoringService.swift      ✅ Core monitoring (heavily enhanced)
│   ├── NotificationService.swift          ✅ macOS notifications
│   ├── SSLCertificateService.swift        ✅ SSL certificate checking
│   ├── SSHMetricsService.swift            ✅ Real metrics via SSH
│   ├── KeychainService.swift              ✅ Secure credential storage
│   └── ExportService.swift                ✅ NEW - JSON/CSV export & import
│
├── Utilities
│   └── SampleData.swift                   ✅ Test data generator
│
└── Documentation
    ├── README.md                          📄 Project overview
    ├── FILE_STRUCTURE.md                  📄 This file
    ├── NEW_FEATURES.md                    📄 NEW - Feature documentation
    ├── ROADMAP.md                         📄 NEW - Future feature plans
    ├── GETTING_STARTED.md                 📄 Setup guide
    ├── IMPLEMENTATION_SUMMARY.md          📄 Implementation details
    ├── QUICK_START_GUIDE.md               📄 Quick start
    ├── QUICK_REFERENCE_DETAILPAGE.md      📄 Detail page reference
    ├── DEMO_DATA_REFERENCE.md             📄 Demo data info
    ├── LAYOUT_FIX_SUMMARY.md              📄 Layout fixes
    └── SCROLLVIEW_WIDTH_FIX.md            📄 ScrollView fixes

Total: 38+ Swift files in Server module
```

## 🆕 New Files (Recent Implementation)

### Models
| File | Purpose |
|------|---------|
| `ServerGroup.swift` | Server organization with groups and tags |
| `AlertThreshold.swift` | Custom metric threshold definitions |
| `UptimeRecord.swift` | Historical status for uptime calculations |
| `ServerTemplate.swift` | Predefined server configurations |
| `MaintenanceWindow.swift` | Scheduled maintenance periods |

### Views
| File | Purpose |
|------|---------|
| `GroupManagementView.swift` | Create/edit/delete server groups |
| `AlertThresholdsView.swift` | Configure alert thresholds per server |
| `CredentialsView.swift` | Manage SSH credentials (Keychain) |
| `MenuBarView.swift` | Menu bar quick status popover |
| `HistoricalChartsView.swift` | Time-based metrics visualization |
| `ServerTemplatesView.swift` | Template selection grid |
| `MaintenanceWindowsView.swift` | Maintenance window management |
| `ImportView.swift` | Server import from JSON/CSV/SSH config |

### Services
| File | Purpose |
|------|---------|
| `NotificationService.swift` | macOS notification center integration |
| `SSLCertificateService.swift` | SSL certificate validation & monitoring |
| `SSHMetricsService.swift` | Real server metrics collection via SSH |
| `KeychainService.swift` | Secure credential storage in Keychain |
| `ExportService.swift` | JSON/CSV export and import parsing |

## 🎯 Primary Files to Know

### User Interface Entry Point
**`DashboardView.swift`** - Main view with server list and group filtering

### Data Models
- **`Server.swift`** - Server entity (enhanced with uptime, SSL, credentials)
- **`ServerGroup.swift`** - Groups and tags
- **`AlertThreshold.swift`** - Alert configuration
- **`UptimeRecord.swift`** - Status history

### Core Services
- **`ServerMonitoringService.swift`** - All monitoring logic
- **`NotificationService.swift`** - Notification handling
- **`SSLCertificateService.swift`** - Certificate checks
- **`SSHMetricsService.swift`** - SSH-based metrics
- **`KeychainService.swift`** - Credential management

## 🔄 Data Flow

```
User Action (Add Server)
    ↓
AddServerView (with group/tag selection)
    ↓
ModelContext.insert(server)
    ↓
SwiftData saves automatically
    ↓
@Query updates DashboardView
    ↓
ServerMonitoringService checks server
    ├── Creates ServerMetric & ServerLog
    ├── Creates UptimeRecord
    ├── Checks AlertThresholds → NotificationService
    ├── Checks SSL Certificate → SSLCertificateService
    └── Collects Real Metrics → SSHMetricsService (if credentials)
    ↓
ServerDetailView displays data
```

## 🧩 Component Hierarchy

```
ServerApp (Entry Point)
    ├── WindowGroup
    │   └── DashboardView
    │       ├── NavigationSplitView (Sidebar)
    │       │   ├── DashboardHeaderView (Stats + Group Filter)
    │       │   └── List
    │       │       └── ServerListItemView (Each Server)
    │       │
    │       └── NavigationSplitView (Detail)
    │           └── ServerDetailView
    │               ├── ServerDetailHeaderView (+ CredentialsBadge)
    │               └── TabView
    │                   ├── ServerOverviewView (+ CredentialsSummaryView)
    │                   ├── ServerMetricsView (with Charts)
    │                   ├── ServerLogsView
    │                   └── SSLCertificateView
    │
    ├── MenuBarExtra
    │   └── MenuBarView
    │       ├── QuickStatView
    │       └── MenuBarServerRow
    │
    └── Settings
        └── SettingsView
            ├── GeneralSettingsView
            ├── NotificationSettingsView
            ├── AlertSettingsView
            └── DataSettingsView
```

## 🔐 Security Architecture

```
Credential Storage Flow:
    User Input → CredentialsEditorView
        ↓
    ServerCredentials struct
        ↓
    KeychainService.saveCredentials()
        ↓
    macOS Keychain (encrypted)

Credential Usage Flow:
    ServerMonitoringService
        ↓
    server.loadCredentials() → KeychainService
        ↓
    SSHMetricsService.collectMetrics()
        ↓
    Real server metrics
```

## 🎨 Customization Points

### If you want to change...

**Colors/Theme**
- Search for: `.foregroundStyle`, `.background`, `Color(`
- Files: All view files

**Layout/Spacing**
- Search for: `.padding`, `spacing:`, `VStack`, `HStack`
- Files: All view files

**Typography**
- Search for: `.font(`
- Files: All view files

**Icons**
- Search for: `systemImage:`, `Image(systemName:`
- Files: All view files

**Monitoring Logic**
- File: `ServerMonitoringService.swift`
- Function: `checkServer(_:)`

**Notifications**
- File: `NotificationService.swift`
- Functions: `notifyServerStatusChange`, `notifyThresholdExceeded`

**Alert Thresholds**
- File: `AlertThreshold.swift`
- Enum: `AlertMetricType`, `AlertSeverity`

**SSH Metrics**
- File: `SSHMetricsService.swift`
- Function: `collectMetrics`

## 🚀 Build Order (What Depends on What)

1. **Models** (No dependencies)
   - Server.swift, ServerMetric.swift, ServerLog.swift
   - ServerGroup.swift, AlertThreshold.swift, UptimeRecord.swift

2. **Services** (Depends on Models)
   - KeychainService.swift
   - NotificationService.swift
   - SSLCertificateService.swift
   - SSHMetricsService.swift
   - ServerMonitoringService.swift

3. **Utilities** (Depends on Models)
   - SampleData.swift

4. **Views** (Depends on Models + Services)
   - ServerListItemView.swift
   - AddServerView.swift
   - CredentialsView.swift
   - GroupManagementView.swift
   - AlertThresholdsView.swift
   - MenuBarView.swift
   - ServerDetailView.swift
   - SettingsView.swift
   - DashboardView.swift

5. **App Entry** (Depends on Everything)
   - ServerApp.swift

## 📦 Safe to Delete

These files are from templates and not actively used:
- **Item.swift** (replaced by Server.swift)
- **ContentView.swift** (replaced by DashboardView.swift)

## 🔍 Quick File Reference

| What you want to do | File to edit |
|---------------------|--------------|
| Add a new server type | `Server.swift` (ServerType enum) |
| Change monitoring interval | `ServerMonitoringService.swift` |
| Modify dashboard layout | `DashboardView.swift` |
| Update server card design | `ServerListItemView.swift` |
| Add new metrics | `ServerMetric.swift` + `ServerDetailView.swift` |
| Change log levels | `ServerLog.swift` (LogLevel enum) |
| Customize notifications | `NotificationService.swift` |
| Add threshold types | `AlertThreshold.swift` (AlertMetricType) |
| Modify credential storage | `KeychainService.swift` |
| Customize menu bar | `MenuBarView.swift` |
| Add SSL checks | `SSLCertificateService.swift` |
| Modify SSH metrics | `SSHMetricsService.swift` |
| Create server groups | `GroupManagementView.swift` |
| Configure alert thresholds | `AlertThresholdsView.swift` |

## 💡 Pro Tips

1. **Search Everywhere**: Use Xcode's `⌘⇧F` to find where things are used
2. **Preview Often**: Each view has `#Preview` - use them!
3. **One File at a Time**: Replace components gradually
4. **Keep Functionality**: When changing UI, keep `@Bindable`, `@Environment`, etc.
5. **Test Frequently**: Run the app after each change
6. **Check Keychain**: Use Keychain Access.app to verify credential storage
7. **Test Notifications**: Use the test button in Settings → Notifications

## 🏁 Current Status

- ✅ 38+ Swift files
- ✅ 9 advanced features implemented
- ✅ 6 quick win features implemented
- ✅ 4 medium effort features implemented
- ✅ Full SwiftData integration
- ✅ Monitoring service with real ping
- ✅ macOS notifications
- ✅ Uptime tracking
- ✅ Server groups/tags
- ✅ Custom alert thresholds
- ✅ SSL certificate monitoring
- ✅ Menu bar quick access
- ✅ Secure credential management
- ✅ Real metrics via SSH
- ✅ Historical charts with trends
- ✅ Server templates (20 built-in)
- ✅ Maintenance windows
- ✅ Import from JSON/CSV/SSH config
- ✅ Search/filter, bulk actions
- ✅ Export to JSON/CSV
- ✅ Keyboard shortcuts
- ✅ Dark/Light theme toggle
- ✅ Documentation updated

**Ready for production use!** 🎉
