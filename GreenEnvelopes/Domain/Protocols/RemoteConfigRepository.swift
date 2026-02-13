//
//  RemoteConfigRepository.swift
//  GreenEnvelopes
//

import Foundation

protocol RemoteConfigRepository {
    func fetchConfiguration() async throws
    func getRemoteURL() -> RemoteURL
}
