//
//  SettingsView.swift
//  GreenEnvelopes
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var showExportSheet = false
    @AppStorage("currencyCode") private var currencyCode = CurrencySettings.defaultCode

    private var appVersion: String {
        (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "1.0"
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Manage Envelopes") {
                    NavigationLink(destination: ManageEnvelopesView()) {
                        Label("Add, edit, delete, reorder", systemImage: "envelope.badge")
                    }
                }
                Section("Currency") {
                    Picker("Currency", selection: $currencyCode) {
                        ForEach(CurrencySettings.supported) { option in
                            Text("\(option.name) (\(option.code))").tag(option.code)
                        }
                    }
                }
                Section("Data Management") {
                    Button {
                        showExportSheet = true
                    } label: {
                        Label("Export to PDF or CSV", systemImage: "square.and.arrow.up")
                    }
                }
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(appVersion)
                            .foregroundStyle(AppColors.secondaryText)
                    }
                    Text("Green Envelopes – Offline envelope budget tracker")
                        .foregroundStyle(AppColors.secondaryText)
                }
                Section("Privacy") {
                    Text("All your data stays on your device. No tracking or internet required.")
                        .foregroundStyle(AppColors.secondaryText)
                }
            }
            .background(AppColors.background(colorScheme: colorScheme))
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(AppColors.primaryAccent)
                }
            }
            .sheet(isPresented: $showExportSheet) {
                ExportView()
            }
        }
    }
}
