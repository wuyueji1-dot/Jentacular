//
//  SecurityDetailView.swift
//  Jentacular
//
//  Detailed security status view with threat analysis and protection features
//

import SwiftUI

struct SecurityDetailView: View {
    // MARK: - Environment
    @EnvironmentObject var securityService: SecurityScoreService
    @EnvironmentObject var vpnService: VPNConnectionService
    @Environment(\.presentationMode) var presentationMode

    // MARK: - State
    @State private var selectedTab: Int = 0
    @State private var showThreatDetails = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Score overview
                    scoreOverviewSection

                    // Tab selector
                    tabSelectorSection

                    // Tab content
                    if selectedTab == 0 {
                        protectionFeaturesSection
                    } else {
                        threatAnalysisSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
        }
        .navigationBarTitle(L("security"), displayMode: .inline)
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

    // MARK: - Score Overview
    private var scoreOverviewSection: some View {
        CustomCard {
            VStack(spacing: 16) {
                // Circular score
                ZStack {
                    Circle()
                        .stroke(Color.dividerColor, lineWidth: 12)
                        .frame(width: 140, height: 140)

                    Circle()
                        .trim(from: 0, to: CGFloat(securityService.securityScore) / 100)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: scoreGradientColors),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 140, height: 140)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1.0), value: securityService.securityScore)

                    VStack(spacing: 4) {
                        Text("\(securityService.securityScore)")
                            .font(.system(size: 42, weight: .bold))
                            .foregroundColor(.primaryText)
                        Text(L("out_of_100"))
                            .font(.system(size: 14))
                            .foregroundColor(.secondaryText)
                    }
                }

                // Level badge
                HStack(spacing: 8) {
                    Circle()
                        .fill(scoreColor)
                        .frame(width: 10, height: 10)
                    Text(securityService.scoreLevel)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(scoreColor)
                }

                Text(vpnService.connectionStatus == .connected ?
                     L("device_fully_protected") :
                     L("connect_vpn_for_protection"))
                    .font(.system(size: 14))
                    .foregroundColor(.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 20)
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

    private var scoreGradientColors: [Color] {
        switch securityService.securityScore {
        case 0...40: return [.accentRed, .accentRed.opacity(0.6)]
        case 41...70: return [.accentGold, .accentGold.opacity(0.6)]
        case 71...90: return [.accentCyan, .accentBlue]
        default: return [.accentGreen, .accentCyan]
        }
    }

    // MARK: - Tab Selector
    private var tabSelectorSection: some View {
        HStack(spacing: 0) {
            TabButton(title: L("protection"), isSelected: selectedTab == 0) {
                withAnimation(.easeInOut) { selectedTab = 0 }
            }
            TabButton(title: L("threats"), isSelected: selectedTab == 1) {
                withAnimation(.easeInOut) { selectedTab = 1 }
            }
        }
        .background(Color.cardBackground)
        .cornerRadius(12)
        .padding(.horizontal, 4)
    }

    // MARK: - Protection Features
    private var protectionFeaturesSection: some View {
        VStack(spacing: 12) {
            ForEach(securityService.securityItems, id: \.title) { item in
                ProtectionFeatureRow(item: item)
            }
        }
    }

    // MARK: - Threat Analysis
    private var threatAnalysisSection: some View {
        VStack(spacing: 12) {
            // No threats when VPN connected
            if vpnService.connectionStatus == .connected {
                CustomCard {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.accentGreen)

                        Text(L("no_threats"))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primaryText)

                        Text(L("vpn_protected_desc"))
                            .font(.system(size: 14))
                            .foregroundColor(.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 24)
                }
            } else {
                // Potential threats when disconnected
                ThreatCard(
                    icon: "eye.fill",
                    title: L("threat_traffic_tracking"),
                    description: L("threat_traffic_tracking_desc"),
                    severity: .high,
                    isActive: true
                )
                ThreatCard(
                    icon: "location.fill",
                    title: L("threat_ip_leak"),
                    description: L("threat_ip_leak_desc"),
                    severity: .medium,
                    isActive: true
                )
                ThreatCard(
                    icon: "wifi.exclamationmark",
                    title: L("threat_insecure_wifi"),
                    description: L("threat_insecure_wifi_desc"),
                    severity: .medium,
                    isActive: true
                )
                ThreatCard(
                    icon: "globe",
                    title: L("threat_geo_restrictions"),
                    description: L("threat_geo_restrictions_desc"),
                    severity: .low,
                    isActive: true
                )
            }
        }
    }
}

// MARK: - Helper Components
struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(isSelected ? .white : .secondaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    isSelected ?
                        LinearGradient(gradient: Gradient(colors: [.accentBlue, .accentCyan]), startPoint: .leading, endPoint: .trailing) :
                        LinearGradient(gradient: Gradient(colors: [.clear, .clear]), startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ProtectionFeatureRow: View {
    let item: SecurityItem

    var body: some View {
        CustomCard {
            HStack(spacing: 14) {
                Image(systemName: item.iconName)
                    .font(.system(size: 22))
                    .foregroundColor(iconColor)
                    .frame(width: 44, height: 44)
                    .background(iconColor.opacity(0.15))
                    .cornerRadius(12)

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primaryText)
                    Text(item.description)
                        .font(.system(size: 13))
                        .foregroundColor(.secondaryText)
                }

                Spacer()

                // Status indicator
                VStack(spacing: 4) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 10, height: 10)
                    Text(statusText)
                        .font(.system(size: 11))
                        .foregroundColor(statusColor)
                }
            }
        }
    }

    private var iconColor: Color {
        switch item.iconColor {
        case .green: return .accentGreen
        case .red: return .accentRed
        case .gold: return .accentGold
        case .cyan: return .accentCyan
        case .blue: return .accentBlue
        case .purple: return .accentPurple
        }
    }

    private var statusColor: Color {
        switch item.status {
        case .good: return .accentGreen
        case .warning: return .accentGold
        case .critical: return .accentRed
        case .neutral: return .accentCyan
        }
    }

    private var statusText: String {
        switch item.status {
        case .good: return "OK"
        case .warning: return L("warning")
        case .critical: return L("danger")
        case .neutral: return L("neutral")
        }
    }
}

struct ThreatCard: View {
    let icon: String
    let title: String
    let description: String
    let severity: ThreatSeverity
    let isActive: Bool

    enum ThreatSeverity {
        case low, medium, high

        var color: Color {
            switch self {
            case .low: return .accentCyan
            case .medium: return .accentGold
            case .high: return .accentRed
            }
        }

        var label: String {
            switch self {
            case .low: return L("low")
            case .medium: return L("medium")
            case .high: return L("high")
            }
        }
    }

    var body: some View {
        CustomCard {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(severity.color)
                    .frame(width: 40, height: 40)
                    .background(severity.color.opacity(0.15))
                    .cornerRadius(10)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primaryText)
                        Spacer()
                        Text(severity.label)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(severity.color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(severity.color.opacity(0.15))
                            .cornerRadius(6)
                    }
                    Text(description)
                        .font(.system(size: 13))
                        .foregroundColor(.secondaryText)
                }
            }
        }
    }
}
