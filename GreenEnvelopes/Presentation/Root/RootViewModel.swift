//
//  RootViewModel.swift
//  GreenEnvelopes
//

import Foundation
import Combine

@MainActor
final class RootViewModel: ObservableObject {
    @Published private(set) var remoteURL: RemoteURL?
    @Published private(set) var isWebViewDismissed = false
    @Published private(set) var isLoading = true

    private let fetchRemoteURLUseCase: FetchRemoteURLUseCase

    init(fetchRemoteURLUseCase: FetchRemoteURLUseCase) {
        self.fetchRemoteURLUseCase = fetchRemoteURLUseCase
    }

    func loadConfiguration() async {
        remoteURL = await fetchRemoteURLUseCase.execute()
        isLoading = false
    }

    func dismissWebView() {
        isWebViewDismissed = true
    }
}
