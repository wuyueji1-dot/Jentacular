//
//  DNSSettingsService.swift
//  Jentacular
//
//  Custom DNS configuration management with preset servers and validation
//

import Foundation
import Network
import Combine

final class DNSSettingsService: ObservableObject {
    static let shared = DNSSettingsService()

    // MARK: - Published
    @Published var customDNSEnabled: Bool = false
    @Published var primaryDNS: String = ""
    @Published var secondaryDNS: String = ""
    @Published var selectedPreset: DNSPreset? = nil

    // MARK: - DNS Preset
    struct DNSPreset: Identifiable, Equatable {
        let id = UUID()
        let name: String
        let primary: String
        let secondary: String
        let provider: String
        let country: String
        let features: [String]
    }

    // MARK: - Presets
    let presets: [DNSPreset] = [
        DNSPreset(
            name: "Cloudflare",
            primary: "1.1.1.1",
            secondary: "1.0.0.1",
            provider: "Cloudflare",
            country: "Global",
            features: ["Fast", "Privacy-focused", "DNSSEC"]
        ),
        DNSPreset(
            name: "Google DNS",
            primary: "8.8.8.8",
            secondary: "8.8.4.4",
            provider: "Google",
            country: "Global",
            features: ["Reliable", "Fast", "DNSSEC"]
        ),
        DNSPreset(
            name: "OpenDNS",
            primary: "208.67.222.222",
            secondary: "208.67.220.220",
            provider: "Cisco",
            country: "Global",
            features: ["Security", "Parental controls", "Phishing protection"]
        ),
        DNSPreset(
            name: "Quad9",
            primary: "9.9.9.9",
            secondary: "149.112.112.112",
            provider: "Quad9",
            country: "Global",
            features: ["Security", "Threat intelligence", "DNSSEC"]
        ),
        DNSPreset(
            name: "AdGuard",
            primary: "94.140.14.14",
            secondary: "94.140.15.15",
            provider: "AdGuard",
            country: "Global",
            features: ["Ad blocking", "Tracking protection", "Family protection"]
        ),
        DNSPreset(
            name: "CleanBrowsing",
            primary: "185.228.168.9",
            secondary: "185.228.169.9",
            provider: "CleanBrowsing",
            country: "Global",
            features: ["Content filtering", "Family safe", "Security"]
        ),
        DNSPreset(
            name: "Yandex DNS",
            primary: "77.88.8.8",
            secondary: "77.88.8.1",
            provider: "Yandex",
            country: "Russia",
            features: ["Fast in CIS", "Reliable", "Basic"]
        ),
        DNSPreset(
            name: "CN2 GIA",
            primary: "119.29.29.29",
            secondary: "182.254.116.116",
            provider: "DNSPod",
            country: "China",
            features: ["Fast in China", "Domestic optimization", "Reliable"]
        )
    ]

    // MARK: - UserDefaults Keys
    private let enabledKey = "jentacular_custom_dns_enabled"
    private let primaryKey = "jentacular_dns_primary"
    private let secondaryKey = "jentacular_dns_secondary"
    private let presetKey = "jentacular_dns_preset_name"

    private init() {
        loadSettings()
    }

    // MARK: - Preset Selection
    func selectPreset(_ preset: DNSPreset) {
        selectedPreset = preset
        primaryDNS = preset.primary
        secondaryDNS = preset.secondary
        customDNSEnabled = true
        saveSettings()
        AppLogger.shared.info(.settings, "DNS preset selected: \(preset.name)")
    }

    func clearPreset() {
        selectedPreset = nil
        primaryDNS = ""
        secondaryDNS = ""
        customDNSEnabled = false
        saveSettings()
    }

    // MARK: - Custom DNS
    func setCustomDNS(primary: String, secondary: String) -> Bool {
        guard isValidIP(primary) else { return false }
        if !secondary.isEmpty && !isValidIP(secondary) { return false }

        primaryDNS = primary
        secondaryDNS = secondary
        selectedPreset = nil
        customDNSEnabled = true
        saveSettings()
        return true
    }

    func toggleCustomDNS(_ enabled: Bool) {
        customDNSEnabled = enabled
        saveSettings()
    }

    // MARK: - Validation
    func isValidIP(_ ip: String) -> Bool {
        let parts = ip.components(separatedBy: ".")
        guard parts.count == 4 else { return false }
        return parts.allSatisfy { part in
            guard let num = Int(part) else { return false }
            return num >= 0 && num <= 255
        }
    }

    func validateDNS(_ ip: String) -> (valid: Bool, message: String) {
        if ip.isEmpty {
            return (false, L("dns_empty"))
        }
        if !isValidIP(ip) {
            return (false, L("dns_invalid"))
        }
        return (true, L("dns_valid"))
    }

    // MARK: - DNS Test
    func testDNSSpeed(_ ip: String) async -> Double? {
        let startTime = Date()
        let connection = NWConnection(host: NWEndpoint.Host(ip), port: 53, using: .udp)

        return await withCheckedContinuation { continuation in
            var didResume = false

            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    connection.cancel()
                    if !didResume {
                        didResume = true
                        continuation.resume(returning: Date().timeIntervalSince(startTime) * 1000)
                    }
                case .failed:
                    connection.cancel()
                    if !didResume {
                        didResume = true
                        continuation.resume(returning: nil)
                    }
                default:
                    break
                }
            }

            DispatchQueue.global().asyncAfter(deadline: .now() + 3.0) {
                if !didResume {
                    connection.cancel()
                    didResume = true
                    continuation.resume(returning: nil)
                }
            }

            connection.start(queue: .global())
        }
    }

    // MARK: - Persistence
    private func saveSettings() {
        UserDefaults.standard.set(customDNSEnabled, forKey: enabledKey)
        UserDefaults.standard.set(primaryDNS, forKey: primaryKey)
        UserDefaults.standard.set(secondaryDNS, forKey: secondaryKey)
        UserDefaults.standard.set(selectedPreset?.name, forKey: presetKey)
    }

    private func loadSettings() {
        customDNSEnabled = UserDefaults.standard.bool(forKey: enabledKey)
        primaryDNS = UserDefaults.standard.string(forKey: primaryKey) ?? ""
        secondaryDNS = UserDefaults.standard.string(forKey: secondaryKey) ?? ""

        if let presetName = UserDefaults.standard.string(forKey: presetKey) {
            selectedPreset = presets.first { $0.name == presetName }
        }
    }

    // MARK: - Current Configuration
    var currentConfigurationDescription: String {
        guard customDNSEnabled else { return L("system_dns") }
        if let preset = selectedPreset {
            return "\(preset.name) (\(preset.primary))"
        }
        return L("custom_dns") + " (\(primaryDNS))"
    }

    var activeDNSServers: [String] {
        guard customDNSEnabled else { return [] }
        var servers: [String] = []
        if !primaryDNS.isEmpty { servers.append(primaryDNS) }
        if !secondaryDNS.isEmpty { servers.append(secondaryDNS) }
        return servers
    }
}
