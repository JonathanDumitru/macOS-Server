//
//  ServerTemplatesView.swift
//  Server
//
//  UI for selecting and managing server templates
//

import SwiftUI
import SwiftData

struct ServerTemplatesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var customTemplates: [ServerTemplate]

    let onSelectTemplate: (ServerTemplate) -> Void

    @State private var showingCreateTemplate = false
    @State private var searchText = ""

    var allTemplates: [ServerTemplate] {
        ServerTemplate.builtInTemplates + customTemplates.filter { !$0.isBuiltIn }
    }

    var filteredTemplates: [ServerTemplate] {
        if searchText.isEmpty {
            return allTemplates
        }
        return allTemplates.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.templateDescription.localizedCaseInsensitiveContains(searchText) ||
            $0.defaultTags.localizedCaseInsensitiveContains(searchText)
        }
    }

    var groupedTemplates: [(String, [ServerTemplate])] {
        let groups: [String: [ServerTemplate]] = Dictionary(grouping: filteredTemplates) { template in
            switch template.serverType {
            case .http, .https: return "Web Servers"
            case .database: return "Databases"
            case .ssh: return "Remote Access"
            case .ftp: return "File Transfer"
            case .custom: return "Other Services"
            }
        }

        let order = ["Web Servers", "Databases", "Remote Access", "File Transfer", "Other Services"]
        return order.compactMap { key in
            guard let templates = groups[key], !templates.isEmpty else { return nil }
            return (key, templates)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "doc.badge.plus")
                    .font(.title2)
                    .foregroundStyle(.blue)
                Text("Choose a Template")
                    .font(.title2.bold())
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
            }
            .padding()

            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search templates...", text: $searchText)
                    .textFieldStyle(.plain)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
            .padding(.horizontal)
            .padding(.bottom)

            Divider()

            // Template List
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(groupedTemplates, id: \.0) { group, templates in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(group)
                                .font(.headline)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal)

                            LazyVGrid(columns: [
                                GridItem(.adaptive(minimum: 180, maximum: 220), spacing: 12)
                            ], spacing: 12) {
                                ForEach(templates, id: \.id) { template in
                                    TemplateCard(template: template) {
                                        onSelectTemplate(template)
                                        dismiss()
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Create Custom Template
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Custom")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)

                        Button {
                            showingCreateTemplate = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.blue)

                                VStack(alignment: .leading) {
                                    Text("Create Custom Template")
                                        .font(.subheadline.bold())
                                    Text("Save your own server configuration")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(nsColor: .controlBackgroundColor))
                                    .stroke(Color.blue.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5, 3]))
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
        }
        .frame(width: 600, height: 500)
        .sheet(isPresented: $showingCreateTemplate) {
            CreateTemplateView()
        }
    }
}

struct TemplateCard: View {
    let template: ServerTemplate
    let onSelect: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: template.iconName)
                        .font(.title3)
                        .foregroundStyle(template.color)
                        .frame(width: 28, height: 28)
                        .background(template.color.opacity(0.15), in: RoundedRectangle(cornerRadius: 6))

                    Spacer()

                    Text(":\(template.defaultPort)")
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }

                Text(template.name)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                    .foregroundStyle(.primary)

                Text(template.templateDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                if !template.defaultTags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(template.defaultTags.split(separator: ",").prefix(2), id: \.self) { tag in
                            Text(String(tag))
                                .font(.system(size: 9))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.15), in: Capsule())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .shadow(color: .black.opacity(isHovered ? 0.15 : 0.08), radius: isHovered ? 8 : 4, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isHovered ? template.color.opacity(0.5) : Color.clear, lineWidth: 2)
            )
            .scaleEffect(isHovered ? 1.02 : 1)
            .animation(.easeInOut(duration: 0.15), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct CreateTemplateView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var templateDescription = ""
    @State private var serverType: ServerType = .http
    @State private var defaultPort = "80"
    @State private var iconName = "server.rack"
    @State private var colorHex = "007AFF"
    @State private var defaultTags = ""
    @State private var defaultNotes = ""

    let availableIcons = [
        "server.rack", "globe", "lock.shield", "terminal", "cylinder",
        "folder", "envelope", "network", "shippingbox", "magnifyingglass",
        "message", "chart.bar", "flame", "hammer", "chevron.left.forwardslash.chevron.right",
        "arrow.triangle.branch", "cpu", "memorychip", "externaldrive", "antenna.radiowaves.left.and.right"
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "plus.circle")
                    .font(.title2)
                    .foregroundStyle(.blue)
                Text("Create Template")
                    .font(.title2.bold())
                Spacer()
            }
            .padding()

            Divider()

            Form {
                Section("Basic Information") {
                    TextField("Template Name", text: $name)
                    TextField("Description", text: $templateDescription)

                    Picker("Server Type", selection: $serverType) {
                        ForEach(ServerType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }

                    TextField("Default Port", text: $defaultPort)
                }

                Section("Appearance") {
                    Picker("Icon", selection: $iconName) {
                        ForEach(availableIcons, id: \.self) { icon in
                            Label(icon, systemImage: icon).tag(icon)
                        }
                    }

                    ColorPicker("Color", selection: Binding(
                        get: { Color(hex: colorHex) ?? .blue },
                        set: { colorHex = $0.hexString }
                    ))
                }

                Section("Defaults") {
                    TextField("Default Tags (comma-separated)", text: $defaultTags)
                    TextField("Default Notes", text: $defaultNotes, axis: .vertical)
                        .lineLimit(3...5)
                }
            }
            .formStyle(.grouped)

            Divider()

            // Actions
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)

                Spacer()

                Button("Create Template") {
                    createTemplate()
                }
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
                .disabled(name.isEmpty)
            }
            .padding()
        }
        .frame(width: 450, height: 550)
    }

    private func createTemplate() {
        let template = ServerTemplate(
            name: name,
            templateDescription: templateDescription,
            serverType: serverType,
            defaultPort: Int(defaultPort) ?? 80,
            iconName: iconName,
            colorHex: colorHex,
            isBuiltIn: false,
            defaultTags: defaultTags,
            defaultNotes: defaultNotes
        )
        modelContext.insert(template)
        dismiss()
    }
}

// MARK: - Template Selector for AddServerView

struct TemplateSelector: View {
    @Binding var selectedTemplate: ServerTemplate?
    @State private var showingTemplates = false

    var body: some View {
        Button {
            showingTemplates = true
        } label: {
            HStack {
                if let template = selectedTemplate {
                    Image(systemName: template.iconName)
                        .foregroundStyle(template.color)
                    Text(template.name)
                    Spacer()
                    Button {
                        selectedTemplate = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                } else {
                    Image(systemName: "doc.badge.plus")
                        .foregroundStyle(.blue)
                    Text("Use Template")
                        .foregroundStyle(.blue)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingTemplates) {
            ServerTemplatesView { template in
                selectedTemplate = template
            }
        }
    }
}
