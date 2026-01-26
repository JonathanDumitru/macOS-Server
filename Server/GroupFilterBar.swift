//
//  GroupFilterBar.swift
//  Server
//
//  Created by Claude on 1/26/26.
//

import SwiftUI
import SwiftData

struct GroupFilterBar: View {
    let groups: [ServerGroup]
    @Binding var selectedGroup: ServerGroup?
    var showAllOption: Bool = true

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if showAllOption {
                    FilterButton(
                        title: "All",
                        isSelected: selectedGroup == nil,
                        color: .secondary
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedGroup = nil
                        }
                    }
                }

                ForEach(groups.sorted(by: { $0.sortOrder < $1.sortOrder })) { group in
                    FilterButton(
                        title: group.name,
                        isSelected: selectedGroup?.id == group.id,
                        color: group.color,
                        icon: group.icon
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if selectedGroup?.id == group.id {
                                selectedGroup = nil
                            } else {
                                selectedGroup = group
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Filter Button

private struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let color: Color
    var icon: String? = nil
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 10, weight: .medium))
                }
                Text(title)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
            }
            .foregroundStyle(isSelected ? .white : color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(isSelected ? color : color.opacity(isHovered ? 0.15 : 0.1))
            )
            .overlay(
                Capsule()
                    .stroke(color.opacity(isSelected ? 0 : 0.3), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Compact Filter (Dropdown Style)

struct GroupFilterDropdown: View {
    let groups: [ServerGroup]
    @Binding var selectedGroup: ServerGroup?

    var body: some View {
        Menu {
            Button {
                selectedGroup = nil
            } label: {
                HStack {
                    Text("All Groups")
                    if selectedGroup == nil {
                        Image(systemName: "checkmark")
                    }
                }
            }

            if !groups.isEmpty {
                Divider()

                ForEach(groups.sorted(by: { $0.sortOrder < $1.sortOrder })) { group in
                    Button {
                        selectedGroup = group
                    } label: {
                        HStack {
                            Image(systemName: group.icon)
                                .foregroundStyle(group.color)
                            Text(group.name)
                            if selectedGroup?.id == group.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                if let group = selectedGroup {
                    Circle()
                        .fill(group.color)
                        .frame(width: 8, height: 8)
                    Text(group.name)
                        .font(.system(size: 12, weight: .medium))
                } else {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                    Text("All Groups")
                        .font(.system(size: 12, weight: .medium))
                }
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .semibold))
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
            )
        }
        .menuStyle(.borderlessButton)
    }
}

// MARK: - Preview

#Preview("Filter Bar") {
    struct PreviewWrapper: View {
        @State private var selectedGroup: ServerGroup?

        let groups = [
            ServerGroup(name: "Production", colorHex: "#34C759", icon: "server.rack", sortOrder: 0),
            ServerGroup(name: "Staging", colorHex: "#FF9500", icon: "flask.fill", sortOrder: 1),
            ServerGroup(name: "Development", colorHex: "#007AFF", icon: "wrench.and.screwdriver.fill", sortOrder: 2),
        ]

        var body: some View {
            VStack(spacing: 20) {
                GroupFilterBar(groups: groups, selectedGroup: $selectedGroup)

                Text("Selected: \(selectedGroup?.name ?? "All")")
                    .foregroundStyle(.secondary)

                Divider()

                GroupFilterDropdown(groups: groups, selectedGroup: $selectedGroup)
            }
            .padding()
            .frame(width: 400)
        }
    }

    return PreviewWrapper()
}
