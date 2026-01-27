//
//  UptimePercentageView.swift
//  Server
//
//  Created by Claude on 1/27/26.
//

import SwiftUI

struct UptimePercentageView: View {
    let percentage: Double
    let period: UptimePeriod
    var size: GaugeSize = .regular
    var showStatus: Bool = true

    enum GaugeSize {
        case small
        case regular
        case large

        var diameter: CGFloat {
            switch self {
            case .small: return 80
            case .regular: return 120
            case .large: return 160
            }
        }

        var lineWidth: CGFloat {
            switch self {
            case .small: return 8
            case .regular: return 12
            case .large: return 16
            }
        }

        var percentageFontSize: CGFloat {
            switch self {
            case .small: return 16
            case .regular: return 24
            case .large: return 32
            }
        }

        var labelFontSize: CGFloat {
            switch self {
            case .small: return 9
            case .regular: return 11
            case .large: return 13
            }
        }
    }

    var uptimeColor: Color {
        UptimeStatus.from(percentage: percentage).color
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: size.lineWidth)

                // Progress ring
                Circle()
                    .trim(from: 0, to: min(percentage / 100, 1.0))
                    .stroke(
                        uptimeColor,
                        style: StrokeStyle(lineWidth: size.lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: percentage)

                // Center content
                VStack(spacing: 2) {
                    Text(String(format: "%.2f%%", percentage))
                        .font(.system(size: size.percentageFontSize, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text("Uptime")
                        .font(.system(size: size.labelFontSize))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: size.diameter, height: size.diameter)

            // Period label
            Text(period.rawValue)
                .font(.system(size: size.labelFontSize, weight: .medium))
                .foregroundStyle(.tertiary)

            // Status badge
            if showStatus {
                UptimeStatusBadge(status: UptimeStatus.from(percentage: percentage))
            }
        }
    }
}

// MARK: - Uptime Status Badge

struct UptimeStatusBadge: View {
    let status: UptimeStatus

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
                .font(.system(size: 10))
            Text(status.rawValue)
                .font(.system(size: 10, weight: .medium))
        }
        .foregroundStyle(status.color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(status.color.opacity(0.15), in: Capsule())
    }
}

// MARK: - Compact Uptime Badge

struct UptimeBadge: View {
    let percentage: Double
    var showIcon: Bool = true

    var status: UptimeStatus {
        UptimeStatus.from(percentage: percentage)
    }

    var body: some View {
        HStack(spacing: 3) {
            if showIcon {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 9))
            }
            Text(String(format: "%.1f%%", percentage))
                .font(.system(size: 10, weight: .medium, design: .rounded))
        }
        .foregroundStyle(status.color)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(status.color.opacity(0.12), in: Capsule())
    }
}

// MARK: - Uptime Period Picker

struct UptimePeriodPicker: View {
    @Binding var selectedPeriod: UptimePeriod

    var body: some View {
        Picker("Period", selection: $selectedPeriod) {
            ForEach(UptimePeriod.allCases) { period in
                Text(period.shortName).tag(period)
            }
        }
        .pickerStyle(.segmented)
        .frame(width: 200)
    }
}

// MARK: - SLA Status View

struct SLAStatusView: View {
    let currentUptime: Double
    let target: SLATarget
    let period: UptimePeriod

    var isMet: Bool {
        currentUptime >= target.percentage
    }

    var deficit: Double {
        max(0, target.percentage - currentUptime)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Image(systemName: isMet ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 20))
                .foregroundStyle(isMet ? .green : .orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("SLA Target: \(target.name)")
                    .font(.system(size: 12, weight: .medium))

                if isMet {
                    Text("Target met")
                        .font(.system(size: 11))
                        .foregroundStyle(.green)
                } else {
                    Text("Below target by \(String(format: "%.2f%%", deficit))")
                        .font(.system(size: 11))
                        .foregroundStyle(.orange)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("Allowed downtime")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                Text(target.formattedAllowedDowntime(for: period))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }
}

// MARK: - Preview

#Preview("Uptime Gauge") {
    HStack(spacing: 24) {
        UptimePercentageView(percentage: 99.95, period: .month30d, size: .small)
        UptimePercentageView(percentage: 99.95, period: .month30d, size: .regular)
        UptimePercentageView(percentage: 99.95, period: .month30d, size: .large)
    }
    .padding()
}

#Preview("Uptime Statuses") {
    VStack(spacing: 12) {
        UptimePercentageView(percentage: 100, period: .day24h)
        UptimePercentageView(percentage: 99.5, period: .week7d)
        UptimePercentageView(percentage: 97.0, period: .month30d)
        UptimePercentageView(percentage: 92.0, period: .quarter90d)
        UptimePercentageView(percentage: 85.0, period: .day24h)
    }
    .padding()
}

#Preview("Uptime Badge") {
    VStack(spacing: 8) {
        UptimeBadge(percentage: 99.99)
        UptimeBadge(percentage: 99.5)
        UptimeBadge(percentage: 95.0)
        UptimeBadge(percentage: 85.0)
    }
    .padding()
}
