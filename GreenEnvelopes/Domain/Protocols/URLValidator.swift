//
//  URLValidator.swift
//  GreenEnvelopes
//

import Foundation

protocol URLValidator {
    func validate(_ urlString: String) -> URL?
}
