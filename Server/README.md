# Server Monitor Dashboard

A comprehensive macOS application for monitoring web, file, and network servers.

## 🏗️ Project Structure

### Models (SwiftData)
- **`Server.swift`** - Main server entity with properties like name, host, port, type, and status
- **`ServerMetric.swift`** - Performance metrics (CPU, memory, disk, network)
- **`ServerLog.swift`** - Log entries with levels (info, warning, error, critical)
- **`Item.swift`** - Legacy model from template (can be removed)

### Views
- **`DashboardView.swift`** - Main dashboard with server list and overview statistics
- **`ServerListItemView.swift`** - Individual server row in the sidebar
- **`ServerDetailView.swift`** - Detailed view with tabs for Overview, Metrics, and Logs
- **`AddServerView.swift`** - Sheet for adding new servers
- **`SettingsView.swift`** - Application settings (monitoring interval, notifications, data retention)
- **`ContentView.swift`** - Legacy template view (not used in main app)

### Services
- **`ServerMonitoringService.swift`** - Background monitoring service that:
  - Checks server status periodically
  - Performs HTTP/HTTPS requests
  - TCP connection checks for non-HTTP servers
  - Logs status changes
  - Records metrics

### Utilities
- **`SampleData.swift`** - Helper to generate sample servers for testing

### App Entry
- **`ServerApp.swift`** - Main app with SwiftData configuration

## 🚀 Features

### ✅ Implemented
1. **Server Management**
   - Add/delete servers
   - Multiple server types (HTTP, HTTPS, FTP, SSH, Database, Custom)
   - Server status tracking (Online, Offline, Warning, Unknown)
   - Response time monitoring

2. **Dashboard Overview**
   - Quick statistics (Total, Online, Offline, Warning servers)
   - Server list with search
   - Real-time status indicators
   - Monitoring toggle

3. **Server Details**
   - Three-tab interface (Overview, Metrics, Logs)
   - Connection information
   - Performance gauges (CPU, Memory, Disk)
   - Interactive charts using Swift Charts
   - Filterable logs by level

4. **Monitoring Service**
   - Background checking every 30 seconds (configurable)
   - HTTP/HTTPS ping support
   - TCP connection checks
   - Automatic metric collection
   - Log generation

5. **Settings**
   - Monitoring interval configuration
   - Notification preferences
   - Data retention limits

### 🔨 To Implement (Next Steps)

1. **Enhanced Monitoring**
   - Real SSH/FTP connection testing
   - Custom port scanning
   - SSL certificate validation
   - Webhook support

2. **Notifications**
   - macOS notifications for status changes
   - Alert rules and thresholds
   - Email notifications

3. **Data Visualization**
   - Uptime percentage graphs
   - Historical status timeline
   - Export reports

4. **Advanced Features**
   - Server groups/categories
   - Bulk operations
   - Import/export server configurations
   - Dark mode optimization

## 🎨 Customization Guide

### Adjusting Monitoring Interval
In `ServerMonitoringService.swift`, change this line:
```swift
try? await Task.sleep(for: .seconds(30)) // Change 30 to your preferred interval
```

### Adding Custom Server Types
1. Edit `ServerType` enum in `Server.swift`
2. Add new case with icon
3. Update connection logic in `ServerMonitoringService.swift`

### Modifying Metrics
1. Add properties to `ServerMetric.swift`
2. Update metric collection in `ServerMonitoringService.checkServer()`
3. Add visualization in `ServerDetailView.ServerMetricsView`

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
   - Optional notes
3. Click "Add"

### Monitoring
- **Start/Stop**: Use the play/pause button in toolbar
- **Manual Check**: Right-click a server → "Check Now"
- **View Details**: Click a server in the list

## 🧪 Testing with Sample Data

The app includes sample data generation. When you run the app, if no servers exist, you'll see a button to load sample data with:
- 6 sample servers of various types
- Metrics history (last hour)
- Sample log entries

## 🛠️ Technical Details

### SwiftData Relationships
- Server → ServerMetric (one-to-many, cascade delete)
- Server → ServerLog (one-to-many, cascade delete)

### Concurrency
- Uses Swift Concurrency (async/await)
- `@MainActor` for UI updates
- Background monitoring with `Task`

### Platform
- macOS only (uses macOS-specific features like Settings scene)
- Requires macOS 14.0+ (SwiftData, Swift Charts)

## 🔧 Build Requirements
- Xcode 15.0+
- macOS 14.0+
- Swift 5.9+

## 📂 Files to Customize Based on Your Figma Design

When you're ready to integrate your Figma-converted files:

1. **Layout**: Adjust spacing, padding in `DashboardView.swift`
2. **Colors**: Update in individual view files (search for `.foregroundStyle`, `.background`)
3. **Typography**: Modify `.font()` modifiers throughout
4. **Components**: Replace `StatCardView`, `ServerListItemView`, etc. with your Figma components
5. **Navigation**: Adjust `NavigationSplitView` configuration in `DashboardView.swift`

## 🎯 Next Steps

1. **Run the app** and explore the interface
2. **Load sample data** to see it in action
3. **Test monitoring** with real servers
4. **Share your Figma files** so I can help integrate them
5. **Identify which views** match your design
6. **Customize styling** to match your brand

## 💡 Tips

- Use CMD+, to open Settings
- Right-click servers for quick actions
- Use search to filter servers
- Monitor response times to identify slow servers
- Check logs for detailed information

---

Need help with anything? Let me know what you'd like to work on next!
