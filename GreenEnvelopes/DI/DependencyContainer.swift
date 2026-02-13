//
//  DependencyContainer.swift
//  GreenEnvelopes
//

import Foundation

final class DependencyContainer {
    static let shared = DependencyContainer()
    
    private init() {}
    
    lazy var urlValidator: URLValidator = {
        HTTPURLValidator()
    }()
    
    lazy var remoteURLMapper: RemoteURLMapper = {
        RemoteURLMapperImpl(validator: urlValidator)
    }()
    
    lazy var remoteConfigRepository: RemoteConfigRepository = {
        FirebaseRemoteConfigRepository(mapper: remoteURLMapper)
    }()
    
    lazy var fetchRemoteURLUseCase: FetchRemoteURLUseCase = {
        FetchRemoteURLUseCaseImpl(repository: remoteConfigRepository)
    }()
    
    func makeRootViewModel() -> RootViewModel {
        RootViewModel(fetchRemoteURLUseCase: fetchRemoteURLUseCase)
    }
}
