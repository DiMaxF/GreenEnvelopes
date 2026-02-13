//
//  FetchRemoteURLUseCase.swift
//  GreenEnvelopes
//

import Foundation

protocol FetchRemoteURLUseCase {
    func execute() async -> RemoteURL
}

final class FetchRemoteURLUseCaseImpl: FetchRemoteURLUseCase {
    private let repository: RemoteConfigRepository
    
    init(repository: RemoteConfigRepository) {
        self.repository = repository
    }
    
    func execute() async -> RemoteURL {
        do {
            try await repository.fetchConfiguration()
            return repository.getRemoteURL()
        } catch {
            return RemoteURL(value: nil)
        }
    }
}
