//
//  ServerRow.swift
//  Jentacular
//
//  Server list row component with flag, ping, load indicator, and selection state
//

import SwiftUI

struct ServerRow: View {
    let server: VPNServerNode
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Flag
                Text(server.flagEmoji)
                    .font(.system(size: 36))
                    .frame(width: 48, height: 48)
                    .background(Color.cardBackgroundHighlighted)
                    .cornerRadius(12)

                // Server info
                VStack(alignment: .leading, spacing: 6) {
                    Text(server.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primaryText)

                    Text(String(format: L("server_location_format"), server.city, server.country))
                        .font(.system(size: 14))
                        .foregroundColor(.secondaryText)

                    // Load indicator
                    LoadIndicatorBar(loadPercent: server.loadPercent)
                }

                Spacer()

                // Ping and selection
                VStack(alignment: .trailing, spacing: 8) {
                    Text("\(server.pingMs) ms")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(pingColor)

                    // Selection indicator
                    ZStack {
                        Circle()
                            .stroke(isSelected ? Color.accentCyan : Color.tertiaryText, lineWidth: 2)
                            .frame(width: 28, height: 28)

                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .background(
                                    Circle()
                                        .fill(Color.accentCyan)
                                        .frame(width: 24, height: 24)
                                )
                        }
                    }
                }
            }
            .padding(16)
            .background(isSelected ? Color.cardBackgroundHighlighted : Color.cardBackground)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.accentCyan.opacity(0.5) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var pingColor: Color {
        switch server.pingMs {
        case 0...50: return .accentGreen
        case 51...100: return .accentCyan
        case 101...200: return .accentOrange
        default: return .accentRed
        }
    }
}

// MARK: - Load Indicator Bar
struct LoadIndicatorBar: View {
    let loadPercent: Int

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.dividerColor)
                    .frame(height: 8)

                RoundedRectangle(cornerRadius: 3)
                    .fill(loadColor)
                    .frame(width: geometry.size.width * CGFloat(min(loadPercent, 100)) / 100, height: 8)
            }
        }
        .frame(height: 8)
    }

    private var loadColor: Color {
        switch loadPercent {
        case 0...30: return .accentGreen
        case 31...60: return .accentGold
        case 61...85: return .accentOrange
        default: return .accentRed
        }
    }
}
