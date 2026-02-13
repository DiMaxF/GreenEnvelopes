//
//  EnvelopeCardView.swift
//  GreenEnvelopes
//

import SwiftUI
import CoreData

struct EnvelopeCardView: View {
    let envelope: Envelope
    let balance: Decimal
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.currencyCode) var currencyCode

    private var progress: Double {
        guard let target = envelope.targetAmountValue, target > 0 else { return 1 }
        let b = NSDecimalNumber(decimal: balance).doubleValue
        let t = target as NSDecimalNumber
        return min(1, max(0, b / t.doubleValue))
    }

    /// Softer, pastel-toned gradients for a premium feel
    private var cardGradient: LinearGradient {
        let colors: [Color]
        if balance <= 0 {
            // Muted coral/rose
            colors = [Color(hex: "E8706A"), Color(hex: "F2A09B")]
        } else if progress < 0.25 {
            // Soft amber
            colors = [Color(hex: "E8A838"), Color(hex: "F5CE6E")]
        } else if progress < 0.6 {
            // Light sage
            colors = [Color(hex: "6CC070"), Color(hex: "A8DBA8")]
        } else {
            // Rich teal → mint
            colors = [Color(hex: "2AAA6A"), Color(hex: "5CD6A0")]
        }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private let cardHeight: CGFloat = 160

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 36, height: 36)
                    Image(systemName: envelope.iconName ?? "envelope.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }
                Spacer()
            }

            Text(envelope.name ?? "Envelope")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.white.opacity(0.9))
                .lineLimit(1)

            Text(currencyString(balance))
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Spacer(minLength: 0)

            // Subtle progress capsule
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.2))
                        .frame(height: 5)
                    Capsule()
                        .fill(.white.opacity(0.8))
                        .frame(width: geo.size.width * progress, height: 5)
                }
            }
            .frame(height: 5)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: cardHeight, maxHeight: cardHeight, alignment: .topLeading)
        .background(cardGradient)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 8, x: 0, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(envelope.name ?? "Envelope"), balance \(currencyString(balance))")
        .accessibilityHint("Double tap to open envelope details")
    }

    private func currencyString(_ value: Decimal) -> String {
        CurrencySettings.format(value, code: currencyCode)
    }
}
