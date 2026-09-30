//
//  AppModels.swift
//  Jentacular
//
//  Data models for VPN servers, connection history, and security metrics
//

import Foundation

// MARK: - VPN Server
struct VPNServerNode: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let country: String
    let countryCode: String
    let city: String
    let ipAddress: String
    let pingMs: Int
    let loadPercent: Int
    let isSelected: Bool

    var flagEmoji: String {
        Self.flagEmoji(for: countryCode)
    }

    static func flagEmoji(for countryCode: String) -> String {
        let base: UInt32 = 127397
        var s = ""
        for v in countryCode.uppercased().unicodeScalars {
            s.unicodeScalars.append(UnicodeScalar(base + v.value)!)
        }
        return s
    }
}

// MARK: - Connection Status
enum ConnectionStatus: String, Codable {
    case disconnected
    case connecting
    case connected
    case disconnecting
    case error

    var displayName: String {
        switch self {
        case .disconnected: return "disconnected"
        case .connecting: return "connecting"
        case .connected: return "connected"
        case .disconnecting: return "disconnecting"
        case .error: return "error"
        }
    }
}

// MARK: - Connection History Entry
struct ConnectionHistoryEntry: Identifiable, Hashable, Codable {
    let id: UUID
    let serverName: String
    let countryCode: String
    let date: Date
    let duration: TimeInterval
    let networkType: NetworkType

    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        let seconds = Int(duration) % 60
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy, HH:mm"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: date)
    }
}

enum NetworkType: String, Codable, CaseIterable {
    case wifi
    case cellular
    case none

    var displayName: String {
        switch self {
        case .wifi: return "Wi-Fi"
        case .cellular: return "Cellular"
        case .none: return "No network"
        }
    }
}

// MARK: - Security Score Enums
enum SecurityStatus {
    case good
    case warning
    case critical
    case neutral
}

enum ColorTheme {
    case red
    case green
    case gold
    case blue
    case purple
    case cyan
}

// MARK: - Security Score Item
struct SecurityItem: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let description: String
    let iconName: String
    let iconColor: ColorTheme
    let status: SecurityStatus
}

// MARK: - Network Analysis Metrics
struct NetworkMetrics {
    var networkType: String
    var ipStatus: IPStatus
    var availability: AvailabilityStatus
    var throttling: ThrottlingStatus
    var latencyMs: Int
    var jitterMs: Int
    var stabilityPercent: Int

    enum IPStatus: String {
        case open
        case protected
    }

    enum AvailabilityStatus: String {
        case online
        case offline
    }

    enum ThrottlingStatus: String {
        case throttled
        case notThrottled
    }
}

// MARK: - Server Sort Option
enum ServerSortOption: String, CaseIterable, Identifiable {
    case recommended
    case lowestPing
    case lowestLoad
    case name

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .recommended: return "Recommended"
        case .lowestPing: return "Lowest ping"
        case .lowestLoad: return "Lowest load"
        case .name: return "Name"
        }
    }
}
