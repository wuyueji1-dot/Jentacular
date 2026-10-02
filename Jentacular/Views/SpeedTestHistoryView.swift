//
//  SpeedTestHistoryView.swift
//  Jentacular
//
//  Speed test history with statistics, charts, and export functionality
//

import SwiftUI

struct SpeedTestHistoryView: View {
    // MARK: - Environment
    @EnvironmentObject var speedTestService: SpeedTestHistoryService
    @Environment(\.presentationMode) var presentationMode

    // MARK: - State
    @State private var showClearConfirmation = false
    @State private var selectedRange: Int = 7 // days
    @State private var showShareSheet = false
    @State private var exportURL: URL?

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerSection

                // Statistics cards
                statisticsSection

                // Range selector
                rangeSelectorSection

                // History list
                ScrollView {
                    if filteredHistory.isEmpty {
                        emptyStateSection
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredHistory) { record in
                                SpeedTestRecordRow(record: record)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .navigationBarTitle(L("speed_history"), displayMode: .inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(
            leading: backButton,
            trailing: !speedTestService.history.isEmpty ?
                Button(action: { showClearConfirmation = true }) {
                    Image(systemName: "trash")
                        .foregroundColor(.accentRed)
                } : nil
        )
        .alert(isPresented: $showClearConfirmation) {
            Alert(
                title: Text(L("clear_history_question")),
                message: Text(L("clear_speed_history_desc")),
                primaryButton: .destructive(Text(L("clear"))) {
                    speedTestService.clearHistory()
                },
                secondaryButton: .cancel()
            )
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = exportURL {
                ShareSheet(url: url)
            }
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

    // MARK: - Header
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(L("speed_history"))
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primaryText)
            Text(String(format: L("records_count"), speedTestService.history.count))
                .font(.system(size: 15))
                .foregroundColor(.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }

    // MARK: - Statistics
    private var statisticsSection: some View {
        HStack(spacing: 12) {
            StatCard(
                icon: "arrow.down.circle.fill",
                iconColor: .accentGreen,
                value: String(format: "%.0f", speedTestService.averageDownload),
                unit: "Mbps",
                label: L("download")
            )
            StatCard(
                icon: "arrow.up.circle.fill",
                iconColor: .accentBlue,
                value: String(format: "%.0f", speedTestService.averageUpload),
                unit: "Mbps",
                label: L("upload")
            )
            StatCard(
                icon: "clock.fill",
                iconColor: .accentGold,
                value: "\(speedTestService.averagePing)",
                unit: "ms",
                label: L("ping")
            )
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    // MARK: - Range Selector
    private var rangeSelectorSection: some View {
        HStack(spacing: 8) {
            RangeButton(title: L("7_days"), isSelected: selectedRange == 7) { selectedRange = 7 }
            RangeButton(title: L("30_days"), isSelected: selectedRange == 30) { selectedRange = 30 }
            RangeButton(title: L("all"), isSelected: selectedRange == 0) { selectedRange = 0 }
            Spacer()
            if let url = speedTestService.exportHistory() {
                Button(action: {
                    exportURL = url
                    showShareSheet = true
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.accentCyan)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.cardBackground)
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    private var filteredHistory: [SpeedTestHistoryService.SpeedTestRecord] {
        if selectedRange == 0 {
            return speedTestService.history
        }
        return speedTestService.history(forLast: selectedRange)
    }

    // MARK: - Empty State
    private var emptyStateSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 48))
                .foregroundColor(.tertiaryText)

            Text(L("speed_history_empty"))
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primaryText)

            Text(L("speed_history_empty_desc"))
                .font(.system(size: 14))
                .foregroundColor(.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 80)
        .padding(.horizontal, 40)
    }
}

// MARK: - Helper Components
struct StatCard: View {
    let icon: String
    let iconColor: Color
    let value: String
    let unit: String
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(iconColor)

            HStack(alignment: .bottom, spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primaryText)
                Text(unit)
                    .font(.system(size: 10))
                    .foregroundColor(.secondaryText)
                    .padding(.bottom, 3)
            }

            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.tertiaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.cardBackground)
        .cornerRadius(14)
    }
}

struct RangeButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isSelected ? .white : .secondaryText)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.accentBlue : Color.cardBackground)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SpeedTestRecordRow: View {
    let record: SpeedTestHistoryService.SpeedTestRecord

    var body: some View {
        CustomCard {
            VStack(spacing: 12) {
                // Header
                HStack {
                    Text(record.timestamp.formattedForHistory)
                        .font(.system(size: 14))
                        .foregroundColor(.secondaryText)
                    Spacer()
                    Text(record.networkType)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.accentCyan)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.accentCyan.opacity(0.15))
                        .cornerRadius(6)
                }

                // Server
                HStack {
                    Image(systemName: "server.rack")
                        .font(.system(size: 14))
                        .foregroundColor(.tertiaryText)
                    Text(record.serverName)
                        .font(.system(size: 14))
                        .foregroundColor(.primaryText)
                    Spacer()
                }

                // Speeds
                HStack(spacing: 20) {
                    SpeedItem(
                        icon: "arrow.down",
                        iconColor: .accentGreen,
                        value: String(format: "%.1f", record.downloadSpeed),
                        unit: "Mbps",
                        label: L("download")
                    )
                    SpeedItem(
                        icon: "arrow.up",
                        iconColor: .accentBlue,
                        value: String(format: "%.1f", record.uploadSpeed),
                        unit: "Mbps",
                        label: L("upload")
                    )
                    SpeedItem(
                        icon: "clock",
                        iconColor: .accentGold,
                        value: "\(record.ping)",
                        unit: "ms",
                        label: L("ping")
                    )
                    SpeedItem(
                        icon: "waveform",
                        iconColor: .accentPurple,
                        value: String(format: "%.1f", record.jitter),
                        unit: "ms",
                        label: L("jitter")
                    )
                }
            }
        }
    }
}

struct SpeedItem: View {
    let icon: String
    let iconColor: Color
    let value: String
    let unit: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(iconColor)
            HStack(alignment: .bottom, spacing: 1) {
                Text(value)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primaryText)
                Text(unit)
                    .font(.system(size: 9))
                    .foregroundColor(.secondaryText)
                    .padding(.bottom, 2)
            }
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.tertiaryText)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Share Sheet (iOS 15 compatible)
struct ShareSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
