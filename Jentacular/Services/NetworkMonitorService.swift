//
//  NetworkMonitorService.swift
//  Jentacular
//
//  Real-time network status monitoring using NWPathMonitor
//  Tracks connection type, interface changes, and VPN tunnel status
//

import Foundation
import Network
import Combine

final class NetworkMonitorService: ObservableObject {
    static let shared = NetworkMonitorService()

    // MARK: - Published Properties
    @Published private(set) var isConnected: Bool = false
    @Published private(set) var connectionType: ConnectionType = .unknown
    @Published private(set) var isExpensive: Bool = false
    @Published private(set) var isConstrained: Bool = false
    @Published private(set) var activeInterfaces: [NWInterface.InterfaceType] = []
    @Published private(set) var vpnTunnelActive: Bool = false
    @Published private(set) var lastStatusChange: Date = Date()

    // MARK: - Connection Type
    enum ConnectionType: String, CaseIterable {
        case wifi = "Wi-Fi"
        case cellular = "Cellular"
        case wiredEthernet = "Ethernet"
        case loopback = "Loopback"
        case other = "Other"
        case unknown = "Unknown"
        case none = "None"
    }

    // MARK: - Private
    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.jentacular.networkmonitor", qos: .utility)
    private var isMonitoring = false
    private var cancellables = Set<AnyCancellable>()

    private init() {}

    // MARK: - Start/Stop Monitoring
    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true

        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.handlePathUpdate(path)
            }
        }

        monitor.start(queue: monitorQueue)
        AppLogger.shared.info(.network, "Network monitoring started")
    }

    func stopMonitoring() {
        guard isMonitoring else { return }
        isMonitoring = false
        monitor.cancel()
        AppLogger.shared.info(.network, "Network monitoring stopped")
    }

    // MARK: - Path Update Handler
    private func handlePathUpdate(_ path: NWPath) {
        let wasConnected = isConnected
        isConnected = path.status == .satisfied
        isExpensive = path.isExpensive
        isConstrained = path.isConstrained

        // Determine connection type
        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .wiredEthernet
        } else if path.usesInterfaceType(.loopback) {
            connectionType = .loopback
        } else if path.status == .satisfied {
            connectionType = .other
        } else {
            connectionType = .none
        }

        // Collect active interfaces
        activeInterfaces = path.availableInterfaces.map { $0.type }

        // Check for VPN tunnel (utun interface)
        vpnTunnelActive = path.availableInterfaces.contains { interface in
            interface.type == .other && interface.name.hasPrefix("utun")
        }

        if wasConnected != isConnected {
            lastStatusChange = Date()
            AppLogger.shared.info(.network, "Network status changed: \(wasConnected ? "connected" : "disconnected") -> \(isConnected ? "connected" : "disconnected")")
        }
    }

    // MARK: - Convenience Properties
    var isOnWifi: Bool {
        connectionType == .wifi
    }

    var isOnCellular: Bool {
        connectionType == .cellular
    }

    var connectionDescription: String {
        guard isConnected else { return L("no_connection") }
        return connectionType.rawValue
    }

    var connectionIcon: String {
        switch connectionType {
        case .wifi: return "wifi"
        case .cellular: return "antenna.radiowaves.left.and.right"
        case .wiredEthernet: return "cable.connector"
        case .loopback: return "arrow.triangle.2.circlepath"
        case .other: return "network"
        case .unknown: return "questionmark.circle"
        case .none: return "wifi.slash"
        }
    }

    // MARK: - Reachability Test
    func testReachability(host: String = "8.8.8.8", port: UInt16 = 53, timeout: TimeInterval = 5.0) async -> Bool {
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
    func resolveDNS(host: String) async -> [String] {
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
                let addr = current.pointee.ai_addr
                let hostname = UnsafeMutablePointer<CChar>.allocate(capacity: Int(NI_MAXHOST))
                defer { hostname.deallocate() }

                if getnameinfo(addr, socklen_t(current.pointee.ai_addrlen), hostname, socklen_t(NI_MAXHOST), nil, 0, NI_NUMERICHOST) == 0 {
                    addresses.append(String(cString: hostname))
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

    deinit {
        stopMonitoring()
    }
}
