//
//  GroupManagementView.swift
//  Server
//
//  Created by Claude on 1/26/26.
//

import SwiftUI
import SwiftData

struct GroupManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ServerGroup.sortOrder) private var groups: [ServerGroup]

    @State private var showingAddGroup = false
    @State private var editingGroup: ServerGroup?
    @State private var groupToDelete: ServerGroup?
    @State private var showingDeleteConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Server Groups")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Organize your servers into groups for easier management")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    showingAddGroup = true
                } label: {
                    Label("Add Group", systemImage: "plus")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding()

            Divider()

            // Group List
            if groups.isEmpty {
                ContentUnavailableView(
                    "No Groups",
                    systemImage: "folder.badge.plus",
                    description: Text("Create groups to organize your servers")
                )
                .frame(maxHeight: .infinity)
            } else {
                List {
                    ForEach(groups) { group in
                        GroupRowView(
                            group: group,
                            onEdit: { editingGroup = group },
                            onDelete: {
                                groupToDelete = group
                                showingDeleteConfirmation = true
                            }
                        )
                    }
                    .onMove(perform: moveGroups)
                }
                .listStyle(.inset)
            }
        }
        .sheet(isPresented: $showingAddGroup) {
            AddGroupView()
        }
        .sheet(item: $editingGroup) { group in
            AddGroupView(editingGroup: group)
        }
        .alert("Delete Group?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                groupToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let group = groupToDelete {
                    deleteGroup(group)
                }
            }
        } message: {
            if let group = groupToDelete {
                Text("Are you sure you want to delete \"\(group.name)\"? Servers in this group will become ungrouped.")
            }
        }
    }

    private func moveGroups(from source: IndexSet, to destination: Int) {
        var sortedGroups = groups.sorted(by: { $0.sortOrder < $1.sortOrder })
        sortedGroups.move(fromOffsets: source, toOffset: destination)

        for (index, group) in sortedGroups.enumerated() {
            group.sortOrder = index
        }
    }

    private func deleteGroup(_ group: ServerGroup) {
        // Remove group reference from all servers
        for server in group.servers {
            server.group = nil
        }
        modelContext.delete(group)
        groupToDelete = nil
    }
}

// MARK: - Group Row View

private struct GroupRowView: View {
    let group: ServerGroup
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(group.color.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: group.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(group.color)
            }

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(group.name)
                    .font(.system(size: 13, weight: .medium))

                Text("\(group.servers.count) server\(group.servers.count == 1 ? "" : "s")")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Actions
            if isHovered {
                HStack(spacing: 8) {
                    Button {
                        onEdit()
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Edit Group")

                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                    .help("Delete Group")
                }
                .transition(.opacity)
            }

            // Drag handle
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Settings Tab Integration

struct GroupSettingsView: View {
    var body: some View {
        GroupManagementView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview("Group Management") {
    GroupManagementView()
        .modelContainer(for: [ServerGroup.self, Server.self], inMemory: true)
        .frame(width: 500, height: 400)
}

#Preview("Empty State") {
    GroupManagementView()
        .modelContainer(for: ServerGroup.self, inMemory: true)
        .frame(width: 500, height: 400)
}
