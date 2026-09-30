//
//  ServersView.swift
//  Jentacular
//
//  Server selection list with search, sorting, and country filtering
//

import SwiftUI

struct ServersView: View {
    // MARK: - Environment Objects
    @EnvironmentObject var vpnService: VPNConnectionService

    // MARK: - State
    @State private var searchText = ""
    @State private var selectedSort: ServerSortOption = .recommended
    @State private var showSortMenu = false
    @State private var selectedCountry: String? = nil
    @State private var selectedServerId: String? = AppConstants.vpnServerName

    // MARK: - Sample Server Data
    private let allServers: [VPNServerNode] = [
        VPNServerNode(
            id: "france-1",
            name: "France",
            country: "France",
            countryCode: "FR",
            city: "Paris",
            ipAddress: AppConstants.vpnServerAddress,
            pingMs: 45,
            loadPercent: 35,
            isSelected: true
        ),
        VPNServerNode(
            id: "germany-1",
            name: "Frankfurt",
            country: "Germany",
            countryCode: "DE",
            city: "Frankfurt",
            ipAddress: "de.example.com",
            pingMs: 52,
            loadPercent: 48,
            isSelected: false
        ),
        VPNServerNode(
            id: "netherlands-1",
            name: "Amsterdam",
            country: "Netherlands",
            countryCode: "NL",
            city: "Amsterdam",
            ipAddress: "nl.example.com",
            pingMs: 58,
            loadPercent: 62,
            isSelected: false
        ),
        VPNServerNode(
            id: "uk-1",
            name: "London",
            country: "United Kingdom",
            countryCode: "GB",
            city: "London",
            ipAddress: "uk.example.com",
            pingMs: 65,
            loadPercent: 41,
            isSelected: false
        ),
        VPNServerNode(
            id: "usa-1",
            name: "New York",
            country: "United States",
            countryCode: "US",
            city: "New York",
            ipAddress: "us.example.com",
            pingMs: 120,
            loadPercent: 55,
            isSelected: false
        ),
        VPNServerNode(
            id: "japan-1",
            name: "Tokyo",
            country: "Japan",
            countryCode: "JP",
            city: "Tokyo",
            ipAddress: "jp.example.com",
            pingMs: 180,
            loadPercent: 30,
            isSelected: false
        ),
        VPNServerNode(
            id: "singapore-1",
            name: "Singapore",
            country: "Singapore",
            countryCode: "SG",
            city: "Singapore",
            ipAddress: "sg.example.com",
            pingMs: 160,
            loadPercent: 45,
            isSelected: false
        )
    ]

    private var countries: [String] {
        Array(Set(allServers.map { $0.country })).sorted()
    }

    private var filteredServers: [VPNServerNode] {
        var result = allServers

        // Filter by search
        if !searchText.isEmpty {
            result = result.filter { server in
                server.name.localizedCaseInsensitiveContains(searchText) ||
                server.country.localizedCaseInsensitiveContains(searchText) ||
                server.city.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Filter by country
        if let country = selectedCountry {
            result = result.filter { $0.country == country }
        }

        // Sort
        switch selectedSort {
        case .recommended:
            result = result.sorted { $0.pingMs < $1.pingMs }
        case .lowestPing:
            result = result.sorted { $0.pingMs < $1.pingMs }
        case .lowestLoad:
            result = result.sorted { $0.loadPercent < $1.loadPercent }
        case .name:
            result = result.sorted { $0.name < $1.name }
        }

        return result
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    headerSection

                    // Search bar
                    searchSection

                    // Sort and filter
                    sortFilterSection

                    // Server list
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredServers) { server in
                                ServerRow(
                                    server: server,
                                    isSelected: selectedServerId == server.id
                                ) {
                                    selectServer(server)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Обзор серверов")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.primaryText)

            Text("Выберите узел подключения")
                .font(.system(size: 16))
                .foregroundColor(.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }

    // MARK: - Search Section
    private var searchSection: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.tertiaryText)
                .padding(.leading, 16)

            TextField("Поиск страны или города", text: $searchText)
                .font(.system(size: 16))
                .foregroundColor(.primaryText)
                .padding(.vertical, 14)
        }
        .background(Color.cardBackground)
        .cornerRadius(16)
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    // MARK: - Sort and Filter Section
    private var sortFilterSection: some View {
        VStack(spacing: 12) {
            // Sort button
            HStack {
                Text("Сортировка")
                    .font(.system(size: 14))
                    .foregroundColor(.secondaryText)

                Spacer()

                Button(action: { showSortMenu.toggle() }) {
                    HStack(spacing: 8) {
                        Text(selectedSort.displayName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.accentCyan)

                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 14))
                            .foregroundColor(.accentCyan)
                    }
                }
            }
            .padding(.horizontal, 20)

            // Sort menu
            if showSortMenu {
                VStack(spacing: 0) {
                    ForEach(ServerSortOption.allCases) { option in
                        Button(action: {
                            selectedSort = option
                            showSortMenu = false
                        }) {
                            HStack {
                                if option == selectedSort {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentCyan)
                                } else {
                                    Spacer().frame(width: 20)
                                }

                                Text(option.displayName)
                                    .font(.system(size: 16))
                                    .foregroundColor(.primaryText)

                                Spacer()
                            }
                            .padding(.vertical, 14)
                            .padding(.horizontal, 20)
                        }

                        if option != ServerSortOption.allCases.last {
                            Divider()
                                .background(Color.dividerColor)
                                .padding(.horizontal, 20)
                        }
                    }
                }
                .background(Color.cardBackgroundHighlighted)
                .cornerRadius(16)
                .padding(.horizontal, 20)
            }

            // Country filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    CountryChip(
                        title: "Все",
                        isSelected: selectedCountry == nil
                    ) {
                        selectedCountry = nil
                    }

                    ForEach(countries, id: \.self) { country in
                        CountryChip(
                            title: country,
                            isSelected: selectedCountry == country
                        ) {
                            selectedCountry = country
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.top, 16)
    }

    // MARK: - Select Server
    private func selectServer(_ server: VPNServerNode) {
        selectedServerId = server.id
        // In a real implementation, this would update the VPN configuration
        // For now, we only support the fixed France server
    }
}

// MARK: - Country Chip
struct CountryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : .secondaryText)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.accentBlue : Color.cardBackground)
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.accentBlue : Color.dividerColor, lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
