//
//  PrivacyConsentView.swift
//  Jentacular
//
//  First launch privacy consent screen explaining data collection practices
//

import SwiftUI

struct PrivacyConsentView: View {
    let onAgree: () -> Void

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Close button
                HStack {
                    Spacer()
                    Button(action: { onAgree() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.secondaryText)
                            .frame(width: 40, height: 40)
                            .background(Color.cardBackground)
                            .cornerRadius(20)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                // Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Title
                        Text("Your Privacy, Your Control")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.primaryText)
                            .padding(.top, 20)

                        // Greeting
                        Text("Hey there! Thanks for choosing Jentacular vpn — we've got your back when it comes to online privacy.")
                            .font(.system(size: 17))
                            .foregroundColor(.secondaryText)

                        // Intro
                        Text("We only collect the bare minimum data needed to keep your connection smooth and secure. Here's a quick breakdown:")
                            .font(.system(size: 17))
                            .foregroundColor(.secondaryText)

                        // Email section
                        privacyItem(
                            title: "*Email (Optional)",
                            description: "Helps with login, password recovery, and service updates. But no worries, you can still use most of our features without signing up."
                        )

                        // Anonymous data section
                        privacyItem(
                            title: "*Anonymous Usage Data",
                            description: "Stuff like your device type, OS version, and error reports. This helps us fix bugs and make sure your VPN runs like a dream."
                        )

                        // No tracking statement
                        Text("That's it. No tracking your browsing history, no selling your data. We stick to a strict no-logs policy and follow privacy laws to the letter. Your data stays yours.")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.accentRed)

                        // Full details link
                        HStack {
                            Text("Want the full details? Check out our")
                                .font(.system(size: 15))
                                .foregroundColor(.secondaryText)

                            Button(action: {
                                if let url = URL(string: AppConstants.privacyPolicyURL) {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                Text("Privacy Policy")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.accentBlue)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }

                // Agree button
                VStack(spacing: 0) {
                    Button(action: { onAgree() }) {
                        Text("Agree")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [.accentRed, .accentRed.opacity(0.8)]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .cornerRadius(.infinity)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
                .background(Color.appBackground)
            }
        }
    }

    // MARK: - Privacy Item
    private func privacyItem(title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primaryText)

            Text(description)
                .font(.system(size: 16))
                .foregroundColor(.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
