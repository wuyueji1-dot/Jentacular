//
//  SpeedTestHistoryService.swift
//  Jentacular
//
//  Speed test history tracking with persistent storage and statistics
//

import Foundation
import Combine

final class SpeedTestHistoryService: ObservableObject {
    static let shared = SpeedTestHistoryService()

    // MARK: - Published
    @Published private(set) var history: [SpeedTestRecord] = []
    @Published private(set) var isRunningTest = false

    // MARK: - Private
    private let userDefaults = UserDefaults.standard
    private let historyKey = "jentacular_speedtest_history"
    private let maxRecords = 100

    private init() {
        loadHistory()
    }

    // MARK: - Speed Test Record
    struct SpeedTestRecord: Identifiable, Codable, Equatable {
        let id: UUID
        let timestamp: Date
        let downloadSpeed: Double // Mbps
        let uploadSpeed: Double // Mbps
        let ping: Int // ms
        let jitter: Double // ms
        let serverName: String
        let networkType: String

        enum CodingKeys: String, CodingKey {
            case id, timestamp, downloadSpeed, uploadSpeed, ping, jitter, serverName, networkType
        }
    }

    // MARK: - History Management
    func addRecord(download: Double, upload: Double, ping: Int, jitter: Double, server: String, network: String) {
        let record = SpeedTestRecord(
            id: UUID(),
            timestamp: Date(),
            downloadSpeed: download,
            uploadSpeed: upload,
            ping: ping,
            jitter: jitter,
            serverName: server,
            networkType: network
        )

        history.insert(record, at: 0)
        if history.count > maxRecords {
            history.removeLast(history.count - maxRecords)
        }
        saveHistory()
    }

    func removeRecord(_ record: SpeedTestRecord) {
        history.removeAll { $0.id == record.id }
        saveHistory()
    }

    func clearHistory() {
        history.removeAll()
        saveHistory()
    }

    // MARK: - Statistics
    var averageDownload: Double {
        guard !history.isEmpty else { return 0 }
        return history.reduce(0) { $0 + $1.downloadSpeed } / Double(history.count)
    }

    var averageUpload: Double {
        guard !history.isEmpty else { return 0 }
        return history.reduce(0) { $0 + $1.uploadSpeed } / Double(history.count)
    }

    var averagePing: Int {
        guard !history.isEmpty else { return 0 }
        return Int(history.reduce(0) { $0 + Double($1.ping) } / Double(history.count))
    }

    var maxDownload: Double {
        history.max(by: { $0.downloadSpeed < $1.downloadSpeed })?.downloadSpeed ?? 0
    }

    var maxUpload: Double {
        history.max(by: { $0.uploadSpeed < $1.uploadSpeed })?.uploadSpeed ?? 0
    }

    var minPing: Int {
        history.min(by: { $0.ping < $1.ping })?.ping ?? 0
    }

    // MARK: - Filtered History
    func history(forLast days: Int) -> [SpeedTestRecord] {
        let cutoff = Date().addingTimeInterval(-Double(days) * 86400)
        return history.filter { $0.timestamp >= cutoff }
    }

    func history(forNetworkType type: String) -> [SpeedTestRecord] {
        history.filter { $0.networkType == type }
    }

    // MARK: - Persistence
    private func saveHistory() {
        do {
            let data = try JSONEncoder().encode(history)
            userDefaults.set(data, forKey: historyKey)
        } catch {
            AppLogger.shared.error(.analytics, "Failed to save speed test history: \(error)")
        }
    }

    private func loadHistory() {
        guard let data = userDefaults.data(forKey: historyKey) else { return }
        do {
            history = try JSONDecoder().decode([SpeedTestRecord].self, from: data)
        } catch {
            AppLogger.shared.error(.analytics, "Failed to load speed test history: \(error)")
        }
    }

    // MARK: - Export
    func exportHistory() -> URL? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        var csvText = "Timestamp,Download(Mbps),Upload(Mbps),Ping(ms),Jitter(ms),Server,Network\n"
        for record in history {
            csvText += "\(formatter.string(from: record.timestamp)),\(record.downloadSpeed),\(record.uploadSpeed),\(record.ping),\(record.jitter),\(record.serverName),\(record.networkType)\n"
        }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("speedtest_history.csv")
        do {
            try csvText.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }
}

// MARK: - Speed Test Simulator (for demo purposes)
extension SpeedTestHistoryService {
    func runSimulatedTest() async -> SpeedTestRecord {
        isRunningTest = true
        defer { isRunningTest = false }

        // Simulate test phases
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second ping phase
        let ping = Int.random(in: 15...80)
        let jitter = Double.random(in: 1...15)

        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds download phase
        let download = Double.random(in: 50...500)

        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds upload phase
        let upload = Double.random(in: 20...200)

        let networkType = "Wi-Fi"
        let server = "France - Paris"

        let record = SpeedTestRecord(
            id: UUID(),
            timestamp: Date(),
            downloadSpeed: download,
            uploadSpeed: upload,
            ping: ping,
            jitter: jitter,
            serverName: server,
            networkType: networkType
        )

        addRecord(
            download: download,
            upload: upload,
            ping: ping,
            jitter: jitter,
            server: server,
            network: networkType
        )

        return record
    }
}
