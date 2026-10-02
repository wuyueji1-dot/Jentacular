//
//  PingService.swift
//  Jentacular
//
//  Real-time server latency measurement using TCP handshake with multiple samples
//

import Foundation
import Network
import SwiftUI

final class PingService: ObservableObject {
    static let shared = PingService()

    @Published private(set) var isPinging = false
    @Published private(set) var lastPingMs: Int?

    private init() {}

    // MARK: - Ping Host
    func ping(host: String, timeout: TimeInterval = 8.0) async -> Int? {
        await MainActor.run { isPinging = true }
        defer {
            Task { @MainActor in
                self.isPinging = false
            }
        }

        // Take 3 samples and use median for stability
        var samples: [Int] = []
        for i in 0..<3 {
            // Small delay between samples
            if i > 0 {
                try? await Task.sleep(nanoseconds: 300_000_000)
            }

            // Try HTTP HEAD request first (most accurate real-world latency)
            if let result = await httpPing(host: host, timeout: timeout) {
                samples.append(result)
                continue
            }

            // Fallback: TCP connection to port 443, then 80
            if let result = await tcpPing(host: host, port: 443, timeout: timeout) {
                samples.append(result)
                continue
            }

            if let result = await tcpPing(host: host, port: 80, timeout: timeout) {
                samples.append(result)
                continue
            }
        }

        // If we have samples, use median
        if !samples.isEmpty {
            let sorted = samples.sorted()
            let median = sorted[sorted.count / 2]
            await MainActor.run { self.lastPingMs = median }
            return median
        }

        // Fallback: DNS resolution time as approximate latency
        if let result = await dnsPing(host: host) {
            await MainActor.run { self.lastPingMs = result }
            return result
        }

        return nil
    }

    // MARK: - HTTP Ping (most accurate real-world latency)
    private func httpPing(host: String, timeout: TimeInterval) async -> Int? {
        guard let url = URL(string: "https://\(host)/") else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = timeout
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData

        let startTime = Date()
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            let elapsed = Date().timeIntervalSince(startTime) * 1000
            let pingMs = Int(elapsed.rounded())
            // HTTP HEAD includes full TLS handshake + server response, realistic latency
            if pingMs >= 20 {
                return pingMs
            }
            return nil
        } catch {
            return nil
        }
    }

    // MARK: - TCP Ping
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
                        // Sanity check: discard unrealistic values (< 50ms likely local/CDN cache)
                        if pingMs >= 50 {
                            continuation.resume(returning: pingMs)
                        } else {
                            continuation.resume(returning: nil)
                        }
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

    // MARK: - DNS Ping (fallback)
    private func dnsPing(host: String) async -> Int? {
        let startTime = Date()

        return await withCheckedContinuation { continuation in
            var hints = addrinfo()
            hints.ai_family = AF_INET
            hints.ai_socktype = SOCK_STREAM

            var result: UnsafeMutablePointer<addrinfo>?
            let status = getaddrinfo(host, nil, &hints, &result)

            if status == 0 {
                freeaddrinfo(result)
                let elapsed = Date().timeIntervalSince(startTime) * 1000
                continuation.resume(returning: Int(elapsed.rounded()))
            } else {
                continuation.resume(returning: nil)
            }
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
