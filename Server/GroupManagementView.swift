//
//  GroupManagementView.swift
//  Server
//
//  Created by Claude on 1/27/26.
//

import SwiftUI
import SwiftData

struct GroupManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ServerGroup.sortOrder) private var groups: [ServerGroup]
    @Query private var tags: [ServerTag]

    @State private var showingCreateGroup = false
    @State private var showingCreateTag = false
    @State private var editingGroup: ServerGroup?
    @State private var editingTag: ServerTag?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Groups Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Groups", systemImage: "folder.fill")
                            .font(.headline)

                        Spacer()

                        Button {
                            showingCreateGroup = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                        }
                        .buttonStyle(.plain)
                    }

                    if groups.isEmpty {
                        ContentUnavailableView(
                            "No Groups",
                            systemImage: "folder",
                            description: Text("Create groups to organize your servers")
                        )
                        .frame(height: 120)
                    } else {
                        List {
                            ForEach(groups) { group in
                                GroupRowView(group: group) {
                                    editingGroup = group
                                } onDelete: {
                                    deleteGroup(group)
                                }
                            }
                            .onMove(perform: moveGroups)
                        }
                        .listStyle(.plain)
                        .frame(height: min(CGFloat(groups.count) * 50 + 20, 200))
                    }
                }
                .padding()

                Divider()

                // Tags Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Tags", systemImage: "tag.fill")
                            .font(.headline)

                        Spacer()

                        Button {
                            showingCreateTag = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                        }
                        .buttonStyle(.plain)
                    }

                    if tags.isEmpty {
                        ContentUnavailableView(
                            "No Tags",
                            systemImage: "tag",
                            description: Text("Create tags for flexible server labeling")
                        )
                        .frame(height: 120)
                    } else {
                        FlowLayout(spacing: 8) {
                            ForEach(tags) { tag in
                                TagRowView(tag: tag) {
                                    editingTag = tag
                                } onDelete: {
                                    deleteTag(tag)
                                }
                            }
                        }
                    }
                }
                .padding()

                Spacer()

                // Footer with defaults button
                Divider()

                HStack {
                    Button("Reset to Defaults") {
                        resetToDefaults()
                    }
                    .foregroundStyle(.red)

                    Spacer()

                    Button("Done") {
                        dismiss()
                    }
                    .keyboardShortcut(.defaultAction)
                }
                .padding()
            }
            .navigationTitle("Manage Groups & Tags")
            .frame(width: 500, height: 600)
            .sheet(isPresented: $showingCreateGroup) {
                CreateGroupSheet { group in
                    modelContext.insert(group)
                }
            }
            .sheet(isPresented: $showingCreateTag) {
                CreateTagSheet { tag in
                    modelContext.insert(tag)
                }
            }
            .sheet(item: $editingGroup) { group in
                EditGroupSheet(group: group)
            }
            .sheet(item: $editingTag) { tag in
                EditTagSheet(tag: tag)
            }
        }
    }

    private func deleteGroup(_ group: ServerGroup) {
        // Remove group assignment from all servers
        for server in group.servers {
            server.group = nil
        }
        modelContext.delete(group)
    }

    private func deleteTag(_ tag: ServerTag) {
        modelContext.delete(tag)
    }

    private func moveGroups(from source: IndexSet, to destination: Int) {
        var mutableGroups = groups
        mutableGroups.move(fromOffsets: source, toOffset: destination)

        for (index, group) in mutableGroups.enumerated() {
            group.sortOrder = index
        }
    }

    private func resetToDefaults() {
        // Delete all existing groups and tags
        for group in groups {
            modelContext.delete(group)
        }
        for tag in tags {
            modelContext.delete(tag)
        }

        // Create default groups
        for group in ServerGroup.createDefaultGroups() {
            modelContext.insert(group)
        }

        // Create default tags
        for tag in ServerTag.createDefaultTags() {
            modelContext.insert(tag)
        }
    }
}

// MARK: - Group Row View

struct GroupRowView: View {
    let group: ServerGroup
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: group.iconName)
                .font(.system(size: 16))
                .foregroundStyle(group.color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(group.name)
                    .font(.system(size: 13, weight: .medium))

                Text("\(group.serverCount) servers")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Status indicator
            HStack(spacing: 4) {
                if group.onlineCount > 0 {
                    Circle().fill(.green).frame(width: 8, height: 8)
                    Text("\(group.onlineCount)")
                        .font(.system(size: 10, design: .rounded))
                }
                if group.offlineCount > 0 {
                    Circle().fill(.red).frame(width: 8, height: 8)
                    Text("\(group.offlineCount)")
                        .font(.system(size: 10, design: .rounded))
                }
            }
            .foregroundStyle(.secondary)

            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 12))
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Tag Row View

struct TagRowView: View {
    let tag: ServerTag
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 4) {
            Text(tag.name)
                .font(.system(size: 11, weight: .medium))

            if isHovered {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 9))
                }
                .buttonStyle(.plain)

                Button(action: onDelete) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(tag.color.opacity(0.2))
        )
        .overlay(
            Capsule()
                .stroke(tag.color, lineWidth: 1)
        )
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Create Tag Sheet

struct CreateTagSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var selectedColor = "8E8E93"

    let onSave: (ServerTag) -> Void

    let colorOptions = [
        "FF3B30", "FF9500", "FFCC00", "34C759",
        "00C7BE", "007AFF", "5856D6", "AF52DE",
        "FF2D55", "8E8E93"
    ]

    var body: some View {
        VStack(spacing: 20) {
            Text("Create Tag")
                .font(.headline)

            Form {
                TextField("Name", text: $name)
                    .textFieldStyle(.roundedBorder)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Color")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(28)), count: 5), spacing: 8) {
                        ForEach(colorOptions, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex) ?? .gray)
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: selectedColor == hex ? 2 : 0)
                                )
                                .onTapGesture {
                                    selectedColor = hex
                                }
                        }
                    }
                }
            }
            .formStyle(.grouped)

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Create") {
                    let tag = ServerTag(name: name, colorHex: selectedColor)
                    onSave(tag)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.isEmpty)
            }
        }
        .padding()
        .frame(width: 300, height: 280)
    }
}

// MARK: - Edit Group Sheet

struct EditGroupSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var group: ServerGroup

    let colorOptions = [
        "FF3B30", "FF9500", "FFCC00", "34C759",
        "00C7BE", "007AFF", "5856D6", "AF52DE",
        "FF2D55", "8E8E93"
    ]

    let iconOptions = [
        "folder.fill", "server.rack", "cloud.fill",
        "network", "desktopcomputer", "building.2.fill",
        "testtube.2", "hammer.fill", "wrench.and.screwdriver.fill",
        "lock.fill", "globe", "externaldrive.fill"
    ]

    var body: some View {
        VStack(spacing: 20) {
            Text("Edit Group")
                .font(.headline)

            Form {
                TextField("Name", text: $group.name)
                    .textFieldStyle(.roundedBorder)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Color")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(28)), count: 5), spacing: 8) {
                        ForEach(colorOptions, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex) ?? .blue)
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: group.colorHex == hex ? 2 : 0)
                                )
                                .onTapGesture {
                                    group.colorHex = hex
                                }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Icon")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(36)), count: 6), spacing: 8) {
                        ForEach(iconOptions, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.system(size: 16))
                                .frame(width: 32, height: 32)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(group.iconName == icon ? Color.accentColor.opacity(0.2) : Color.clear)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(group.iconName == icon ? Color.accentColor : Color.clear, lineWidth: 1)
                                )
                                .onTapGesture {
                                    group.iconName = icon
                                }
                        }
                    }
                }
            }
            .formStyle(.grouped)

            HStack {
                Spacer()

                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 350, height: 400)
    }
}

// MARK: - Edit Tag Sheet

struct EditTagSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var tag: ServerTag

    let colorOptions = [
        "FF3B30", "FF9500", "FFCC00", "34C759",
        "00C7BE", "007AFF", "5856D6", "AF52DE",
        "FF2D55", "8E8E93"
    ]

    var body: some View {
        VStack(spacing: 20) {
            Text("Edit Tag")
                .font(.headline)

            Form {
                TextField("Name", text: $tag.name)
                    .textFieldStyle(.roundedBorder)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Color")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(28)), count: 5), spacing: 8) {
                        ForEach(colorOptions, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex) ?? .gray)
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: tag.colorHex == hex ? 2 : 0)
                                )
                                .onTapGesture {
                                    tag.colorHex = hex
                                }
                        }
                    }
                }
            }
            .formStyle(.grouped)

            HStack {
                Spacer()

                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 300, height: 280)
    }
}

#Preview {
    GroupManagementView()
        .modelContainer(for: [ServerGroup.self, ServerTag.self], inMemory: true)
}
