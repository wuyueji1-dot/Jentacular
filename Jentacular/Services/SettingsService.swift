//
//  SettingsService.swift
//  Jentacular
//
//  Manages app settings persistence and user preferences
//

import Foundation
import Combine

final class SettingsService: ObservableObject {
    static let shared = SettingsService()

    // MARK: - Published Properties
    @Published var autoConnectEnabled: Bool
    @Published var wifiOnlyEnabled: Bool
    @Published var notificationsEnabled: Bool
    @Published var selectedLanguage: AppLanguage

    // MARK: - Private Properties
    private let defaults = UserDefaults.standard

    private init() {
        // Load saved settings or use defaults
        self.autoConnectEnabled = defaults.bool(forKey: AppConstants.UserDefaultsKeys.autoConnectEnabled)
        self.wifiOnlyEnabled = defaults.object(forKey: AppConstants.UserDefaultsKeys.wifiOnlyEnabled) as? Bool ?? true
        self.notificationsEnabled = defaults.object(forKey: AppConstants.UserDefaultsKeys.notificationsEnabled) as? Bool ?? true

        if let savedLang = defaults.string(forKey: AppConstants.UserDefaultsKeys.selectedLanguage),
           let language = AppLanguage(rawValue: savedLang) {
            self.selectedLanguage = language
        } else {
            self.selectedLanguage = .system
        }
    }

    // MARK: - Update Settings
    func setAutoConnect(_ enabled: Bool) {
        autoConnectEnabled = enabled
        defaults.set(enabled, forKey: AppConstants.UserDefaultsKeys.autoConnectEnabled)
    }

    func setWifiOnly(_ enabled: Bool) {
        wifiOnlyEnabled = enabled
        defaults.set(enabled, forKey: AppConstants.UserDefaultsKeys.wifiOnlyEnabled)
    }

    func setNotifications(_ enabled: Bool) {
        notificationsEnabled = enabled
        defaults.set(enabled, forKey: AppConstants.UserDefaultsKeys.notificationsEnabled)

        if enabled {
            requestNotificationPermissions()
        }
    }

    func setLanguage(_ language: AppLanguage) {
        selectedLanguage = language
        defaults.set(language.rawValue, forKey: AppConstants.UserDefaultsKeys.selectedLanguage)
        LocalizationManager.shared.setLanguage(language)
    }

    // MARK: - Notification Permissions
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }

    // MARK: - Send Connection Status Notification
    func sendConnectionStatusNotification(status: ConnectionStatus) {
        guard notificationsEnabled else { return }

        let content = UNMutableNotificationContent()
        content.sound = .default

        switch status {
        case .connected:
            content.title = "VPN Подключен"
            content.body = "Ваше соединение защищено"
        case .disconnected:
            content.title = "VPN Отключен"
            content.body = "Ваше соединение больше не защищено"
        default:
            return
        }

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Reset All Settings
    func resetAllSettings() {
        autoConnectEnabled = false
        wifiOnlyEnabled = true
        notificationsEnabled = true
        selectedLanguage = .system

        defaults.removeObject(forKey: AppConstants.UserDefaultsKeys.autoConnectEnabled)
        defaults.removeObject(forKey: AppConstants.UserDefaultsKeys.wifiOnlyEnabled)
        defaults.removeObject(forKey: AppConstants.UserDefaultsKeys.notificationsEnabled)
        defaults.removeObject(forKey: AppConstants.UserDefaultsKeys.selectedLanguage)
    }
}
