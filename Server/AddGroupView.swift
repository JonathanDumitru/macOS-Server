//
//  AddGroupView.swift
//  Server
//
//  Created by Claude on 1/26/26.
//

import SwiftUI
import SwiftData

struct AddGroupView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var editingGroup: ServerGroup?

    @State private var name = ""
    @State private var selectedColor: GroupColor = .blue
    @State private var selectedIcon: GroupIcon = .folder

    var isEditing: Bool {
        editingGroup != nil
    }

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Group Information") {
                    TextField("Name", text: $name)
                        .textFieldStyle(.roundedBorder)

                    // Preview
                    HStack {
                        Text("Preview")
                            .foregroundStyle(.secondary)
                        Spacer()
                        ServerGroupBadge(
                            group: ServerGroup(
                                name: name.isEmpty ? "Group Name" : name,
                                colorHex: selectedColor.rawValue,
                                icon: selectedIcon.rawValue
                            ),
                            size: .large
                        )
                    }
                }

                Section("Color") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 12) {
                        ForEach(GroupColor.allCases) { color in
                            ColorOption(
                                color: color,
                                isSelected: selectedColor == color
                            ) {
                                selectedColor = color
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("Icon") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 12) {
                        ForEach(GroupIcon.allCases) { icon in
                            IconOption(
                                icon: icon,
                                color: selectedColor.color,
                                isSelected: selectedIcon == icon
                            ) {
                                selectedIcon = icon
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .formStyle(.grouped)
            .navigationTitle(isEditing ? "Edit Group" : "New Group")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        saveGroup()
                    }
                    .disabled(!isValid)
                }
            }
            .onAppear {
                if let group = editingGroup {
                    name = group.name
                    if let color = GroupColor.allCases.first(where: { $0.rawValue == group.colorHex }) {
                        selectedColor = color
                    }
                    if let icon = GroupIcon.allCases.first(where: { $0.rawValue == group.icon }) {
                        selectedIcon = icon
                    }
                }
            }
        }
        .frame(minWidth: 400, minHeight: 500)
    }

    private func saveGroup() {
        if let group = editingGroup {
            group.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            group.colorHex = selectedColor.rawValue
            group.icon = selectedIcon.rawValue
        } else {
            let newGroup = ServerGroup(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                colorHex: selectedColor.rawValue,
                icon: selectedIcon.rawValue,
                sortOrder: getNextSortOrder()
            )
            modelContext.insert(newGroup)
        }

        dismiss()
    }

    private func getNextSortOrder() -> Int {
        let descriptor = FetchDescriptor<ServerGroup>(
            sortBy: [SortDescriptor(\.sortOrder, order: .reverse)]
        )
        let groups = (try? modelContext.fetch(descriptor)) ?? []
        return (groups.first?.sortOrder ?? -1) + 1
    }
}

// MARK: - Color Option

private struct ColorOption: View {
    let color: GroupColor
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color.color)
                    .frame(width: 36, height: 36)

                if isSelected {
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                        .frame(width: 28, height: 28)

                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .scaleEffect(isHovered ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
        .help(color.name)
    }
}

// MARK: - Icon Option

private struct IconOption: View {
    let icon: GroupIcon
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? color : Color(nsColor: .controlBackgroundColor))
                    .frame(width: 40, height: 40)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? color : Color.primary.opacity(0.1), lineWidth: isSelected ? 0 : 1)
                    )

                Image(systemName: icon.rawValue)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(isSelected ? .white : color)
            }
            .scaleEffect(isHovered ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
        .help(icon.name)
    }
}

// MARK: - Preview

#Preview("Add Group") {
    AddGroupView()
        .modelContainer(for: ServerGroup.self, inMemory: true)
}

#Preview("Edit Group") {
    AddGroupView(
        editingGroup: ServerGroup(
            name: "Production",
            colorHex: "#34C759",
            icon: "server.rack"
        )
    )
    .modelContainer(for: ServerGroup.self, inMemory: true)
}
