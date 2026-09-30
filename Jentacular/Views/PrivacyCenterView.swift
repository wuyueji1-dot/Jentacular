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
            .navigationTitle("Центр конфиденциальности")
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

            Text("Конфиденциальность по умолчанию")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.primaryText)
                .multilineTextAlignment(.center)

            Text("Jentacular VPN создан, чтобы знать о вас как можно меньше.")
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
                title: "Без аккаунта",
                description: "Без регистрации, почты и телефона. Просто подключайтесь."
            )

            PrivacyFeatureCard(
                iconName: "checkmark.shield.fill",
                iconColor: .accentBlue,
                title: "Аутентификация по сертификату",
                description: "Доступ предоставляется по сертификату устройства, а не по паролю."
            )

            PrivacyFeatureCard(
                iconName: "externaldrive.fill.badge.checkmark",
                iconColor: .accentCyan,
                title: "Локальное хранение данных",
                description: "Ваша история и настройки не покидают это устройство."
            )

            PrivacyFeatureCard(
                iconName: "eye.slash.fill",
                iconColor: .accentRed,
                title: "Без слежки",
                description: "Мы не ведём журналы, не продаём и не анализируем вашу активность."
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
