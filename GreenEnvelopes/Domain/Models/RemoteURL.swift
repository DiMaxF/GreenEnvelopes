//
//  RemoteURL.swift
//  GreenEnvelopes
//

import Foundation

struct RemoteURL {
    let value: URL?
    
    var isValid: Bool {
        value != nil
    }
}
