//
//  VPNConnectionService.swift
//  Jentacular
//
//  Manages IKEv2 VPN connection lifecycle with file-based debug logging
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
    @Published var diagnosticLog: [String] = []

    // MARK: - Private Properties
    private let manager = NEVPNManager.shared()
    private var statusObserver: NSObjectProtocol?
    private var durationTimer: Timer?
    private var connectionStartDate: Date?
    private let logFileURL: URL

    // MARK: - Fixed Server Configuration
    private let serverAddress = AppConstants.vpnServerAddress
    private let username = AppConstants.vpnUsername
    private let password = AppConstants.vpnPassword

    private init() {
        // Setup file logging
        let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        logFileURL = docsDir.appendingPathComponent("vpn_debug.log")
        // Clear old log
        try? "=== VPN Debug Log - \(Date()) ===\n".write(to: logFileURL, atomically: true, encoding: .utf8)

        log("Service initialized, server=\(serverAddress), username=\(username), passwordLength=\(password.count)")
        setupStatusObserver()
        loadExistingConfiguration()
    }

    // MARK: - Logging (file + in-memory for UI display)
    private func log(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let line = "[\(timestamp)] \(message)"
        // Add to in-memory array for UI display
        DispatchQueue.main.async {
            self.diagnosticLog.append(line)
            // Keep last 100 lines
            if self.diagnosticLog.count > 100 {
                self.diagnosticLog.removeFirst(self.diagnosticLog.count - 100)
            }
        }
        // Write to file
        if let handle = try? FileHandle(forWritingTo: logFileURL) {
            handle.seekToEndOfFile()
            handle.write((line + "\n").data(using: .utf8)!)
            try? handle.close()
        }
        print("JentacularVPN: \(message)")
    }

    // MARK: - Status Observer
    private func setupStatusObserver() {
        statusObserver = NotificationCenter.default.addObserver(
            forName: .NEVPNStatusDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleStatusChange()
        }
    }

    private func handleStatusChange() {
        let connection = manager.connection
        log("[handleStatusChange] VPN status changed to: \(statusDescription(connection.status))")

        switch connection.status {
        case .invalid:
            if connectionStatus == .connected {
                ConnectionHistoryService.shared.endSession(
                    serverName: AppConstants.vpnServerName,
                    serverCountry: AppConstants.vpnServerCountry,
                    successful: true,
                    avgPing: PingService.shared.lastPingMs
                )
            }
            connectionStatus = .disconnected
            stopDurationTimer()
        case .disconnected:
            if connectionStatus == .connected {
                ConnectionHistoryService.shared.endSession(
                    serverName: AppConstants.vpnServerName,
                    serverCountry: AppConstants.vpnServerCountry,
                    successful: true,
                    avgPing: PingService.shared.lastPingMs
                )
            }
            connectionStatus = .disconnected
            stopDurationTimer()
        case .connecting:
            connectionStatus = .connecting
        case .connected:
            log("[handleStatusChange] *** VPN CONNECTED SUCCESSFULLY! ***")
            connectionStatus = .connected
            startDurationTimer()
            connectionStartDate = Date()
            ConnectionHistoryService.shared.startSession(
                serverName: AppConstants.vpnServerName,
                serverCountry: AppConstants.vpnServerCountry
            )
        case .reasserting:
            connectionStatus = .connecting
        case .disconnecting:
            connectionStatus = .disconnecting
        @unknown default:
            connectionStatus = .disconnected
        }
    }

    private func statusDescription(_ status: NEVPNStatus) -> String {
        switch status {
        case .invalid: return "invalid"
        case .disconnected: return "disconnected"
        case .connecting: return "connecting"
        case .connected: return "connected"
        case .reasserting: return "reasserting"
        case .disconnecting: return "disconnecting"
        @unknown default: return "unknown"
        }
    }

    // MARK: - Load Existing Configuration
    private func loadExistingConfiguration() {
        log("[loadExistingConfiguration] Calling loadFromPreferences...")
        manager.loadFromPreferences { [weak self] error in
            if let error = error {
                let nsError = error as NSError
                self?.log("[loadExistingConfiguration] FAILED: domain=\(nsError.domain), code=\(nsError.code), desc=\(nsError.localizedDescription)")
                DispatchQueue.main.async {
                    self?.lastError = "Load failed: \(error.localizedDescription)"
                }
                return
            }
            guard let self = self else { return }
            let hasConfig = self.manager.protocolConfiguration != nil
            let isEnabled = self.manager.isEnabled
            self.log("[loadExistingConfiguration] SUCCESS: hasConfig=\(hasConfig), isEnabled=\(isEnabled)")
            DispatchQueue.main.async {
                self.handleStatusChange()
            }
        }
    }

    // MARK: - Build IKEv2 Protocol (with EAP - useExtendedAuthentication is REQUIRED)
    private func buildIKEv2Protocol() -> NEVPNProtocolIKEv2 {
        log("[buildIKEv2Protocol] Building IKEv2 with EAP...")
        let proto = NEVPNProtocolIKEv2()

        // Server
        proto.serverAddress = serverAddress
        proto.remoteIdentifier = serverAddress
        log("[buildIKEv2Protocol] server=\(serverAddress), remoteId=\(serverAddress)")

        // EAP authentication - useExtendedAuthentication MUST be true for EAP
        proto.useExtendedAuthentication = true
        proto.authenticationMethod = .none
        proto.username = username
        log("[buildIKEv2Protocol] EAP enabled: useExtendedAuth=true, authMethod=.none, user=\(username)")

        // Store password in keychain and get persistent reference
        guard let passwordRef = storePasswordInKeychain() else {
            log("[buildIKEv2Protocol] FATAL: passwordReference is nil!")
            DispatchQueue.main.async {
                self.lastError = "Keychain failed"
            }
            return proto
        }
        proto.passwordReference = passwordRef
        log("[buildIKEv2Protocol] passwordReference set: \(passwordRef.count) bytes")

        // Basic settings
        proto.disconnectOnSleep = false
        proto.enablePFS = false
        proto.enableRevocationCheck = false

        log("[buildIKEv2Protocol] VERIFY: server=\(proto.serverAddress ?? "nil"), user=\(proto.username ?? "nil"), hasPassRef=\(proto.passwordReference != nil), useExtAuth=\(proto.useExtendedAuthentication), authMethod=\(proto.authenticationMethod.rawValue)")
        log("[buildIKEv2Protocol] DONE")
        return proto
    }

    // MARK: - Keychain Password Storage (using kSecClassGenericPassword as per Apple docs)
    private func storePasswordInKeychain() -> Data? {
        log("[storePasswordInKeychain] Starting with kSecClassGenericPassword...")
        let passwordData = Data(password.utf8)
        let service = "com.hitvpn.hitvpn2026.vpn.password"
        log("[storePasswordInKeychain] service=\(service), account=\(username), passwordLength=\(passwordData.count)")

        // Delete existing (both generic and internet password)
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: username
        ]
        let deleteStatus = SecItemDelete(deleteQuery as CFDictionary)
        log("[storePasswordInKeychain] SecItemDelete (generic) status=\(deleteStatus) (0=ok, -25300=notFound)")

        // Also delete old internet password if exists
        let deleteInternetQuery: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrServer as String: serverAddress,
            kSecAttrAccount as String: username
        ]
        SecItemDelete(deleteInternetQuery as CFDictionary)

        // Add new as Generic Password (this is what works with NEVPNProtocolIKEv2)
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: username,
            kSecValueData as String: passwordData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        log("[storePasswordInKeychain] SecItemAdd (generic) status=\(addStatus) (0=success)")
        guard addStatus == errSecSuccess else {
            log("[storePasswordInKeychain] SecItemAdd FAILED! code=\(addStatus)")
            lastError = "Keychain add failed (code \(addStatus))"
            return nil
        }
        log("[storePasswordInKeychain] Generic password stored successfully")

        // Get persistent reference
        var ref: AnyObject?
        let copyQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: username,
            kSecReturnPersistentRef as String: true
        ]
        let copyStatus = SecItemCopyMatching(copyQuery as CFDictionary, &ref)
        log("[storePasswordInKeychain] SecItemCopyMatching status=\(copyStatus)")
        guard copyStatus == errSecSuccess, let data = ref as? Data else {
            log("[storePasswordInKeychain] Failed to get persistent reference! copyStatus=\(copyStatus)")
            lastError = "Keychain ref failed (code \(copyStatus))"
            return nil
        }
        log("[storePasswordInKeychain] Got persistent reference, length=\(data.count) bytes")
        return data
    }

    // MARK: - Install VPN Configuration
    private func installConfiguration() async throws {
        log("[installConfiguration] Step 1: loadFromPreferences...")
        do {
            try await manager.loadFromPreferences()
            log("[installConfiguration] Step 1 OK: hasExistingConfig=\(manager.protocolConfiguration != nil)")
        } catch {
            let nsError = error as NSError
            log("[installConfiguration] Step 1 FAILED: domain=\(nsError.domain), code=\(nsError.code), desc=\(nsError.localizedDescription)")
            throw error
        }

        log("[installConfiguration] Step 2: buildIKEv2Protocol (with useExtendedAuthentication=true)...")
        let proto = buildIKEv2Protocol()
        manager.protocolConfiguration = proto
        manager.localizedDescription = "Jentacular vpn"
        manager.isEnabled = true
        manager.isOnDemandEnabled = false
        log("[installConfiguration] Step 2 OK: proto configured")

        log("[installConfiguration] Step 3: saveToPreferences (triggers permission prompt)...")
        do {
            try await manager.saveToPreferences()
            log("[installConfiguration] Step 3 OK: saveToPreferences succeeded!")
        } catch {
            let nsError = error as NSError
            log("[installConfiguration] Step 3 FAILED: domain=\(nsError.domain), code=\(nsError.code), desc=\(nsError.localizedDescription), userInfo=\(nsError.userInfo)")
            throw error
        }

        log("[installConfiguration] Step 4: wait 300ms...")
        try await Task.sleep(nanoseconds: 300_000_000)

        log("[installConfiguration] Step 5: reload to verify...")
        do {
            try await manager.loadFromPreferences()
            let proto = manager.protocolConfiguration as? NEVPNProtocolIKEv2
            log("[installConfiguration] Step 5 OK: protoType=\(proto != nil ? "IKEv2" : "nil"), server=\(proto?.serverAddress ?? "nil"), user=\(proto?.username ?? "nil"), hasPassRef=\(proto?.passwordReference != nil), useExtAuth=\(proto?.useExtendedAuthentication ?? false), authMethod=\(proto?.authenticationMethod.rawValue ?? -1)")
        } catch {
            let nsError = error as NSError
            log("[installConfiguration] Step 5 FAILED: domain=\(nsError.domain), code=\(nsError.code)")
            throw error
        }
        log("[installConfiguration] ALL STEPS COMPLETED!")
    }

    // MARK: - Connect
    func connect() async {
        // Concurrency guard: prevent duplicate connection attempts
        if isLoading {
            log("[connect] SKIP: already connecting, ignore duplicate call")
            return
        }

        log("========================================")
        log("[connect] STARTING VPN CONNECTION")
        log("========================================")

        await MainActor.run {
            isLoading = true
            lastError = nil
            connectionStatus = .connecting
        }

        do {
            log("[connect] Phase 1: installConfiguration...")
            try await installConfiguration()
            log("[connect] Phase 1 COMPLETE")

            log("[connect] Phase 2: wait 500ms...")
            try await Task.sleep(nanoseconds: 500_000_000)

            log("[connect] Phase 3: startVPNTunnel...")
            do {
                try manager.connection.startVPNTunnel()
                log("[connect] Phase 3 OK: startVPNTunnel called! Waiting for status change...")
            } catch {
                let nsError = error as NSError
                log("[connect] Phase 3 FAILED: domain=\(nsError.domain), code=\(nsError.code), desc=\(nsError.localizedDescription)")
                throw error
            }

            await MainActor.run {
                connectionStatus = .connecting
            }
        } catch {
            let nsError = error as NSError
            log("========================================")
            log("[connect] CONNECTION FAILED!")
            log("[connect] domain=\(nsError.domain)")
            log("[connect] code=\(nsError.code)")
            log("[connect] desc=\(nsError.localizedDescription)")
            log("[connect] userInfo=\(nsError.userInfo)")
            log("========================================")

            await MainActor.run {
                lastError = error.localizedDescription
                connectionStatus = .error
            }
        }

        await MainActor.run {
            isLoading = false
        }
        log("[connect] connect() returned, status=\(connectionStatus)")
    }

    // MARK: - Disconnect
    func disconnect() {
        log("[disconnect] Stopping VPN tunnel...")
        manager.connection.stopVPNTunnel()
        DispatchQueue.main.async {
            self.connectionStatus = .disconnecting
            self.stopDurationTimer()
        }
    }

    // MARK: - Toggle Connection
    func toggleConnection() async {
        log("[toggleConnection] currentStatus=\(connectionStatus)")
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
