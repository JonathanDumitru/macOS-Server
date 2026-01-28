//
//  DependencyTracking.swift
//  Server
//
//  Created by Claude on 1/28/26.
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - Dependency Model

@Model
final class ServerDependency {
    var id: UUID
    var sourceServerId: UUID
    var targetServerId: UUID
    var dependencyType: DependencyType
    var description: String
    var isRequired: Bool // If true, source cannot function without target
    var createdAt: Date

    init(
        id: UUID = UUID(),
        sourceServerId: UUID,
        targetServerId: UUID,
        dependencyType: DependencyType = .depends,
        description: String = "",
        isRequired: Bool = true
    ) {
        self.id = id
        self.sourceServerId = sourceServerId
        self.targetServerId = targetServerId
        self.dependencyType = dependencyType
        self.description = description
        self.isRequired = isRequired
        self.createdAt = Date()
    }
}

enum DependencyType: String, Codable, CaseIterable, Identifiable {
    case depends = "Depends On"
    case provides = "Provides For"
    case backup = "Backup Of"
    case loadBalances = "Load Balances"
    case database = "Database Connection"
    case api = "API Dependency"
    case auth = "Authentication"
    case cache = "Caching"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .depends: return "arrow.right"
        case .provides: return "arrow.left"
        case .backup: return "arrow.2.squarepath"
        case .loadBalances: return "arrow.triangle.branch"
        case .database: return "cylinder"
        case .api: return "network"
        case .auth: return "lock.shield"
        case .cache: return "memorychip"
        }
    }

    var color: Color {
        switch self {
        case .depends: return .blue
        case .provides: return .green
        case .backup: return .purple
        case .loadBalances: return .orange
        case .database: return .cyan
        case .api: return .pink
        case .auth: return .red
        case .cache: return .yellow
        }
    }
}

// MARK: - Dependency Service

@MainActor
class DependencyService {
    static let shared = DependencyService()

    private var modelContext: ModelContext?

    private init() {}

    func configure(with context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - CRUD Operations

    func addDependency(
        source: Server,
        target: Server,
        type: DependencyType,
        description: String = "",
        isRequired: Bool = true
    ) {
        guard let context = modelContext else { return }

        // Check if dependency already exists
        let sourceId = source.id
        let targetId = target.id
        let descriptor = FetchDescriptor<ServerDependency>(
            predicate: #Predicate {
                $0.sourceServerId == sourceId && $0.targetServerId == targetId
            }
        )

        if let existing = try? context.fetch(descriptor), !existing.isEmpty {
            return // Dependency already exists
        }

        let dependency = ServerDependency(
            sourceServerId: source.id,
            targetServerId: target.id,
            dependencyType: type,
            description: description,
            isRequired: isRequired
        )

        context.insert(dependency)
        try? context.save()
    }

    func removeDependency(_ dependency: ServerDependency) {
        modelContext?.delete(dependency)
        try? modelContext?.save()
    }

    func getDependencies(for server: Server) -> (upstream: [ServerDependency], downstream: [ServerDependency]) {
        guard let context = modelContext else { return ([], []) }

        let serverId = server.id

        // Dependencies where this server depends on others
        let upstreamDescriptor = FetchDescriptor<ServerDependency>(
            predicate: #Predicate { $0.sourceServerId == serverId }
        )

        // Dependencies where others depend on this server
        let downstreamDescriptor = FetchDescriptor<ServerDependency>(
            predicate: #Predicate { $0.targetServerId == serverId }
        )

        let upstream = (try? context.fetch(upstreamDescriptor)) ?? []
        let downstream = (try? context.fetch(downstreamDescriptor)) ?? []

        return (upstream, downstream)
    }

    // MARK: - Impact Analysis

    func analyzeImpact(if serverGoesOffline server: Server, allServers: [Server]) -> [Server] {
        guard let context = modelContext else { return [] }

        var impactedServers: Set<UUID> = []
        var toCheck: [UUID] = [server.id]

        while !toCheck.isEmpty {
            let current = toCheck.removeFirst()

            // Find servers that depend on current
            let descriptor = FetchDescriptor<ServerDependency>(
                predicate: #Predicate { $0.targetServerId == current && $0.isRequired }
            )

            if let dependencies = try? context.fetch(descriptor) {
                for dep in dependencies {
                    if !impactedServers.contains(dep.sourceServerId) {
                        impactedServers.insert(dep.sourceServerId)
                        toCheck.append(dep.sourceServerId)
                    }
                }
            }
        }

        return allServers.filter { impactedServers.contains($0.id) }
    }

    // MARK: - Validation

    func checkDependencyHealth(for server: Server, allServers: [Server]) -> DependencyHealthStatus {
        let (upstream, _) = getDependencies(for: server)

        var unhealthyDeps: [(ServerDependency, Server)] = []

        for dep in upstream where dep.isRequired {
            if let targetServer = allServers.first(where: { $0.id == dep.targetServerId }) {
                if targetServer.status != .online {
                    unhealthyDeps.append((dep, targetServer))
                }
            }
        }

        if unhealthyDeps.isEmpty {
            return .healthy
        } else if unhealthyDeps.count < upstream.filter({ $0.isRequired }).count {
            return .degraded(unhealthyDeps)
        } else {
            return .critical(unhealthyDeps)
        }
    }
}

enum DependencyHealthStatus {
    case healthy
    case degraded([(ServerDependency, Server)])
    case critical([(ServerDependency, Server)])

    var color: Color {
        switch self {
        case .healthy: return .green
        case .degraded: return .orange
        case .critical: return .red
        }
    }

    var icon: String {
        switch self {
        case .healthy: return "checkmark.circle.fill"
        case .degraded: return "exclamationmark.triangle.fill"
        case .critical: return "xmark.circle.fill"
        }
    }
}

// MARK: - Dependency Map View

struct DependencyMapView: View {
    @Query private var servers: [Server]
    @Query private var dependencies: [ServerDependency]
    @State private var selectedServer: Server?
    @State private var showAddDependency = false
    @State private var zoomLevel: Double = 1.0

    var body: some View {
        HSplitView {
            // Server List
            VStack(spacing: 0) {
                HStack {
                    Text("Servers")
                        .font(.headline)
                    Spacer()
                }
                .padding()

                Divider()

                List(servers, selection: $selectedServer) { server in
                    HStack {
                        Circle()
                            .fill(Color(server.status.color))
                            .frame(width: 8, height: 8)
                        Text(server.name)
                            .font(.system(size: 13))

                        Spacer()

                        let deps = getDependencyCount(for: server)
                        if deps.total > 0 {
                            Text("\(deps.total)")
                                .font(.system(size: 10, weight: .medium))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.2))
                                .foregroundStyle(.blue)
                                .clipShape(Capsule())
                        }
                    }
                    .tag(server)
                }
                .listStyle(.inset)
            }
            .frame(minWidth: 200, maxWidth: 250)

            // Dependency Graph
            VStack(spacing: 0) {
                // Toolbar
                HStack {
                    Text("Dependency Map")
                        .font(.headline)

                    Spacer()

                    HStack(spacing: 8) {
                        Button {
                            zoomLevel = max(0.5, zoomLevel - 0.25)
                        } label: {
                            Image(systemName: "minus.magnifyingglass")
                        }

                        Text("\(Int(zoomLevel * 100))%")
                            .font(.caption)
                            .frame(width: 40)

                        Button {
                            zoomLevel = min(2.0, zoomLevel + 0.25)
                        } label: {
                            Image(systemName: "plus.magnifyingglass")
                        }
                    }
                    .buttonStyle(.plain)

                    if selectedServer != nil {
                        Button {
                            showAddDependency = true
                        } label: {
                            Label("Add Dependency", systemImage: "plus")
                        }
                    }
                }
                .padding()

                Divider()

                if let server = selectedServer {
                    DependencyGraphView(
                        server: server,
                        allServers: servers,
                        dependencies: dependencies,
                        zoomLevel: zoomLevel
                    )
                } else {
                    emptyState
                }
            }
        }
        .sheet(isPresented: $showAddDependency) {
            if let server = selectedServer {
                AddDependencySheet(sourceServer: server, allServers: servers)
            }
        }
    }

    private func getDependencyCount(for server: Server) -> (upstream: Int, downstream: Int, total: Int) {
        let upstream = dependencies.filter { $0.sourceServerId == server.id }.count
        let downstream = dependencies.filter { $0.targetServerId == server.id }.count
        return (upstream, downstream, upstream + downstream)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.triangle.branch")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Select a Server")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text("Choose a server to view its dependencies")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Dependency Graph View

struct DependencyGraphView: View {
    let server: Server
    let allServers: [Server]
    let dependencies: [ServerDependency]
    let zoomLevel: Double

    var upstreamDeps: [ServerDependency] {
        dependencies.filter { $0.sourceServerId == server.id }
    }

    var downstreamDeps: [ServerDependency] {
        dependencies.filter { $0.targetServerId == server.id }
    }

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            VStack(spacing: 40) {
                // Upstream (servers this one depends on)
                if !upstreamDeps.isEmpty {
                    VStack(spacing: 8) {
                        Text("Depends On")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 20) {
                            ForEach(upstreamDeps, id: \.id) { dep in
                                if let target = allServers.first(where: { $0.id == dep.targetServerId }) {
                                    DependencyNodeView(
                                        server: target,
                                        dependency: dep,
                                        isUpstream: true
                                    )
                                }
                            }
                        }
                    }
                }

                // Arrows pointing down
                if !upstreamDeps.isEmpty {
                    Image(systemName: "arrow.down")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }

                // Central Server
                CentralServerNodeView(server: server)

                // Arrows pointing down
                if !downstreamDeps.isEmpty {
                    Image(systemName: "arrow.down")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }

                // Downstream (servers that depend on this one)
                if !downstreamDeps.isEmpty {
                    VStack(spacing: 8) {
                        Text("Depended On By")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 20) {
                            ForEach(downstreamDeps, id: \.id) { dep in
                                if let source = allServers.first(where: { $0.id == dep.sourceServerId }) {
                                    DependencyNodeView(
                                        server: source,
                                        dependency: dep,
                                        isUpstream: false
                                    )
                                }
                            }
                        }
                    }
                }

                if upstreamDeps.isEmpty && downstreamDeps.isEmpty {
                    Text("No dependencies configured")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(40)
            .scaleEffect(zoomLevel)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct CentralServerNodeView: View {
    let server: Server

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color(server.status.color).opacity(0.2))
                    .frame(width: 80, height: 80)

                Circle()
                    .stroke(Color(server.status.color), lineWidth: 3)
                    .frame(width: 80, height: 80)

                Image(systemName: server.serverType.iconName)
                    .font(.system(size: 28))
                    .foregroundStyle(Color(server.status.color))
            }

            Text(server.name)
                .font(.system(size: 14, weight: .semibold))

            Text(server.host)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
    }
}

struct DependencyNodeView: View {
    @Environment(\.modelContext) private var modelContext
    let server: Server
    let dependency: ServerDependency
    let isUpstream: Bool

    @State private var showDelete = false

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(Color(server.status.color).opacity(0.15))
                    .frame(width: 60, height: 60)

                Circle()
                    .stroke(dependency.dependencyType.color, lineWidth: 2)
                    .frame(width: 60, height: 60)

                Image(systemName: server.serverType.iconName)
                    .font(.system(size: 20))
                    .foregroundStyle(Color(server.status.color))
            }

            Text(server.name)
                .font(.system(size: 12, weight: .medium))
                .lineLimit(1)

            HStack(spacing: 4) {
                Image(systemName: dependency.dependencyType.icon)
                    .font(.system(size: 9))
                Text(dependency.dependencyType.rawValue)
                    .font(.system(size: 9))
            }
            .foregroundStyle(dependency.dependencyType.color)

            if dependency.isRequired {
                Text("REQUIRED")
                    .font(.system(size: 8, weight: .bold))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Color.red.opacity(0.2))
                    .foregroundStyle(.red)
                    .clipShape(Capsule())
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .contextMenu {
            Button(role: .destructive) {
                DependencyService.shared.removeDependency(dependency)
            } label: {
                Label("Remove Dependency", systemImage: "trash")
            }
        }
    }
}

// MARK: - Add Dependency Sheet

struct AddDependencySheet: View {
    @Environment(\.dismiss) private var dismiss
    let sourceServer: Server
    let allServers: [Server]

    @State private var selectedTargetId: UUID?
    @State private var dependencyType: DependencyType = .depends
    @State private var description: String = ""
    @State private var isRequired: Bool = true

    var availableTargets: [Server] {
        allServers.filter { $0.id != sourceServer.id }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Cancel") {
                    dismiss()
                }

                Spacer()

                Text("Add Dependency")
                    .font(.headline)

                Spacer()

                Button("Add") {
                    addDependency()
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedTargetId == nil)
            }
            .padding()

            Divider()

            Form {
                Section("Source Server") {
                    HStack {
                        Circle()
                            .fill(Color(sourceServer.status.color))
                            .frame(width: 10, height: 10)
                        Text(sourceServer.name)
                            .font(.system(size: 13, weight: .medium))
                    }
                }

                Section("Target Server") {
                    Picker("Depends On", selection: $selectedTargetId) {
                        Text("Select a server...").tag(nil as UUID?)
                        ForEach(availableTargets) { server in
                            HStack {
                                Circle()
                                    .fill(Color(server.status.color))
                                    .frame(width: 8, height: 8)
                                Text(server.name)
                            }
                            .tag(server.id as UUID?)
                        }
                    }
                }

                Section("Dependency Details") {
                    Picker("Type", selection: $dependencyType) {
                        ForEach(DependencyType.allCases) { type in
                            Label(type.rawValue, systemImage: type.icon).tag(type)
                        }
                    }

                    TextField("Description (optional)", text: $description)

                    Toggle("Required Dependency", isOn: $isRequired)

                    if isRequired {
                        Text("If the target server goes offline, this server will be marked as impacted")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 400, height: 450)
    }

    private func addDependency() {
        guard let targetId = selectedTargetId,
              let target = allServers.first(where: { $0.id == targetId }) else { return }

        DependencyService.shared.addDependency(
            source: sourceServer,
            target: target,
            type: dependencyType,
            description: description,
            isRequired: isRequired
        )

        dismiss()
    }
}

// MARK: - Impact Analysis View

struct ImpactAnalysisView: View {
    let server: Server
    let allServers: [Server]

    var impactedServers: [Server] {
        DependencyService.shared.analyzeImpact(if: server, allServers: allServers)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
                Text("Impact Analysis")
                    .font(.headline)
            }

            if impactedServers.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle")
                        .foregroundStyle(.green)
                    Text("No servers would be impacted if \(server.name) goes offline")
                        .font(.subheadline)
                }
            } else {
                Text("The following \(impactedServers.count) server(s) would be impacted:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ForEach(impactedServers) { impacted in
                    HStack {
                        Circle()
                            .fill(Color(impacted.status.color))
                            .frame(width: 8, height: 8)
                        Text(impacted.name)
                            .font(.system(size: 13))
                        Spacer()
                        Text(impacted.host)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }
}

#Preview {
    DependencyMapView()
}
