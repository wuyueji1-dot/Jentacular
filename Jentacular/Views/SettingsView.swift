//
//  SettingsView.swift
//  Jentacular
//
//  App settings with language selection, VPN preferences, notifications, and more
//

import SwiftUI

struct SettingsView: View {
    // MARK: - Environment Objects
    @EnvironmentObject var settingsService: SettingsService
    @EnvironmentObject var historyService: ConnectionHistoryService

    // MARK: - State
    @State private var showConnectionHistory = false
    @State private var showPrivacyCenter = false
    @State private var showLanguageSelection = false
    @State private var showAbout = false
    @State private var showHelp = false
    @State private var showNetworkTools = false
    @State private var showDNSSettings = false
    @State private var showPrivacyPolicy = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerSection

                    // Language section
                    languageSection

                    // VPN section
                    vpnSection

                    // Notifications section
                    notificationsSection

                    // More section
                    moreSection

                    // App info
                    appInfoSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showConnectionHistory) {
            NavigationView { ConnectionHistoryView() }
        }
        .sheet(isPresented: $showPrivacyCenter) {
            NavigationView { PrivacyCenterView() }
        }
        .sheet(isPresented: $showLanguageSelection) {
            NavigationView { LanguageSelectionView() }
        }
        .sheet(isPresented: $showAbout) {
            NavigationView { AboutView() }
        }
        .sheet(isPresented: $showHelp) {
            NavigationView { HelpView() }
        }
        .sheet(isPresented: $showNetworkTools) {
            NavigationView { NetworkToolsView() }
        }
        .sheet(isPresented: $showDNSSettings) {
            NavigationView { DNSSettingsView() }
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            NavigationView { PrivacyPolicyView() }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        Text(L("settings_title"))
            .font(.system(size: 32, weight: .bold))
            .foregroundColor(.primaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Language Section
    private var languageSection: some View {
        CustomCard {
            VStack(alignment: .leading, spacing: 0) {
                SectionHeader(title: L("language"))

                ForEach(AppLanguage.allCases) { language in
                    Button(action: {
                        settingsService.setLanguage(language)
                    }) {
                        HStack {
                            Text(language.displayName)
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.primaryText)

                            Spacer()

                            if settingsService.selectedLanguage == language {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.accentCyan)
                            }
                        }
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(PlainButtonStyle())

                    if language != AppLanguage.allCases.last {
                        Divider()
                            .background(Color.dividerColor)
                    }
                }
            }
        }
    }

    // MARK: - VPN Section
    private var vpnSection: some View {
        CustomCard {
            VStack(alignment: .leading, spacing: 0) {
                SectionHeader(title: "VPN")

                ToggleRow(
                    title: L("auto_connect"),
                    description: L("auto_connect_desc"),
                    isOn: Binding(
                        get: { settingsService.autoConnectEnabled },
                        set: { settingsService.setAutoConnect($0) }
                    )
                )
            }
        }
    }

    // MARK: - Notifications Section
    private var notificationsSection: some View {
        CustomCard {
            VStack(alignment: .leading, spacing: 0) {
                SectionHeader(title: L("notifications"))

                ToggleRow(
                    title: L("enable_notifications"),
                    description: L("enable_notifications_desc"),
                    isOn: Binding(
                        get: { settingsService.notificationsEnabled },
                        set: { settingsService.setNotifications($0) }
                    )
                )
            }
        }
    }

    // MARK: - More Section
    private var moreSection: some View {
        CustomCard {
            VStack(alignment: .leading, spacing: 0) {
                SectionHeader(title: L("more"))

                NavigationRow(
                    iconName: "clock.arrow.circlepath",
                    iconColor: .accentBlue,
                    title: L("connection_history"),
                    value: "\(historyService.totalConnections)"
                ) {
                    showConnectionHistory = true
                }

                Divider()
                    .background(Color.dividerColor)
                    .padding(.vertical, 8)

                NavigationRow(
                    iconName: "hand.raised.fill",
                    iconColor: .accentPurple,
                    title: L("privacy_center"),
                    value: nil
                ) {
                    showPrivacyCenter = true
                }

                Divider()
                    .background(Color.dividerColor)
                    .padding(.vertical, 8)

                NavigationRow(
                    iconName: "doc.text.fill",
                    iconColor: .accentCyan,
                    title: L("privacy_policy"),
                    value: nil
                ) {
                    showPrivacyPolicy = true
                }

                Divider()
                    .background(Color.dividerColor)
                    .padding(.vertical, 8)

                NavigationRow(
                    iconName: "questionmark.circle.fill",
                    iconColor: .accentGold,
                    title: L("help_support"),
                    value: nil
                ) {
                    showHelp = true
                }

                Divider()
                    .background(Color.dividerColor)
                    .padding(.vertical, 8)

                NavigationRow(
                    iconName: "info.circle.fill",
                    iconColor: .accentBlue,
                    title: L("about"),
                    value: AppConstants.appVersion
                ) {
                    showAbout = true
                }

                Divider()
                    .background(Color.dividerColor)
                    .padding(.vertical, 8)

                NavigationRow(
                    iconName: "wifi",
                    iconColor: .accentCyan,
                    title: L("network_tools"),
                    value: nil
                ) {
                    showNetworkTools = true
                }

                Divider()
                    .background(Color.dividerColor)
                    .padding(.vertical, 8)

                NavigationRow(
                    iconName: "globe",
                    iconColor: .accentPurple,
                    title: L("dns_settings"),
                    value: nil
                ) {
                    showDNSSettings = true
                }
            }
        }
    }

    // MARK: - App Info Section
    private var appInfoSection: some View {
        VStack(spacing: 8) {
            Text(L("app_name"))
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.secondaryText)

            Text(String(format: L("version_format"), AppConstants.appVersion, AppConstants.buildNumber))
                .font(.system(size: 14))
                .foregroundColor(.tertiaryText)
        }
        .padding(.top, 20)
    }
}

// MARK: - Language Selection View
struct LanguageSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var settingsService: SettingsService

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                List {
                    ForEach(AppLanguage.allCases) { language in
                        Button(action: {
                            settingsService.setLanguage(language)
                            dismiss()
                        }) {
                            HStack {
                                Text(language.displayName)
                                    .foregroundColor(.primaryText)

                                Spacer()

                                if settingsService.selectedLanguage == language {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentCyan)
                                }
                            }
                        }
                        .listRowBackground(Color.cardBackground)
                    }
                }
                .listStyle(PlainListStyle())
                .navigationTitle(L("language_nav"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(L("done")) {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}
