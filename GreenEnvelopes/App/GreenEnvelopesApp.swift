//
//  GreenEnvelopesApp.swift
//  GreenEnvelopes
//

import SwiftUI
import FirebaseCore

@main
struct GreenEnvelopesApp: App {
    let persistence = PersistenceController.shared
    @StateObject private var appState = AppState()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootSceneView()
                .environment(\.managedObjectContext, persistence.viewContext)
                .environmentObject(appState)
        }
    }
}
