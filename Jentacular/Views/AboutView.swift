//
//  AboutView.swift
//  Jentacular
//
//  App information page with version details, credits, and legal links
//

import SwiftUI

struct AboutView: View {
    // MARK: - Environment
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var settingsService: SettingsService

    // MARK: - State
    @State private var showPrivacyPolicy = false
    @State private var showTermsOfService = false
    @State private var showAcknowledgements = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // App icon and name
                    appHeaderSection

                    // Version info
                    versionInfoSection

                    // Links
                    linksSection

                    // Credits
                    creditsSection

                    // Copyright
                    copyrightSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
        .navigationBarTitle(L("about_title"), displayMode: .inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: backButton)
        .sheet(isPresented: $showPrivacyPolicy) {
            NavigationView { PrivacyPolicyView() }
                .navigationViewStyle(StackNavigationViewStyle())
        }
        .sheet(isPresented: $showTermsOfService) {
            NavigationView { TermsOfServiceView() }
                .navigationViewStyle(StackNavigationViewStyle())
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

    // MARK: - App Header
    private var appHeaderSection: some View {
        VStack(spacing: 16) {
            // App icon placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.accentBlue, .accentCyan]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 96, height: 96)
                    .shadow(color: .accentBlue.opacity(0.4), radius: 16, x: 0, y: 8)

                Image(systemName: "shield.fill")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundColor(.white)
            }

            Text(L("app_name"))
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.primaryText)

            Text(L("about_title"))
                .font(.system(size: 15))
                .foregroundColor(.secondaryText)
        }
        .padding(.bottom, 8)
    }

    // MARK: - Version Info
    private var versionInfoSection: some View {
        CustomCard {
            VStack(spacing: 14) {
                InfoRow(label: L("version_label"), value: AppConstants.appVersion)
                Divider().background(Color.dividerColor)
                InfoRow(label: L("build_label"), value: DeviceInfo.appBuildNumber)
                Divider().background(Color.dividerColor)
                InfoRow(label: L("protocol"), value: "IKEv2")
                Divider().background(Color.dividerColor)
                InfoRow(label: L("encryption"), value: "AES-256-GCM")
                Divider().background(Color.dividerColor)
                InfoRow(label: L("min_ios"), value: "15.0")
            }
        }
    }

    // MARK: - Links
    private var linksSection: some View {
        VStack(spacing: 12) {
            LinkRow(icon: "lock.shield.fill", iconColor: .accentGreen, title: L("privacy_policy")) {
                showPrivacyPolicy = true
            }

            LinkRow(icon: "doc.text.fill", iconColor: .accentBlue, title: L("terms_of_service")) {
                showTermsOfService = true
            }

            LinkRow(icon: "heart.fill", iconColor: .accentRed, title: L("acknowledgements")) {
                showAcknowledgements = true
            }
        }
        .sheet(isPresented: $showAcknowledgements) {
            AcknowledgementsView()
        }
    }

    // MARK: - Credits
    private var creditsSection: some View {
        CustomCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(L("about_subtitle"))
                    .font(.system(size: 14))
                    .foregroundColor(.secondaryText)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                HStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.accentGreen)
                    Text(L("about_no_logs"))
                        .font(.system(size: 13))
                        .foregroundColor(.primaryText)
                    Spacer()
                }

                HStack(spacing: 12) {
                    Image(systemName: "eye.slash.fill")
                        .foregroundColor(.accentPurple)
                    Text(L("about_data_ownership"))
                        .font(.system(size: 13))
                        .foregroundColor(.primaryText)
                    Spacer()
                }

                HStack(spacing: 12) {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.accentGold)
                    Text(L("about_servers"))
                        .font(.system(size: 13))
                        .foregroundColor(.primaryText)
                    Spacer()
                }
            }
        }
    }

    // MARK: - Copyright
    private var copyrightSection: some View {
        VStack(spacing: 4) {
            Text(L("copyright_jentacular"))
                .font(.system(size: 12))
                .foregroundColor(.tertiaryText)
            Text(L("all_rights_reserved"))
                .font(.system(size: 11))
                .foregroundColor(.tertiaryText)
        }
        .padding(.top, 8)
    }
}

// MARK: - Helper Components
struct LinkRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            CustomCard {
                HStack(spacing: 14) {
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(iconColor)
                        .frame(width: 36, height: 36)
                        .background(iconColor.opacity(0.15))
                        .cornerRadius(10)

                    Text(title)
                        .font(.system(size: 15))
                        .foregroundColor(.primaryText)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.tertiaryText)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Acknowledgements View
struct AcknowledgementsView: View {
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        Text(L("about_credits"))
                            .font(.system(size: 14))
                            .foregroundColor(.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.top, 8)

                        AcknowledgementItem(name: "SwiftUI", description: L("ack_swiftui_desc"))
                        AcknowledgementItem(name: "NetworkExtension", description: L("ack_networkextension_desc"))
                        AcknowledgementItem(name: "Combine", description: L("ack_combine_desc"))
                        AcknowledgementItem(name: "OSLog", description: L("ack_oslog_desc"))
                        AcknowledgementItem(name: "NWPathMonitor", description: L("ack_nwpathmonitor_desc"))
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarTitle(L("acknowledgements"), displayMode: .inline)
            .navigationBarItems(trailing: Button(L("done")) {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct AcknowledgementItem: View {
    let name: String
    let description: String

    var body: some View {
        CustomCard {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primaryText)
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
