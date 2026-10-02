//
//  DateFormatter+Extension.swift
//  Jentacular
//
//  Custom date formatting utilities for connection history and timestamps
//

import Foundation

extension DateFormatter {
    // MARK: - Shared Formatters
    static let connectionHistory: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale.current
        return formatter
    }()

    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter
    }()

    static let shortTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    static let fullTimestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    static let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    static let relativeDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.doesRelativeDateFormatting = true
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

extension Date {
    // MARK: - Formatting
    var formattedForHistory: String {
        DateFormatter.connectionHistory.string(from: self)
    }

    var shortDateString: String {
        DateFormatter.shortDate.string(from: self)
    }

    var shortTimeString: String {
        DateFormatter.shortTime.string(from: self)
    }

    var fullTimestampString: String {
        DateFormatter.fullTimestamp.string(from: self)
    }

    var iso8601String: String {
        DateFormatter.iso8601.string(from: self)
    }

    var relativeString: String {
        DateFormatter.relativeDate.string(from: self)
    }

    // MARK: - Time Ago
    var timeAgoString: String {
        let now = Date()
        let interval = now.timeIntervalSince(self)

        if interval < 60 {
            return L("just_now")
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return String(format: L("minutes_ago"), minutes)
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return String(format: L("hours_ago"), hours)
        } else if interval < 604800 {
            let days = Int(interval / 86400)
            return String(format: L("days_ago"), days)
        } else {
            return shortDateString
        }
    }

    // MARK: - Duration Formatting
    static func formatDuration(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }

    static func formatDurationReadable(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60

        var parts: [String] = []
        if hours > 0 {
            parts.append(String(format: L("hours_short"), hours))
        }
        if minutes > 0 {
            parts.append(String(format: L("minutes_short"), minutes))
        }
        if secs > 0 || parts.isEmpty {
            parts.append(String(format: L("seconds_short"), secs))
        }

        return parts.joined(separator: " ")
    }

    // MARK: - Date Components
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay)!
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    var isThisWeek: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }

    // MARK: - Date Math
    func addingDays(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self)!
    }

    func addingHours(_ hours: Int) -> Date {
        Calendar.current.date(byAdding: .hour, value: hours, to: self)!
    }

    func addingMinutes(_ minutes: Int) -> Date {
        Calendar.current.date(byAdding: .minute, value: minutes, to: self)!
    }

    func daysSince(_ date: Date) -> Int {
        Calendar.current.dateComponents([.day], from: date, to: self).day ?? 0
    }

    // MARK: - Weekday
    var weekdayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: self)
    }

    var shortWeekdayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: self)
    }

    // MARK: - Month
    var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: self)
    }

    var shortMonthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: self)
    }
}

// MARK: - TimeInterval Extension
extension TimeInterval {
    var formattedDuration: String {
        Date.formatDuration(self)
    }

    var readableDuration: String {
        Date.formatDurationReadable(self)
    }

    var milliseconds: Int {
        Int(self * 1000)
    }
}
