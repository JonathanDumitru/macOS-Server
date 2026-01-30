# Product Roadmap

Future feature ideas for Server Monitor Dashboard, organized by implementation effort.

---

## Implemented Quick Wins

### 1. Server Search/Filter Enhancement ✅
**Status:** Implemented

- Search bar in dashboard sidebar
- Filter by server name, host, tags, or group
- Real-time filtering as user types
- Clear search button (X icon)

---

### 2. Bulk Actions ✅
**Status:** Implemented

- Select mode toggle button
- Select All / Deselect All
- Bulk delete with confirmation
- Bulk move to group
- Bulk export selected servers

---

### 3. Dark/Light Theme Toggle ✅
**Status:** Implemented

- Settings → General → Appearance
- System / Light / Dark options
- Persisted with @AppStorage
- Applied via NSApp.appearance

---

### 4. Export Server List ✅
**Status:** Implemented

- Export to JSON format (pretty-printed)
- Export to CSV format (spreadsheet-compatible)
- Export all servers or selected servers
- Save dialog with file chooser

**New file:** `ExportService.swift`

---

### 5. Keyboard Shortcuts ✅
**Status:** Implemented

| Shortcut | Action |
|----------|--------|
| ⌘N | Add new server |
| ⌘R | Refresh all servers |
| ⌘⇧M | Toggle monitoring |
| ⌘⇧E | Export servers |
| ⌘F | Focus search |
| ⌘1 | Go to Dashboard |
| ⌘2 | Go to Roles & Features |
| ⌘3 | Go to Storage |
| ⌘4 | Go to Networking |
| ⌘5 | Go to Security |
| ⌘6 | Go to Updates |

---

### 6. Quick Actions Context Menu ✅
**Status:** Implemented

Right-click context menu for servers:
- Check Now (refresh single server)
- Copy Host
- Copy Host:Port
- Open in Browser (HTTP/HTTPS servers)
- Open SSH in Terminal (SSH servers)
- Export Server
- Delete (with destructive style)

---

## Remaining Quick Wins

**Files to modify:**
- `ServerListItemView.swift`
- `DashboardView.swift`

---

## Implemented Medium Effort Features

### 7. Historical Charts ✅
**Status:** Implemented

- Time range selection: 1H, 6H, 24H, 7D, 30D
- Metric types: Response Time, CPU, Memory, Disk, Uptime
- Stats summary with avg/min/max values
- Trend analysis and insights
- Integrated as History tab in ServerDetailView

**New files:**
- `HistoricalChartsView.swift`

**Files modified:**
- `ServerDetailView.swift`

---

### 8. Server Templates ✅
**Status:** Implemented

- 20 built-in templates for common server types
- Categories: Web Servers, Databases, Cache/Queue, Monitoring, etc.
- Custom template creation support
- Template selector integrated into AddServerView
- Automatic port and type configuration

**New files:**
- `ServerTemplate.swift`
- `ServerTemplatesView.swift`

**Files modified:**
- `AddServerView.swift`

---

### 9. Maintenance Windows ✅
**Status:** Implemented

- Schedule maintenance periods
- Recurrence types: Daily, Weekdays, Weekends, Weekly, Monthly
- Global or per-server scope
- Full CRUD UI with status tracking
- Active/Scheduled/Recurring/Completed sections

**New files:**
- `MaintenanceWindow.swift`
- `MaintenanceWindowsView.swift`

---

### 10. Import from File ✅
**Status:** Implemented

- Import from JSON, CSV, or SSH config files
- Duplicate detection with skip option
- Preview imported servers before confirming
- Menu bar shortcut (⌘⇧I)
- SSH config parser for ~/.ssh/config

**New files:**
- `ImportView.swift`

**Files modified:**
- `DashboardView.swift`
- `ServerApp.swift`

---

## Remaining Medium Effort Features

### 11. Custom Status Pages
**Priority:** Low
**Effort:** 6-8 hours

- Generate HTML status page
- Shareable public URL
- Customizable branding
- Real-time updates via WebSocket
- Embed code for websites

**New files:**
- `StatusPageService.swift`
- `StatusPageView.swift`

---

### 12. Response Time Alerts
**Priority:** High
**Effort:** 2-3 hours

- Alert when response time exceeds threshold
- Trend detection (getting slower)
- Historical comparison
- Already partially implemented in AlertThreshold

**Files to modify:**
- `AlertThreshold.swift`
- `ServerMonitoringService.swift`

---

## Higher Effort Features

### 13. Multi-User / iCloud Sync
**Priority:** Low
**Effort:** 8-12 hours

- Sync servers across devices via iCloud
- CloudKit integration
- Conflict resolution
- Shared team configurations

**Requires:**
- CloudKit container setup
- Schema migration
- Sync conflict handling

---

### 14. Webhooks & Integrations
**Priority:** High
**Effort:** 6-8 hours

Send alerts to external services:
- Slack
- Discord
- Microsoft Teams
- PagerDuty
- Generic webhook URL
- Custom headers/payload

**New files:**
- `WebhookService.swift`
- `IntegrationsView.swift`
- `WebhookConfiguration.swift`

---

### 15. Port Scanning
**Priority:** Medium
**Effort:** 4-5 hours

- Check multiple ports on single host
- Common port presets
- Custom port lists
- Port status history

**New files:**
- `PortScanService.swift`
- `PortScanView.swift`

---

### 16. Service Dependencies
**Priority:** Medium
**Effort:** 6-8 hours

Define server relationships:
- Server A depends on Server B
- Visual dependency graph
- Cascade status (if DB down, show Web as affected)
- Dependency validation

**New files:**
- `ServiceDependency.swift`
- `DependencyGraphView.swift`

---

### 17. Mobile Companion App (iOS)
**Priority:** Low
**Effort:** 20+ hours

- iOS app with push notifications
- Share servers via iCloud
- Quick status overview
- Critical alerts only mode
- Apple Watch complication

**Requires:**
- New iOS target
- Push notification server
- Shared Swift package for models

---

### 18. Advanced Reporting
**Priority:** Medium
**Effort:** 8-10 hours

- Weekly/monthly reports
- PDF generation
- Email delivery
- SLA compliance tracking
- Uptime summaries

**New files:**
- `ReportGenerator.swift`
- `ReportView.swift`
- `EmailService.swift`

---

### 19. Performance Baselines
**Priority:** Medium
**Effort:** 5-6 hours

- Establish normal performance baseline
- Detect anomalies automatically
- Alert on deviation from baseline
- Machine learning for prediction

**New files:**
- `BaselineService.swift`
- `AnomalyDetector.swift`

---

### 20. Plugin System
**Priority:** Low
**Effort:** 15+ hours

- Custom check types via plugins
- Plugin marketplace
- JavaScript or Swift plugins
- Sandboxed execution

---

## Implementation Priority Matrix

| Feature | Impact | Effort | Priority Score |
|---------|--------|--------|----------------|
| Historical Charts | High | Medium | 1 |
| Webhooks & Integrations | High | Medium | 2 |
| Server Search | Medium | Low | 3 |
| Bulk Actions | Medium | Low | 4 |
| Import from File | Medium | Medium | 5 |
| Server Templates | Medium | Medium | 6 |
| Maintenance Windows | Medium | Medium | 7 |
| Port Scanning | Medium | Medium | 8 |
| Keyboard Shortcuts | Low | Low | 9 |
| Export Server List | Medium | Low | 10 |

---

## Version Planning

### v1.1 (Completed)
- [x] Server Search/Filter
- [x] Bulk Actions
- [x] Keyboard Shortcuts
- [x] Export Server List
- [x] Quick Actions Context Menu
- [x] Dark/Light Theme Toggle

### v1.2 (Completed)
- [x] Historical Charts
- [x] Import from File
- [x] Server Templates
- [x] Maintenance Windows

### v1.3 (Next Release)
- [ ] Webhooks & Integrations
- [ ] Custom Status Pages
- [ ] Advanced Reporting

### v2.0
- [ ] Multi-User / iCloud Sync
- [ ] iOS Companion App
- [ ] Service Dependencies

---

## Contributing

Want to implement a feature? Here's how:

1. Pick a feature from this roadmap
2. Create a branch: `feature/feature-name`
3. Implement following existing patterns
4. Add documentation
5. Submit pull request

---

## Feature Requests

Have an idea not on this list? Open an issue with:
- Feature description
- Use case / problem it solves
- Suggested implementation approach
- Priority (nice-to-have vs critical)
