//
//  DEMO_DATA_REFERENCE.md
//  Complete listing of demo data in the application
//

# Demo Data Reference

This document lists all the demo data used throughout the Server Management Dashboard application.

## Server Roles (8 total)

| Role Name | Status | Impact | Reboot Required | Dependencies |
|-----------|--------|--------|-----------------|--------------|
| Active Directory Domain Services | Installed | High | ✓ | DNS Server |
| DNS Server | Installed | High | ✗ | None |
| DHCP Server | Installed | Medium | ✗ | None |
| File and Storage Services | Installed | High | ✗ | None |
| Web Server (IIS) | Not Installed | Medium | ✓ | None |
| Remote Desktop Services | Not Installed | Medium | ✓ | None |
| Hyper-V | Installed | High | ✓ | None |
| Windows Server Update Services | Not Installed | Low | ✗ | IIS |

### Services Tracked
- NTDS, Kerberos (AD DS)
- DNS
- DHCP
- LanmanServer (File Services)
- W3SVC, WAS (IIS)
- TermService (RDS)
- vmms, vmcompute (Hyper-V)
- WsusService (WSUS)

## Server Features (8 total)

| Feature Name | Installed | Impact |
|-------------|-----------|--------|
| .NET Framework 4.8 | ✓ | Low |
| BitLocker Drive Encryption | ✓ | Medium |
| Failover Clustering | ✗ | High |
| Network Load Balancing | ✗ | Medium |
| Remote Server Administration Tools | ✓ | Low |
| Telnet Client | ✗ | Low |
| Windows PowerShell 5.1 | ✓ | Low |
| Windows Subsystem for Linux | ✗ | Low |

## Storage Volumes (4 total)

| Name | Mount Point | Filesystem | Total Size | Used Size | Used % | Health |
|------|-------------|-----------|------------|-----------|--------|--------|
| System | / | NTFS | 500 GB | 245 GB | 49% | Healthy |
| Data | /Volumes/Data | NTFS | 2 TB | 1.65 TB | 82.5% | Warning |
| Backup | /Volumes/Backup | NTFS | 4 TB | 2.8 TB | 70% | Healthy |
| VMs | /Volumes/VMs | ReFS | 8 TB | 5.2 TB | 65% | Healthy |

**Total Capacity**: 14.5 TB  
**Total Used**: 9.895 TB (68.2%)  
**Total Free**: 4.605 TB (31.8%)

## Physical Disks (4 total)

| Model | Size | Interface | Health | Temperature | Serial Number |
|-------|------|-----------|--------|-------------|---------------|
| Samsung 870 EVO | 500 GB | SATA III | OK | 35°C | S5H2NS0N123456 |
| WD Red Pro | 4 TB | SATA III | OK | 38°C | WD-WCC7K1234567 |
| Seagate IronWolf | 8 TB | SATA III | OK | 40°C | ZA123456 |
| Intel Optane P5800X | 1.6 TB | NVMe | OK | 42°C | PHLN123456789ABC |

## Network Adapters (4 total)

| Name | Status | Link Speed | IPv4 | IPv6 | DHCP | DNS Servers | TX Rate | RX Rate |
|------|--------|-----------|------|------|------|-------------|---------|---------|
| Ethernet 1 | Active | 10 Gbps | 192.168.1.100 | fe80::1 | ✗ | 8.8.8.8, 8.8.4.4 | 245.5 Mbps | 1205.8 Mbps |
| Ethernet 2 | Active | 10 Gbps | 10.0.0.50 | - | ✗ | 1.1.1.1, 1.0.0.1 | 89.2 Mbps | 432.1 Mbps |
| Management | Active | 1 Gbps | 192.168.100.10 | - | ✓ | 192.168.100.1 | 2.3 Mbps | 5.1 Mbps |
| Ethernet 3 | Disconnected | N/A | N/A | - | ✓ | - | 0 Mbps | 0 Mbps |

**Total Throughput**: 1,974.9 Mbps (1.97 Gbps)

## Security Alerts (6 total)

### Critical (2)
1. **Multiple Failed Login Attempts** (Open)
   - Category: Authentication
   - Resource: DC01
   - Description: User account 'administrator' has experienced 15 failed login attempts from IP 203.0.113.45
   - Remediation: Verify source IP, enable account lockout policies

2. **Potential Malware Detected** (Open)
   - Category: Malware
   - Resource: APP01
   - Description: Windows Defender detected suspicious behavior from svchost.exe (PID 4892)
   - Remediation: Isolate server, run full scan, analyze process

### High (1)
3. **Firewall Rule Disabled** (Open)
   - Category: Firewall
   - Resource: Firewall - WAN Interface
   - Description: Critical rule blocking inbound RDP from external networks disabled
   - Remediation: Re-enable rule immediately, investigate who made change

### Medium (1)
4. **Security Updates Pending** (Acknowledged)
   - Category: Update
   - Resource: All Servers
   - Description: 5 critical security updates available for more than 7 days
   - Remediation: Schedule maintenance window to install updates

### Low (1)
5. **Password Policy Non-Compliance** (Acknowledged)
   - Category: Policy
   - Resource: Active Directory
   - Description: 3 user accounts have passwords not meeting complexity requirements
   - Remediation: Force password reset, enforce strong password policy

### Info (1)
6. **TLS 1.0 Still Enabled** (Resolved)
   - Category: Configuration
   - Resource: WEB01, WEB02
   - Description: Legacy TLS 1.0 protocol still enabled on web servers
   - Remediation: Disable TLS 1.0, enable only TLS 1.2 and 1.3

**Summary**:
- Open: 3 alerts
- Acknowledged: 2 alerts
- Resolved: 1 alert

## System Updates (5 total)

| KB Number | Title | Size | Reboot | Status | Release Date |
|-----------|-------|------|--------|--------|--------------|
| KB5034441 | 2026-01 Cumulative Update for Windows Server 2025 | 485.2 MB | ✓ | Available | 1 day ago |
| KB5034129 | 2026-01 Security Update for .NET Framework | 125.6 MB | ✓ | Available | 2 days ago |
| KB5033918 | Update for Windows Defender Definitions | 42.8 MB | ✗ | Downloaded | 12 hours ago |
| KB5032392 | 2025-12 Cumulative Update for Windows Server 2025 | 502.1 MB | ✓ | Installed | 30 days ago |
| KB5031984 | Servicing Stack Update | 15.3 MB | ✗ | Installed | 35 days ago |

**Summary**:
- Available: 2 updates (610.8 MB)
- Downloaded: 1 update (42.8 MB)
- Installed: 2 updates (517.4 MB)

## Quick Access Items (Default Configuration)

| Order | Item | Icon | Pinned by Default |
|-------|------|------|-------------------|
| 1 | Event Viewer | list.bullet.rectangle | ✓ |
| 2 | Services | gearshape.2 | ✓ |
| 3 | Performance Monitor | chart.xyaxis.line | ✓ |
| 4 | Disk Management | externaldrive | ✓ |
| 5 | Task Manager | list.bullet.clipboard | ✓ |
| 6 | PowerShell | terminal | ✓ |

All 6 default items are pinned by default. Users can unpin up to 3 items (minimum 3 must remain).

## Dashboard Metrics (Calculated from Demo Data)

### Summary Cards
- **Uptime**: Average calculated from server metrics
- **Active Users**: Sum of active connections across servers
- **Running Services**: Count of online servers / total servers
- **Security Alerts**: Count of warning/offline servers
- **Failed Logins**: Count of error-level authentication logs
- **Disk Usage**: Average disk usage percentage
- **Network Traffic**: Sum of all adapter TX/RX rates
- **Pending Updates**: Warning servers × 2 (simulated)

### Chart Data
- **CPU Usage**: Last 20 metrics per server, random 15-45% for demo
- **Memory Usage**: Last 20 metrics per server, random 40-70% for demo
- **Time Range**: Last 200 minutes (20 points × 10 min intervals)

## Color Scheme

### Status Colors
- 🟢 Green (#00C853): Healthy, Online, Success, Installed
- 🟡 Yellow (#FFD600): Medium priority, Caution
- 🟠 Orange (#FF9800): Warning, Attention needed, Pending
- 🔴 Red (#F44336): Critical, Error, Offline, Failed
- 🔵 Blue (#2196F3): Active, Information, Primary action
- 🟣 Purple (#9C27B0): Special status, Alternate
- 🔷 Cyan (#00BCD4): Network, Tertiary
- 🟤 Mint (#00C9A7): Network traffic, Growth

### Severity Colors (Security)
- Critical: Red (#F44336)
- High: Orange (#FF9800)
- Medium: Yellow (#FFD600)
- Low: Blue (#2196F3)
- Info: Green (#00C853)

## Mock Calculations

### Performance Metrics
- **Average IOPS**: Random between 15,000-25,000
- **Latency**: Random between 1-5 ms
- **Network Traffic (demo charts)**: 
  - TX: Random 100-800 Mbps
  - RX: Random 500-2000 Mbps

### Time-based Data
- **Last Check**: "1 hour ago"
- **Last Scan**: "2 hours ago"
- **Last Change**: "2 days ago"

## Notes for Testing

1. **Role toggling**: Changes status to "Pending" or "Pending Install"
2. **Feature toggling**: Immediately switches installed state
3. **Volume creation**: Adds new volume to list and charts
4. **Volume deletion**: Removes volume from all displays
5. **DNS updates**: Updates adapter's DNS server list
6. **DHCP toggle**: Switches adapter DHCP state
7. **Alert actions**: Changes alert status (acknowledge/resolve)
8. **Update actions**: Progresses update through states (available → downloaded → installed)
9. **Quick Access**: Persists to UserDefaults, survives app restart

## Realistic Scenarios Represented

- **Storage**: One volume (Data) showing warning at 82% usage
- **Network**: One adapter disconnected, three active with varied speeds
- **Security**: Mix of open, acknowledged, and resolved alerts
- **Updates**: Pipeline showing different stages of update process
- **Roles**: Mix of installed and available roles with dependencies
- **Health**: Generally healthy system with a few attention items

This creates a realistic dashboard showing:
- Mostly operational system (green indicators)
- A few items requiring attention (orange/yellow)
- Some critical issues to address (red)
- Normal day-to-day server management tasks

---

**Purpose**: This data enables comprehensive UI testing without requiring actual server connections.  
**Maintenance**: Update this reference when adding or modifying demo data.
