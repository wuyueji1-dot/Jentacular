//
//  DNSSettingsView.swift
//  Jentacular
//
//  Custom DNS configuration with presets, custom input, and speed testing
//

import SwiftUI

struct DNSSettingsView: View {
    // MARK: - Environment
    @EnvironmentObject var dnsService: DNSSettingsService
    @Environment(\.presentationMode) var presentationMode

    // MARK: - State
    @State private var customPrimary = ""
    @State private var customSecondary = ""
    @State private var showCustomInput = false
    @State private var testingPreset: UUID? = nil
    @State private var testResults: [UUID: Double] = [:]

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerSection

                    // Current status
                    currentStatusSection

                    // Custom DNS toggle
                    customToggleSection

                    if dnsService.customDNSEnabled {
                        // Presets
                        presetsSection

                        // Custom input
                        if showCustomInput {
                            customInputSection
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
        .navigationBarTitle(L("dns_settings"), displayMode: .inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: backButton)
        .onAppear {
            customPrimary = dnsService.primaryDNS
            customSecondary = dnsService.secondaryDNS
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
            Text(L("dns_settings_title"))
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primaryText)
            Text(L("dns_subtitle"))
                .font(.system(size: 15))
                .foregroundColor(.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Current Status
    private var currentStatusSection: some View {
        CustomCard {
            HStack(spacing: 14) {
                Image(systemName: dnsService.customDNSEnabled ? "checkmark.shield.fill" : "shield.slash")
                    .font(.system(size: 24))
                    .foregroundColor(dnsService.customDNSEnabled ? .accentGreen : .accentGold)
                    .frame(width: 48, height: 48)
                    .background((dnsService.customDNSEnabled ? Color.accentGreen : Color.accentGold).opacity(0.15))
                    .cornerRadius(12)

                VStack(alignment: .leading, spacing: 4) {
                    Text(dnsService.customDNSEnabled ? L("custom_dns_active") : L("system_dns_active"))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primaryText)
                    Text(dnsService.currentConfigurationDescription)
                        .font(.system(size: 13))
                        .foregroundColor(.secondaryText)
                }

                Spacer()
            }
        }
    }

    // MARK: - Custom Toggle
    private var customToggleSection: some View {
        CustomCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L("custom_dns"))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primaryText)
                        Text(L("custom_dns_desc"))
                            .font(.system(size: 13))
                            .foregroundColor(.secondaryText)
                    }
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { dnsService.customDNSEnabled },
                        set: { dnsService.toggleCustomDNS($0) }
                    ))
                    .labelsHidden()
                    .tint(.accentBlue)
                }
            }
        }
    }

    // MARK: - Presets
    private var presetsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L("quick_presets"))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primaryText)
                Spacer()
                Button(action: { showCustomInput.toggle() }) {
                    Text(showCustomInput ? L("hide") : L("custom_dns"))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.accentCyan)
                }
            }

            ForEach(dnsService.presets) { preset in
                PresetCard(
                    preset: preset,
                    isSelected: dnsService.selectedPreset?.id == preset.id,
                    isTesting: testingPreset == preset.id,
                    testResult: testResults[preset.id],
                    onSelect: {
                        dnsService.selectPreset(preset)
                        customPrimary = preset.primary
                        customSecondary = preset.secondary
                        showCustomInput = false
                    },
                    onTest: {
                        Task {
                            testingPreset = preset.id
                            let speed = await dnsService.testDNSSpeed(preset.primary)
                            testResults[preset.id] = speed
                            testingPreset = nil
                        }
                    }
                )
            }
        }
    }

    // MARK: - Custom Input
    private var customInputSection: some View {
        CustomCard {
            VStack(alignment: .leading, spacing: 16) {
                Text(L("custom_dns_servers"))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primaryText)

                VStack(alignment: .leading, spacing: 8) {
                    Text(L("primary_dns"))
                        .font(.system(size: 13))
                        .foregroundColor(.secondaryText)
                    TextField(L("example_dns"), text: $customPrimary)
                        .font(.system(size: 16))
                        .foregroundColor(.primaryText)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(Color.cardBackgroundHighlighted)
                        .cornerRadius(10)
                        .keyboardType(.numbersAndPunctuation)
                        .autocapitalization(.none)
                    if !customPrimary.isEmpty {
                        let validation = dnsService.validateDNS(customPrimary)
                        Text(validation.message)
                            .font(.system(size: 12))
                            .foregroundColor(validation.valid ? .accentGreen : .accentRed)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(L("secondary_dns"))
                        .font(.system(size: 13))
                        .foregroundColor(.secondaryText)
                    TextField(L("example_dns"), text: $customSecondary)
                        .font(.system(size: 16))
                        .foregroundColor(.primaryText)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(Color.cardBackgroundHighlighted)
                        .cornerRadius(10)
                        .keyboardType(.numbersAndPunctuation)
                        .autocapitalization(.none)
                    if !customSecondary.isEmpty {
                        let validation = dnsService.validateDNS(customSecondary)
                        Text(validation.message)
                            .font(.system(size: 12))
                            .foregroundColor(validation.valid ? .accentGreen : .accentRed)
                    }
                }

                Button(action: {
                    if dnsService.setCustomDNS(primary: customPrimary, secondary: customSecondary) {
                        showCustomInput = false
                    }
                }) {
                    Text(L("apply_settings"))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(gradient: Gradient(colors: [.accentBlue, .accentCyan]), startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(10)
                }
                .disabled(!dnsService.validateDNS(customPrimary).valid)
                .opacity(dnsService.validateDNS(customPrimary).valid ? 1 : 0.5)
            }
        }
    }
}

// MARK: - Preset Card
struct PresetCard: View {
    let preset: DNSSettingsService.DNSPreset
    let isSelected: Bool
    let isTesting: Bool
    let testResult: Double?
    let onSelect: () -> Void
    let onTest: () -> Void

    var body: some View {
        Button(action: onSelect) {
            CustomCard {
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(preset.name)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.primaryText)
                            Text("\(preset.provider) • \(preset.country)")
                                .font(.system(size: 13))
                                .foregroundColor(.secondaryText)
                        }
                        Spacer()
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.accentGreen)
                        }
                    }

                    HStack(spacing: 12) {
                        DNSAddressLabel(title: L("primary"), address: preset.primary)
                        DNSAddressLabel(title: L("secondary"), address: preset.secondary)
                        Spacer()
                    }

                    HStack {
                        ForEach(preset.features, id: \.self) { feature in
                            Text(feature)
                                .font(.system(size: 11))
                                .foregroundColor(.accentCyan)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.accentCyan.opacity(0.1))
                                .cornerRadius(6)
                        }
                        Spacer()
                        Button(action: onTest) {
                            HStack(spacing: 4) {
                                if isTesting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .accentCyan))
                                        .scaleEffect(0.7)
                                } else {
                                    Image(systemName: "gauge")
                                        .font(.system(size: 12))
                                }
                                if let result = testResult {
                                    Text(String(format: "%.0f ms", result))
                                        .font(.system(size: 12, weight: .semibold))
                                } else {
                                    Text(L("test"))
                                        .font(.system(size: 12))
                                }
                            }
                            .foregroundColor(.accentCyan)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.accentCyan.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.accentGreen.opacity(0.6) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DNSAddressLabel: View {
    let title: String
    let address: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(.tertiaryText)
            Text(address)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primaryText)
        }
    }
}
