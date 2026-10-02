//
//  AppLogger.swift
//  Jentacular
//
//  Structured logging system with multiple levels, categories, and file persistence
//  Original ring-buffer implementation with privacy-aware redaction
//

import Foundation
import OSLog

final class AppLogger {
    static let shared = AppLogger()

    // MARK: - Log Level
    enum LogLevel: Int, Comparable, CustomStringConvertible, Codable {
        case debug = 0
        case info = 1
        case warning = 2
        case error = 3
        case critical = 4

        var description: String {
            switch self {
            case .debug: return "DEBUG"
            case .info: return "INFO"
            case .warning: return "WARN"
            case .error: return "ERROR"
            case .critical: return "CRIT"
            }
        }

        var osLogType: OSLogType {
            switch self {
            case .debug: return .debug
            case .info: return .info
            case .warning: return .default
            case .error: return .error
            case .critical: return .fault
            }
        }

        static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    // MARK: - Log Category
    enum LogCategory: String, Codable {
        case vpn = "VPN"
        case ui = "UI"
        case network = "NETWORK"
        case cache = "CACHE"
        case security = "SECURITY"
        case settings = "SETTINGS"
        case lifecycle = "LIFECYCLE"
        case analytics = "ANALYTICS"
        case general = "GENERAL"
    }

    // MARK: - Log Entry
    struct LogEntry: Codable, Identifiable {
        let id: UUID
        let timestamp: Date
        let level: LogLevel
        let category: LogCategory
        let message: String
        let file: String
        let function: String
        let line: Int

        enum CodingKeys: String, CodingKey {
            case id, timestamp, level, category, message, file, function, line
        }
    }

    // MARK: - Configuration
    var minimumLevel: LogLevel = .debug
    var logToFile: Bool = true
    var logToOSLog: Bool = true
    var maxFileSize: Int64 = 2 * 1024 * 1024 // 2MB
    var maxLogEntries: Int = 1000

    // MARK: - Private
    private let osLog = OSLog(subsystem: "com.jentacular.app", category: "AppLogger")
    private let logQueue = DispatchQueue(label: "com.jentacular.logger", qos: .background)
    private var entries: [LogEntry] = []
    private let fileManager = FileManager.default
    private let logDirectory: URL
    private let logFileURL: URL

    private init() {
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        logDirectory = paths[0].appendingPathComponent("Logs", isDirectory: true)
        logFileURL = logDirectory.appendingPathComponent("jentacular.log")
        try? fileManager.createDirectory(at: logDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Public Logging Methods
    func debug(_ category: LogCategory = .general, _ message: String,
               file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .debug, category: category, message: message, file: file, function: function, line: line)
    }

    func info(_ category: LogCategory = .general, _ message: String,
              file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .info, category: category, message: message, file: file, function: function, line: line)
    }

    func warning(_ category: LogCategory = .general, _ message: String,
                 file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .warning, category: category, message: message, file: file, function: function, line: line)
    }

    func error(_ category: LogCategory = .general, _ message: String,
               file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .error, category: category, message: message, file: file, function: function, line: line)
    }

    func critical(_ category: LogCategory = .general, _ message: String,
                  file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .critical, category: category, message: message, file: file, function: function, line: line)
    }

    func log(level: LogLevel, category: LogCategory, message: String,
             file: String = #file, function: String = #function, line: Int = #line) {
        guard level >= minimumLevel else { return }

        let redactedMessage = redactSensitiveData(message)
        let fileName = (file as NSString).lastPathComponent

        let entry = LogEntry(
            id: UUID(),
            timestamp: Date(),
            level: level,
            category: category,
            message: redactedMessage,
            file: fileName,
            function: function,
            line: line
        )

        logQueue.async { [weak self] in
            guard let self = self else { return }

            // Memory storage
            self.entries.append(entry)
            if self.entries.count > self.maxLogEntries {
                self.entries.removeFirst(self.entries.count - self.maxLogEntries)
            }

            // OS Log
            if self.logToOSLog {
                os_log("%{public}@ [%{public}@] %{public}@:%{public}d - %{public}@",
                       log: self.osLog,
                       type: level.osLogType,
                       level.description, category.rawValue, fileName, line, redactedMessage)
            }

            // File Log
            if self.logToFile {
                self.writeToFile(entry)
            }
        }
    }

    // MARK: - File Operations
    private func writeToFile(_ entry: LogEntry) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        let timestamp = dateFormatter.string(from: entry.timestamp)

        let logLine = "\(timestamp) [\(entry.level.description)] [\(entry.category.rawValue)] \(entry.file):\(entry.line) - \(entry.message)\n"

        guard let data = logLine.data(using: .utf8) else { return }

        // Check file size and rotate if needed
        if let attributes = try? fileManager.attributesOfItem(atPath: logFileURL.path),
           let fileSize = attributes[.size] as? Int64,
           fileSize > maxFileSize {
            rotateLogFile()
        }

        if fileManager.fileExists(atPath: logFileURL.path) {
            if let handle = try? FileHandle(forWritingTo: logFileURL) {
                handle.seekToEndOfFile()
                handle.write(data)
                try? handle.close()
            }
        } else {
            try? data.write(to: logFileURL, options: .atomic)
        }
    }

    private func rotateLogFile() {
        let backupURL = logDirectory.appendingPathComponent("jentacular_prev.log")
        try? fileManager.removeItem(at: backupURL)
        try? fileManager.moveItem(at: logFileURL, to: backupURL)
    }

    // MARK: - Privacy Redaction
    private func redactSensitiveData(_ message: String) -> String {
        var result = message
        // Redact IP addresses
        result = result.replacingOccurrences(
            of: "\\b(?:[0-9]{1,3}\\.){3}[0-9]{1,3}\\b",
            with: "[IP_REDACTED]",
            options: .regularExpression
        )
        // Redact emails
        result = result.replacingOccurrences(
            of: "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}",
            with: "[EMAIL_REDACTED]",
            options: .regularExpression
        )
        // Redact passwords
        result = result.replacingOccurrences(
            of: "(password|passwd|pwd|secret|token|api[_-]?key)\\s*[=:]\\s*\\S+",
            with: "$1=[REDACTED]",
            options: [.regularExpression, .caseInsensitive]
        )
        return result
    }

    // MARK: - Log Retrieval
    func getRecentLogs(limit: Int = 100, level: LogLevel? = nil) -> [LogEntry] {
        logQueue.sync {
            var filtered = entries
            if let level = level {
                filtered = filtered.filter { $0.level >= level }
            }
            return Array(filtered.suffix(limit))
        }
    }

    func getLogFileContent() -> String? {
        try? String(contentsOf: logFileURL, encoding: .utf8)
    }

    func clearLogs() {
        logQueue.async { [weak self] in
            guard let self = self else { return }
            self.entries.removeAll()
            try? self.fileManager.removeItem(at: self.logFileURL)
        }
    }

    // MARK: - Export
    func exportLogs() -> URL? {
        let exportURL = logDirectory.appendingPathComponent("jentacular_export.log")
        logQueue.sync {
            if let content = getLogFileContent() {
                try? content.write(to: exportURL, atomically: true, encoding: .utf8)
            }
        }
        return exportURL
    }
}
