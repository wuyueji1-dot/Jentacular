//
//  HomeView.swift
//  Jentacular
//
//  Main home screen with animated VPN connect button and connection status
//

import SwiftUI

struct HomeView: View {
    // MARK: - Environment Objects
    @EnvironmentObject var vpnService: VPNConnectionService
    @EnvironmentObject var securityService: SecurityScoreService
    @EnvironmentObject var pingService: PingService

    // MARK: - State
    @State private var showServerList = false
    @State private var buttonScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.0
    @State private var flowRotation: Double = 0

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

                // Background gradient when connected
                if vpnService.connectionStatus == .connected {
                    RadialGradient(
                        gradient: Gradient(colors: [Color.accentGreen.opacity(0.15), Color.clear]),
                        center: .center,
                        startRadius: 0,
                        endRadius: 300
                    )
                    .ignoresSafeArea()
                    .transition(.opacity)
                }

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection

                        // Connect button with animation
                        connectButtonSection

                        // Connection info (shown when connected)
                        if vpnService.connectionStatus == .connected {
                            connectionInfoSection
                                .transition(.move(edge: .top).combined(with: .opacity))
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
            .navigationBarHidden(true)
            .animation(.easeInOut(duration: 0.3), value: vpnService.connectionStatus)
            .onAppear {
                pingService.startAutoRefresh(host: AppConstants.vpnServerAddress, interval: 15.0)
            }
            .onDisappear {
                pingService.stopAutoRefresh()
            }
        }
        .sheet(isPresented: $showServerList) {
            NavigationView { ServersView() }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(L("app_name"))
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
                    .foregroundColor(scoreColor)

                Text(L("security_score"))
                    .font(.system(size: 11))
                    .foregroundColor(.tertiaryText)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.cardBackground)
            .cornerRadius(16)
        }
    }

    private var scoreColor: Color {
        switch securityService.securityScore {
        case 0...40: return .accentRed
        case 41...70: return .accentGold
        case 71...90: return .accentCyan
        default: return .accentGreen
        }
    }

    private var statusSubtitle: String {
        switch vpnService.connectionStatus {
        case .connected: return L("connected")
        case .connecting: return L("connecting")
        case .disconnecting: return "Disconnecting..."
        case .error: return "Connection error"
        case .disconnected: return L("home_subtitle")
        }
    }

    // MARK: - Connect Button Section
    private var connectButtonSection: some View {
        VStack(spacing: 20) {
            ZStack {
                // Pulsing rings when connecting
                if vpnService.connectionStatus == .connecting {
                    ForEach(0..<3) { i in
                        Circle()
                            .stroke(buttonColor.opacity(0.3), lineWidth: 2)
                            .frame(width: 160 + CGFloat(i * 30), height: 160 + CGFloat(i * 30))
                            .opacity(pulseOpacity)
                            .animation(
                                Animation.easeOut(duration: 1.5)
                                    .repeatForever(autoreverses: false)
                                    .delay(Double(i) * 0.5),
                                value: pulseOpacity
                            )
                    }
                    .onAppear { pulseOpacity = 1.0 }
                    .onDisappear { pulseOpacity = 0.0 }
                }

                // Flowing light ring when connected
                if vpnService.connectionStatus == .connected {
                    Circle()
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [
                                    Color.accentGreen.opacity(0.0),
                                    Color.accentGreen.opacity(0.8),
                                    Color.accentCyan.opacity(0.9),
                                    Color.accentGreen.opacity(0.8),
                                    Color.accentGreen.opacity(0.0)
                                ]),
                                center: .center
                            ),
                            lineWidth: 4
                        )
                        .frame(width: 185, height: 185)
                        .rotationEffect(.degrees(flowRotation))
                        .animation(
                            Animation.linear(duration: 2.5).repeatForever(autoreverses: false),
                            value: flowRotation
                        )
                        .onAppear { flowRotation = 360 }
                        .onDisappear { }

                    // Second slower flowing ring
                    Circle()
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [
                                    Color.accentCyan.opacity(0.0),
                                    Color.accentCyan.opacity(0.5),
                                    Color.accentGreen.opacity(0.6),
                                    Color.accentCyan.opacity(0.0)
                                ]),
                                center: .center
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(-flowRotation * 0.6))
                        .animation(
                            Animation.linear(duration: 4.0).repeatForever(autoreverses: false),
                            value: flowRotation
                        )
                }

                // Outer glow
                Circle()
                    .fill(buttonColor.opacity(0.2))
                    .frame(width: 200, height: 200)
                    .blur(radius: 20)

                // Main button
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    Task {
                        await vpnService.toggleConnection()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [buttonColor, buttonColor.opacity(0.85)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 160, height: 160)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.25), lineWidth: 2)
                            )
                            .shadow(color: buttonColor.opacity(0.5), radius: 20, x: 0, y: 10)

                        VStack(spacing: 10) {
                            ZStack {
                                Image(systemName: buttonIconName)
                                    .font(.system(size: 48, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(width: 60, height: 60)
                                    .rotationEffect(
                                        .degrees(vpnService.connectionStatus == .connecting ? 360 : 0),
                                        anchor: .center
                                    )
                                    .animation(
                                        vpnService.connectionStatus == .connecting ?
                                            Animation.linear(duration: 1.0).repeatForever(autoreverses: false) : .default,
                                        value: vpnService.connectionStatus
                                    )
                            }
                            .frame(width: 60, height: 60)

                            Text(buttonTitle)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .scaleEffect(buttonScale)
                .pressAction {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        buttonScale = 0.95
                    }
                } onRelease: {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        buttonScale = 1.0
                    }
                }
                .disabled(vpnService.isLoading)
            }
            .frame(height: 200)

            // Loading indicator
            if vpnService.isLoading {
                HStack(spacing: 8) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .accentBlue))
                    Text(L("connecting"))
                        .font(.system(size: 14))
                        .foregroundColor(.secondaryText)
                }
            }

            // Error message
            if let error = vpnService.lastError {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundColor(.accentRed)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
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
        case .connected: return L("disconnect_button")
        case .connecting: return L("connecting")
        case .disconnecting: return "Disconnecting"
        case .error: return "Error"
        case .disconnected: return L("connect_button")
        }
    }

    // MARK: - Connection Info Section
    private var connectionInfoSection: some View {
        CustomCard {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.accentCyan)

                    Text(L("connection_time"))
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
                    Image(systemName: "network")
                        .foregroundColor(.accentPurple)

                    Text(L("protocol"))
                        .font(.system(size: 15))
                        .foregroundColor(.secondaryText)

                    Spacer()

                    Text("IKEv2")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primaryText)
                }
            }
            .padding(16)
        }
    }
            }
        }
    }

    // MARK: - Current Server Section
    private var currentServerSection: some View {
        Button(action: { showServerList = true }) {
            CustomCard {
                HStack(spacing: 16) {
                    Text("🇺🇸")
                        .font(.system(size: 32))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(L("current_server"))
                            .font(.system(size: 13))
                            .foregroundColor(.tertiaryText)

                        Text(L("us_new_york"))
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primaryText)

                        if let ping = pingService.lastPingMs {
                            Text(String(format: L("ping_ms"), ping))
                                .font(.system(size: 12))
                                .foregroundColor(ping < 100 ? .accentGreen : .accentGold)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.tertiaryText)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Quick Stats Section
    private var quickStatsSection: some View {
        HStack(spacing: 12) {
            QuickStatCard(
                iconName: "shield.fill",
                iconColor: vpnService.connectionStatus == .connected ? .accentGreen : .accentRed,
                value: vpnService.connectionStatus == .connected ? L("vpn_active") : L("vpn_inactive"),
                label: L("vpn_active_label")
            )

            QuickStatCard(
                iconName: "eye.slash.fill",
                iconColor: vpnService.connectionStatus == .connected ? .accentPurple : .accentGold,
                value: vpnService.connectionStatus == .connected ? L("ip_hidden") : L("ip_visible"),
                label: L("ip_address_label")
            )

            QuickStatCard(
                iconName: "lock.fill",
                iconColor: .accentCyan,
                value: L("encryption"),
                label: L("encryption_label")
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

// MARK: - Press Action Modifier
extension View {
    func pressAction(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        self.gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in onPress() }
                .onEnded { _ in onRelease() }
        )
    }
}
