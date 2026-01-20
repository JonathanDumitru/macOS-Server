//
//  QUICK_START_GUIDE.md
//  Server Management Dashboard - Quick Start Guide
//

# Quick Start Guide

## Getting Started

Your Server Management Dashboard now includes comprehensive management sections for Windows Server operations. Here's how to use each feature:

## Navigation

### Sidebar Structure
- **Primary Sections**: Dashboard, Roles & Features, Storage, Networking, Security, Updates
- **Quick Access**: Customizable shortcuts (Event Viewer, Services, Performance Monitor, etc.)
- **Server Status**: Real-time monitoring controls and status badges

### Quick Access Customization
1. Click the ellipsis (···) icon next to "QUICK ACCESS"
2. Drag items to reorder (in Pinned Items section)
3. Click + to add items from Available Tools
4. Click - to remove items (minimum 3 required)
5. Click "Done" to save changes

## Section Features

### Dashboard
**What it shows**: Complete system overview with metrics, charts, and server status
**Key features**:
- 8 summary metric cards (Uptime, Active Users, Running Services, etc.)
- Real-time CPU and Memory usage charts
- Server status grid with quick metrics
- "View Servers" button to see individual server details

### Roles & Features
**What it shows**: Windows Server roles and optional features
**Key features**:
- Filter by: All, Roles, Features, Installed, Not Installed, Pending
- Summary cards showing installed/available counts
- Install or remove roles with one click
- Dependency and service impact information
- Reboot requirement indicators

**Try this**:
1. Select "Web Server (IIS)" from the list
2. Click "Install Role" button
3. Notice the status changes to "Pending Install"
4. View affected services in the detail panel

### Storage
**What it shows**: Disk volumes and physical storage devices
**Key features**:
- Toggle between Volumes and Disks views
- Usage bar chart showing capacity distribution
- Create new volumes with custom size and filesystem
- Health monitoring with warning indicators
- SMART status for physical disks
- Run disk checks and resize operations

**Try this**:
1. Click "Create Volume" toolbar button
2. Enter name, select filesystem, adjust size slider
3. Click "Create" to add volume
4. View it in the volume list and chart

### Networking
**What it shows**: Network adapters, IP configuration, and traffic
**Key features**:
- Active adapter status and IP addresses
- Real-time traffic chart (TX/RX)
- DHCP toggle for each adapter
- DNS server configuration (comma-separated)
- Network diagnostics tool
- Link speed and throughput monitoring

**Try this**:
1. Select "Ethernet 1" adapter
2. Toggle "Use DHCP" switch
3. Update DNS servers (e.g., "8.8.8.8, 1.1.1.1")
4. Click "Run Network Diagnostics" to see test results

### Security
**What it shows**: Security alerts, threats, and system protection status
**Key features**:
- Filter alerts by severity (Critical, High, Medium, Low, Info)
- Filter by status (Open, Acknowledged, Resolved)
- Alert distribution visualization
- Detailed remediation recommendations
- Acknowledge or resolve alerts
- Security recommendations panel

**Try this**:
1. Filter by "Critical" severity
2. Select "Multiple Failed Login Attempts" alert
3. Read the remediation steps
4. Click "Acknowledge Alert" or "Mark as Resolved"

### Updates
**What it shows**: Windows Update status and available patches
**Key features**:
- Filter by update status (Available, Downloaded, Installed, etc.)
- Auto-update toggle
- Update status distribution bar chart
- KB article numbers with sizes
- Reboot requirement indicators
- Download and install actions

**Try this**:
1. Click "Check for Updates" in toolbar
2. Select an "Available" update
3. Click "Download Update" button
4. After download, click "Install Update"

## Keyboard Shortcuts

- `⌘ + Return` - Confirm/Save in sheets
- `Escape` - Cancel/Close sheets
- `Tab` / `Shift+Tab` - Navigate between fields
- Arrow keys - Navigate lists
- `Space` - Toggle selection in lists

## Status Indicators

### Color Coding
- 🟢 **Green**: Healthy, Online, OK, Installed
- 🟡 **Yellow**: Warning, Medium priority
- 🟠 **Orange**: Attention needed, Pending, Acknowledged
- 🔴 **Red**: Critical, Offline, Failed, High priority
- 🔵 **Blue**: Active, In progress, Information

### Icons
- ✓ **Checkmark**: Completed, Healthy, Enabled
- ⚠️ **Triangle**: Warning, Requires attention
- ✕ **X mark**: Error, Disabled, Failed
- ⟳ **Circular arrow**: Restart required, Refresh
- ⏸ **Pause**: Inactive, Stopped
- ⏵ **Play**: Active, Running

## Server Monitoring

### Start/Stop Monitoring
1. Use sidebar "Start" button to begin monitoring
2. Green "Live" indicator shows active monitoring
3. Click "Stop" to pause monitoring
4. Status badges update in real-time

### Add Server
1. Click "Add" button in sidebar
2. Fill in server details (name, host, type)
3. Configure monitoring settings
4. Click "Add Server" to save

## Tips & Tricks

### Quick Navigation
- Click any primary navigation item to switch sections
- Use Quick Access for frequently used tools
- Sidebar items highlight on hover

### Filtering and Search
- Use search bars to find specific items quickly
- Combine search with filters for precise results
- Clear search to see all items

### Detail Inspection
- Click any list item to see full details in right panel
- Overview shows when nothing is selected
- Use "Back" to return to overview

### Action Confirmation
- Destructive actions (Delete, Remove) show confirmation dialogs
- Orange info boxes warn about important consequences
- Actions take effect immediately (no apply button needed)

### Data Updates
- All changes update the UI instantly
- Demo data persists during app session
- Quick Access customization saves to disk

## Troubleshooting

**Q: Why don't I see my changes?**
A: Changes to demo data persist during the app session but reset when you relaunch. Quick Access customization is permanently saved.

**Q: Can I add more than 10 Quick Access items?**
A: No, the maximum is 10 items to maintain sidebar usability. Minimum is 3 items.

**Q: Where is the real data coming from?**
A: This implementation uses realistic demo data. In production, you would connect to actual Windows Server APIs (WinRM, PowerShell remoting, etc.).

**Q: How do I reset Quick Access to defaults?**
A: Open Quick Access customization and click "Reset to Default" button.

**Q: Charts show "DEMO DATA" label?**
A: This indicates placeholder data is being displayed. Real implementation would connect to monitoring services.

## Next Steps

1. **Explore each section** to familiarize yourself with the interface
2. **Try customizing Quick Access** to match your workflow
3. **Practice filtering and searching** to find items quickly
4. **Review security alerts** to understand the remediation workflow
5. **Check system updates** to see the installation process

## Getting Help

- Hover over icons and buttons for tooltips
- Check "IMPLEMENTATION_SUMMARY.md" for technical details
- Review section overviews for high-level information
- Look for info (ⓘ) icons for contextual help

---

**Version**: 1.0  
**Last Updated**: January 14, 2026  
**Compatibility**: macOS 14.0+
