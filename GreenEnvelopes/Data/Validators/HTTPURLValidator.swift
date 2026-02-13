//
//  HTTPURLValidator.swift
//  GreenEnvelopes
//

import Foundation

final class HTTPURLValidator: URLValidator {
    private let allowedSchemes = ["http", "https"]
    
    func validate(_ urlString: String) -> URL? {
        guard !urlString.isEmpty,
              let url = URL(string: urlString),
              let scheme = url.scheme,
              allowedSchemes.contains(scheme) else {
            return nil
        }
        return url
    }
}
