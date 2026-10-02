//
//  SecurityScoreService.swift
//  Jentacular
//
//  Calculates device security score - 100 when VPN is connected
//

import Foundation
import Combine

final class SecurityScoreService: ObservableObject {
    static let shared = SecurityScoreService()

    // MARK: - Published Properties
    @Published private(set) var securityScore: Int = 0
    @Published private(set) var securityItems: [SecurityItem] = []
    @Published private(set) var isMonitoring: Bool = false

    // MARK: - Private Properties
    private var monitorTimer: Timer?
    private let vpnService = VPNConnectionService.shared
    private var cancellables = Set<AnyCancellable>()

    private init() {
        calculateSecurityScore()
        setupVPNStatusObservation()
    }

    // MARK: - VPN Status Observation
    private func setupVPNStatusObservation() {
        vpnService.$connectionStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.calculateSecurityScore()
            }
            .store(in: &cancellables)
    }

    // MARK: - Calculate Security Score
    func calculateSecurityScore() {
        let vpnActive = vpnService.connectionStatus == .connected

        if vpnActive {
            // When VPN is connected: full 100 score, all items good
            securityScore = 100
            securityItems = [
                SecurityItem(
                    title: L("vpn_tunnel"),
                    description: L("vpn_tunnel_active"),
                    iconName: "lock.shield.fill",
                    iconColor: .green,
                    status: .good
                ),
                SecurityItem(
                    title: L("wifi_security"),
                    description: L("wifi_secure"),
                    iconName: "wifi",
                    iconColor: .green,
                    status: .good
                ),
                SecurityItem(
                    title: L("network_environment"),
                    description: L("trusted_secure_network"),
                    iconName: "network",
                    iconColor: .green,
                    status: .good
                ),
                SecurityItem(
                    title: L("dns_protection"),
                    description: L("dns_requests_protected"),
                    iconName: "dot.radiowaves.left.and.right",
                    iconColor: .green,
                    status: .good
                )
            ]
        } else {
            // When VPN disconnected: medium score with warnings
            var score = 0
            var items: [SecurityItem] = []

            // VPN Tunnel (0 points when disconnected)
            items.append(SecurityItem(
                title: L("vpn_tunnel"),
                description: L("vpn_tunnel_inactive"),
                iconName: "lock.shield",
                iconColor: .red,
                status: .critical
            ))

            // Wi-Fi Security (25 points)
            score += 25
            items.append(SecurityItem(
                title: L("wifi_security"),
                description: L("wifi_secure"),
                iconName: "wifi",
                iconColor: .green,
                status: .good
            ))

            // Network Environment (20 points - public network warning)
            score += 20
            items.append(SecurityItem(
                title: L("network_environment"),
                description: L("trusted_unlimited_network"),
                iconName: "globe",
                iconColor: .green,
                status: .good
            ))

            // DNS Protection (0 points - vulnerable without VPN)
            items.append(SecurityItem(
                title: L("dns_protection"),
                description: L("dns_requests_visible"),
                iconName: "exclamationmark.shield",
                iconColor: .gold,
                status: .warning
            ))

            securityScore = score
            securityItems = items
        }
    }

    // MARK: - Score Level
    var scoreLevel: String {
        switch securityScore {
        case 0...40: return L("score_low")
        case 41...70: return L("score_medium")
        case 71...90: return L("score_good")
        default: return L("score_excellent")
        }
    }

    var scoreColor: ColorTheme {
        switch securityScore {
        case 0...40: return .red
        case 41...70: return .gold
        case 71...90: return .cyan
        default: return .green
        }
    }

    // MARK: - Start/Stop Monitoring
    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        monitorTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.calculateSecurityScore()
        }
    }

    func stopMonitoring() {
        isMonitoring = false
        monitorTimer?.invalidate()
        monitorTimer = nil
    }

    deinit {
        stopMonitoring()
    }
}
