//
//  ThemeManager.swift
//  Jentacular
//
//  Dynamic theme management with custom color schemes and appearance settings
//  Original implementation supporting light/dark/system modes with accent customization
//

import Foundation
import SwiftUI
import Combine

final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    // MARK: - Theme Mode
    enum ThemeMode: String, CaseIterable, Identifiable {
        case system = "system"
        case light = "light"
        case dark = "dark"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .system: return L("theme_system")
            case .light: return L("theme_light")
            case .dark: return L("theme_dark")
            }
        }

        var iconName: String {
            switch self {
            case .system: return "circle.lefthalf.filled"
            case .light: return "sun.max.fill"
            case .dark: return "moon.fill"
            }
        }

        var colorScheme: ColorScheme? {
            switch self {
            case .system: return nil
            case .light: return .light
            case .dark: return .dark
            }
        }
    }

    // MARK: - Accent Color
    enum AccentColor: String, CaseIterable, Identifiable {
        case cyan = "cyan"
        case blue = "blue"
        case green = "green"
        case purple = "purple"
        case gold = "gold"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .cyan: return L("accent_turquoise")
            case .blue: return L("accent_blue")
            case .green: return L("accent_green")
            case .purple: return L("accent_purple")
            case .gold: return L("accent_gold")
            }
        }

        var color: Color {
            switch self {
            case .cyan: return Color(red: 0.0, green: 0.8, blue: 0.9)
            case .blue: return Color(red: 0.2, green: 0.4, blue: 1.0)
            case .green: return Color(red: 0.2, green: 0.85, blue: 0.4)
            case .purple: return Color(red: 0.6, green: 0.3, blue: 0.9)
            case .gold: return Color(red: 1.0, green: 0.75, blue: 0.2)
            }
        }
    }

    // MARK: - Published
    @Published var currentMode: ThemeMode = .dark
    @Published var currentAccent: AccentColor = .cyan
    @Published var reduceMotion: Bool = false
    @Published var increaseContrast: Bool = false

    // MARK: - Private
    private let userDefaults = UserDefaults.standard
    private let modeKey = "jentacular_theme_mode"
    private let accentKey = "jentacular_accent_color"
    private let reduceMotionKey = "jentacular_reduce_motion"
    private let contrastKey = "jentacular_increase_contrast"

    private init() {
        loadPreferences()
    }

    // MARK: - Load/Save
    private func loadPreferences() {
        if let modeRaw = userDefaults.string(forKey: modeKey),
           let mode = ThemeMode(rawValue: modeRaw) {
            currentMode = mode
        }

        if let accentRaw = userDefaults.string(forKey: accentKey),
           let accent = AccentColor(rawValue: accentRaw) {
            currentAccent = accent
        }

        reduceMotion = userDefaults.bool(forKey: reduceMotionKey)
        increaseContrast = userDefaults.bool(forKey: contrastKey)
    }

    func savePreferences() {
        userDefaults.set(currentMode.rawValue, forKey: modeKey)
        userDefaults.set(currentAccent.rawValue, forKey: accentKey)
        userDefaults.set(reduceMotion, forKey: reduceMotionKey)
        userDefaults.set(increaseContrast, forKey: contrastKey)
    }

    // MARK: - Computed Colors
    var primaryBackground: Color {
        if increaseContrast {
            return currentMode == .light ? Color.white : Color.black
        }
        return currentMode == .light ? Color(red: 0.96, green: 0.97, blue: 0.98) : Color(red: 0.05, green: 0.07, blue: 0.12)
    }

    var secondaryBackground: Color {
        currentMode == .light ? Color.white : Color(red: 0.09, green: 0.11, blue: 0.17)
    }

    var cardBackground: Color {
        currentMode == .light ? Color.white : Color(red: 0.11, green: 0.14, blue: 0.21)
    }

    var primaryText: Color {
        currentMode == .light ? Color(red: 0.08, green: 0.09, blue: 0.12) : Color.white
    }

    var secondaryText: Color {
        currentMode == .light ? Color(red: 0.4, green: 0.45, blue: 0.55) : Color(red: 0.6, green: 0.65, blue: 0.75)
    }

    var tertiaryText: Color {
        currentMode == .light ? Color(red: 0.6, green: 0.65, blue: 0.72) : Color(red: 0.4, green: 0.45, blue: 0.55)
    }

    var dividerColor: Color {
        currentMode == .light ? Color(red: 0.88, green: 0.9, blue: 0.93) : Color(red: 0.18, green: 0.22, blue: 0.3)
    }

    var accentColor: Color {
        currentAccent.color
    }

    var gradientStart: Color {
        currentAccent.color.opacity(0.9)
    }

    var gradientEnd: Color {
        currentAccent.color.opacity(0.6)
    }

    // MARK: - Animation Duration
    var defaultAnimationDuration: Double {
        reduceMotion ? 0.1 : 0.3
    }

    var springAnimation: Animation {
        if reduceMotion {
            return .easeInOut(duration: 0.1)
        }
        return .spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.2)
    }

    // MARK: - Theme Application
    var preferredColorScheme: ColorScheme? {
        currentMode.colorScheme
    }

    func applyTheme() {
        savePreferences()
        AppLogger.shared.info(.ui, "Theme applied: mode=\(currentMode.rawValue), accent=\(currentAccent.rawValue)")
    }

    func cycleThemeMode() {
        let allModes = ThemeMode.allCases
        if let currentIndex = allModes.firstIndex(of: currentMode) {
            let nextIndex = (currentIndex + 1) % allModes.count
            currentMode = allModes[nextIndex]
            applyTheme()
        }
    }

    func cycleAccentColor() {
        let allAccents = AccentColor.allCases
        if let currentIndex = allAccents.firstIndex(of: currentAccent) {
            let nextIndex = (currentIndex + 1) % allAccents.count
            currentAccent = allAccents[nextIndex]
            applyTheme()
        }
    }
}
