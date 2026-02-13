//
//  AppColors.swift
//  GreenEnvelopes
//

import SwiftUI

enum AppColors {

    static let backgroundLight = Color(hex: "FFFFFF")
    static let backgroundDark = Color(hex: "121412")

    static let primaryAccent = Color(hex: "34C759")
    static let lightGreen = Color(hex: "8FD14F")
    static let deepGreen = Color(hex: "1e5631")

    static let secondaryText = Color(hex: "8E8E93")

    static let warning = Color(hex: "FFCC00")
    static let critical = Color(hex: "FF3B30")

    /// Background that adapts to light/dark.
    static func background(colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? backgroundDark : backgroundLight
    }
}

// MARK: - Color hex initializer
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
