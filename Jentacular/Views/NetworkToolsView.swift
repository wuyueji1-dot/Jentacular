//
//  NetworkToolsView.swift
//  Jentacular
//
//  Network diagnostic tools: Ping, DNS lookup, Port scan with results display
//

import SwiftUI

struct NetworkToolsView: View {
    // MARK: - Environment
    @EnvironmentObject var networkTools: NetworkToolsService
    @Environment(\.presentationMode) var presentationMode

    // MARK: - State
    @State private var selectedTab = 0
    @State private var pingHost = "google.com"
    @State private var dnsHost = "google.com"
    @State private var portHost = "google.com"
    @State private var isRunning = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerSection

                // Tab selector
                tabSelector

                // Content
                ScrollView {
                    VStack(spacing: 20) {
                        if selectedTab == 0 {
                            pingSection
                        } else if selectedTab == 1 {
                            dnsSection
                        } else {
                            portSection
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarTitle(L("network_tools_title"), displayMode: .inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: backButton)
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

    // MARK: - Header
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(L("network_tools_title"))
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primaryText)
            Text(L("network_tools_subtitle"))
                .font(.system(size: 15))
                .foregroundColor(.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }

    // MARK: - Tab Selector
    private var tabSelector: some View {
        HStack(spacing: 0) {
            NetworkToolsTabButton(title: "Ping", icon: "wifi", isSelected: selectedTab == 0) {
                withAnimation(.easeInOut) { selectedTab = 0 }
            }
            NetworkToolsTabButton(title: "DNS", icon: "globe", isSelected: selectedTab == 1) {
                withAnimation(.easeInOut) { selectedTab = 1 }
            }
            NetworkToolsTabButton(title: L("ports"), icon: "rectangle.connected.to.line.below", isSelected: selectedTab == 2) {
                withAnimation(.easeInOut) { selectedTab = 2 }
            }
        }
        .background(Color.cardBackground)
        .cornerRadius(12)
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    // MARK: - Ping Section
    private var pingSection: some View {
        VStack(spacing: 16) {
            // Input
            CustomCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text(L("host_or_ip"))
                        .font(.system(size: 14))
                        .foregroundColor(.secondaryText)

                    TextField(L("example_google"), text: $pingHost)
                        .font(.system(size: 16))
                        .foregroundColor(.primaryText)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(Color.cardBackgroundHighlighted)
                        .cornerRadius(10)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)

                    Button(action: {
                        Task {
                            isRunning = true
                            networkTools.clearPingResults()
                            _ = await networkTools.ping(host: pingHost, count: 4)
                            isRunning = false
                        }
                    }) {
                        HStack {
                            if isRunning {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "play.fill")
                            }
                            Text(isRunning ? L("running") : L("start_ping"))
                                .font(.system(size: 15, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(gradient: Gradient(colors: [.accentBlue, .accentCyan]), startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(10)
                    }
                    .disabled(isRunning || pingHost.isEmpty)
                }
            }

            // Results
            if !networkTools.pingResults.isEmpty {
                CustomCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(L("results"))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primaryText)

                        ForEach(networkTools.pingResults) { result in
                            PingResultRow(result: result)
                        }

                        // Statistics
                        let stats = networkTools.pingStatistics(for: networkTools.pingResults)
                        Divider().background(Color.dividerColor)

                        HStack {
                            StatItem(label: L("min"), value: String(format: "%.1f ms", stats.min))
                            Spacer()
                            StatItem(label: L("max"), value: String(format: "%.1f ms", stats.max))
                            Spacer()
                            StatItem(label: L("avg"), value: String(format: "%.1f ms", stats.avg))
                            Spacer()
                            StatItem(label: L("loss"), value: String(format: "%.0f%%", stats.loss))
                        }
                    }
                }
            }
        }
    }

    // MARK: - DNS Section
    private var dnsSection: some View {
        VStack(spacing: 16) {
            CustomCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text(L("domain_name"))
                        .font(.system(size: 14))
                        .foregroundColor(.secondaryText)

                    TextField(L("example_google"), text: $dnsHost)
                        .font(.system(size: 16))
                        .foregroundColor(.primaryText)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(Color.cardBackgroundHighlighted)
                        .cornerRadius(10)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)

                    Button(action: {
                        Task {
                            isRunning = true
                            _ = await networkTools.dnsLookup(host: dnsHost)
                            isRunning = false
                        }
                    }) {
                        HStack {
                            if isRunning {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "magnifyingglass")
                            }
                            Text(isRunning ? L("searching") : L("find_dns"))
                                .font(.system(size: 15, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(gradient: Gradient(colors: [.accentPurple, .accentBlue]), startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(10)
                    }
                    .disabled(isRunning || dnsHost.isEmpty)
                }
            }

            if !networkTools.dnsResults.isEmpty {
                CustomCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(L("query_history"))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primaryText)

                        ForEach(networkTools.dnsResults.prefix(10)) { result in
                            DNSResultRow(result: result)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Port Section
    private var portSection: some View {
        VStack(spacing: 16) {
            CustomCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text(L("scan_host"))
                        .font(.system(size: 14))
                        .foregroundColor(.secondaryText)

                    TextField(L("example_google"), text: $portHost)
                        .font(.system(size: 16))
                        .foregroundColor(.primaryText)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(Color.cardBackgroundHighlighted)
                        .cornerRadius(10)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)

                    Button(action: {
                        Task {
                            isRunning = true
                            networkTools.clearPortResults()
                            let ports = NetworkToolsService.commonPorts.map { $0.port }
                            _ = await networkTools.portScan(host: portHost, ports: Array(ports.prefix(10)))
                            isRunning = false
                        }
                    }) {
                        HStack {
                            if isRunning {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "radiowaves.right")
                            }
                            Text(isRunning ? L("scanning") : L("scan_ports"))
                                .font(.system(size: 15, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(gradient: Gradient(colors: [.accentGold, .accentRed]), startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(10)
                    }
                    .disabled(isRunning || portHost.isEmpty)
                }
            }

            if !networkTools.portResults.isEmpty {
                CustomCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(L("scan_results"))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primaryText)

                        ForEach(networkTools.portResults) { result in
                            PortResultRow(result: result)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Helper Components
struct NetworkToolsTabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(isSelected ? .white : .secondaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                isSelected ?
                    LinearGradient(gradient: Gradient(colors: [.accentBlue, .accentCyan]), startPoint: .leading, endPoint: .trailing) :
                    nil
            )
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PingResultRow: View {
    let result: NetworkToolsService.PingResult

    var body: some View {
        HStack {
            Circle()
                .fill(result.success ? Color.accentGreen : Color.accentRed)
                .frame(width: 8, height: 8)

            Text("\(result.ipAddress)")
                .font(.system(size: 14))
                .foregroundColor(.primaryText)

            Spacer()

            if result.success {
                Text(String(format: "%.1f ms", result.time))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.accentCyan)
            } else {
                Text(L("timeout"))
                    .font(.system(size: 14))
                    .foregroundColor(.accentRed)
            }
        }
        .padding(.vertical, 4)
    }
}

struct DNSResultRow: View {
    let result: NetworkToolsService.DNSResult

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(result.host)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primaryText)
                Spacer()
                Text(String(format: "%.0f ms", result.resolveTime))
                    .font(.system(size: 12))
                    .foregroundColor(.accentCyan)
            }

            if result.success {
                ForEach(result.ipAddresses, id: \.self) { ip in
                    Text(ip)
                        .font(.system(size: 13))
                        .foregroundColor(.secondaryText)
                }
            } else {
                Text(L("resolve_failed"))
                    .font(.system(size: 13))
                    .foregroundColor(.accentRed)
            }
        }
        .padding(.vertical, 8)
        .background(Color.cardBackgroundHighlighted)
        .cornerRadius(8)
        .padding(.horizontal, 4)
    }
}

struct PortResultRow: View {
    let result: NetworkToolsService.PortResult

    var body: some View {
        HStack {
            Text("\(result.port)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primaryText)
                .frame(width: 60, alignment: .leading)

            Text(result.serviceName)
                .font(.system(size: 14))
                .foregroundColor(.secondaryText)

            Spacer()

            HStack(spacing: 6) {
                Circle()
                    .fill(result.isOpen ? Color.accentGreen : Color.accentRed)
                    .frame(width: 8, height: 8)
                Text(result.isOpen ? L("open") : L("closed"))
                    .font(.system(size: 13))
                    .foregroundColor(result.isOpen ? .accentGreen : .secondaryText)
            }
        }
        .padding(.vertical, 4)
    }
}
