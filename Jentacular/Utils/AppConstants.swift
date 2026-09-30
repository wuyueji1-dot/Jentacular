//
//  AppConstants.swift
//  Jentacular
//
//  Application constants and configuration values
//

import Foundation

enum AppConstants {
    // App information
    static let appName = "Jentacular vpn"
    static let bundleIdentifier = "com.hitvpn.hitvpn2026"
    static let appVersion = "1.0"
    static let buildNumber = "1"

    // VPN configuration - Fixed France server
    static let vpnServerAddress = "ikev.gotou.top"
    static let vpnUsername = "iphone"
    static let vpnPassword = "J294urqXB327$"
    static let vpnServerName = "France"
    static let vpnServerCountry = "France"
    static let vpnServerCountryCode = "FR"
    static let vpnServerCity = "Paris"
    static let vpnProtocol = "IKEv2"

    // Privacy policy URL
    static let privacyPolicyURL = "https://privacys.notion.site/Privacy-Policy-38ef2f8ba6f5805f9754ec0d3198d019"

    // UserDefaults keys
    enum UserDefaultsKeys {
        static let hasSeenPrivacyConsent = "has_seen_privacy_consent"
        static let autoConnectEnabled = "auto_connect_enabled"
        static let wifiOnlyEnabled = "wifi_only_enabled"
        static let notificationsEnabled = "notifications_enabled"
        static let selectedLanguage = "selected_language"
        static let connectionHistory = "connection_history"
        static let lastConnectionDate = "last_connection_date"
    }

    // Network timeouts
    static let connectionTimeout: TimeInterval = 30
    static let latencyTestTimeout: TimeInterval = 10
}
