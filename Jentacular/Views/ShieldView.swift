//
//  ShieldView.swift
//  Jentacular
//
//  Security score dashboard with circular progress and security item list
//

import SwiftUI

struct ShieldView: View {
    // MARK: - Environment Objects
    @EnvironmentObject var securityService: SecurityScoreService
    @EnvironmentObject var vpnService: VPNConnectionService

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Security score
                    scoreSection

                    // Security items
                    securityItemsSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
        .background(AppBackgroundView(imageName: AppBackgroundTheme.shield))
        .navigationBarHidden(true)
        .onAppear {
            securityService.calculateSecurityScore()
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L("shield_title"))
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.primaryText)

            Text(L("shield_subtitle"))
                .font(.system(size: 16))
                .foregroundColor(.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Score Section
    private var scoreSection: some View {
        CustomCard(padding: 30) {
            VStack(spacing: 20) {
                ScoreDisplayView(
                    score: securityService.securityScore,
                    level: securityService.scoreLevel,
                    progressColor: scoreProgressColor
                )

                // Score description
                Text(scoreDescription)
                    .font(.system(size: 14))
                    .foregroundColor(.secondaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var scoreProgressColor: Color {
        switch securityService.securityScore {
        case 0...40: return .accentRed
        case 41...70: return .accentGold
        case 71...90: return .accentCyan
        default: return .accentGreen
        }
    }

    private var scoreDescription: String {
        switch securityService.securityScore {
        case 0...40:
            return L("security_poor")
        case 41...70:
            return L("security_medium")
        case 71...90:
            return L("security_good")
        default:
            return L("security_excellent")
        }
    }

    // MARK: - Security Items Section
    private var securityItemsSection: some View {
        VStack(spacing: 12) {
            ForEach(securityService.securityItems) { item in
                SecurityItemRow(item: item)
            }
        }
    }
}

// MARK: - Security Item Row
struct SecurityItemRow: View {
    let item: SecurityItem

    var body: some View {
        IconCard(
            iconName: item.iconName,
            iconColor: iconColor,
            title: item.title,
            description: item.description,
            statusIcon: statusIconName,
            statusColor: statusColor
        )
    }

    private var iconColor: Color {
        switch item.iconColor {
        case .red: return .accentRed
        case .green: return .accentGreen
        case .gold: return .accentGold
        case .blue: return .accentBlue
        case .purple: return .accentPurple
        case .cyan: return .accentCyan
        }
    }

    private var statusIconName: String? {
        switch item.status {
        case .good: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.shield.fill"
        case .critical: return "xmark.circle.fill"
        case .neutral: return nil
        }
    }

    private var statusColor: Color? {
        switch item.status {
        case .good: return .accentGreen
        case .warning: return .accentGold
        case .critical: return .accentRed
        case .neutral: return nil
        }
    }
}
