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

    var body: some View {
        NavigationView {
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
                ConnectionHistoryView()
            }
            .sheet(isPresented: $showPrivacyCenter) {
                PrivacyCenterView()
            }
            .sheet(isPresented: $showLanguageSelection) {
                LanguageSelectionView()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    // MARK: - Header Section
    private var headerSection: some View {
        Text("Настройки")
            .font(.system(size: 32, weight: .bold))
            .foregroundColor(.primaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Language Section
    private var languageSection: some View {
        CustomCard {
            VStack(alignment: .leading, spacing: 0) {
                SectionHeader(title: "Язык")

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
                    title: "Автоподключение",
                    description: "Автоматически подключаться в доверенных сетях",
                    isOn: Binding(
                        get: { settingsService.autoConnectEnabled },
                        set: { settingsService.setAutoConnect($0) }
                    )
                )

                Divider()
                    .background(Color.dividerColor)
                    .padding(.vertical, 8)

                ToggleRow(
                    title: "Только Wi-Fi",
                    description: "Отключать VPN в сотовых сетях",
                    isOn: Binding(
                        get: { settingsService.wifiOnlyEnabled },
                        set: { settingsService.setWifiOnly($0) }
                    )
                )
            }
        }
    }

    // MARK: - Notifications Section
    private var notificationsSection: some View {
        CustomCard {
            VStack(alignment: .leading, spacing: 0) {
                SectionHeader(title: "Уведомления")

                ToggleRow(
                    title: "Включить уведомления",
                    description: "Оповещения об изменении статуса подключения",
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
                SectionHeader(title: "Ещё")

                NavigationRow(
                    iconName: "clock.arrow.circlepath",
                    iconColor: .accentBlue,
                    title: "История подключений",
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
                    title: "Центр конфиденциальности",
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
                    title: "Политика конфиденциальности",
                    value: nil
                ) {
                    if let url = URL(string: AppConstants.privacyPolicyURL) {
                        UIApplication.shared.open(url)
                    }
                }
            }
        }
    }

    // MARK: - App Info Section
    private var appInfoSection: some View {
        VStack(spacing: 8) {
            Text("Jentacular vpn")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.secondaryText)

            Text("Версия \(AppConstants.appVersion) (\(AppConstants.buildNumber))")
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
                .navigationTitle("Язык")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Готово") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}
