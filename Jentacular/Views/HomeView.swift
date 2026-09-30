//
//  HomeView.swift
//  Jentacular
//
//  Main home screen with VPN connect button, server info, and connection status
//

import SwiftUI

struct HomeView: View {
    // MARK: - Environment Objects
    @EnvironmentObject var vpnService: VPNConnectionService
    @EnvironmentObject var securityService: SecurityScoreService

    // MARK: - State
    @State private var showServerList = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection

                        // Connect button
                        connectButtonSection

                        // Connection info
                        if vpnService.connectionStatus == .connected {
                            connectionInfoSection
                        }

                        // Current server
                        currentServerSection

                        // Quick stats
                        quickStatsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Jentacular")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primaryText)

                Text(statusSubtitle)
                    .font(.system(size: 15))
                    .foregroundColor(.secondaryText)
            }

            Spacer()

            // Security score mini indicator
            VStack(spacing: 4) {
                Text("\(securityService.securityScore)")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.accentGold)

                Text("безопасность")
                    .font(.system(size: 11))
                    .foregroundColor(.tertiaryText)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.cardBackground)
            .cornerRadius(16)
        }
    }

    private var statusSubtitle: String {
        switch vpnService.connectionStatus {
        case .connected: return "Защищенное соединение"
        case .connecting: return "Подключение..."
        case .disconnecting: return "Отключение..."
        case .error: return "Ошибка подключения"
        case .disconnected: return "Нажмите для подключения"
        }
    }

    // MARK: - Connect Button Section
    private var connectButtonSection: some View {
        VStack(spacing: 20) {
            // Animated connect button
            Button(action: {
                Task {
                    await vpnService.toggleConnection()
                }
            }) {
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(buttonColor.opacity(0.2))
                        .frame(width: 200, height: 200)
                        .blur(radius: 20)

                    // Main circle
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [buttonColor, buttonColor.opacity(0.8)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 160, height: 160)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 2)
                        )

                    // Icon
                    VStack(spacing: 8) {
                        Image(systemName: buttonIconName)
                            .font(.system(size: 48, weight: .semibold))
                            .foregroundColor(.white)

                        Text(buttonTitle)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(vpnService.isLoading)

            // Loading indicator
            if vpnService.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .accentBlue))
            }
        }
        .padding(.vertical, 20)
    }

    private var buttonColor: Color {
        switch vpnService.connectionStatus {
        case .connected: return .accentGreen
        case .connecting, .disconnecting: return .accentGold
        case .error: return .accentRed
        case .disconnected: return .accentBlue
        }
    }

    private var buttonIconName: String {
        switch vpnService.connectionStatus {
        case .connected: return "power"
        case .connecting: return "link"
        case .disconnecting: return "link.badge.minus"
        case .error: return "exclamationmark.triangle"
        case .disconnected: return "power"
        }
    }

    private var buttonTitle: String {
        switch vpnService.connectionStatus {
        case .connected: return "ОТКЛЮЧИТЬ"
        case .connecting: return "ПОДКЛЮЧЕНИЕ"
        case .disconnecting: return "ОТКЛЮЧЕНИЕ"
        case .error: return "ОШИБКА"
        case .disconnected: return "ПОДКЛЮЧИТЬ"
        }
    }

    // MARK: - Connection Info Section
    private var connectionInfoSection: some View {
        CustomCard {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.accentCyan)

                    Text("Время подключения")
                        .font(.system(size: 15))
                        .foregroundColor(.secondaryText)

                    Spacer()

                    Text(vpnService.formattedDuration)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primaryText)
                }

                Divider()
                    .background(Color.dividerColor)

                HStack {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(.accentGreen)

                    Text("Скачивание")
                        .font(.system(size: 15))
                        .foregroundColor(.secondaryText)

                    Spacer()

                    Text("— Мбит/с")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primaryText)
                }

                HStack {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(.accentBlue)

                    Text("Загрузка")
                        .font(.system(size: 15))
                        .foregroundColor(.secondaryText)

                    Spacer()

                    Text("— Мбит/с")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primaryText)
                }
            }
        }
    }

    // MARK: - Current Server Section
    private var currentServerSection: some View {
        Button(action: { showServerList = true }) {
            CustomCard {
                HStack(spacing: 16) {
                    Text(VPNServerNode.flagEmoji(for: AppConstants.vpnServerCountryCode))
                        .font(.system(size: 32))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Текущий сервер")
                            .font(.system(size: 13))
                            .foregroundColor(.tertiaryText)

                        Text("\(AppConstants.vpnServerName) — \(AppConstants.vpnServerCity)")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primaryText)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.tertiaryText)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showServerList) {
            ServersView()
        }
    }

    // MARK: - Quick Stats Section
    private var quickStatsSection: some View {
        HStack(spacing: 12) {
            QuickStatCard(
                iconName: "shield.fill",
                iconColor: .accentGreen,
                value: vpnService.connectionStatus == .connected ? "Да" : "Нет",
                label: "VPN активен"
            )

            QuickStatCard(
                iconName: "eye.slash.fill",
                iconColor: .accentPurple,
                value: vpnService.connectionStatus == .connected ? "Скрыт" : "Виден",
                label: "IP адрес"
            )

            QuickStatCard(
                iconName: "lock.fill",
                iconColor: .accentCyan,
                value: "AES-256",
                label: "Шифрование"
            )
        }
    }
}

// MARK: - Quick Stat Card
struct QuickStatCard: View {
    let iconName: String
    let iconColor: Color
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: iconName)
                .font(.system(size: 20))
                .foregroundColor(iconColor)

            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.primaryText)
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.tertiaryText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(Color.cardBackground)
        .cornerRadius(16)
    }
}
