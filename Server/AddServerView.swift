//
//  AddServerView.swift
//  Server
//
//  Created by Jonathan Hines Dumitru on 1/13/26.
//

import SwiftUI
import SwiftData

struct AddServerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ServerGroup.sortOrder) private var groups: [ServerGroup]
    @Query private var allTags: [ServerTag]

    @State private var name = ""
    @State private var host = ""
    @State private var port = 80
    @State private var serverType: ServerType = .http
    @State private var notes = ""
    @State private var selectedGroup: ServerGroup?
    @State private var selectedTagNames: Set<String> = []
    @State private var newTagName = ""
    @State private var showingCreateGroup = false
    @State private var selectedTemplate: ServerTemplate?

    var isValid: Bool {
        !name.isEmpty && !host.isEmpty && port > 0 && port <= 65535
    }

    var body: some View {
        NavigationStack {
            Form {
                // Template Selector
                Section("Quick Start") {
                    TemplateSelector(selectedTemplate: $selectedTemplate)
                        .onChange(of: selectedTemplate) { _, newTemplate in
                            if let template = newTemplate {
                                applyTemplate(template)
                            }
                        }
                }

                Section("Server Information") {
                    TextField("Name", text: $name)
                        .textFieldStyle(.roundedBorder)

                    TextField("Host", text: $host)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.URL)

                    HStack {
                        Text("Port")
                        Spacer()
                        TextField("Port", value: $port, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                            .multilineTextAlignment(.trailing)
                    }

                    Picker("Type", selection: $serverType) {
                        ForEach(ServerType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.iconName)
                                .tag(type)
                        }
                    }
                }

                Section("Organization") {
                    // Group Picker
                    HStack {
                        Text("Group")
                        Spacer()
                        Picker("Group", selection: $selectedGroup) {
                            Text("None").tag(nil as ServerGroup?)
                            ForEach(groups) { group in
                                Label(group.name, systemImage: group.iconName)
                                    .foregroundStyle(group.color)
                                    .tag(group as ServerGroup?)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 180)

                        Button {
                            showingCreateGroup = true
                        } label: {
                            Image(systemName: "plus.circle")
                        }
                        .buttonStyle(.plain)
                        .help("Create new group")
                    }

                    // Tags
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tags")

                        // Existing tags
                        if !allTags.isEmpty {
                            FlowLayout(spacing: 6) {
                                ForEach(allTags) { tag in
                                    TagToggleButton(
                                        tag: tag,
                                        isSelected: selectedTagNames.contains(tag.name)
                                    ) {
                                        if selectedTagNames.contains(tag.name) {
                                            selectedTagNames.remove(tag.name)
                                        } else {
                                            selectedTagNames.insert(tag.name)
                                        }
                                    }
                                }
                            }
                        }

                        // Add new tag
                        HStack {
                            TextField("Add new tag...", text: $newTagName)
                                .textFieldStyle(.roundedBorder)
                                .frame(maxWidth: 200)

                            Button("Add") {
                                addNewTag()
                            }
                            .disabled(newTagName.isEmpty)
                        }
                    }
                }

                Section("Notes (Optional)") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }

                Section {
                    HStack {
                        Text("URL Preview")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(urlPreview)
                            .font(.caption.monospaced())
                            .foregroundStyle(.blue)
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Add Server")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addServer()
                    }
                    .disabled(!isValid)
                }
            }
            .sheet(isPresented: $showingCreateGroup) {
                CreateGroupSheet { group in
                    modelContext.insert(group)
                    selectedGroup = group
                }
            }
            .onAppear {
                // Create default groups if none exist
                if groups.isEmpty {
                    for group in ServerGroup.createDefaultGroups() {
                        modelContext.insert(group)
                    }
                }
                // Create default tags if none exist
                if allTags.isEmpty {
                    for tag in ServerTag.createDefaultTags() {
                        modelContext.insert(tag)
                    }
                }
            }
        }
        .frame(minWidth: 500, minHeight: 500)
    }

    private var urlPreview: String {
        switch serverType {
        case .http: return "http://\(host.isEmpty ? "example.com" : host):\(port)"
        case .https: return "https://\(host.isEmpty ? "example.com" : host):\(port)"
        case .ftp: return "ftp://\(host.isEmpty ? "example.com" : host):\(port)"
        case .ssh: return "ssh://\(host.isEmpty ? "example.com" : host):\(port)"
        default: return "\(host.isEmpty ? "example.com" : host):\(port)"
        }
    }

    private func applyTemplate(_ template: ServerTemplate) {
        serverType = template.serverType
        port = template.defaultPort
        notes = template.defaultNotes

        // Apply default tags
        if !template.defaultTags.isEmpty {
            let tags = template.defaultTags.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
            selectedTagNames = Set(tags)
        }
    }

    private func addNewTag() {
        let trimmed = newTagName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        // Check if tag already exists
        if !allTags.contains(where: { $0.name.lowercased() == trimmed.lowercased() }) {
            let newTag = ServerTag(name: trimmed)
            modelContext.insert(newTag)
        }

        selectedTagNames.insert(trimmed)
        newTagName = ""
    }

    private func addServer() {
        let newServer = Server(
            name: name,
            host: host,
            port: port,
            serverType: serverType,
            notes: notes
        )

        // Set group
        newServer.group = selectedGroup

        // Set tags
        newServer.tagNames = Array(selectedTagNames)

        modelContext.insert(newServer)
        dismiss()
    }
}

// MARK: - Tag Toggle Button

struct TagToggleButton: View {
    let tag: ServerTag
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(tag.name)
                .font(.system(size: 11, weight: .medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(isSelected ? tag.color : Color.gray.opacity(0.2))
                )
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Flow Layout for Tags

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }

            size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}

// MARK: - Create Group Sheet

struct CreateGroupSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var selectedColor = "007AFF"
    @State private var selectedIcon = "folder.fill"

    let onSave: (ServerGroup) -> Void

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
            Text("Create Group")
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
                                .fill(Color(hex: hex) ?? .blue)
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
                                        .fill(selectedIcon == icon ? Color.accentColor.opacity(0.2) : Color.clear)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(selectedIcon == icon ? Color.accentColor : Color.clear, lineWidth: 1)
                                )
                                .onTapGesture {
                                    selectedIcon = icon
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
                    let group = ServerGroup(
                        name: name,
                        colorHex: selectedColor,
                        iconName: selectedIcon
                    )
                    onSave(group)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.isEmpty)
            }
        }
        .padding()
        .frame(width: 350, height: 400)
    }
}

#Preview {
    AddServerView()
        .modelContainer(for: [Server.self, ServerGroup.self, ServerTag.self], inMemory: true)
}
