//
//  ContentView.swift
//  GreenEnvelopes
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            HomeView()
                .tabItem {
                    Label("Envelopes", systemImage: "envelope.fill")
                }
                .tag(0)
                .accessibilityLabel("Envelopes tab")
            BudgetView()
                .tabItem {
                    Label("Budget", systemImage: "gauge.with.needle.fill")
                }
                .tag(1)
                .accessibilityLabel("Budget tab")
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
                .tag(2)
                .accessibilityLabel("History tab")
            InsightsView()
                .tabItem {
                    Label("Insights", systemImage: "chart.pie.fill")
                }
                .tag(3)
                .accessibilityLabel("Insights tab")
        }
        .tint(AppColors.primaryAccent)
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.shared.viewContext)
        .environmentObject(AppState())
}
