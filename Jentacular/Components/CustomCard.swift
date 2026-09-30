//
//  CustomCard.swift
//  Jentacular
//
//  Reusable card view with consistent styling
//

import SwiftUI

struct CustomCard<Content: View>: View {
    var content: Content
    var padding: CGFloat = 20
    var cornerRadius: CGFloat = 20
    var backgroundColor: Color = .cardBackground

    init(padding: CGFloat = 20,
         cornerRadius: CGFloat = 20,
         backgroundColor: Color = .cardBackground,
         @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.backgroundColor = backgroundColor
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
    }
}

// MARK: - Card with Icon
struct IconCard: View {
    let iconName: String
    let iconColor: Color
    let title: String
    let description: String
    let statusIcon: String?
    let statusColor: Color?

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: iconName)
                .font(.system(size: 28))
                .foregroundColor(iconColor)
                .frame(width: 44, height: 44)
                .background(iconColor.opacity(0.15))
                .cornerRadius(12)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primaryText)

                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondaryText)
            }

            Spacer()

            if let statusIcon = statusIcon, let statusColor = statusColor {
                Image(systemName: statusIcon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(statusColor)
            }
        }
        .padding(20)
        .background(Color.cardBackground)
        .cornerRadius(20)
    }
}

// MARK: - Metric Card (2x2 grid)
struct MetricCard: View {
    let iconName: String
    let iconColor: Color
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: iconName)
                .font(.system(size: 28))
                .foregroundColor(iconColor)

            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primaryText)

            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.cardBackground)
        .cornerRadius(20)
    }
}
