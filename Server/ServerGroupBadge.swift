//
//  ServerGroupBadge.swift
//  Server
//
//  Created by Claude on 1/26/26.
//

import SwiftUI

struct ServerGroupBadge: View {
    let group: ServerGroup?
    var showLabel: Bool = true
    var size: BadgeSize = .regular

    enum BadgeSize {
        case small
        case regular
        case large

        var dotSize: CGFloat {
            switch self {
            case .small: return 6
            case .regular: return 8
            case .large: return 10
            }
        }

        var fontSize: CGFloat {
            switch self {
            case .small: return 9
            case .regular: return 10
            case .large: return 12
            }
        }

        var horizontalPadding: CGFloat {
            switch self {
            case .small: return 4
            case .regular: return 6
            case .large: return 8
            }
        }

        var verticalPadding: CGFloat {
            switch self {
            case .small: return 1
            case .regular: return 2
            case .large: return 4
            }
        }
    }

    var body: some View {
        if let group = group {
            HStack(spacing: 4) {
                Circle()
                    .fill(group.color)
                    .frame(width: size.dotSize, height: size.dotSize)

                if showLabel {
                    Text(group.name)
                        .font(.system(size: size.fontSize, weight: .medium))
                        .foregroundStyle(group.color)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, size.horizontalPadding)
            .padding(.vertical, size.verticalPadding)
            .background(group.color.opacity(0.15), in: Capsule())
        }
    }
}

// MARK: - Compact Badge (dot only)

struct ServerGroupDot: View {
    let group: ServerGroup?
    var size: CGFloat = 8

    var body: some View {
        if let group = group {
            Circle()
                .fill(group.color)
                .frame(width: size, height: size)
                .help(group.name)
        }
    }
}

// MARK: - Preview

#Preview("Badge Sizes") {
    let previewGroup = ServerGroup(name: "Production", colorHex: "#34C759", icon: "server.rack")

    VStack(spacing: 16) {
        ServerGroupBadge(group: previewGroup, size: .small)
        ServerGroupBadge(group: previewGroup, size: .regular)
        ServerGroupBadge(group: previewGroup, size: .large)
        ServerGroupBadge(group: previewGroup, showLabel: false)
        ServerGroupDot(group: previewGroup)
    }
    .padding()
}

#Preview("Color Variants") {
    VStack(spacing: 8) {
        ForEach(GroupColor.allCases) { color in
            ServerGroupBadge(
                group: ServerGroup(name: color.name, colorHex: color.rawValue),
                size: .regular
            )
        }
    }
    .padding()
}
