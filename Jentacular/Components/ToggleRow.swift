//
//  ToggleRow.swift
//  Jentacular
//
//  Settings row with toggle switch and description text
//

import SwiftUI

struct ToggleRow: View {
    let title: String
    let description: String
    @Binding var isOn: Bool
    let onToggle: ((Bool) -> Void)?

    init(title: String,
         description: String,
         isOn: Binding<Bool>,
         onToggle: ((Bool) -> Void)? = nil) {
        self.title = title
        self.description = description
        self._isOn = isOn
        self.onToggle = onToggle
    }

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primaryText)

                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { isOn },
                set: { newValue in
                    isOn = newValue
                    onToggle?(newValue)
                }
            ))
            .labelsHidden()
            .toggleStyle(SwitchToggleStyle(tint: .toggleOnColor))
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Navigation Row
struct NavigationRow: View {
    let iconName: String
    let iconColor: Color
    let title: String
    let value: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: iconName)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
                    .frame(width: 36, height: 36)
                    .background(iconColor.opacity(0.15))
                    .cornerRadius(10)

                Text(title)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.primaryText)

                Spacer()

                if let value = value {
                    Text(value)
                        .font(.system(size: 15))
                        .foregroundColor(.secondaryText)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.tertiaryText)
            }
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.tertiaryText)
            .padding(.top, 8)
            .padding(.bottom, 4)
    }
}
