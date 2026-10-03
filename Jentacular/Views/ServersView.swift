//
//  ServersView.swift
//  Jentacular
//
//  Server selection with single France node and real-time ping measurement
//

import SwiftUI

struct ServersView: View {
    // MARK: - Environment Objects
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var vpnService: VPNConnectionService
    @EnvironmentObject var pingService: PingService

    // MARK: - State
    @State private var showSortMenu = false
    @State private var selectedSort: ServerSortOption = .recommended
    @State private var searchText = ""
    @State private var selectedCountry = "all"

    private var isVpnTransitioning: Bool {
        vpnService.connectionStatus == .connecting || vpnService.connectionStatus == .disconnecting
    }

    // MARK: - Single United States Server
    private let usServer = VPNServerNode(
        id: "us-newyork-01",
        name: "United States",
        country: "United States",
        countryCode: "US",
        city: "New York",
        ipAddress: AppConstants.vpnServerAddress,
        pingMs: 0,
        loadPercent: 30,
        isSelected: true
    )

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header
                headerSection

                // Search bar (decorative since only one server)
                searchSection

                // Sort section
                sortSection

                // Server list
                ScrollView {
                    VStack(spacing: 12) {
                        // US server card with shared ping from PingService
                        USServerCard(
                            server: usServer,
                            ping: pingService.lastPingMs,
                            isPinging: pingService.isPinging,
                            isConnected: vpnService.connectionStatus == .connected,
                            isButtonLoading: isVpnTransitioning,
                            onRefreshPing: {
                                Task {
                                    await pingService.ping(host: AppConstants.vpnServerAddress)
                                }
                            },
                            onConnect: {
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                                Task {
                                    await vpnService.toggleConnection()
                                }
                            }
                        )

                        // Server info card
                        serverInfoCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
        }
        .background(AppBackgroundView(imageName: AppBackgroundTheme.servers))
        .navigationBarTitle(L("servers_title"), displayMode: .inline)
        .navigationBarItems(leading: backButton)
        .onAppear {
            if pingService.lastPingMs == nil {
                Task {
                    await pingService.ping(host: AppConstants.vpnServerAddress)
                }
            }
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

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L("servers_title"))
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.primaryText)

            Text(L("servers_subtitle"))
                .font(.system(size: 16))
                .foregroundColor(.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }

    // MARK: - Search Section
    private var searchSection: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.tertiaryText)
                .padding(.leading, 16)

            TextField(L("search_placeholder"), text: $searchText)
                .font(.system(size: 16))
                .foregroundColor(.primaryText)
                .accentColor(.accentCyan)

            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.tertiaryText)
                        .padding(.trailing, 12)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.cardBackground)
        .cornerRadius(16)
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    // MARK: - Sort Section
    private var sortSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text(L("sort_by"))
                    .font(.system(size: 14))
                    .foregroundColor(.secondaryText)

                Spacer()

                Button(action: { showSortMenu.toggle() }) {
                    HStack(spacing: 8) {
                        Text(selectedSort.displayName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.accentCyan)

                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 14))
                            .foregroundColor(.accentCyan)
                    }
                }
            }
            .padding(.horizontal, 20)

            // Country filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    CountryChip(title: L("all"), isSelected: selectedCountry == "all") {
                        selectedCountry = "all"
                    }
                    CountryChip(title: "United States", isSelected: selectedCountry == "us") {
                        selectedCountry = "us"
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.top, 16)
    }

    // MARK: - Server Info Card
    private var serverInfoCard: some View {
        CustomCard {
            VStack(alignment: .leading, spacing: 16) {
                Text(L("server_info"))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primaryText)

                InfoRow(label: L("address"), value: L("us_new_york"))
                InfoRow(label: L("protocol"), value: "IKEv2")
                InfoRow(label: L("encryption"), value: "AES-256-GCM")
                InfoRow(label: L("location"), value: "New York, United States")
                InfoRow(label: L("load"), value: "30%")
            }
        }
    }
}

// MARK: - US Server Card
struct USServerCard: View {
    let server: VPNServerNode
    let ping: Int?
    let isPinging: Bool
    let isConnected: Bool
    let isButtonLoading: Bool
    let onRefreshPing: () -> Void
    let onConnect: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // Flag
                Text(server.flagEmoji)
                    .font(.system(size: 40))
                    .frame(width: 56, height: 56)
                    .background(Color.cardBackgroundHighlighted)
                    .cornerRadius(14)

                // Server info
                VStack(alignment: .leading, spacing: 6) {
                    Text(server.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primaryText)

                    Text(String(format: L("server_location_format"), server.city, server.country))
                        .font(.system(size: 15))
                        .foregroundColor(.secondaryText)

                    // Load indicator
                    HStack(spacing: 8) {
                        LoadIndicatorBar(loadPercent: server.loadPercent)
                            .frame(width: 80)
                        Text("\(server.loadPercent)\(L("percent_unit"))")
                            .font(.system(size: 12))
                            .foregroundColor(.tertiaryText)
                    }
                }

                Spacer()

                // Ping and status
                VStack(alignment: .trailing, spacing: 8) {
                    // Ping with refresh
                    Button(action: onRefreshPing) {
                        HStack(spacing: 6) {
                            if isPinging {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .accentCyan))
                                    .scaleEffect(0.8)
                            } else {
                                Text(ping != nil ? "\(ping!) ms" : "— ms")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(pingColor)

                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 14))
                                    .foregroundColor(.accentCyan)
                            }
                        }
                    }

                    // Status badge
                    HStack(spacing: 6) {
                        Circle()
                            .fill(isConnected ? Color.accentGreen : Color.accentGold)
                            .frame(width: 8, height: 8)

                        Text(isConnected ? L("connected") : L("available"))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(isConnected ? .accentGreen : .accentGold)
                    }
                }
            }
            .padding(20)

            // Connect button with loading feedback
            Button(action: onConnect) {
                HStack {
                    if isButtonLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.9)
                    } else {
                        Image(systemName: isConnected ? "power" : "bolt.fill")
                            .font(.system(size: 18, weight: .semibold))
                    }

                    Text(isButtonLoading ? L("connecting") : (isConnected ? L("disconnect").uppercased() : L("connect")))
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: isConnected ? [.accentRed, .accentRed.opacity(0.8)] : [.accentBlue, .accentCyan]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(14)
                .opacity(isButtonLoading ? 0.7 : 1.0)
            }
            .disabled(isButtonLoading)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color.cardBackgroundHighlighted)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.accentCyan.opacity(0.5), lineWidth: 2)
        )
    }

    private var pingColor: Color {
        guard let ping = ping else { return .tertiaryText }
        switch ping {
        case 0...50: return .accentGreen
        case 51...100: return .accentCyan
        case 101...200: return .accentGold
        default: return .accentRed
        }
    }
}

// MARK: - Info Row
struct InfoRow: View {
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

// MARK: - Country Chip
struct CountryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : .secondaryText)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.accentBlue : Color.cardBackground)
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.accentBlue : Color.dividerColor, lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
