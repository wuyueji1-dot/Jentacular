//
//  NetworkToolsService.swift
//  Jentacular
//
//  Network diagnostic tools: Ping, Traceroute, DNS lookup, Port scan
//

import Foundation
import Network
import Combine

final class NetworkToolsService: ObservableObject {
    static let shared = NetworkToolsService()

    // MARK: - Published
    @Published private(set) var pingResults: [PingResult] = []
    @Published private(set) var dnsResults: [DNSResult] = []
    @Published private(set) var portResults: [PortResult] = []
    @Published private(set) var isRunning = false

    // MARK: - Ping Result
    struct PingResult: Identifiable, Equatable {
        let id = UUID()
        let sequence: Int
        let host: String
        let ipAddress: String
        let time: Double // ms
        let ttl: Int
        let success: Bool
        let errorMessage: String?
    }

    // MARK: - DNS Result
    struct DNSResult: Identifiable, Equatable {
        let id = UUID()
        let host: String
        let ipAddresses: [String]
        let recordType: String
        let resolveTime: Double // ms
        let success: Bool
    }

    // MARK: - Port Result
    struct PortResult: Identifiable, Equatable {
        let id = UUID()
        let port: UInt16
        let serviceName: String
        let isOpen: Bool
        let responseTime: Double // ms
    }

    private init() {}

    // MARK: - Ping
    func ping(host: String, count: Int = 4, timeout: TimeInterval = 2.0) async -> [PingResult] {
        await MainActor.run { isRunning = true }
        defer { Task { @MainActor in isRunning = false } }

        var results: [PingResult] = []

        // Resolve host first
        let ipAddress = await resolveHost(host) ?? host

        for i in 0..<count {
            let startTime = Date()
            let success = await tcpPing(host: ipAddress, port: 80, timeout: timeout)
            let elapsed = Date().timeIntervalSince(startTime) * 1000

            let result = PingResult(
                sequence: i + 1,
                host: host,
                ipAddress: ipAddress,
                time: success ? elapsed : 0,
                ttl: 64,
                success: success,
                errorMessage: success ? nil : "Request timeout"
            )
            results.append(result)

            await MainActor.run {
                self.pingResults.append(result)
            }

            if i < count - 1 {
                try? await Task.sleep(nanoseconds: 500_000_000)
            }
        }

        return results
    }

    func pingStatistics(for results: [PingResult]) -> (min: Double, max: Double, avg: Double, loss: Double) {
        let successful = results.filter { $0.success }
        let times = successful.map { $0.time }

        let min = times.min() ?? 0
        let max = times.max() ?? 0
        let avg = times.isEmpty ? 0 : times.reduce(0, +) / Double(times.count)
        let loss = results.isEmpty ? 0 : Double(results.count - successful.count) / Double(results.count) * 100

        return (min, max, avg, loss)
    }

    // MARK: - DNS Lookup
    func dnsLookup(host: String) async -> DNSResult {
        let startTime = Date()

        let addresses = await resolveHostAll(host)
        let elapsed = Date().timeIntervalSince(startTime) * 1000

        let result = DNSResult(
            host: host,
            ipAddresses: addresses,
            recordType: "A",
            resolveTime: elapsed,
            success: !addresses.isEmpty
        )

        await MainActor.run {
            self.dnsResults.insert(result, at: 0)
            if self.dnsResults.count > 50 {
                self.dnsResults.removeLast()
            }
        }

        return result
    }

    // MARK: - Port Scan
    func portScan(host: String, ports: [UInt16], timeout: TimeInterval = 2.0) async -> [PortResult] {
        await MainActor.run { isRunning = true }
        defer { Task { @MainActor in isRunning = false } }

        var results: [PortResult] = []

        for port in ports {
            let startTime = Date()
            let isOpen = await tcpPing(host: host, port: port, timeout: timeout)
            let elapsed = Date().timeIntervalSince(startTime) * 1000

            let result = PortResult(
                port: port,
                serviceName: serviceName(for: port),
                isOpen: isOpen,
                responseTime: isOpen ? elapsed : 0
            )
            results.append(result)

            await MainActor.run {
                self.portResults.append(result)
            }
        }

        return results
    }

    // MARK: - Common Ports
    static let commonPorts: [(port: UInt16, name: String)] = [
        (21, "FTP"),
        (22, "SSH"),
        (23, "Telnet"),
        (25, "SMTP"),
        (53, "DNS"),
        (80, "HTTP"),
        (110, "POP3"),
        (143, "IMAP"),
        (443, "HTTPS"),
        (465, "SMTPS"),
        (587, "Submission"),
        (993, "IMAPS"),
        (995, "POP3S"),
        (3306, "MySQL"),
        (3389, "RDP"),
        (5432, "PostgreSQL"),
        (6379, "Redis"),
        (8080, "HTTP-Alt"),
        (8443, "HTTPS-Alt")
    ]

    private func serviceName(for port: UInt16) -> String {
        NetworkToolsService.commonPorts.first { $0.port == port }?.name ?? "Unknown"
    }

    // MARK: - TCP Ping (internal)
    private func tcpPing(host: String, port: UInt16, timeout: TimeInterval) async -> Bool {
        let connection = NWConnection(host: NWEndpoint.Host(host), port: NWEndpoint.Port(rawValue: port)!, using: .tcp)

        return await withCheckedContinuation { continuation in
            var didResume = false

            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    connection.cancel()
                    if !didResume {
                        didResume = true
                        continuation.resume(returning: true)
                    }
                case .failed:
                    connection.cancel()
                    if !didResume {
                        didResume = true
                        continuation.resume(returning: false)
                    }
                default:
                    break
                }
            }

            DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
                if !didResume {
                    connection.cancel()
                    didResume = true
                    continuation.resume(returning: false)
                }
            }

            connection.start(queue: .global())
        }
    }

    // MARK: - DNS Resolution
    private func resolveHost(_ host: String) async -> String? {
        await withCheckedContinuation { continuation in
            var hints = addrinfo()
            hints.ai_family = AF_INET
            hints.ai_socktype = SOCK_STREAM

            var result: UnsafeMutablePointer<addrinfo>?
            let status = getaddrinfo(host, nil, &hints, &result)

            guard status == 0, let first = result else {
                continuation.resume(returning: nil)
                return
            }

            defer { freeaddrinfo(result) }

            let hostname = UnsafeMutablePointer<CChar>.allocate(capacity: Int(NI_MAXHOST))
            defer { hostname.deallocate() }

            if getnameinfo(first.pointee.ai_addr, socklen_t(first.pointee.ai_addrlen), hostname, socklen_t(NI_MAXHOST), nil, 0, NI_NUMERICHOST) == 0 {
                continuation.resume(returning: String(cString: hostname))
            } else {
                continuation.resume(returning: nil)
            }
        }
    }

    private func resolveHostAll(_ host: String) async -> [String] {
        await withCheckedContinuation { continuation in
            var hints = addrinfo()
            hints.ai_family = AF_UNSPEC
            hints.ai_socktype = SOCK_STREAM

            var result: UnsafeMutablePointer<addrinfo>?
            let status = getaddrinfo(host, nil, &hints, &result)

            guard status == 0, let first = result else {
                continuation.resume(returning: [])
                return
            }

            defer { freeaddrinfo(result) }

            var addresses: [String] = []
            var current = first
            while true {
                let hostname = UnsafeMutablePointer<CChar>.allocate(capacity: Int(NI_MAXHOST))
                defer { hostname.deallocate() }

                if getnameinfo(current.pointee.ai_addr, socklen_t(current.pointee.ai_addrlen), hostname, socklen_t(NI_MAXHOST), nil, 0, NI_NUMERICHOST) == 0 {
                    let addr = String(cString: hostname)
                    if !addresses.contains(addr) {
                        addresses.append(addr)
                    }
                }

                if let next = current.pointee.ai_next {
                    current = next
                } else {
                    break
                }
            }

            continuation.resume(returning: addresses)
        }
    }

    // MARK: - Clear Results
    func clearPingResults() {
        pingResults.removeAll()
    }

    func clearDNSResults() {
        dnsResults.removeAll()
    }

    func clearPortResults() {
        portResults.removeAll()
    }
}
