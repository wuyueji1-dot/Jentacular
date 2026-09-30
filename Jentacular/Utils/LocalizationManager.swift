//
//  LocalizationManager.swift
//  Jentacular
//
//  Manages app language selection and localized string lookup
//

import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case system = "system"
    case english = "en"
    case russian = "ru"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "Системный"
        case .english: return "English"
        case .russian: return "Русский"
        }
    }

    var localeIdentifier: String? {
        switch self {
        case .system: return nil
        case .english: return "en"
        case .russian: return "ru"
        }
    }
}

final class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    @Published private(set) var currentLanguage: AppLanguage = .system

    private init() {
        loadSavedLanguage()
    }

    private func loadSavedLanguage() {
        if let saved = UserDefaults.standard.string(forKey: AppConstants.UserDefaultsKeys.selectedLanguage),
           let language = AppLanguage(rawValue: saved) {
            currentLanguage = language
        }
    }

    func setLanguage(_ language: AppLanguage) {
        currentLanguage = language
        UserDefaults.standard.set(language.rawValue, forKey: AppConstants.UserDefaultsKeys.selectedLanguage)
    }

    func localizedString(for key: String) -> String {
        guard let localeId = currentLanguage.localeIdentifier else {
            return NSLocalizedString(key, comment: "")
        }

        let path = Bundle.main.path(forResource: localeId, ofType: "lproj")
        if let path = path, let bundle = Bundle(path: path) {
            return bundle.localizedString(forKey: key, value: nil, table: nil)
        }
        return NSLocalizedString(key, comment: "")
    }
}

// MARK: - Localized String Keys
enum L10n {
    // Tab bar
    static let homeTab = "home_tab"
    static let shieldTab = "shield_tab"
    static let serversTab = "servers_tab"
    static let analysisTab = "analysis_tab"
    static let settingsTab = "settings_tab"

    // Home
    static let homeTitle = "home_title"
    static let homeSubtitle = "home_subtitle"
    static let connectButton = "connect_button"
    static let disconnectButton = "disconnect_button"
    static let connecting = "connecting"
    static let connected = "connected"
    static let disconnected = "disconnected"
    static let currentServer = "current_server"

    // Shield
    static let shieldTitle = "shield_title"
    static let shieldSubtitle = "shield_subtitle"
    static let securityScore = "security_score"
    static let scoreMedium = "score_medium"
    static let scoreGood = "score_good"
    static let scoreLow = "score_low"
    static let vpnTunnel = "vpn_tunnel"
    static let vpnTunnelInactive = "vpn_tunnel_inactive"
    static let vpnTunnelActive = "vpn_tunnel_active"
    static let wifiSecurity = "wifi_security"
    static let wifiSecure = "wifi_secure"
    static let networkEnvironment = "network_environment"
    static let trustedNetwork = "trusted_network"
    static let dnsProtection = "dns_protection"
    static let dnsVulnerable = "dns_vulnerable"
    static let dnsProtected = "dns_protected"

    // Servers
    static let serversTitle = "servers_title"
    static let serversSubtitle = "servers_subtitle"
    static let searchPlaceholder = "search_placeholder"
    static let sortBy = "sort_by"
    static let sortRecommended = "sort_recommended"
    static let sortLowestPing = "sort_lowest_ping"
    static let sortLowestLoad = "sort_lowest_load"
    static let sortByName = "sort_by_name"
    static let allCountries = "all_countries"
    static let ms = "ms"

    // Analysis
    static let analysisTitle = "analysis_title"
    static let analysisSubtitle = "analysis_subtitle"
    static let networkType = "network_type"
    static let ipStatus = "ip_status"
    static let ipOpen = "ip_open"
    static let ipProtected = "ip_protected"
    static let availability = "availability"
    static let online = "online"
    static let offline = "offline"
    static let throttled = "throttled"
    static let notThrottled = "not_throttled"
    static let latencyTest = "latency_test"
    static let latency = "latency"
    static let jitter = "jitter"
    static let networkStability = "network_stability"

    // Settings
    static let settingsTitle = "settings_title"
    static let languageSection = "language_section"
    static let vpnSection = "vpn_section"
    static let autoConnect = "auto_connect"
    static let autoConnectDesc = "auto_connect_desc"
    static let wifiOnly = "wifi_only"
    static let wifiOnlyDesc = "wifi_only_desc"
    static let notificationsSection = "notifications_section"
    static let enableNotifications = "enable_notifications"
    static let enableNotificationsDesc = "enable_notifications_desc"
    static let moreSection = "more_section"
    static let connectionHistory = "connection_history"
    static let privacyCenter = "privacy_center"
    static let privacyPolicy = "privacy_policy"
    static let aboutApp = "about_app"

    // Connection History
    static let historyTitle = "history_title"
    static let clearHistory = "clear_history"
    static let noHistory = "no_history"
    static let networkWifi = "network_wifi"
    static let networkCellular = "network_cellular"
    static let networkNone = "network_none"

    // Privacy Center
    static let privacyCenterTitle = "privacy_center_title"
    static let privacyByDefault = "privacy_by_default"
    static let privacyDescription = "privacy_description"
    static let noAccount = "no_account"
    static let noAccountDesc = "no_account_desc"
    static let certificateAuth = "certificate_auth"
    static let certificateAuthDesc = "certificate_auth_desc"
    static let localDataStorage = "local_data_storage"
    static let localDataStorageDesc = "local_data_storage_desc"
    static let noTracking = "no_tracking"
    static let noTrackingDesc = "no_tracking_desc"

    // Privacy Consent
    static let privacyConsentTitle = "privacy_consent_title"
    static let privacyConsentGreeting = "privacy_consent_greeting"
    static let privacyConsentIntro = "privacy_consent_intro"
    static let privacyConsentBreakdown = "privacy_consent_breakdown"
    static let privacyEmailOptional = "privacy_email_optional"
    static let privacyEmailOptionalDesc = "privacy_email_optional_desc"
    static let privacyAnonymousData = "privacy_anonymous_data"
    static let privacyAnonymousDataDesc = "privacy_anonymous_data_desc"
    static let privacyNoTracking = "privacy_no_tracking"
    static let privacyFullDetails = "privacy_full_details"
    static let agreeButton = "agree_button"

    // Common
    static let back = "back"
    static let done = "done"
    static let cancel = "cancel"
    static let ok = "ok"
    static let retry = "retry"
}
