//
//  RootSceneView.swift
//  GreenEnvelopes
//

import SwiftUI

struct RootSceneView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var appState: AppState
    @StateObject private var rootViewModel = DependencyContainer.shared.makeRootViewModel()

    var body: some View {
        RootView()
            .environment(\.managedObjectContext, viewContext)
            .environmentObject(appState)
            .environmentObject(rootViewModel)
    }
}
