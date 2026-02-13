//
//  RemoteURLMapper.swift
//  GreenEnvelopes
//

import Foundation

protocol RemoteURLMapper {
    func map(from urlString: String) -> RemoteURL
}

final class RemoteURLMapperImpl: RemoteURLMapper {
    private let validator: URLValidator
    
    init(validator: URLValidator) {
        self.validator = validator
    }
    
    func map(from urlString: String) -> RemoteURL {
        let validatedURL = validator.validate(urlString)
        return RemoteURL(value: validatedURL)
    }
}
