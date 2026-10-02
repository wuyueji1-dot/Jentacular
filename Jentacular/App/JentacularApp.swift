//
//  JentacularApp.swift
//  Jentacular
//
//  Application entry point with dependency injection
//

import SwiftUI

@main
struct JentacularApp: App {
    // MARK: - Services
    @StateObject private var vpnService = VPNConnectionService.shared
    @StateObject private var securityService = SecurityScoreService.shared
    @StateObject private var analysisService = NetworkAnalysisService.shared
    @StateObject private var settingsService = SettingsService.shared
    @StateObject private var historyService = ConnectionHistoryService.shared
    @StateObject private var localizationManager = LocalizationManager.shared
    @StateObject private var pingService = PingService.shared
    @StateObject private var cacheService = DataCacheService.shared
    @StateObject private var networkMonitor = NetworkMonitorService.shared
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var networkToolsService = NetworkToolsService.shared
    @StateObject private var dnsSettingsService = DNSSettingsService.shared

    // MARK: - State
    @State private var showPrivacyConsent = false
    @State private var languageRefresh = 0

    init() {
        // Check if privacy consent has been shown
        if !UserDefaults.standard.bool(forKey: AppConstants.UserDefaultsKeys.hasSeenPrivacyConsent) {
            _showPrivacyConsent = State(initialValue: true)
        }

        // Start network monitoring
        NetworkMonitorService.shared.startMonitoring()

        // Log app launch
        AppLogger.shared.info(.lifecycle, "App launched - version \(AppConstants.appVersion) build \(DeviceInfo.appBuildNumber)")

        // Configure global appearance
        configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if showPrivacyConsent {
                    PrivacyConsentView {
                        UserDefaults.standard.set(true, forKey: AppConstants.UserDefaultsKeys.hasSeenPrivacyConsent)
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showPrivacyConsent = false
                        }
                        // Auto-connect after consent if enabled
                        let autoConnect = UserDefaults.standard.bool(forKey: AppConstants.UserDefaultsKeys.autoConnectEnabled)
                        if autoConnect {
                            Task {
                                await VPNConnectionService.shared.connect()
                            }
                        }
                    }
                    .transition(.opacity)
                    .zIndex(1)
                } else {
                    RootTabView()
                        .id(languageRefresh)
                        .environmentObject(vpnService)
                        .environmentObject(securityService)
                        .environmentObject(analysisService)
                        .environmentObject(settingsService)
                        .environmentObject(historyService)
                        .environmentObject(localizationManager)
                        .environmentObject(pingService)
                        .environmentObject(cacheService)
                        .environmentObject(networkMonitor)
                        .environmentObject(themeManager)
                        .environmentObject(networkToolsService)
                        .environmentObject(dnsSettingsService)
                        .preferredColorScheme(.dark)
                        .onReceive(NotificationCenter.default.publisher(for: .appLanguageDidChange)) { _ in
                            languageRefresh += 1
                        }
                        .onAppear {
                            // Auto-connect if enabled and privacy consent already given
                            let hasConsent = UserDefaults.standard.bool(forKey: AppConstants.UserDefaultsKeys.hasSeenPrivacyConsent)
                            let autoConnect = UserDefaults.standard.bool(forKey: AppConstants.UserDefaultsKeys.autoConnectEnabled)
                            if hasConsent && autoConnect {
                                Task {
                                    await VPNConnectionService.shared.connect()
                                }
                            }
                        }
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: showPrivacyConsent)
        }
    }

    // MARK: - Appearance Configuration
    private func configureAppearance() {
        // Configure tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(red: 0.06, green: 0.07, blue: 0.11, alpha: 1.0)
        tabBarAppearance.selectionIndicatorTintColor = .clear
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        UITabBar.appearance().isTranslucent = false
        UITabBar.appearance().tintColor = UIColor(red: 0.35, green: 0.55, blue: 0.95, alpha: 1.0)

        // Configure navigation bar appearance
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = UIColor(red: 0.04, green: 0.05, blue: 0.09, alpha: 1.0)
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
    }
}
