//
//  ServerDetailView.swift
//  Jentacular
//
//  Detailed server information view with connection stats and technical details
//

import SwiftUI

struct ServerDetailView: View {
    // MARK: - Environment
    @EnvironmentObject var vpnService: VPNConnectionService
    @EnvironmentObject var pingService: PingService
    @Environment(\.presentationMode) var presentationMode

    // MARK: - State
    @State private var showTechnicalDetails = false
    @State private var pingHistory: [Int] = []
    @State private var isRefreshing = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Server header
                    serverHeaderSection

                    // Connection status
                    connectionStatusSection

                    // Ping chart
                    pingChartSection

                    // Technical details (expandable)
                    technicalDetailsSection

                    // Connection button
                    connectButtonSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
        }
        .navigationBarTitle(L("server_details"), displayMode: .inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: backButton)
        .onAppear {
            startPingMonitoring()
        }
        .onDisappear {
            stopPingMonitoring()
        }
    }

    // MARK: - Back Button
    private var backButton: some View {
        Button(action: { presentationMode.wrappedValue.dismiss() }) {
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                Text(L("back"))
                    .font(.system(size: 16))
            }
            .foregroundColor(.accentCyan)
        }
    }

    // MARK: - Server Header
    private var serverHeaderSection: some View {
        CustomCard {
            HStack(spacing: 16) {
                Text("🇫🇷")
                    .font(.system(size: 56))
                    .frame(width: 72, height: 72)
                    .background(Color.cardBackgroundHighlighted)
                    .cornerRadius(18)

                VStack(alignment: .leading, spacing: 6) {
                    Text(L("france_paris"))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.primaryText)

                    Text(L("france_paris"))
                        .font(.system(size: 14))
                        .foregroundColor(.secondaryText)

                    HStack(spacing: 8) {
                        StatusBadge(text: "IKEv2", color: .accentCyan)
                        StatusBadge(text: "AES-256", color: .accentGreen)
                    }
                }

                Spacer()
            }
        }
    }

    // MARK: - Connection Status
    private var connectionStatusSection: some View {
        CustomCard {
            VStack(spacing: 16) {
                HStack {
                    Text(L("connection_status"))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primaryText)
                    Spacer()
                }

                HStack(spacing: 12) {
                    Circle()
                        .fill(vpnService.connectionStatus == .connected ? Color.accentGreen : Color.accentGold)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(vpnService.connectionStatus == .connected ? Color.accentGreen.opacity(0.3) : Color.accentGold.opacity(0.3), lineWidth: 4)
                        )

                    Text(statusText)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primaryText)

                    Spacer()
                }

                if vpnService.connectionStatus == .connected {
                    Divider().background(Color.dividerColor)

                    HStack {
                        Text(L("connection_time"))
                            .font(.system(size: 14))
                            .foregroundColor(.secondaryText)
                        Spacer()
                        Text(vpnService.formattedDuration)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primaryText)
                    }
                }
            }
        }
    }

    private var statusText: String {
        switch vpnService.connectionStatus {
        case .connected: return L("connected")
        case .connecting: return L("connecting")
        case .disconnecting: return L("disconnecting")
        case .error: return L("error")
        case .disconnected: return L("disconnected")
        }
    }

    // MARK: - Ping Chart
    private var pingChartSection: some View {
        CustomCard {
            VStack(spacing: 16) {
                HStack {
                    Text(L("latency"))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primaryText)

                    Spacer()

                    Button(action: {
                        Task {
                            isRefreshing = true
                            let ping = await pingService.ping(host: AppConstants.vpnServerAddress)
                            if let ping = ping {
                                pingHistory.append(ping)
                                if pingHistory.count > 20 {
                                    pingHistory.removeFirst()
                                }
                            }
                            isRefreshing = false
                        }
                    }) {
                        HStack(spacing: 6) {
                            if isRefreshing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .accentCyan))
                                    .scaleEffect(0.7)
                            } else {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 14))
                            }
                            Text(L("refresh"))
                                .font(.system(size: 13))
                        }
                        .foregroundColor(.accentCyan)
                    }
                }

                // Current ping
                HStack(alignment: .bottom, spacing: 4) {
                    Text("\(pingService.lastPingMs ?? 0)")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(pingColor)
                    Text(L("ms_unit"))
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.secondaryText)
                        .padding(.bottom, 6)
                }

                // Mini bar chart
                if !pingHistory.isEmpty {
                    HStack(alignment: .bottom, spacing: 3) {
                        ForEach(Array(pingHistory.enumerated()), id: \.offset) { _, value in
                            Rectangle()
                                .fill(pingColorForValue(value))
                                .frame(width: 8, height: CGFloat(min(value, 200)) / 2)
                                .cornerRadius(2)
                        }
                    }
                    .frame(height: 60)
                }

                // Stats
                HStack {
                    StatItem(label: L("min"), value: "\(pingHistory.min() ?? 0) ms")
                    Spacer()
                    StatItem(label: L("max"), value: "\(pingHistory.max() ?? 0) ms")
                    Spacer()
                    StatItem(label: L("avg"), value: "\(pingHistory.isEmpty ? 0 : pingHistory.reduce(0, +) / pingHistory.count) ms")
                }
            }
        }
    }

    private var pingColor: Color {
        guard let ping = pingService.lastPingMs else { return .tertiaryText }
        return pingColorForValue(ping)
    }

    private func pingColorForValue(_ value: Int) -> Color {
        switch value {
        case 0...50: return .accentGreen
        case 51...100: return .accentCyan
        case 101...200: return .accentGold
        default: return .accentRed
        }
    }

    // MARK: - Technical Details
    private var technicalDetailsSection: some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation(.easeInOut) {
                    showTechnicalDetails.toggle()
                }
            }) {
                CustomCard {
                    HStack {
                        Text(L("technical_details"))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primaryText)
                        Spacer()
                        Image(systemName: showTechnicalDetails ? "chevron.up" : "chevron.down")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.tertiaryText)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())

            if showTechnicalDetails {
                CustomCard {
                    VStack(spacing: 12) {
                        TechDetailRow(label: L("protocol"), value: "IKEv2")
                        TechDetailRow(label: L("encryption"), value: "AES-256-GCM")
                        TechDetailRow(label: L("hash_function"), value: "SHA-512")
                        TechDetailRow(label: L("dh_group"), value: "DH20 (256-bit ECP)")
                        TechDetailRow(label: L("port"), value: "UDP 500 / 4500")
                        TechDetailRow(label: "MTU", value: "1400")
                        TechDetailRow(label: L("dns_servers"), value: "1.1.1.1, 8.8.8.8")
                        TechDetailRow(label: "Kill Switch", value: L("enabled"))
                        TechDetailRow(label: "IPv6", value: L("disabled"))
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    // MARK: - Connect Button
    private var connectButtonSection: some View {
        Button {
            Task {
                await vpnService.toggleConnection()
            }
        } label: {
            HStack {
                Image(systemName: vpnService.connectionStatus == .connected ? "power" : "bolt.fill")
                    .font(.system(size: 18, weight: .semibold))
                Text(vpnService.connectionStatus == .connected ? L("disconnect").uppercased() : L("connect").uppercased())
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: vpnService.connectionStatus == .connected ? [.accentRed, .accentRed.opacity(0.8)] : [.accentBlue, .accentCyan]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: (vpnService.connectionStatus == .connected ? Color.accentRed : Color.accentBlue).opacity(0.4), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Ping Monitoring
    private func startPingMonitoring() {
        // Initial ping
        Task {
            let ping = await pingService.ping(host: AppConstants.vpnServerAddress)
            if let ping = ping {
                pingHistory.append(ping)
            }
        }
    }

    private func stopPingMonitoring() {
        // Cleanup if needed
    }
}

// MARK: - Helper Components
struct StatusBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .cornerRadius(8)
    }
}

struct StatItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.tertiaryText)
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primaryText)
        }
    }
}

struct TechDetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.secondaryText)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primaryText)
        }
    }
}
