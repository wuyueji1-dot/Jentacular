//
//  PrivacyPolicyView.swift
//  Jentacular
//
//  Full privacy policy page with official text
//

import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    headerSection

                    // Introduction
                    sectionTitle("1. Introduction")
                    paragraph("This Privacy Policy describes how NATIONAL IMPORT SERVICES, INC. (\"we\", \"us\", or \"our\") collects, uses, and discloses information when you use our VPN application (the \"Service\"). We are committed to protecting your privacy and complying with applicable data protection laws and Apple platform requirements. By using the Service, you agree to the practices described in this policy.")

                    // Information We Collect
                    sectionTitle("2. Information We Collect")

                    subSectionTitle("2.1 VPN Service Data")
                    paragraph("Our VPN service does not collect, store, log, or retain any network activity data that passes through the VPN tunnel. This includes:")

                    bulletList([
                        "IP addresses of websites or services you visit",
                        "Browsing history, search history, or content accessed",
                        "DNS queries or domain names",
                        "Connection timestamps or session duration related to specific VPN activity",
                        "Bandwidth usage per individual user",
                        "Any content transmitted over the VPN connection"
                    ])

                    paragraph("All VPN encryption, decryption, and traffic processing occurs entirely locally on your device. We have no access to the content of your VPN traffic.")

                    subSectionTitle("2.2 Application Usage Data")
                    paragraph("We collect only minimal, non-personally identifiable information about how you use the application itself, unrelated to VPN network activity. This may include:")

                    bulletList([
                        "App launch frequency and general session duration",
                        "Feature usage statistics (e.g., which app functions are used)",
                        "Crash reports and error logs",
                        "General device information (device model, operating system version, language setting)"
                    ])

                    paragraph("This data is fully anonymous and cannot be used to identify individual users.")

                    // How We Use
                    sectionTitle("3. How We Use Your Information")
                    paragraph("The limited application usage data we collect is used exclusively for the following purposes:")

                    bulletList([
                        "To maintain and improve the stability, performance, and functionality of the app",
                        "To identify and fix technical bugs and errors",
                        "To understand general usage patterns to optimize user experience",
                        "To provide customer support when requested"
                    ])

                    paragraph("We never use this data to track, profile, or identify individual users, nor do we use it for advertising or marketing purposes.")

                    // Data Sharing
                    sectionTitle("4. Data Sharing and Disclosure")

                    subSectionTitle("4.1 No VPN Data Sharing")
                    paragraph("We do not share, sell, rent, or disclose any VPN network activity data to any third party for any purpose.")

                    subSectionTitle("4.2 Third-Party Service Providers")
                    paragraph("We may share anonymous application usage data with contracted third-party service providers who assist us in operating and improving our Service. These providers include:")

                    bulletList([
                        "Crash reporting and performance monitoring services",
                        "Cloud hosting providers for secure data storage"
                    ])

                    paragraph("All third-party providers are bound by strict confidentiality agreements and are prohibited from using the data for any purpose other than providing services to us.")

                    subSectionTitle("4.3 Legal Requirements")
                    paragraph("We may disclose information if required to do so by law or in response to valid requests from public authorities (e.g., a court or government agency).")

                    // Data Retention
                    sectionTitle("5. Data Retention")
                    paragraph("Anonymous application usage data is retained for a maximum of 24 months. After this period, the data is either permanently deleted or further anonymized for aggregate statistical analysis.")
                    paragraph("No VPN network activity data is ever stored or retained.")

                    // Data Security
                    sectionTitle("6. Data Security")
                    paragraph("We implement commercially reasonable security measures to protect the limited data we collect, including encrypted transmission and secure server storage. However, no method of electronic storage or transmission over the internet is 100% secure, and we cannot guarantee absolute security.")

                    // Privacy Rights
                    sectionTitle("7. Your Privacy Rights")
                    paragraph("You have the right to:")

                    bulletList([
                        "Request access to any usage data associated with your device (where identifiable)",
                        "Request deletion of your data",
                        "Opt out of non-essential usage data collection where applicable"
                    ])

                    paragraph("To exercise these rights, please contact us using the information provided below.")

                    // Children's Privacy
                    sectionTitle("8. Children's Privacy")
                    paragraph("Our Service is not intended for use by children under the age of 16. We do not knowingly collect personal information from children under 16. If you believe we have collected such information, please contact us immediately.")

                    // Changes
                    sectionTitle("9. Changes to This Privacy Policy")
                    paragraph("We may update this Privacy Policy from time to time. We will post the updated version on this page and update the \"Last updated\" date above. We encourage you to review this policy periodically.")

                    // Contact
                    sectionTitle("10. Contact Us")
                    paragraph("If you have any questions about this Privacy Policy or our data practices, please contact us at:")

                    contactSection
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
        .navigationBarTitle("Privacy Policy", displayMode: .inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: backButton)
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L("privacy_policy_title"))
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primaryText)

            Text(L("company_name"))
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.accentCyan)

            Text(L("privacy_last_updated"))
                .font(.system(size: 13))
                .foregroundColor(.secondaryText)
        }
        .padding(.bottom, 8)
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

    // MARK: - Contact
    private var contactSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "envelope.fill")
                    .foregroundColor(.accentCyan)
                Text(L("contact_email"))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primaryText)
            }
            HStack(spacing: 10) {
                Image(systemName: "building.2.fill")
                    .foregroundColor(.accentCyan)
                Text(L("company_name"))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primaryText)
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(12)
    }

    // MARK: - Helpers
    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(.primaryText)
            .padding(.top, 8)
    }

    private func subSectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.accentBlue)
    }

    private func paragraph(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14))
            .foregroundColor(.secondaryText)
            .fixedSize(horizontal: false, vertical: true)
            .lineSpacing(4)
    }

    private func bulletList(_ items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 6))
                        .foregroundColor(.accentCyan)
                        .padding(.top, 6)
                    Text(item)
                        .font(.system(size: 14))
                        .foregroundColor(.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.leading, 8)
    }
}
