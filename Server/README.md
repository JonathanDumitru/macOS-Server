# Server Monitor Dashboard

A comprehensive macOS application for monitoring web, file, and network servers with enterprise-grade features including real-time metrics, SSL certificate monitoring, and secure credential management.

## 🏗️ Project Structure

### Models (SwiftData)
- **`Server.swift`** - Main server entity with properties like name, host, port, type, status, uptime tracking, and SSL info
- **`ServerMetric.swift`** - Performance metrics (CPU, memory, disk, network)
- **`ServerLog.swift`** - Log entries with levels (info, warning, error, critical)
- **`ServerGroup.swift`** - Server organization with groups and tags
- **`AlertThreshold.swift`** - Custom alert threshold configurations
- **`UptimeRecord.swift`** - Historical status records for uptime calculations

### Views
- **`DashboardView.swift`** - Main dashboard with server list, overview statistics, and group filtering
- **`ServerListItemView.swift`** - Individual server row in the sidebar
- **`ServerDetailView.swift`** - Detailed view with tabs for Overview, Metrics, Logs, and SSL
- **`AddServerView.swift`** - Sheet for adding new servers with group/tag selection
- **`SettingsView.swift`** - Application settings (General, Notifications, Alerts, Data)
- **`GroupManagementView.swift`** - Create and manage server groups/tags
- **`AlertThresholdsView.swift`** - Configure custom alert thresholds
- **`CredentialsView.swift`** - Secure credential management for SSH access
- **`MenuBarView.swift`** - Menu bar quick access popover
- **`WelcomeView.swift`** - First launch onboarding screen

### Services
- **`ServerMonitoringService.swift`** - Core background monitoring service with:
  - Real ping/connectivity checks using Network framework
  - Notification integration
  - Uptime tracking
  - Alert threshold checking
  - SSL certificate monitoring
  - Real metrics via SSH

- **`NotificationService.swift`** - macOS notification management:
  - Status change notifications
  - Error alerts
  - Threshold exceeded warnings
  - SSL certificate expiry alerts

- **`SSLCertificateService.swift`** - SSL/TLS certificate monitoring:
  - Certificate validation
  - Expiry date tracking
  - Chain information

- **`SSHMetricsService.swift`** - Real server metrics via SSH:
  - CPU, memory, disk usage
  - Load averages
  - Process counts
  - Network I/O

- **`KeychainService.swift`** - Secure credential storage:
  - Password authentication
  - Private key storage
  - Passphrase-protected keys

### Utilities
- **`SampleData.swift`** - Helper to generate sample servers for testing

### App Entry
- **`ServerApp.swift`** - Main app with SwiftData configuration and MenuBarExtra

## 🚀 Features

### ✅ Core Features
1. **Server Management**
   - Add/edit/delete servers
   - Multiple server types (HTTP, HTTPS, FTP, SSH, Database, Custom)
   - Server status tracking (Online, Offline, Warning, Unknown)
   - Response time monitoring
   - Notes and descriptions

2. **Dashboard Overview**
   - Quick statistics (Total, Online, Offline, Warning servers)
   - Server list with search and filtering
   - Real-time status indicators
   - Monitoring toggle
   - Group filtering

3. **Server Details**
   - Four-tab interface (Overview, Metrics, Logs, SSL)
   - Connection information
   - Performance gauges (CPU, Memory, Disk)
   - Interactive charts using Swift Charts
   - Filterable logs by level
   - Credential management badge

### ✅ Implemented Advanced Features

4. **Real Ping/Connectivity (Feature 1)**
   - Network framework-based TCP connections
   - True connectivity verification
   - Accurate response time measurement

5. **macOS Notifications (Feature 2)**
   - Native notification center integration
   - Status change alerts
   - Error notifications
   - Permission management in settings

6. **Uptime Tracking (Feature 3)**
   - Historical status recording
   - Uptime percentage calculations
   - Status change timestamps
   - Downtime duration tracking

7. **Server Groups & Tags (Feature 4)**
   - Custom group creation with colors and icons
   - Tag-based organization
   - Group filtering on dashboard
   - Bulk organization capabilities

8. **Custom Alert Thresholds (Feature 5)**
   - Per-server threshold configuration
   - Multiple metric types (CPU, Memory, Disk, Response Time)
   - Severity levels (Info, Warning, Critical)
   - Cooldown periods to prevent alert spam

9. **SSL Certificate Monitoring (Feature 6)**
   - Automatic certificate discovery
   - Expiry date tracking
   - Days-until-expiry warnings
   - Certificate chain information
   - Dedicated SSL tab in server details

10. **Menu Bar Quick Access (Feature 7)**
    - System tray icon with status overview
    - Quick stats (Online/Offline/Warning counts)
    - Server list preview
    - One-click dashboard access
    - Configurable visibility

11. **Secure Credential Management (Feature 8)**
    - macOS Keychain integration
    - Password authentication
    - Private key authentication
    - Passphrase-protected key support
    - Credential editing and deletion

12. **Real Metrics via SSH (Feature 9)**
    - Live CPU usage collection
    - Memory utilization
    - Disk space monitoring
    - Load averages (1, 5, 15 min)
    - Process counts
    - Network I/O statistics
    - Requires stored credentials

### Settings Categories
- **General**: Monitoring interval, real metrics toggle, menu bar visibility
- **Notifications**: Permission status, alert toggles, test notifications
- **Alerts**: Threshold alerts toggle, threshold configuration
- **Data**: Log/metric retention limits, data cleanup

## 🎨 Customization Guide

### Adjusting Monitoring Interval
In Settings → General, choose from:
- 15 seconds
- 30 seconds (default)
- 1 minute
- 2 minutes
- 5 minutes

### Adding Custom Server Types
1. Edit `ServerType` enum in `Server.swift`
2. Add new case with icon
3. Update connection logic in `ServerMonitoringService.swift`

### Configuring Alert Thresholds
1. Go to Settings → Alerts
2. Click "Configure Thresholds"
3. Add per-server or global thresholds
4. Set metric type, value, and severity

### Styling
- Colors are using semantic colors (`.blue`, `.green`, `.red`, etc.)
- Materials use `.ultraThinMaterial` for translucency
- SF Symbols for all icons

## 📝 Usage

### First Run
1. Build and run the app
2. Click "Add Server" to add your first server
3. Click "Start Monitoring" to begin automatic checks
4. Select a server from the list to view details

### Adding a Server
1. Click the "+" button in the toolbar
2. Fill in server details:
   - Name (display name)
   - Host (domain or IP)
   - Port (1-65535)
   - Type (HTTP, HTTPS, etc.)
   - Group (optional)
   - Tags (optional)
   - Optional notes
3. Click "Add"

### Managing Credentials
1. Select a server
2. In the Overview tab, find "Authentication" section
3. Click "Add" or "Edit" to manage credentials
4. Choose authentication type (Password, Private Key, or Key with Passphrase)
5. Credentials are stored securely in macOS Keychain

### Monitoring SSL Certificates
1. Add an HTTPS server
2. Select the server
3. Click the "SSL" tab
4. View certificate details and expiry information

### Using Server Groups
1. Go to Settings (⌘,) or click gear icon
2. Open "Groups" management
3. Create groups with custom colors and icons
4. Assign servers to groups when adding/editing

### Menu Bar Access
1. Enable "Show in Menu Bar" in Settings → General
2. Click the menu bar icon for quick status overview
3. Click "Open Dashboard" for full application

## 🧪 Testing with Sample Data

The app includes sample data generation. When you run the app, if no servers exist, you'll see a button to load sample data with:
- Sample servers of various types
- Metrics history
- Sample log entries

## 🛠️ Technical Details

### SwiftData Relationships
- Server → ServerMetric (one-to-many, cascade delete)
- Server → ServerLog (one-to-many, cascade delete)
- Server → UptimeRecord (one-to-many, cascade delete)
- Server → AlertThreshold (one-to-many, cascade delete)
- ServerGroup → Server (one-to-many)

### Concurrency
- Uses Swift Concurrency (async/await)
- `@MainActor` for UI updates
- Background monitoring with `Task`

### Security
- Credentials stored in macOS Keychain
- Private keys with proper file permissions
- No sensitive data in SwiftData

### Platform
- macOS only (uses macOS-specific features)
- Requires macOS 14.0+ (SwiftData, Swift Charts)
- MenuBarExtra for system tray integration

## 🔧 Build Requirements
- Xcode 15.0+
- macOS 14.0+
- Swift 5.9+

## ⌨️ Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| ⌘N | Add new server |
| ⌘R | Refresh all servers |
| ⌘⇧M | Toggle monitoring on/off |
| ⌘⇧E | Export servers |
| ⌘F | Focus search field |
| ⌘, | Open Settings |
| ⌘1-6 | Navigate to sections (Dashboard, Roles, Storage, etc.) |

## 💡 Tips

- Use ⌘, to open Settings
- Right-click servers for quick actions (Check Now, Copy Host, Open in Browser, SSH Terminal)
- Use search to filter servers by name, host, tags, or group
- Select multiple servers with the "Select" button for bulk operations
- Export servers to JSON or CSV for backup
- Choose Dark/Light/System theme in Settings → General
- Monitor response times to identify slow servers
- Check logs for detailed information
- Enable real metrics for SSH servers with credentials
- Set up alert thresholds to get proactive notifications
- Use groups to organize servers by project, environment, or team

---

Need help with anything? Check the other documentation files or open an issue!
