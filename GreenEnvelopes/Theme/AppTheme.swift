//
//  AppTheme.swift
//  GreenEnvelopes
//

import SwiftUI

// App background that respects light/dark mode:
struct AppBackgroundModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .background(AppColors.background(colorScheme: colorScheme))
            .ignoresSafeArea()
    }
}

extension View {
    func appBackgroundAdaptive() -> some View {
        modifier(AppBackgroundModifier())
    }
}
