//
//  PrivacyConsentView.swift
//  Jentacular
//
//  First launch privacy consent screen with original Jentacular design
//

import SwiftUI

struct PrivacyConsentView: View {
    let onAgree: () -> Void

    // MARK: - State
    @State private var animateIcon = false
    @State private var showPrivacyPolicy = false

    var body: some View {
        ZStack {
            // Animated gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.04, green: 0.06, blue: 0.12),
                    Color(red: 0.06, green: 0.09, blue: 0.18),
                    Color(red: 0.04, green: 0.07, blue: 0.14)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Floating glow effects
            Circle()
                .fill(Color.accentBlue.opacity(0.08))
                .frame(width: 300, height: 300)
                .blur(radius: 60)
                .offset(x: -100, y: animateIcon ? -200 : -150)
                .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: animateIcon)

            Circle()
                .fill(Color.accentCyan.opacity(0.06))
                .frame(width: 250, height: 250)
                .blur(radius: 50)
                .offset(x: 120, y: animateIcon ? 300 : 250)
                .animation(.easeInOut(duration: 5).repeatForever(autoreverses: true), value: animateIcon)

            VStack(spacing: 0) {
                // Header with shield icon
                headerSection

                // Scrollable content
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        // Welcome message
                        welcomeSection

                        // Privacy principles
                        privacyPrinciplesSection

                        // Data collection details
                        dataCollectionSection

                        // No-logs guarantee
                        noLogsGuaranteeSection

                        // Full policy link
                        fullPolicySection
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 30)
                }

                // Bottom action area
                bottomActionSection
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animateIcon = true
            }
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            NavigationView {
                PrivacyPolicyView()
            }
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Shield icon with glow
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [Color.accentBlue.opacity(0.3), .clear]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 140, height: 140)
                    .opacity(animateIcon ? 1 : 0)

                // Shield icon container
                ZStack {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.accentBlue, Color.accentCyan]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 88, height: 88)
                        .shadow(color: Color.accentBlue.opacity(0.5), radius: 20, x: 0, y: 10)

                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 42, weight: .semibold))
                        .foregroundColor(.white)
                }
                .scaleEffect(animateIcon ? 1 : 0.5)
                .opacity(animateIcon ? 1 : 0)
            }
            .padding(.top, 40)

            // Title
            Text(L("privacy"))
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primaryText)

            // Subtitle
            Text(L("privacy_subtitle"))
                .font(.system(size: 15))
                .foregroundColor(.secondaryText)
        }
        .padding(.bottom, 20)
    }

    // MARK: - Welcome
    private var welcomeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L("welcome"))
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primaryText)

            Text(L("welcome_desc"))
                .font(.system(size: 15))
                .foregroundColor(.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 8)
    }

    // MARK: - Privacy Principles
    private var privacyPrinciplesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L("our_principles"))
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.primaryText)

            VStack(spacing: 10) {
                PrivacyPrincipleRow(
                    icon: "eye.slash.fill",
                    iconColor: .accentPurple,
                    title: L("privacy_no_tracking"),
                    description: L("privacy_no_tracking_desc")
                )
                PrivacyPrincipleRow(
                    icon: "lock.fill",
                    iconColor: .accentGreen,
                    title: L("privacy_encryption"),
                    description: L("privacy_encryption_desc")
                )
                PrivacyPrincipleRow(
                    icon: "server.rack",
                    iconColor: .accentCyan,
                    title: L("privacy_no_logs"),
                    description: L("privacy_no_logs_desc")
                )
            }
        }
    }

    // MARK: - Data Collection
    private var dataCollectionSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L("data_collected"))
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.primaryText)

            VStack(spacing: 10) {
                DataCollectionRow(
                    icon: "iphone",
                    iconColor: .accentBlue,
                    title: L("privacy_device_info"),
                    description: L("privacy_device_info_desc")
                )
                DataCollectionRow(
                    icon: "ant.fill",
                    iconColor: .accentGold,
                    title: L("privacy_crash_reports"),
                    description: L("privacy_crash_reports_desc")
                )
                DataCollectionRow(
                    icon: "chart.bar",
                    iconColor: .accentPurple,
                    title: L("privacy_anonymous_stats"),
                    description: L("privacy_anonymous_stats_desc")
                )
            }
        }
    }

    // MARK: - No Logs Guarantee
    private var noLogsGuaranteeSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header with icon and title
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.accentGreen.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.accentGreen)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(L("our_guarantee"))
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.accentGreen)
                    Text(L("zero_log_policy"))
                        .font(.system(size: 12))
                        .foregroundColor(.tertiaryText)
                }
            }

            Divider()
                .background(Color.accentGreen.opacity(0.2))

            Text(L("we_do_not_collect"))
                .font(.system(size: 14))
                .foregroundColor(.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 10) {
                GuaranteeCheckmarkItem(text: L("guarantee_browsing_history"))
                GuaranteeCheckmarkItem(text: L("guarantee_traffic_content"))
                GuaranteeCheckmarkItem(text: L("guarantee_dns_queries"))
                GuaranteeCheckmarkItem(text: L("guarantee_real_location"))
                GuaranteeCheckmarkItem(text: L("guarantee_connection_logs"))
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.accentGreen.opacity(0.1), Color.accentGreen.opacity(0.04)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.accentGreen.opacity(0.25), lineWidth: 1)
        )
    }

    // MARK: - Full Policy
    private var fullPolicySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L("full_privacy_policy"))
                .font(.system(size: 15))
                .foregroundColor(.secondaryText)

            Button(action: { showPrivacyPolicy = true }) {
                HStack {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.accentCyan)
                    Text(L("read_full_version"))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.accentCyan)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.accentCyan)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(Color.cardBackground)
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    // MARK: - Bottom Action
    private var bottomActionSection: some View {
        VStack(spacing: 12) {
            // Agree button
            Button(action: { onAgree() }) {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                    Text(L("accept_continue"))
                        .font(.system(size: 17, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.accentBlue, .accentCyan]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: Color.accentBlue.opacity(0.4), radius: 12, x: 0, y: 6)
            }
            .buttonStyle(PlainButtonStyle())
            .opacity(showContent ? 1 : 0)
            .scaleEffect(showContent ? 1 : 0.9)

            // Disclaimer
            Text(L("accept_disclaimer"))
                .font(.system(size: 12))
                .foregroundColor(.tertiaryText)
                .multilineTextAlignment(.center)
                .opacity(showContent ? 1 : 0)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 30)
        .padding(.top, 10)
    }
}

// MARK: - Helper Components
struct PrivacyPrincipleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(iconColor)
                .frame(width: 40, height: 40)
                .background(iconColor.opacity(0.15))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primaryText)
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct DataCollectionRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(iconColor)
                .frame(width: 36, height: 36)
                .background(iconColor.opacity(0.12))
                .cornerRadius(9)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primaryText)
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct GuaranteeCheckmarkItem: View {
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(.accentRed)
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.secondaryText)
        }
    }
}
