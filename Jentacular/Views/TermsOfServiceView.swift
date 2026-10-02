//
//  TermsOfServiceView.swift
//  Jentacular
//
//  Terms of Service page with full text
//

import SwiftUI

struct TermsOfServiceView: View {
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        headerSection
                        termsContent
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitle(L("terms_of_service"), displayMode: .inline)
            .navigationBarItems(leading: backButton)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

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

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L("terms_of_service"))
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primaryText)

            Text(L("last_updated"))
                .font(.system(size: 14))
                .foregroundColor(.secondaryText)
        }
    }

    private var termsContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            termSection(number: "1", title: L("tos_1_title"), content: L("tos_1_content"))

            termSection(number: "2", title: L("tos_2_title"), content: L("tos_2_content"))

            termSection(number: "3", title: L("tos_3_title"), content: L("tos_3_content"))

            termSection(number: "4", title: L("tos_4_title"), content: L("tos_4_content"))

            termSection(number: "5", title: L("tos_5_title"), content: L("tos_5_content"))

            termSection(number: "6", title: L("tos_6_title"), content: L("tos_6_content"))

            termSection(number: "7", title: L("tos_7_title"), content: L("tos_7_content"))

            Divider()
                .background(Color.dividerColor)

            Text(L("copyright"))
                .font(.system(size: 13))
                .foregroundColor(.tertiaryText)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
    }

    private func termSection(number: String, title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Text(number)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(Color.accentBlue)
                    .cornerRadius(8)

                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primaryText)
            }

            Text(content)
                .font(.system(size: 15))
                .foregroundColor(.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(16)
    }
}
