//
//  CurrencySettings.swift
//  GreenEnvelopes
//

import SwiftUI

struct CurrencyOption: Identifiable {
    let code: String
    let name: String
    var id: String { code }
}

enum CurrencySettings {
    static let supported: [CurrencyOption] = [
        CurrencyOption(code: "USD", name: "US Dollar"),
        CurrencyOption(code: "EUR", name: "Euro"),
        CurrencyOption(code: "GBP", name: "British Pound"),
        CurrencyOption(code: "CHF", name: "Swiss Franc"),
        CurrencyOption(code: "JPY", name: "Japanese Yen"),
        CurrencyOption(code: "CAD", name: "Canadian Dollar"),
        CurrencyOption(code: "AUD", name: "Australian Dollar"),
        CurrencyOption(code: "RUB", name: "Russian Ruble"),
    ]

    static let defaultCode = "USD"

    static func format(_ value: Decimal, code: String) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = code
        return f.string(from: NSDecimalNumber(decimal: value)) ?? "0"
    }

    static func formatter(code: String) -> NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = code
        return f
    }
}

// MARK: - Environment key for currency code
private struct CurrencyCodeKey: EnvironmentKey {
    static let defaultValue: String = CurrencySettings.defaultCode
}

extension EnvironmentValues {
    var currencyCode: String {
        get { self[CurrencyCodeKey.self] }
        set { self[CurrencyCodeKey.self] = newValue }
    }
}
