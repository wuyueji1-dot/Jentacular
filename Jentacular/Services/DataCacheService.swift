//
//  DataCacheService.swift
//  Jentacular
//
//  Lightweight in-memory and disk cache for app data with TTL support
//  Original implementation using NSCache + FileManager
//

import Foundation
import Combine

final class DataCacheService: ObservableObject {
    static let shared = DataCacheService()

    // MARK: - Cache Entry
    private struct CacheEntry: Codable {
        let data: Data
        let timestamp: Date
        let ttl: TimeInterval

        var isExpired: Bool {
            Date().timeIntervalSince(timestamp) > ttl
        }
    }

    // MARK: - Published
    @Published private(set) var cacheHitCount: Int = 0
    @Published private(set) var cacheMissCount: Int = 0

    // MARK: - Private
    private let memoryCache = NSCache<NSString, NSData>()
    private let cacheQueue = DispatchQueue(label: "com.jentacular.datacache", qos: .utility)
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let defaultTTL: TimeInterval = 300 // 5 minutes

    private init() {
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = paths[0].appendingPathComponent("JentacularCache", isDirectory: true)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        memoryCache.countLimit = 50
        memoryCache.totalCostLimit = 10 * 1024 * 1024 // 10MB
    }

    // MARK: - Cache Operations
    func set<T: Encodable>(_ value: T, forKey key: String, ttl: TimeInterval? = nil) {
        let effectiveTTL = ttl ?? defaultTTL
        cacheQueue.async { [weak self] in
            guard let self = self else { return }
            do {
                let data = try JSONEncoder().encode(value)
                let entry = CacheEntry(data: data, timestamp: Date(), ttl: effectiveTTL)
                let entryData = try JSONEncoder().encode(entry)

                // Memory cache
                self.memoryCache.setObject(entryData as NSData, forKey: key as NSString)

                // Disk cache
                let fileURL = self.cacheDirectory.appendingPathComponent(self.safeFileName(key))
                try entryData.write(to: fileURL, options: .atomic)
            } catch {
                self.logError("Cache set failed for key: \(key), error: \(error)")
            }
        }
    }

    func get<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        var result: T?

        cacheQueue.sync { [weak self] in
            guard let self = self else { return }

            // Check memory cache first
            if let nsData = self.memoryCache.object(forKey: key as NSString) {
                if let entry = try? JSONDecoder().decode(CacheEntry.self, from: nsData as Data) {
                    if !entry.isExpired {
                        if let value = try? JSONDecoder().decode(T.self, from: entry.data) {
                            self.cacheHitCount += 1
                            result = value
                            return
                        }
                    }
                }
            }

            // Check disk cache
            let fileURL = self.cacheDirectory.appendingPathComponent(self.safeFileName(key))
            guard let entryData = try? Data(contentsOf: fileURL),
                  let entry = try? JSONDecoder().decode(CacheEntry.self, from: entryData) else {
                self.cacheMissCount += 1
                return
            }

            if entry.isExpired {
                try? self.fileManager.removeItem(at: fileURL)
                self.cacheMissCount += 1
                return
            }

            if let value = try? JSONDecoder().decode(T.self, from: entry.data) {
                // Update memory cache
                self.memoryCache.setObject(entryData as NSData, forKey: key as NSString)
                self.cacheHitCount += 1
                result = value
            } else {
                self.cacheMissCount += 1
            }
        }

        return result
    }

    func remove(forKey key: String) {
        cacheQueue.async { [weak self] in
            guard let self = self else { return }
            self.memoryCache.removeObject(forKey: key as NSString)
            let fileURL = self.cacheDirectory.appendingPathComponent(self.safeFileName(key))
            try? self.fileManager.removeItem(at: fileURL)
        }
    }

    func clearAll() {
        cacheQueue.async { [weak self] in
            guard let self = self else { return }
            self.memoryCache.removeAllObjects()
            try? self.fileManager.removeItem(at: self.cacheDirectory)
            try? self.fileManager.createDirectory(at: self.cacheDirectory, withIntermediateDirectories: true)
        }
    }

    func clearExpired() {
        cacheQueue.async { [weak self] in
            guard let self = self else { return }
            guard let files = try? self.fileManager.contentsOfDirectory(
                at: self.cacheDirectory,
                includingPropertiesForKeys: nil
            ) else { return }

            for fileURL in files {
                guard let data = try? Data(contentsOf: fileURL),
                      let entry = try? JSONDecoder().decode(CacheEntry.self, from: data),
                      entry.isExpired else { continue }
                try? self.fileManager.removeItem(at: fileURL)
            }
        }
    }

    // MARK: - Statistics
    var cacheHitRate: Double {
        let total = cacheHitCount + cacheMissCount
        guard total > 0 else { return 0 }
        return Double(cacheHitCount) / Double(total)
    }

    var diskCacheSize: Int64 {
        var totalSize: Int64 = 0
        cacheQueue.sync {
            guard let files = try? fileManager.contentsOfDirectory(
                at: cacheDirectory,
                includingPropertiesForKeys: [.fileSizeKey]
            ) else { return }
            for fileURL in files {
                if let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    totalSize += Int64(size)
                }
            }
        }
        return totalSize
    }

    // MARK: - Helpers
    private func safeFileName(_ key: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_."))
        let safe = key.components(separatedBy: allowed.inverted).joined()
        return safe + ".cache"
    }

    private func logError(_ message: String) {
        AppLogger.shared.log(level: .error, category: .cache, message: message)
    }
}
