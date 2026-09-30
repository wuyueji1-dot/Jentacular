//
//  VPNConnectionService.swift
//  Jentacular
//
//  Manages IKEv2 VPN connection lifecycle using NetworkExtension framework
//

import Foundation
import NetworkExtension
import Combine

final class VPNConnectionService: ObservableObject {
    static let shared = VPNConnectionService()

    // MARK: - Published Properties
    @Published private(set) var connectionStatus: ConnectionStatus = .disconnected
    @Published private(set) var connectedDuration: TimeInterval = 0
    @Published private(set) var lastError: String?
    @Published private(set) var isLoading: Bool = false

    // MARK: - Private Properties
    private var vpnManager: NEVPNManager?
    private var statusObserver: NSObjectProtocol?
    private var durationTimer: Timer?
    private var connectionStartDate: Date?

    // MARK: - Fixed Server Configuration
    private let serverAddress = AppConstants.vpnServerAddress
    private let username = AppConstants.vpnUsername
    private let password = AppConstants.vpnPassword

    private init() {
        setupStatusObserver()
        loadVPNPreferences()
    }

    // MARK: - Status Observer
    private func setupStatusObserver() {
        statusObserver = NotificationCenter.default.addObserver(
            forName: .NEVPNStatusDidChange,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleStatusChange()
        }
    }

    private func handleStatusChange() {
        guard let connection = vpnManager?.connection else { return }

        switch connection.status {
        case .invalid:
            connectionStatus = .disconnected
            stopDurationTimer()
        case .disconnected:
            connectionStatus = .disconnected
            stopDurationTimer()
        case .connecting:
            connectionStatus = .connecting
        case .connected:
            connectionStatus = .connected
            startDurationTimer()
            connectionStartDate = Date()
        case .reasserting:
            connectionStatus = .connecting
        case .disconnecting:
            connectionStatus = .disconnecting
        @unknown default:
            connectionStatus = .disconnected
        }
    }

    // MARK: - Load VPN Preferences
    private func loadVPNPreferences() {
        NEVPNManager.shared().loadFromPreferences { [weak self] error in
            if let error = error {
                self?.lastError = "Failed to load VPN preferences: \(error.localizedDescription)"
                return
            }
            self?.vpnManager = NEVPNManager.shared()
            self?.handleStatusChange()
        }
    }

    // MARK: - Configure IKEv2
    private func configureIKEv2() async throws {
        let manager = NEVPNManager.shared()

        let ikev2Protocol = NEVPNProtocolIKEv2()
        ikev2Protocol.serverAddress = serverAddress
        ikev2Protocol.localIdentifier = username
        ikev2Protocol.remoteIdentifier = serverAddress
        ikev2Protocol.username = username

        // Store password in keychain
        let passwordData = Data(password.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.hitvpn.hitvpn2026.vpn",
            kSecAttrAccount as String: username,
            kSecValueData as String: passwordData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]

        // Delete existing password first
        SecItemDelete(query as CFDictionary)

        // Add new password
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw NSError(domain: "VPNError", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Failed to store VPN password"])
        }

        // Get persistent reference for password
        var persistentRef: AnyObject?
        let persistentQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.hitvpn.hitvpn2026.vpn",
            kSecAttrAccount as String: username,
            kSecReturnPersistentRef as String: true
        ]
        let persistentStatus = SecItemCopyMatching(persistentQuery as CFDictionary, &persistentRef)
        if persistentStatus == errSecSuccess, let ref = persistentRef as? Data {
            ikev2Protocol.passwordReference = ref
        }

        // Configure IKEv2 security parameters
        ikev2Protocol.ikeSecurityAssociationParameters.encryptionAlgorithm = .algorithmAES256GCM
        ikev2Protocol.ikeSecurityAssociationParameters.integrityAlgorithm = .SHA512
        ikev2Protocol.ikeSecurityAssociationParameters.diffieHellmanGroup = .group20
        ikev2Protocol.ikeSecurityAssociationParameters.lifetimeMinutes = 1440

        ikev2Protocol.childSecurityAssociationParameters.encryptionAlgorithm = .algorithmAES256GCM
        ikev2Protocol.childSecurityAssociationParameters.integrityAlgorithm = .SHA256
        ikev2Protocol.childSecurityAssociationParameters.diffieHellmanGroup = .group20
        ikev2Protocol.childSecurityAssociationParameters.lifetimeMinutes = 1440

        // Configure manager
        manager.protocolConfiguration = ikev2Protocol
        manager.localizedDescription = "Jentacular VPN"
        manager.isEnabled = true
        manager.isOnDemandEnabled = false

        // Save preferences
        try await manager.saveToPreferences()
        try await manager.loadFromPreferences()

        vpnManager = manager
    }

    // MARK: - Connect
    func connect() async {
        isLoading = true
        lastError = nil

        do {
            try await configureIKEv2()

            guard let manager = vpnManager else {
                throw NSError(domain: "VPNError", code: -2,
                             userInfo: [NSLocalizedDescriptionKey: "VPN manager not available"])
            }

            try manager.connection.startVPNTunnel()
            connectionStatus = .connecting
        } catch {
            lastError = error.localizedDescription
            connectionStatus = .error
        }

        isLoading = false
    }

    // MARK: - Disconnect
    func disconnect() {
        guard let manager = vpnManager else { return }
        manager.connection.stopVPNTunnel()
        connectionStatus = .disconnecting
        stopDurationTimer()
    }

    // MARK: - Toggle Connection
    func toggleConnection() async {
        switch connectionStatus {
        case .connected, .connecting:
            disconnect()
        case .disconnected, .disconnecting, .error:
            await connect()
        }
    }

    // MARK: - Duration Timer
    private func startDurationTimer() {
        stopDurationTimer()
        connectionStartDate = Date()
        durationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let startDate = self.connectionStartDate else { return }
            self.connectedDuration = Date().timeIntervalSince(startDate)
        }
    }

    private func stopDurationTimer() {
        durationTimer?.invalidate()
        durationTimer = nil
        connectedDuration = 0
    }

    // MARK: - Formatted Duration
    var formattedDuration: String {
        let hours = Int(connectedDuration) / 3600
        let minutes = Int(connectedDuration) / 60 % 60
        let seconds = Int(connectedDuration) % 60
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    // MARK: - Cleanup
    deinit {
        if let observer = statusObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        stopDurationTimer()
    }
}
