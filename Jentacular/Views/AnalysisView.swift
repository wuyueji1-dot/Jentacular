//
//  AnalysisView.swift
//  Jentacular
//
//  Network analysis dashboard with real-time metrics, latency test, and stability
//

import SwiftUI

struct AnalysisView: View {
    // MARK: - Environment Objects
    @EnvironmentObject var analysisService: NetworkAnalysisService
    @EnvironmentObject var vpnService: VPNConnectionService

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection

                        // Network status cards (2x2 grid)
                        networkStatusGrid

                        // Latency test
                        latencyTestSection

                        // Network stability
                        stabilitySection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Анализ сети")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.primaryText)

            Text("Анализ вашего соединения в реальном времени")
                .font(.system(size: 16))
                .foregroundColor(.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Network Status Grid
    private var networkStatusGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            // Network Type
            MetricCard(
                iconName: "wifi",
                iconColor: .accentBlue,
                value: analysisService.metrics.networkType,
                label: "Тип сети"
            )

            // IP Status
            MetricCard(
                iconName: "eye",
                iconColor: vpnService.connectionStatus == .connected ? .accentGreen : .accentGold,
                value: ipStatusText,
                label: "Статус IP"
            )

            // Availability
            MetricCard(
                iconName: "antenna.radiowaves.left.and.right",
                iconColor: analysisService.metrics.availability == .online ? .accentGreen : .accentRed,
                value: availabilityText,
                label: "Доступность"
            )

            // Throttling
            MetricCard(
                iconName: "gauge.with.dots.needle.bottom.50percent",
                iconColor: analysisService.metrics.throttling == .throttled ? .accentOrange : .accentGreen,
                value: throttlingText,
                label: "Лимитная"
            )
        }
    }

    private var ipStatusText: String {
        analysisService.metrics.ipStatus == .protected ? "Защищен" : "Открыт"
    }

    private var availabilityText: String {
        analysisService.metrics.availability == .online ? "В сети" : "Не в сети"
    }

    private var throttlingText: String {
        analysisService.metrics.throttling == .throttled ? "Да" : "Нет"
    }

    // MARK: - Latency Test Section
    private var latencyTestSection: some View {
        CustomCard {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Text("Тест задержки")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primaryText)

                    Spacer()

                    Button(action: {
                        Task {
                            await analysisService.runLatencyTest()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 20))
                            .foregroundColor(.accentCyan)
                            .rotationEffect(.degrees(analysisService.isTesting ? 360 : 0))
                            .animation(analysisService.isTesting ? Animation.linear(duration: 1.0).repeatForever(autoreverses: false) : .default, value: analysisService.isTesting)
                    }
                    .disabled(analysisService.isTesting)
                }

                // Metrics
                HStack(spacing: 40) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(analysisService.metrics.latencyMs)")
                            .font(.system(size: 42, weight: .bold))
                            .foregroundColor(.primaryText)

                        Text("ms")
                            .font(.system(size: 16))
                            .foregroundColor(.secondaryText)

                        Text("Задержка")
                            .font(.system(size: 14))
                            .foregroundColor(.tertiaryText)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(analysisService.metrics.jitterMs)")
                            .font(.system(size: 42, weight: .bold))
                            .foregroundColor(.primaryText)

                        Text("ms")
                            .font(.system(size: 16))
                            .foregroundColor(.secondaryText)

                        Text("Джиттер")
                            .font(.system(size: 14))
                            .foregroundColor(.tertiaryText)
                    }
                }

                // Last test time
                if let lastTest = analysisService.lastTestDate {
                    Text("Последний тест: \(formattedDate(lastTest))")
                        .font(.system(size: 12))
                        .foregroundColor(.tertiaryText)
                }
            }
        }
    }

    // MARK: - Stability Section
    private var stabilitySection: some View {
        CustomCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Стабильность сети")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primaryText)

                // Progress bar
                VStack(alignment: .trailing, spacing: 8) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.dividerColor)
                                .frame(height: 12)

                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.accentCyan, .accentBlue]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * CGFloat(analysisService.metrics.stabilityPercent) / 100, height: 12)
                        }
                    }
                    .frame(height: 12)

                    Text("\(analysisService.metrics.stabilityPercent)%")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.accentCyan)
                }

                // Stability description
                Text(stabilityDescription)
                    .font(.system(size: 14))
                    .foregroundColor(.secondaryText)
            }
        }
    }

    private var stabilityDescription: String {
        switch analysisService.metrics.stabilityPercent {
        case 0...30:
            return "Нестабильное соединение. Возможны потери пакетов и обрывы."
        case 31...60:
            return "Средняя стабильность. Рекомендуется выбрать сервер с меньшей загрузкой."
        case 61...85:
            return "Хорошая стабильность. Соединение работает без значительных проблем."
        default:
            return "Отличная стабильность. Соединение работает идеально."
        }
    }

    // MARK: - Helper
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}
