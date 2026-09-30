//
//  ColorExtensions.swift
//  Jentacular
//
//  Custom color palette for the app design system
//

import SwiftUI

extension Color {
    // Background colors
    static let appBackground = Color(red: 0.04, green: 0.05, blue: 0.09)
    static let cardBackground = Color(red: 0.09, green: 0.10, blue: 0.15)
    static let cardBackgroundHighlighted = Color(red: 0.12, green: 0.14, blue: 0.20)

    // Accent colors
    static let accentCyan = Color(red: 0.25, green: 0.85, blue: 0.90)
    static let accentBlue = Color(red: 0.35, green: 0.55, blue: 0.95)
    static let accentGold = Color(red: 0.90, green: 0.75, blue: 0.40)
    static let accentRed = Color(red: 0.90, green: 0.30, blue: 0.35)
    static let accentGreen = Color(red: 0.30, green: 0.80, blue: 0.55)
    static let accentOrange = Color(red: 0.95, green: 0.65, blue: 0.30)
    static let accentPurple = Color(red: 0.60, green: 0.45, blue: 0.90)

    // Text colors
    static let primaryText = Color.white
    static let secondaryText = Color(red: 0.65, green: 0.68, blue: 0.75)
    static let tertiaryText = Color(red: 0.45, green: 0.48, blue: 0.55)

    // UI element colors
    static let dividerColor = Color(red: 0.15, green: 0.17, blue: 0.22)
    static let toggleOnColor = Color(red: 0.40, green: 0.55, blue: 0.95)
    static let toggleOffColor = Color(red: 0.25, green: 0.27, blue: 0.32)
}

extension UIColor {
    static let appBackground = UIColor(red: 0.04, green: 0.05, blue: 0.09, alpha: 1.0)
    static let cardBackground = UIColor(red: 0.09, green: 0.10, blue: 0.15, alpha: 1.0)
}
