//
//  ConnectionHistoryService.swift
//  Jentacular
//
//  Manages VPN connection history recording and persistence
//

import Foundation
import Combine

final class ConnectionHistoryService: ObservableObject {
    static let shared = ConnectionHistoryService()

    // MARK: - Published Properties
    @Published private(set) var history: [ConnectionHistoryEntry] = []

    // MARK: - Private Properties
    private let defaults = UserDefaults.standard
    private let vpnService = VPNConnectionService.shared
    private var cancellables = Set<AnyCancellable>()
    private var currentConnectionStart: Date?

    private init() {
        loadHistory()
        setupVPNStatusObservation()
    }

    // MARK: - VPN Status Observation
    private func setupVPNStatusObservation() {
        vpnService.$connectionStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.handleVPNStatusChange(status)
            }
            .store(in: &cancellables)
    }

    private func handleVPNStatusChange(_ status: ConnectionStatus) {
        switch status {
        case .connected:
            currentConnectionStart = Date()
        case .disconnected:
            if let startDate = currentConnectionStart {
                let duration = Date().timeIntervalSince(startDate)
                addConnectionEntry(duration: duration)
                currentConnectionStart = nil
            }
        default:
            break
        }
    }

    // MARK: - Add Connection Entry
    private func addConnectionEntry(duration: TimeInterval) {
        let entry = ConnectionHistoryEntry(
            id: UUID(),
            serverName: AppConstants.vpnServerName,
            countryCode: AppConstants.vpnServerCountryCode,
            date: Date(),
            duration: duration,
            networkType: currentNetworkType()
        )

        history.insert(entry, at: 0)

        // Keep only last 50 entries
        if history.count > 50 {
            history = Array(history.prefix(50))
        }

        saveHistory()
    }

    private func currentNetworkType() -> NetworkType {
        // In a real implementation, this would use NWPathMonitor
        return .wifi
    }

    // MARK: - Persistence
    private func saveHistory() {
        do {
            let data = try JSONEncoder().encode(history)
            defaults.set(data, forKey: AppConstants.UserDefaultsKeys.connectionHistory)
        } catch {
            print("Failed to save connection history: \(error)")
        }
    }

    private func loadHistory() {
        guard let data = defaults.data(forKey: AppConstants.UserDefaultsKeys.connectionHistory) else {
            history = []
            return
        }

        do {
            history = try JSONDecoder().decode([ConnectionHistoryEntry].self, from: data)
        } catch {
            print("Failed to load connection history: \(error)")
            history = []
        }
    }

    // MARK: - Clear History
    func clearHistory() {
        history.removeAll()
        defaults.removeObject(forKey: AppConstants.UserDefaultsKeys.connectionHistory)
    }

    // MARK: - Statistics
    var totalConnections: Int {
        history.count
    }

    var totalDuration: TimeInterval {
        history.reduce(0) { $0 + $1.duration }
    }

    var formattedTotalDuration: String {
        let hours = Int(totalDuration) / 3600
        let minutes = Int(totalDuration) / 60 % 60
        if hours > 0 {
            return String(format: L("hours_minutes_short"), hours, minutes)
        } else {
            return String(format: L("minutes_short"), minutes)
        }
    }
}
