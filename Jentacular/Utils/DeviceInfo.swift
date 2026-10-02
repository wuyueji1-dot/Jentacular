//
//  DeviceInfo.swift
//  Jentacular
//
//  Device information utilities for analytics and diagnostics
//

import Foundation
import UIKit

struct DeviceInfo {
    // MARK: - Device Model
    static var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return mapDeviceIdentifier(identifier)
    }

    static var modelIdentifier: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        return machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
    }

    // MARK: - System Version
    static var systemVersion: String {
        UIDevice.current.systemVersion
    }

    static var systemName: String {
        UIDevice.current.systemName
    }

    static var iOSVersionMajor: Int {
        Int(UIDevice.current.systemVersion.components(separatedBy: ".").first ?? "0") ?? 0
    }

    // MARK: - Screen
    static var screenSize: CGSize {
        UIScreen.main.bounds.size
    }

    static var screenWidth: CGFloat {
        UIScreen.main.bounds.width
    }

    static var screenHeight: CGFloat {
        UIScreen.main.bounds.height
    }

    static var screenScale: CGFloat {
        UIScreen.main.scale
    }

    static var screenBrightness: CGFloat {
        UIScreen.main.brightness
    }

    static var isSmallScreen: Bool {
        screenHeight <= 667
    }

    static var isLargeScreen: Bool {
        screenHeight >= 896
    }

    static var hasNotch: Bool {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return screenHeight >= 812
        }
        return window.safeAreaInsets.bottom > 0
    }

    static var safeAreaInsets: UIEdgeInsets {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return .zero
        }
        return window.safeAreaInsets
    }

    // MARK: - Device Type
    static var isPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }

    static var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    static var isMac: Bool {
        if #available(iOS 14.0, *) {
            return ProcessInfo.processInfo.isiOSAppOnMac
        }
        return false
    }

    // MARK: - Orientation
    static var isPortrait: Bool {
        UIDevice.current.orientation.isPortrait ||
        UIDevice.current.orientation == .unknown
    }

    static var isLandscape: Bool {
        UIDevice.current.orientation.isLandscape
    }

    // MARK: - Battery
    static var batteryLevel: Float {
        UIDevice.current.isBatteryMonitoringEnabled = true
        return UIDevice.current.batteryLevel
    }

    static var isCharging: Bool {
        UIDevice.current.isBatteryMonitoringEnabled = true
        return UIDevice.current.batteryState == .charging
    }

    static var batteryState: UIDevice.BatteryState {
        UIDevice.current.isBatteryMonitoringEnabled = true
        return UIDevice.current.batteryState
    }

    // MARK: - Storage
    static var totalDiskSpace: Int64 {
        guard let attributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
              let totalSize = attributes[.systemSize] as? Int64 else {
            return 0
        }
        return totalSize
    }

    static var freeDiskSpace: Int64 {
        guard let attributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
              let freeSize = attributes[.systemFreeSize] as? Int64 else {
            return 0
        }
        return freeSize
    }

    static var usedDiskSpace: Int64 {
        totalDiskSpace - freeDiskSpace
    }

    static var freeDiskSpacePercentage: Double {
        guard totalDiskSpace > 0 else { return 0 }
        return Double(freeDiskSpace) / Double(totalDiskSpace) * 100
    }

    // MARK: - Memory
    static var totalMemory: UInt64 {
        ProcessInfo.processInfo.physicalMemory
    }

    static var usedMemory: UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        if kerr == KERN_SUCCESS {
            return info.resident_size
        }
        return 0
    }

    static var memoryUsagePercentage: Double {
        guard totalMemory > 0 else { return 0 }
        return Double(usedMemory) / Double(totalMemory) * 100
    }

    // MARK: - CPU
    static var processorCount: Int {
        ProcessInfo.processInfo.processorCount
    }

    static var activeProcessorCount: Int {
        ProcessInfo.processInfo.activeProcessorCount
    }

    // MARK: - App Info
    static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    static var appBuildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }

    static var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "Unknown"
    }

    static var appName: String {
        Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ??
        Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "Jentacular"
    }

    // MARK: - Locale
    static var currentLanguage: String {
        Locale.current.languageCode ?? "en"
    }

    static var currentRegion: String {
        Locale.current.regionCode ?? "US"
    }

    static var currentLocale: String {
        Locale.current.identifier
    }

    static var is24HourTime: Bool {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        let timeString = formatter.string(from: Date())
        return !timeString.contains("AM") && !timeString.contains("PM")
    }

    // MARK: - Network
    static var isWiFiConnected: Bool {
        // Simplified check - actual check requires NWPathMonitor
        false
    }

    // MARK: - Formatting Helpers
    static func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    static func formatBytes(_ bytes: UInt64) -> String {
        formatBytes(Int64(bytes))
    }

    static func formatPercentage(_ value: Double, decimalPlaces: Int = 1) -> String {
        String(format: "%.\(decimalPlaces)f%%", value)
    }

    // MARK: - Device Identifier Mapping
    private static func mapDeviceIdentifier(_ identifier: String) -> String {
        switch identifier {
        // iPhone
        case "iPhone12,1": return "iPhone 11"
        case "iPhone12,3": return "iPhone 11 Pro"
        case "iPhone12,5": return "iPhone 11 Pro Max"
        case "iPhone13,1": return "iPhone 12 mini"
        case "iPhone13,2": return "iPhone 12"
        case "iPhone13,3": return "iPhone 12 Pro"
        case "iPhone13,4": return "iPhone 12 Pro Max"
        case "iPhone14,4": return "iPhone 13 mini"
        case "iPhone14,5": return "iPhone 13"
        case "iPhone14,2": return "iPhone 13 Pro"
        case "iPhone14,3": return "iPhone 13 Pro Max"
        case "iPhone14,6": return "iPhone SE (3rd gen)"
        case "iPhone14,7": return "iPhone 14"
        case "iPhone14,8": return "iPhone 14 Plus"
        case "iPhone15,2": return "iPhone 14 Pro"
        case "iPhone15,3": return "iPhone 14 Pro Max"
        case "iPhone15,4": return "iPhone 15"
        case "iPhone15,5": return "iPhone 15 Plus"
        case "iPhone16,1": return "iPhone 15 Pro"
        case "iPhone16,2": return "iPhone 15 Pro Max"
        case "iPhone17,1": return "iPhone 16 Pro"
        case "iPhone17,2": return "iPhone 16 Pro Max"
        case "iPhone17,3": return "iPhone 16"
        case "iPhone17,4": return "iPhone 16 Plus"
        // iPad
        case "iPad13,1", "iPad13,2": return "iPad Air (4th gen)"
        case "iPad13,4", "iPad13,5", "iPad13,6", "iPad13,7": return "iPad Pro 11\" (3rd gen)"
        case "iPad13,8", "iPad13,9", "iPad13,10", "iPad13,11": return "iPad Pro 12.9\" (5th gen)"
        case "iPad14,1", "iPad14,2": return "iPad mini (6th gen)"
        case "iPad14,3", "iPad14,4": return "iPad Air (5th gen)"
        case "iPad14,5", "iPad14,6": return "iPad Pro 11\" (4th gen)"
        case "iPad14,7", "iPad14,8": return "iPad Pro 12.9\" (6th gen)"
        // Simulator
        case "i386", "x86_64", "arm64": return "Simulator"
        default: return identifier
        }
    }

    // MARK: - Diagnostic Report
    static func generateDiagnosticReport() -> [String: String] {
        [
            "device_model": modelName,
            "device_identifier": modelIdentifier,
            "system_version": systemVersion,
            "system_name": systemName,
            "screen_size": "\(Int(screenWidth))x\(Int(screenHeight))",
            "screen_scale": "\(screenScale)x",
            "app_version": appVersion,
            "app_build": appBuildNumber,
            "bundle_id": bundleIdentifier,
            "language": currentLanguage,
            "region": currentRegion,
            "locale": currentLocale,
            "free_disk_space": formatBytes(freeDiskSpace),
            "total_disk_space": formatBytes(totalDiskSpace),
            "total_memory": formatBytes(totalMemory),
            "battery_level": "\(Int(batteryLevel * 100))%",
            "is_charging": isCharging ? "Yes" : "No"
        ]
    }
}
