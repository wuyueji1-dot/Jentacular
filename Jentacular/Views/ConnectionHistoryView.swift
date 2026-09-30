//
//  ConnectionHistoryView.swift
//  Jentacular
//
//  Displays VPN connection history with server info, duration, and network type
//

import SwiftUI

struct ConnectionHistoryView: View {
    // MARK: - Environment Objects
    @EnvironmentObject var historyService: ConnectionHistoryService
    @Environment(\.dismiss) private var dismiss

    // MARK: - State
    @State private var showClearConfirmation = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                if historyService.history.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(historyService.history) { entry in
                                HistoryEntryRow(entry: entry)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("История подключений")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primaryText)
                },
                trailing: Button(action: { showClearConfirmation = true }) {
                    Image(systemName: "trash")
                        .font(.system(size: 18))
                        .foregroundColor(.accentRed)
                }
                .disabled(historyService.history.isEmpty)
            )
            .alert(isPresented: $showClearConfirmation) {
                Alert(
                    title: Text("Очистить историю?"),
                    message: Text("Все записи истории подключений будут удалены безвозвратно."),
                    primaryButton: .destructive(Text("Очистить")) {
                        historyService.clearHistory()
                    },
                    secondaryButton: .cancel(Text("Отмена"))
                )
            }
        }
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 64))
                .foregroundColor(.tertiaryText)

            Text("История пуста")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.primaryText)

            Text("Здесь будут отображаться ваши подключения к VPN")
                .font(.system(size: 15))
                .foregroundColor(.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

// MARK: - History Entry Row
struct HistoryEntryRow: View {
    let entry: ConnectionHistoryEntry

    var body: some View {
        HStack(spacing: 16) {
            // Flag
            Text(VPNServerNode.flagEmoji(for: entry.countryCode))
                .font(.system(size: 32))
                .frame(width: 48, height: 48)
                .background(Color.cardBackgroundHighlighted)
                .cornerRadius(12)

            // Server info
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.serverName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primaryText)

                Text(entry.formattedDate)
                    .font(.system(size: 13))
                    .foregroundColor(.secondaryText)
            }

            Spacer()

            // Duration and network type
            VStack(alignment: .trailing, spacing: 6) {
                Text(entry.formattedDuration)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.accentCyan)

                NetworkTypeBadge(type: entry.networkType)
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(20)
    }
}

// MARK: - Network Type Badge
struct NetworkTypeBadge: View {
    let type: NetworkType

    var body: some View {
        Text(displayText)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .cornerRadius(8)
    }

    private var displayText: String {
        switch type {
        case .wifi: return "Wi-Fi"
        case .cellular: return "Сеть"
        case .none: return "Нет сети"
        }
    }

    private var backgroundColor: Color {
        switch type {
        case .wifi: return .accentBlue
        case .cellular: return .accentGreen
        case .none: return .accentRed
        }
    }
}
