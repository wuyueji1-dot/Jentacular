//
//  HelpView.swift
//  Jentacular
//
//  Help and support center with FAQ, troubleshooting, and contact options
//

import SwiftUI

struct HelpView: View {
    // MARK: - Environment
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedCategory: HelpCategory? = nil
    @State private var searchText = ""

    // MARK: - Categories
    enum HelpCategory: String, CaseIterable, Identifiable {
        case connection = "Connection"
        case account = "Account"
        case security = "Security"
        case technical = "Technical"
        case billing = "Billing"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .connection: return L("help_category_connection")
            case .account: return L("help_category_account")
            case .security: return L("help_category_security")
            case .technical: return L("help_category_technical")
            case .billing: return L("help_category_billing")
            }
        }

        var icon: String {
            switch self {
            case .connection: return "wifi"
            case .account: return "person.circle"
            case .security: return "shield.fill"
            case .technical: return "wrench.fill"
            case .billing: return "creditcard.fill"
            }
        }

        var color: Color {
            switch self {
            case .connection: return .accentCyan
            case .account: return .accentBlue
            case .security: return .accentGreen
            case .technical: return .accentGold
            case .billing: return .accentPurple
            }
        }
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    searchSection
                    quickActionsSection
                    categoriesSection
                    popularQuestionsSection
                    contactSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
        }
        .navigationBarTitle(L("help_title"), displayMode: .inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: backButton)
        .sheet(item: $selectedCategory) { category in
            CategoryHelpView(category: category)
        }
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

    private var searchSection: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.tertiaryText)
                .padding(.leading, 16)

            TextField(L("help_search_placeholder"), text: $searchText)
                .font(.system(size: 16))
                .foregroundColor(.primaryText)
                .accentColor(.accentCyan)

            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.tertiaryText)
                        .padding(.trailing, 16)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.cardBackground)
        .cornerRadius(16)
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L("help_quick_actions"))
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primaryText)

            HStack(spacing: 12) {
                QuickActionButton(icon: "bolt.fill", color: .accentGold, title: L("help_no_connection")) {
                    selectedCategory = .connection
                }
                QuickActionButton(icon: "gauge", color: .accentCyan, title: L("help_slow_internet")) {
                    selectedCategory = .connection
                }
            }

            HStack(spacing: 12) {
                QuickActionButton(icon: "lock.open.fill", color: .accentRed, title: L("help_cant_connect")) {
                    selectedCategory = .connection
                }
                QuickActionButton(icon: "questionmark.circle", color: .accentBlue, title: L("help_how_to_use")) {
                    selectedCategory = .technical
                }
            }
        }
    }

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L("help_categories"))
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primaryText)

            ForEach(HelpCategory.allCases) { category in
                Button(action: { selectedCategory = category }) {
                    CustomCard {
                        HStack(spacing: 14) {
                            Image(systemName: category.icon)
                                .font(.system(size: 20))
                                .foregroundColor(category.color)
                                .frame(width: 44, height: 44)
                                .background(category.color.opacity(0.15))
                                .cornerRadius(12)

                            Text(category.displayName)
                                .font(.system(size: 16))
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
    }

    private var popularQuestionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L("help_faq"))
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primaryText)

            ForEach(popularQuestions, id: \.question) { item in
                FAQExpandableItem(question: item.question, answer: item.answer)
            }
        }
    }

    private let popularQuestions: [(question: String, answer: String)] = [
        (L("help_faq_q1"), L("help_faq_a1")),
        (L("help_faq_q2"), L("help_faq_a2")),
        (L("help_faq_q3"), L("help_faq_a3")),
        (L("help_faq_q4"), L("help_faq_a4"))
    ]

    private var contactSection: some View {
        CustomCard {
            VStack(spacing: 16) {
                Text(L("help_contact"))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primaryText)

                Text(L("help_contact_desc"))
                    .font(.system(size: 14))
                    .foregroundColor(.secondaryText)
                    .multilineTextAlignment(.center)

                Button(action: {}) {
                    HStack {
                        Image(systemName: "envelope.fill")
                        Text(L("help_email"))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(gradient: Gradient(colors: [.accentBlue, .accentCyan]), startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let color: Color
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                    .frame(width: 56, height: 56)
                    .background(color.opacity(0.15))
                    .cornerRadius(16)

                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(.primaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.cardBackground)
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FAQExpandableItem: View {
    let question: String
    let answer: String
    @State private var isExpanded = false

    var body: some View {
        CustomCard {
            VStack(alignment: .leading, spacing: 0) {
                Button(action: {
                    withAnimation(.easeInOut) {
                        isExpanded.toggle()
                    }
                }) {
                    HStack {
                        Text(question)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primaryText)
                            .multilineTextAlignment(.leading)

                        Spacer()

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.tertiaryText)
                    }
                }
                .buttonStyle(PlainButtonStyle())

                if isExpanded {
                    Text(answer)
                        .font(.system(size: 14))
                        .foregroundColor(.secondaryText)
                        .padding(.top, 12)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
    }
}

struct CategoryHelpView: View {
    let category: HelpView.HelpCategory
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(categoryQuestions, id: \.question) { item in
                            FAQExpandableItem(question: item.question, answer: item.answer)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            .navigationBarTitle(category.rawValue, displayMode: .inline)
            .navigationBarItems(trailing: Button(L("done")) {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }

    private var categoryQuestions: [(question: String, answer: String)] {
        switch category {
        case .connection:
            return [
                (L("help_conn_q1"), L("help_conn_a1")),
                (L("help_conn_q2"), L("help_conn_a2")),
                (L("help_conn_q3"), L("help_conn_a3"))
            ]
        case .account:
            return [
                (L("help_acc_q1"), L("help_acc_a1")),
                (L("help_acc_q2"), L("help_acc_a2"))
            ]
        case .security:
            return [
                (L("help_sec_q1"), L("help_sec_a1")),
                (L("help_sec_q2"), L("help_sec_a2"))
            ]
        case .technical:
            return [
                (L("help_tech_q1"), L("help_tech_a1")),
                (L("help_tech_q2"), L("help_tech_a2"))
            ]
        case .billing:
            return [
                (L("help_bill_q1"), L("help_bill_a1"))
            ]
        }
    }
}
