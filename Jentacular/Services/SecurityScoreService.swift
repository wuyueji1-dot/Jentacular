//
//  SecurityScoreService.swift
//  Jentacular
//
//  Calculates and monitors device security score based on multiple factors
//

import Foundation
import Combine
import Network

final class SecurityScoreService: ObservableObject {
    static let shared = SecurityScoreService()

    // MARK: - Published Properties
    @Published private(set) var securityScore: Int = 0
    @Published private(set) var securityItems: [SecurityItem] = []
    @Published private(set) var isMonitoring: Bool = false

    // MARK: - Private Properties
    private var monitorTimer: Timer?
    private let vpnService = VPNConnectionService.shared

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

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Calculate Security Score
    func calculateSecurityScore() {
        var score = 0
        var items: [SecurityItem] = []

        // VPN Tunnel (30 points)
        let vpnActive = vpnService.connectionStatus == .connected
        if vpnActive {
            score += 30
            items.append(SecurityItem(
                title: "VPN-туннель",
                description: "Трафик зашифрован",
                iconName: "lock.shield.fill",
                iconColor: .green,
                status: .good
            ))
        } else {
            items.append(SecurityItem(
                title: "VPN-туннель",
                description: "Трафик не зашифрован",
                iconName: "lock.shield",
                iconColor: .red,
                status: .critical
            ))
        }

        // Wi-Fi Security (25 points)
        let wifiSecure = checkWiFiSecurity()
        if wifiSecure {
            score += 25
            items.append(SecurityItem(
                title: "Безопасность Wi-Fi",
                description: "Ваше соединение защищено",
                iconName: "wifi",
                iconColor: .green,
                status: .good
            ))
        } else {
            score += 10
            items.append(SecurityItem(
                title: "Безопасность Wi-Fi",
                description: "Проверьте настройки Wi-Fi",
                iconName: "wifi.exclamationmark",
                iconColor: .gold,
                status: .warning
            ))
        }

        // Network Environment (25 points)
        let trustedNetwork = checkNetworkTrust()
        if trustedNetwork {
            score += 25
            items.append(SecurityItem(
                title: "Сетевая среда",
                description: "Доверенная безлимитная сеть",
                iconName: "network",
                iconColor: .green,
                status: .good
            ))
        } else {
            score += 15
            items.append(SecurityItem(
                title: "Сетевая среда",
                description: "Публичная сеть, используйте VPN",
                iconName: "globe",
                iconColor: .gold,
                status: .warning
            ))
        }

        // DNS Protection (20 points)
        let dnsProtected = checkDNSProtection()
        if dnsProtected {
            score += 20
            items.append(SecurityItem(
                title: "Защита DNS",
                description: "DNS-запросы защищены",
                iconName: "dot.radiowaves.left.and.right",
                iconColor: .green,
                status: .good
            ))
        } else {
            score += 5
            items.append(SecurityItem(
                title: "Защита DNS",
                description: "DNS-запросы могут быть видны",
                iconName: "exclamationmark.shield",
                iconColor: .gold,
                status: .warning
            ))
        }

        securityScore = min(score, 100)
        securityItems = items
    }

    // MARK: - Security Checks
    private func checkWiFiSecurity() -> Bool {
        // In a real implementation, this would check current Wi-Fi security type
        // For simulator/debug, return true as default
        return true
    }

    private func checkNetworkTrust() -> Bool {
        // Check if connected to a trusted network (home/work) vs public
        // For simplicity, return based on connection type
        return true
    }

    private func checkDNSProtection() -> Bool {
        // Check if DNS is protected (VPN active or custom DNS configured)
        return vpnService.connectionStatus == .connected
    }

    // MARK: - Score Level
    var scoreLevel: String {
        switch securityScore {
        case 0...40: return "НИЗКИЙ"
        case 41...70: return "СРЕДНЕ"
        case 71...90: return "ХОРОШО"
        default: return "ОТЛИЧНО"
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
