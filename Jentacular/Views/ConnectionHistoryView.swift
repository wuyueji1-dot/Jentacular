//
//  ConnectionHistoryView.swift
//  Jentacular
//
//  Displays VPN connection history with statistics and per-session details
//

import SwiftUI

struct ConnectionHistoryView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var historyService: ConnectionHistoryService

    @State private var selectedFilter: HistoryFilter = .all
    @State private var showClearConfirmation = false

    enum HistoryFilter: String, CaseIterable {
        case sevenDays = "7 days"
        case thirtyDays = "30 days"
        case all = "All"

        var days: Int? {
            switch self {
            case .sevenDays: return 7
            case .thirtyDays: return 30
            case .all: return nil
            }
        }
    }

    private var filteredRecords: [ConnectionHistoryRecord] {
        if let days = selectedFilter.days {
            return historyService.records(forLastDays: days)
        }
        return historyService.records
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerSection

                // Statistics cards
                statisticsSection

                // Filter
                filterSection

                // History list
                ScrollView(showsIndicators: false) {
                    if filteredRecords.isEmpty {
                        emptyStateSection
                    } else {
                        LazyVStack(spacing: 10) {
                            ForEach(filteredRecords) { record in
                                HistoryRecordRow(record: record)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .navigationBarTitle("Connection History", displayMode: .inline)
        .navigationBarItems(
            leading: Button(action: { presentationMode.wrappedValue.dismiss() }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 16))
                }
                .foregroundColor(.accentCyan)
            },
            trailing: Button(action: { showClearConfirmation = true }) {
                Image(systemName: "trash")
                    .foregroundColor(.accentRed)
            }
            .disabled(historyService.records.isEmpty)
            .opacity(historyService.records.isEmpty ? 0.3 : 1.0)
        )
        .alert(isPresented: $showClearConfirmation) {
            Alert(
                title: Text("Clear History"),
                message: Text("Are you sure you want to clear all connection history? This cannot be undone."),
                primaryButton: .destructive(Text("Clear")) {
                    historyService.clearHistory()
                },
                secondaryButton: .cancel()
            )
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Connection History")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primaryText)

            Text("\(historyService.totalConnections) sessions • \(historyService.formattedTotalTime) total")
                .font(.system(size: 14))
                .foregroundColor(.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 16)
    }

    // MARK: - Statistics
    private var statisticsSection: some View {
        HStack(spacing: 12) {
            StatCard(
                icon: "arrow.down.circle.fill",
                iconColor: .accentGreen,
                value: String(format: "%.1f", historyService.avgDownload),
                unit: "Mbps",
                label: "Avg Download"
            )

            StatCard(
                icon: "arrow.up.circle.fill",
                iconColor: .accentBlue,
                value: String(format: "%.1f", historyService.avgUpload),
                unit: "Mbps",
                label: "Avg Upload"
            )

            StatCard(
                icon: "clock.fill",
                iconColor: .accentGold,
                value: "\(historyService.avgPing)",
                unit: "ms",
                label: "Avg Ping"
            )
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }

    // MARK: - Filter
    private var filterSection: some View {
        HStack(spacing: 10) {
            ForEach(HistoryFilter.allCases, id: \.self) { filter in
                Button(action: { selectedFilter = filter }) {
                    Text(filter.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(selectedFilter == filter ? .white : .secondaryText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(selectedFilter == filter ? Color.accentBlue : Color.cardBackground)
                        )
                }
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    // MARK: - Empty State
    private var emptyStateSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar")
                .font(.system(size: 48))
                .foregroundColor(.tertiaryText)

            Text("No history yet")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primaryText)

            Text("Your VPN connection history will appear here after you connect.")
                .font(.system(size: 14))
                .foregroundColor(.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.top, 80)
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let icon: String
    let iconColor: Color
    let value: String
    let unit: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(iconColor)

            HStack(alignment: .bottom, spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primaryText)
                Text(unit)
                    .font(.system(size: 11))
                    .foregroundColor(.tertiaryText)
                    .padding(.bottom, 3)
            }

            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.cardBackground)
        .cornerRadius(14)
    }
}

// MARK: - History Record Row
struct HistoryRecordRow: View {
    let record: ConnectionHistoryRecord

    var body: some View {
        HStack(spacing: 14) {
            // Status icon
            ZStack {
                Circle()
                    .fill(record.wasSuccessful ? Color.accentGreen.opacity(0.15) : Color.accentRed.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: record.wasSuccessful ? "checkmark" : "xmark")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(record.wasSuccessful ? .accentGreen : .accentRed)
            }

            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(record.serverName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primaryText)

                Text(record.formattedDate)
                    .font(.system(size: 12))
                    .foregroundColor(.tertiaryText)

                HStack(spacing: 12) {
                    Label("\(record.formattedDuration)", systemImage: "clock")
                        .font(.system(size: 12))
                        .foregroundColor(.secondaryText)

                    Label("\(record.avgPingMs)ms", systemImage: "wifi")
                        .font(.system(size: 12))
                        .foregroundColor(.secondaryText)
                }
            }

            Spacer()

            // Speed
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 2) {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 10))
                        .foregroundColor(.accentGreen)
                    Text(String(format: "%.0f", record.avgDownloadMbps))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.accentGreen)
                }
                HStack(spacing: 2) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 10))
                        .foregroundColor(.accentBlue)
                    Text(String(format: "%.0f", record.avgUploadMbps))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.accentBlue)
                }
            }
        }
        .padding(14)
        .background(Color.cardBackground)
        .cornerRadius(14)
    }
}
