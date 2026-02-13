//
//  AppState.swift
//  GreenEnvelopes
//

import SwiftUI
import CoreData
import Combine

/// Shared app state for tab selection and history filter (e.g. from Envelope Detail "View Full History").
final class AppState: ObservableObject {
    @Published var selectedTab: Int = 0
    /// When set, History tab should filter by this envelope (objectID).
    @Published var historyEnvelopeID: NSManagedObjectID?
}
