//
//  RootTabView.swift
//  Jentacular
//
//  Main tab bar navigation with 5 tabs: Home, Shield, Servers, Analysis, Settings
//

import SwiftUI

struct RootTabView: View {
    // MARK: - Environment Objects
    @EnvironmentObject var vpnService: VPNConnectionService
    @EnvironmentObject var securityService: SecurityScoreService
    @EnvironmentObject var analysisService: NetworkAnalysisService
    @EnvironmentObject var settingsService: SettingsService
    @EnvironmentObject var historyService: ConnectionHistoryService

    // MARK: - State
    @State private var selectedTab: Tab

    init() {
        let initialTabIndex = UserDefaults.standard.integer(forKey: "initial_tab")
        _selectedTab = State(initialValue: Tab(rawValue: initialTabIndex) ?? .home)
    }

    enum Tab: Int, CaseIterable {
        case home
        case shield
        case servers
        case analysis
        case settings

        var iconName: String {
            switch self {
            case .home: return "bolt.shield"
            case .shield: return "shield"
            case .servers: return "globe"
            case .analysis: return "chart.bar"
            case .settings: return "gearshape"
            }
        }

        var selectedIconName: String {
            switch self {
            case .home: return "bolt.shield.fill"
            case .shield: return "shield.fill"
            case .servers: return "globe"
            case .analysis: return "chart.bar.fill"
            case .settings: return "gearshape.fill"
            }
        }

        var title: String {
            switch self {
            case .home: return L("home_tab")
            case .shield: return L("shield_tab")
            case .servers: return L("servers_tab")
            case .analysis: return L("analysis_tab")
            case .settings: return L("settings_tab")
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: selectedTab == .home ? Tab.home.selectedIconName : Tab.home.iconName)
                    Text(Tab.home.title)
                }
                .tag(Tab.home)

            ShieldView()
                .tabItem {
                    Image(systemName: selectedTab == .shield ? Tab.shield.selectedIconName : Tab.shield.iconName)
                    Text(Tab.shield.title)
                }
                .tag(Tab.shield)

            ServersView()
                .tabItem {
                    Image(systemName: selectedTab == .servers ? Tab.servers.selectedIconName : Tab.servers.iconName)
                    Text(Tab.servers.title)
                }
                .tag(Tab.servers)

            AnalysisView()
                .tabItem {
                    Image(systemName: selectedTab == .analysis ? Tab.analysis.selectedIconName : Tab.analysis.iconName)
                    Text(Tab.analysis.title)
                }
                .tag(Tab.analysis)

            SettingsView()
                .tabItem {
                    Image(systemName: selectedTab == .settings ? Tab.settings.selectedIconName : Tab.settings.iconName)
                    Text(Tab.settings.title)
                }
                .tag(Tab.settings)
        }
        .accentColor(.accentBlue)
        .onAppear {
            securityService.startMonitoring()
        }
    }
}
