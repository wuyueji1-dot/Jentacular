//
//  PingService.swift
//  Jentacular
//
//  Real-time server latency measurement using TCP handshake
//

import Foundation
import Network
import SwiftUI

final class PingService: ObservableObject {
    static let shared = PingService()

    @Published private(set) var isPinging = false
    @Published private(set) var lastPingMs: Int?

    private var autoRefreshTimer: Timer?
    private var currentHost: String?

    private init() {}

    // MARK: - Auto Refresh
    func startAutoRefresh(host: String, interval: TimeInterval = 15.0) {
        stopAutoRefresh()
        currentHost = host
        // Initial ping immediately
        Task { await ping(host: host) }
        autoRefreshTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self, let host = self.currentHost else { return }
            Task { await self.ping(host: host) }
        }
    }

    func stopAutoRefresh() {
        autoRefreshTimer?.invalidate()
        autoRefreshTimer = nil
        currentHost = nil
    }

    // MARK: - Ping Host (single TCP connection to port 443)
    func ping(host: String, timeout: TimeInterval = 3.0) async -> Int? {
        // Skip if already pinging to avoid duplicate measurements
        if isPinging {
            return lastPingMs
        }

        await MainActor.run { isPinging = true }
        defer {
            Task { @MainActor in
                self.isPinging = false
            }
        }

        // Single TCP connection to port 443 - this is the real TCP RTT
        if let result = await tcpPing(host: host, port: 443, timeout: timeout) {
            await MainActor.run { self.lastPingMs = result }
            return result
        }

        // Fallback: TCP port 80
        if let result = await tcpPing(host: host, port: 80, timeout: timeout) {
            await MainActor.run { self.lastPingMs = result }
            return result
        }

        return nil
    }

    // MARK: - TCP Ping (single connection, no filtering)
    private func tcpPing(host: String, port: UInt16, timeout: TimeInterval) async -> Int? {
        let startTime = Date()
        let connection = NWConnection(host: NWEndpoint.Host(host), port: NWEndpoint.Port(rawValue: port)!, using: .tcp)

        return await withCheckedContinuation { continuation in
            var didResume = false

            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    let elapsed = Date().timeIntervalSince(startTime) * 1000
                    let pingMs = Int(elapsed.rounded())
                    connection.cancel()
                    if !didResume {
                        didResume = true
                        // Return real value, no minimum threshold filtering
                        continuation.resume(returning: max(1, pingMs))
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

            // Timeout
            DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
                if !didResume {
                    connection.cancel()
                    didResume = true
                    continuation.resume(returning: nil)
                }
            }

            connection.start(queue: .global())
        }
    }

    // MARK: - Format Ping
    func formattedPing(_ ms: Int?) -> String {
        guard let ms = ms else { return "—" }
        return "\(ms) ms"
    }

    func pingColor(_ ms: Int?) -> Color {
        guard let ms = ms else { return .tertiaryText }
        switch ms {
        case 0...50: return .accentGreen
        case 51...100: return .accentCyan
        case 101...200: return .accentGold
        default: return .accentRed
        }
    }
}
