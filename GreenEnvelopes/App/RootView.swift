//
//  RootView.swift
//  GreenEnvelopes
//

import SwiftUI

struct RootView: View {
    @AppStorage("currencyCode") private var currencyCode = CurrencySettings.defaultCode
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @EnvironmentObject private var viewModel: RootViewModel

    var body: some View {
        Group {
            if let remoteURL = viewModel.remoteURL, remoteURL.isValid, let url = remoteURL.value {
                WebViewContainer(url: url)
            } else {
                appContent
            }
        }
        .task {
            await viewModel.loadConfiguration()
        }
    }
    
    private var appContent: some View {
        Group {
            if hasCompletedOnboarding {
                ContentView()
                    .environment(\.currencyCode, currencyCode)
            } else {
                OnboardingView {
                    hasCompletedOnboarding = true
                }
            }
        }
    }
}
