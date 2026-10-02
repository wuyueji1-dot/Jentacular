//
//  VPNDiagnosticView.swift
//  Jentacular
//
//  In-app VPN diagnostic log viewer
//

import SwiftUI

struct VPNDiagnosticView: View {
    @EnvironmentObject var vpnService: VPNConnectionService
    @State private var showingClearConfirm = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Status bar
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Status: \(vpnService.connectionStatus.rawValue)")
                            .font(.caption)
                            .foregroundColor(vpnService.connectionStatus == .connected ? .green : .red)
                        if let error = vpnService.lastError {
                            Text("Error: \(error)")
                                .font(.caption)
                                .foregroundColor(.red)
                                .lineLimit(2)
                        }
                    }
                    Spacer()
                    Button(action: {
                        showingClearConfirm = true
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
                .padding()
                .background(Color(.systemGray6))

                // Log content
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        if vpnService.diagnosticLog.isEmpty {
                            Text("No logs yet. Tap Connect on Home screen to start.")
                                .foregroundColor(.gray)
                                .padding()
                        } else {
                            ForEach(Array(vpnService.diagnosticLog.enumerated()), id: \.offset) { _, line in
                                Text(line)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(line.contains("FATAL") || line.contains("FAILED") || line.contains("ERROR") ? .red : .primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 1)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("VPN Diagnostic")
            .navigationBarTitleDisplayMode(.inline)
            .alert(isPresented: $showingClearConfirm) {
                Alert(
                    title: Text("Clear Logs"),
                    message: Text("Clear all diagnostic logs?"),
                    primaryButton: .destructive(Text("Clear")) {
                        vpnService.diagnosticLog.removeAll()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
}
