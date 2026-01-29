//
//  SoundAlertService.swift
//  Server
//
//  Created by Claude on 1/28/26.
//

import Foundation
import AppKit
import os.log

private let logger = Logger(subsystem: "com.server.app", category: "SoundAlerts")

/// Available alert sounds
enum AlertSound: String, CaseIterable, Identifiable, Codable {
    case none = "None"
    case glass = "Glass"
    case ping = "Ping"
    case pop = "Pop"
    case purr = "Purr"
    case sosumi = "Sosumi"
    case submarine = "Submarine"
    case tink = "Tink"
    case blow = "Blow"
    case bottle = "Bottle"
    case frog = "Frog"
    case funk = "Funk"
    case hero = "Hero"
    case morse = "Morse"

    var id: String { rawValue }

    var systemSoundName: String? {
        switch self {
        case .none: return nil
        case .glass: return "Glass"
        case .ping: return "Ping"
        case .pop: return "Pop"
        case .purr: return "Purr"
        case .sosumi: return "Sosumi"
        case .submarine: return "Submarine"
        case .tink: return "Tink"
        case .blow: return "Blow"
        case .bottle: return "Bottle"
        case .frog: return "Frog"
        case .funk: return "Funk"
        case .hero: return "Hero"
        case .morse: return "Morse"
        }
    }
}

/// Alert types that can trigger sounds
enum AlertType: String, CaseIterable, Identifiable, Codable {
    case serverOffline = "Server Offline"
    case serverRecovered = "Server Recovered"
    case sslExpiring = "SSL Expiring"
    case highResponseTime = "High Response Time"
    case incidentCreated = "New Incident"
    case maintenanceStarting = "Maintenance Starting"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .serverOffline: return "xmark.circle.fill"
        case .serverRecovered: return "checkmark.circle.fill"
        case .sslExpiring: return "lock.trianglebadge.exclamationmark"
        case .highResponseTime: return "gauge.with.needle.fill"
        case .incidentCreated: return "exclamationmark.triangle.fill"
        case .maintenanceStarting: return "calendar.badge.clock"
        }
    }

    var defaultSound: AlertSound {
        switch self {
        case .serverOffline: return .sosumi
        case .serverRecovered: return .glass
        case .sslExpiring: return .purr
        case .highResponseTime: return .tink
        case .incidentCreated: return .funk
        case .maintenanceStarting: return .ping
        }
    }
}

/// Configuration for sound alerts
struct SoundAlertConfiguration: Codable {
    var isEnabled: Bool
    var soundMappings: [String: String] // AlertType.rawValue -> AlertSound.rawValue
    var quietHoursEnabled: Bool
    var quietHoursStart: Int // Hour (0-23)
    var quietHoursEnd: Int // Hour (0-23)
    var volume: Double // 0.0 - 1.0

    static var `default`: SoundAlertConfiguration {
        var mappings: [String: String] = [:]
        for alertType in AlertType.allCases {
            mappings[alertType.rawValue] = alertType.defaultSound.rawValue
        }
        return SoundAlertConfiguration(
            isEnabled: true,
            soundMappings: mappings,
            quietHoursEnabled: false,
            quietHoursStart: 22,
            quietHoursEnd: 7,
            volume: 1.0
        )
    }

    func sound(for alertType: AlertType) -> AlertSound {
        if let soundName = soundMappings[alertType.rawValue],
           let sound = AlertSound(rawValue: soundName) {
            return sound
        }
        return alertType.defaultSound
    }
}

/// Service for managing sound alerts
@MainActor
class SoundAlertService {
    static let shared = SoundAlertService()

    private let configKey = "soundAlertConfiguration"
    private(set) var configuration: SoundAlertConfiguration

    private init() {
        if let data = UserDefaults.standard.data(forKey: configKey),
           let config = try? JSONDecoder().decode(SoundAlertConfiguration.self, from: data) {
            configuration = config
        } else {
            configuration = .default
        }
    }

    // MARK: - Configuration

    func updateConfiguration(_ config: SoundAlertConfiguration) {
        configuration = config
        saveConfiguration()
    }

    func setSound(_ sound: AlertSound, for alertType: AlertType) {
        configuration.soundMappings[alertType.rawValue] = sound.rawValue
        saveConfiguration()
    }

    func setEnabled(_ enabled: Bool) {
        configuration.isEnabled = enabled
        saveConfiguration()
    }

    func setVolume(_ volume: Double) {
        configuration.volume = max(0, min(1, volume))
        saveConfiguration()
    }

    func setQuietHours(enabled: Bool, start: Int? = nil, end: Int? = nil) {
        configuration.quietHoursEnabled = enabled
        if let start = start {
            configuration.quietHoursStart = start
        }
        if let end = end {
            configuration.quietHoursEnd = end
        }
        saveConfiguration()
    }

    private func saveConfiguration() {
        if let data = try? JSONEncoder().encode(configuration) {
            UserDefaults.standard.set(data, forKey: configKey)
        }
    }

    // MARK: - Play Sounds

    func playAlert(for alertType: AlertType) {
        guard configuration.isEnabled else {
            logger.debug("Sound alerts disabled")
            return
        }

        guard !isInQuietHours() else {
            logger.debug("In quiet hours, skipping sound")
            return
        }

        let sound = configuration.sound(for: alertType)
        playSound(sound)
    }

    func playSound(_ sound: AlertSound) {
        guard let soundName = sound.systemSoundName else { return }

        if let nsSound = NSSound(named: NSSound.Name(soundName)) {
            nsSound.volume = Float(configuration.volume)
            nsSound.play()
            logger.debug("Playing sound: \(soundName)")
        } else {
            logger.warning("Sound not found: \(soundName)")
        }
    }

    func previewSound(_ sound: AlertSound) {
        guard let soundName = sound.systemSoundName else { return }
        if let nsSound = NSSound(named: NSSound.Name(soundName)) {
            nsSound.volume = Float(configuration.volume)
            nsSound.play()
        }
    }

    // MARK: - Quiet Hours

    private func isInQuietHours() -> Bool {
        guard configuration.quietHoursEnabled else { return false }

        let hour = Calendar.current.component(.hour, from: Date())
        let start = configuration.quietHoursStart
        let end = configuration.quietHoursEnd

        if start < end {
            // Same day quiet hours (e.g., 9-17)
            return hour >= start && hour < end
        } else {
            // Overnight quiet hours (e.g., 22-7)
            return hour >= start || hour < end
        }
    }
}

// MARK: - SwiftUI Settings View Extension

import SwiftUI

struct SoundAlertSettingsView: View {
    @State private var service = SoundAlertService.shared
    @State private var config: SoundAlertConfiguration

    init() {
        _config = State(initialValue: SoundAlertService.shared.configuration)
    }

    var body: some View {
        Form {
            Section {
                Toggle("Enable Sound Alerts", isOn: $config.isEnabled)
                    .onChange(of: config.isEnabled) { _, newValue in
                        service.setEnabled(newValue)
                    }

                HStack {
                    Text("Volume")
                    Slider(value: $config.volume, in: 0...1)
                        .onChange(of: config.volume) { _, newValue in
                            service.setVolume(newValue)
                        }
                    Text("\(Int(config.volume * 100))%")
                        .frame(width: 40)
                }
            }

            Section("Alert Sounds") {
                ForEach(AlertType.allCases) { alertType in
                    HStack {
                        Image(systemName: alertType.icon)
                            .frame(width: 24)
                        Text(alertType.rawValue)

                        Spacer()

                        Picker("", selection: Binding(
                            get: { config.sound(for: alertType) },
                            set: { newSound in
                                config.soundMappings[alertType.rawValue] = newSound.rawValue
                                service.setSound(newSound, for: alertType)
                            }
                        )) {
                            ForEach(AlertSound.allCases) { sound in
                                Text(sound.rawValue).tag(sound)
                            }
                        }
                        .frame(width: 120)

                        Button {
                            service.previewSound(config.sound(for: alertType))
                        } label: {
                            Image(systemName: "speaker.wave.2")
                        }
                        .buttonStyle(.plain)
                        .disabled(config.sound(for: alertType) == .none)
                    }
                }
            }

            Section("Quiet Hours") {
                Toggle("Enable Quiet Hours", isOn: $config.quietHoursEnabled)
                    .onChange(of: config.quietHoursEnabled) { _, newValue in
                        service.setQuietHours(enabled: newValue)
                    }

                if config.quietHoursEnabled {
                    HStack {
                        Text("From")
                        Picker("", selection: $config.quietHoursStart) {
                            ForEach(0..<24, id: \.self) { hour in
                                Text(formatHour(hour)).tag(hour)
                            }
                        }
                        .frame(width: 80)
                        .onChange(of: config.quietHoursStart) { _, newValue in
                            service.setQuietHours(enabled: true, start: newValue)
                        }

                        Text("to")

                        Picker("", selection: $config.quietHoursEnd) {
                            ForEach(0..<24, id: \.self) { hour in
                                Text(formatHour(hour)).tag(hour)
                            }
                        }
                        .frame(width: 80)
                        .onChange(of: config.quietHoursEnd) { _, newValue in
                            service.setQuietHours(enabled: true, end: newValue)
                        }
                    }

                    Text("Sounds will be muted during quiet hours")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
    }

    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        let date = Calendar.current.date(from: DateComponents(hour: hour)) ?? Date()
        return formatter.string(from: date)
    }
}
