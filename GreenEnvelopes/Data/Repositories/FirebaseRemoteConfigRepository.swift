//
//  FirebaseRemoteConfigRepository.swift
//  GreenEnvelopes
//

import Foundation
import FirebaseRemoteConfig

final class FirebaseRemoteConfigRepository: RemoteConfigRepository {
    private let remoteConfig: RemoteConfig
    private let mapper: RemoteURLMapper
    private let urlKey: String
    
    init(
        remoteConfig: RemoteConfig = RemoteConfig.remoteConfig(),
        mapper: RemoteURLMapper,
        urlKey: String = "url1"
    ) {
        self.remoteConfig = remoteConfig
        self.mapper = mapper
        self.urlKey = urlKey
        
        configureSettings()
        setDefaultValues()
    }
    
    func fetchConfiguration() async throws {
        _ = try await remoteConfig.fetchAndActivate()
    }
    
    func getRemoteURL() -> RemoteURL {
        let urlString = remoteConfig.configValue(forKey: urlKey).stringValue ?? ""
        return mapper.map(from: urlString)
    }
    
    private func configureSettings() {
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0
        remoteConfig.configSettings = settings
    }
    
    private func setDefaultValues() {
        remoteConfig.setDefaults([urlKey: "" as NSObject])
    }
}
