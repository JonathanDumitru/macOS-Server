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
│   ├── ServerGroup.swift                  ✅ NEW - Server groups/tags
│   ├── AlertThreshold.swift               ✅ NEW - Custom alert thresholds
│   ├── UptimeRecord.swift                 ✅ NEW - Historical uptime records
│   ├── AppModel.swift                     📦 App state model
│   └── Item.swift                         📦 Legacy - Template model
│
├── Views
│   ├── DashboardView.swift                ✅ Main dashboard with group filtering
│   ├── ServerListItemView.swift           ✅ Server row component
│   ├── ServerDetailView.swift             ✅ Detail with 4 tabs (Overview/Metrics/Logs/SSL)
│   ├── AddServerView.swift                ✅ Add server form with groups/tags
│   ├── SettingsView.swift                 ✅ Settings (General/Notifications/Alerts/Data)
│   ├── WelcomeView.swift                  ✅ First launch screen
│   ├── GroupManagementView.swift          ✅ NEW - Group/tag management
│   ├── AlertThresholdsView.swift          ✅ NEW - Threshold configuration
│   ├── CredentialsView.swift              ✅ NEW - SSH credential management
│   ├── MenuBarView.swift                  ✅ NEW - Menu bar popover
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
│   ├── NotificationService.swift          ✅ NEW - macOS notifications
│   ├── SSLCertificateService.swift        ✅ NEW - SSL certificate checking
│   ├── SSHMetricsService.swift            ✅ NEW - Real metrics via SSH
│   └── KeychainService.swift              ✅ NEW - Secure credential storage
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

Total: 32+ Swift files in Server module
```

## 🆕 New Files (Recent Implementation)

### Models
| File | Purpose |
|------|---------|
| `ServerGroup.swift` | Server organization with groups and tags |
| `AlertThreshold.swift` | Custom metric threshold definitions |
| `UptimeRecord.swift` | Historical status for uptime calculations |

### Views
| File | Purpose |
|------|---------|
| `GroupManagementView.swift` | Create/edit/delete server groups |
| `AlertThresholdsView.swift` | Configure alert thresholds per server |
| `CredentialsView.swift` | Manage SSH credentials (Keychain) |
| `MenuBarView.swift` | Menu bar quick status popover |

### Services
| File | Purpose |
|------|---------|
| `NotificationService.swift` | macOS notification center integration |
| `SSLCertificateService.swift` | SSL certificate validation & monitoring |
| `SSHMetricsService.swift` | Real server metrics collection via SSH |
| `KeychainService.swift` | Secure credential storage in Keychain |

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

- ✅ 32+ Swift files
- ✅ 9 advanced features implemented
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
- ✅ Documentation updated

**Ready for production use!** 🎉
