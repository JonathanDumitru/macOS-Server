//
//  AlertThresholdsView.swift
//  Server
//
//  Created by Claude on 1/27/26.
//

import SwiftUI
import SwiftData

struct AlertThresholdsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \AlertThreshold.metricType.rawValue) private var thresholds: [AlertThreshold]
    @Query(sort: \AlertEvent.timestamp, order: .reverse) private var recentAlerts: [AlertEvent]

    @State private var showingAddThreshold = false
    @State private var editingThreshold: AlertThreshold?
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                // Thresholds Tab
                thresholdsTab
                    .tabItem {
                        Label("Thresholds", systemImage: "slider.horizontal.3")
                    }
                    .tag(0)

                // Alert History Tab
                alertHistoryTab
                    .tabItem {
                        Label("History", systemImage: "clock.arrow.circlepath")
                    }
                    .tag(1)
            }
            .navigationTitle("Alert Thresholds")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                if selectedTab == 0 {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showingAddThreshold = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddThreshold) {
                AddThresholdSheet { threshold in
                    modelContext.insert(threshold)
                }
            }
            .sheet(item: $editingThreshold) { threshold in
                EditThresholdSheet(threshold: threshold)
            }
            .onAppear {
                initializeDefaultsIfNeeded()
            }
        }
        .frame(minWidth: 600, minHeight: 500)
    }

    // MARK: - Thresholds Tab

    private var thresholdsTab: some View {
        VStack(spacing: 0) {
            if thresholds.isEmpty {
                ContentUnavailableView(
                    "No Thresholds",
                    systemImage: "slider.horizontal.3",
                    description: Text("Add thresholds to get notified when metrics exceed limits")
                )
            } else {
                List {
                    ForEach(AlertMetricType.allCases) { metricType in
                        let typeThresholds = thresholds.filter { $0.metricType == metricType }
                        if !typeThresholds.isEmpty {
                            Section {
                                ForEach(typeThresholds) { threshold in
                                    ThresholdRowView(threshold: threshold) {
                                        editingThreshold = threshold
                                    } onDelete: {
                                        deleteThreshold(threshold)
                                    } onToggle: {
                                        threshold.isEnabled.toggle()
                                    }
                                }
                            } header: {
                                Label(metricType.rawValue, systemImage: metricType.icon)
                            }
                        }
                    }
                }
                .listStyle(.inset)
            }

            Divider()

            HStack {
                Button("Reset to Defaults") {
                    resetToDefaults()
                }
                .foregroundStyle(.red)

                Spacer()

                Text("\(thresholds.filter { $0.isEnabled }.count) active thresholds")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }

    // MARK: - Alert History Tab

    private var alertHistoryTab: some View {
        VStack(spacing: 0) {
            if recentAlerts.isEmpty {
                ContentUnavailableView(
                    "No Alerts",
                    systemImage: "checkmark.circle",
                    description: Text("Alert history will appear here when thresholds are exceeded")
                )
            } else {
                List {
                    ForEach(recentAlerts) { alert in
                        AlertEventRowView(alert: alert) {
                            alert.isAcknowledged = true
                        }
                    }
                    .onDelete(perform: deleteAlerts)
                }
                .listStyle(.inset)
            }

            Divider()

            HStack {
                Button("Clear All History", role: .destructive) {
                    clearAllAlerts()
                }

                Spacer()

                let unacknowledged = recentAlerts.filter { !$0.isAcknowledged }.count
                if unacknowledged > 0 {
                    Text("\(unacknowledged) unacknowledged")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            .padding()
        }
    }

    // MARK: - Actions

    private func initializeDefaultsIfNeeded() {
        if thresholds.isEmpty {
            for threshold in AlertThreshold.createDefaultThresholds() {
                modelContext.insert(threshold)
            }
        }
    }

    private func deleteThreshold(_ threshold: AlertThreshold) {
        modelContext.delete(threshold)
    }

    private func deleteAlerts(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(recentAlerts[index])
        }
    }

    private func clearAllAlerts() {
        for alert in recentAlerts {
            modelContext.delete(alert)
        }
    }

    private func resetToDefaults() {
        // Delete existing thresholds
        for threshold in thresholds {
            modelContext.delete(threshold)
        }

        // Create defaults
        for threshold in AlertThreshold.createDefaultThresholds() {
            modelContext.insert(threshold)
        }
    }
}

// MARK: - Threshold Row View

struct ThresholdRowView: View {
    @Bindable var threshold: AlertThreshold
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Severity indicator
            Image(systemName: threshold.severity.icon)
                .foregroundStyle(Color(threshold.severity.color))
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(threshold.comparison.rawValue)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(.secondary)

                    Text("\(Int(threshold.thresholdValue))\(threshold.metricType.unit)")
                        .font(.system(size: 14, weight: .semibold))
                }

                HStack(spacing: 8) {
                    Text(threshold.severity.rawValue)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color(threshold.severity.color))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color(threshold.severity.color).opacity(0.15))
                        )

                    Text("Cooldown: \(threshold.cooldownMinutes)m")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { threshold.isEnabled },
                set: { _ in onToggle() }
            ))
            .labelsHidden()
            .toggleStyle(.switch)
            .controlSize(.small)

            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.red)
        }
        .padding(.vertical, 4)
        .opacity(threshold.isEnabled ? 1 : 0.5)
    }
}

// MARK: - Alert Event Row View

struct AlertEventRowView: View {
    let alert: AlertEvent
    let onAcknowledge: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: alert.severity.icon)
                .foregroundStyle(Color(alert.severity.color))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(alert.serverName)
                        .font(.system(size: 13, weight: .semibold))

                    Text("-")
                        .foregroundStyle(.tertiary)

                    Text(alert.metricType.rawValue)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 4) {
                    Text("\(Int(alert.actualValue))\(alert.metricType.unit)")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.red)

                    Text("(threshold: \(Int(alert.thresholdValue))\(alert.metricType.unit))")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }

                Text(alert.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            if !alert.isAcknowledged {
                Button("Ack") {
                    onAcknowledge()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Threshold Sheet

struct AddThresholdSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var metricType: AlertMetricType = .cpuUsage
    @State private var thresholdValue: Double = 80
    @State private var comparison: ThresholdComparison = .greaterThan
    @State private var severity: AlertSeverity = .warning
    @State private var cooldownMinutes: Int = 5

    let onSave: (AlertThreshold) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Metric") {
                    Picker("Metric Type", selection: $metricType) {
                        ForEach(AlertMetricType.allCases) { type in
                            Label(type.rawValue, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    .onChange(of: metricType) { _, newType in
                        thresholdValue = newType.defaultThreshold
                    }
                }

                Section("Threshold") {
                    Picker("Comparison", selection: $comparison) {
                        ForEach(ThresholdComparison.allCases, id: \.self) { comp in
                            Text("\(comp.rawValue) \(comp.description)")
                                .tag(comp)
                        }
                    }

                    HStack {
                        Text("Value")
                        Spacer()
                        TextField("Value", value: $thresholdValue, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                            .multilineTextAlignment(.trailing)
                        Text(metricType.unit)
                            .foregroundStyle(.secondary)
                    }

                    Slider(
                        value: $thresholdValue,
                        in: metricType.minValue...metricType.maxValue,
                        step: 1
                    ) {
                        Text("Value")
                    }
                }

                Section("Alert Settings") {
                    Picker("Severity", selection: $severity) {
                        ForEach(AlertSeverity.allCases, id: \.self) { sev in
                            Label(sev.rawValue, systemImage: sev.icon)
                                .tag(sev)
                        }
                    }
                    .pickerStyle(.segmented)

                    Stepper("Cooldown: \(cooldownMinutes) minutes", value: $cooldownMinutes, in: 1...60)

                    Text("Minimum time between repeated alerts for the same server")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Preview") {
                    HStack {
                        Image(systemName: severity.icon)
                            .foregroundStyle(Color(severity.color))

                        Text("Alert when \(metricType.rawValue) \(comparison.description.lowercased()) \(Int(thresholdValue))\(metricType.unit)")
                            .font(.system(size: 13))
                    }
                    .padding(.vertical, 4)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Add Threshold")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let threshold = AlertThreshold(
                            metricType: metricType,
                            thresholdValue: thresholdValue,
                            comparison: comparison,
                            severity: severity,
                            cooldownMinutes: cooldownMinutes
                        )
                        onSave(threshold)
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 450, height: 500)
    }
}

// MARK: - Edit Threshold Sheet

struct EditThresholdSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var threshold: AlertThreshold

    var body: some View {
        NavigationStack {
            Form {
                Section("Metric") {
                    Picker("Metric Type", selection: $threshold.metricType) {
                        ForEach(AlertMetricType.allCases) { type in
                            Label(type.rawValue, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                }

                Section("Threshold") {
                    Picker("Comparison", selection: $threshold.comparison) {
                        ForEach(ThresholdComparison.allCases, id: \.self) { comp in
                            Text("\(comp.rawValue) \(comp.description)")
                                .tag(comp)
                        }
                    }

                    HStack {
                        Text("Value")
                        Spacer()
                        TextField("Value", value: $threshold.thresholdValue, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                            .multilineTextAlignment(.trailing)
                        Text(threshold.metricType.unit)
                            .foregroundStyle(.secondary)
                    }

                    Slider(
                        value: $threshold.thresholdValue,
                        in: threshold.metricType.minValue...threshold.metricType.maxValue,
                        step: 1
                    ) {
                        Text("Value")
                    }
                }

                Section("Alert Settings") {
                    Picker("Severity", selection: $threshold.severity) {
                        ForEach(AlertSeverity.allCases, id: \.self) { sev in
                            Label(sev.rawValue, systemImage: sev.icon)
                                .tag(sev)
                        }
                    }
                    .pickerStyle(.segmented)

                    Stepper("Cooldown: \(threshold.cooldownMinutes) minutes", value: $threshold.cooldownMinutes, in: 1...60)

                    Toggle("Enabled", isOn: $threshold.isEnabled)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Edit Threshold")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 450, height: 480)
    }
}

#Preview {
    AlertThresholdsView()
        .modelContainer(for: [AlertThreshold.self, AlertEvent.self], inMemory: true)
}
