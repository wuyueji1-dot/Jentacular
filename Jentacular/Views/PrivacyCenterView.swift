//
//  PrivacyCenterView.swift
//  Jentacular
//
//  Privacy center explaining app privacy features and no-logs policy
//

import SwiftUI

struct PrivacyCenterView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header icon and title
                        headerSection

                        // Privacy features
                        privacyFeaturesSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle(L("privacy_center_nav"))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primaryText)
                }
            )
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 64))
                .foregroundColor(.accentPurple)
                .padding(.bottom, 8)

            Text(L("privacy_by_default"))
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.primaryText)
                .multilineTextAlignment(.center)

            Text(L("privacy_by_default_desc"))
                .font(.system(size: 16))
                .foregroundColor(.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .padding(.vertical, 20)
    }

    // MARK: - Privacy Features Section
    private var privacyFeaturesSection: some View {
        VStack(spacing: 16) {
            PrivacyFeatureCard(
                iconName: "person.crop.circle.badge.xmark",
                iconColor: .accentPurple,
                title: L("privacy_no_account"),
                description: L("privacy_no_account_desc")
            )

            PrivacyFeatureCard(
                iconName: "checkmark.shield.fill",
                iconColor: .accentBlue,
                title: L("privacy_cert_auth"),
                description: L("privacy_cert_auth_desc")
            )

            PrivacyFeatureCard(
                iconName: "externaldrive.fill.badge.checkmark",
                iconColor: .accentCyan,
                title: L("privacy_local_storage"),
                description: L("privacy_local_storage_desc")
            )

            PrivacyFeatureCard(
                iconName: "eye.slash.fill",
                iconColor: .accentRed,
                title: L("privacy_no_tracking"),
                description: L("privacy_no_tracking_center_desc")
            )
        }
    }
}

// MARK: - Privacy Feature Card
struct PrivacyFeatureCard: View {
    let iconName: String
    let iconColor: Color
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: iconName)
                .font(.system(size: 28))
                .foregroundColor(iconColor)
                .frame(width: 48, height: 48)
                .background(iconColor.opacity(0.15))
                .cornerRadius(12)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 19, weight: .bold))
                    .foregroundColor(.primaryText)

                Text(description)
                    .font(.system(size: 15))
                    .foregroundColor(.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground)
        .cornerRadius(20)
    }
}
