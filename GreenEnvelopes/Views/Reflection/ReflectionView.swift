//
//  ReflectionView.swift
//  GreenEnvelopes
//

import SwiftUI

struct ReflectionView: View {
    var onDone: () -> Void
    @Environment(\.colorScheme) var colorScheme

    private static let prompts: [String] = [
        "Did this align with your priorities?",
        "How necessary was this purchase?",
        "Would you make this choice again?",
        "What mattered most about this decision?",
        "Did this support your goals?",
        "Was this planned or spontaneous?",
        "How do you feel about this use of money?",
        "What would you do differently next time?",
        "Did this bring you closer to your goals?",
        "Was the timing right for this?",
        "What did you gain from this?",
        "How does this fit your budget?",
        "Was this a need or a want?",
        "Did you consider alternatives?",
        "How will this affect your other plans?",
        "Was this worth the trade-off?",
        "What triggered this decision?",
        "How does this reflect your values?",
        "Did you feel in control of this choice?",
        "What will you remember about this in a month?",
        "Did this simplify or complicate your life?",
        "How does this compare to what you planned?",
        "What would you tell a friend about this?",
        "Did this expense bring you joy?",
        "How important was this in the moment?",
        "What would have happened if you had waited?",
        "Did this align with your budget?",
        "How do you feel now that it's done?",
        "Was there a less expensive option?",
        "Did this help or hinder your progress?",
        "What did you learn from this?",
        "Would you recommend this to someone else?",
        "How does this fit into your bigger picture?",
        "Did you feel any pressure to do this?",
        "What was the real cost of this?",
        "Did this match your expectations?",
        "How will this impact your next steps?",
        "Was the outcome what you hoped?",
        "What would you change if you could?",
        "Did this feel like a good use of resources?",
        "How does this connect to your priorities?",
        "Was there a better time for this?",
        "What made you say yes to this?",
        "Did this add value to your life?",
        "How does this sit with your financial goals?",
        "Was this decision easy or hard?",
        "What will you do next time?",
        "Did this reflect who you want to be?",
        "How does this compare to similar past choices?",
        "Was the benefit worth the cost?",
    ]

    private var prompt: String {
        Self.prompts.randomElement() ?? Self.prompts[0]
    }

    var body: some View {
        VStack(spacing: 28) {
            // Header
            VStack(spacing: 8) {
                Text("Quick reflection")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text("Take a moment to think — your answer is optional.")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            .padding(.top, 20)

            // Question
            Text(prompt)
                .font(.title3)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
                .padding(.horizontal, 28)
                .accessibilityLabel("Reflection: \(prompt)")

            // Quick response buttons
            VStack(spacing: 12) {
                Text("How did this affect you?")
                    .font(.caption)
                    .foregroundStyle(AppColors.secondaryText)

                HStack(spacing: 12) {
                    ReflectionChip(title: "Helped", icon: "checkmark.circle.fill", color: AppColors.primaryAccent) {
                        onDone()
                    }
                    ReflectionChip(title: "Hindered", icon: "xmark.circle.fill", color: AppColors.critical) {
                        onDone()
                    }
                    ReflectionChip(title: "Neutral", icon: "minus.circle.fill", color: AppColors.secondaryText) {
                        onDone()
                    }
                }
                .padding(.horizontal, 16)
            }

            // Done
            Button {
                onDone()
            } label: {
                Text("Done")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .background(AppColors.primaryAccent)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 28)
            .padding(.top, 8)
            .accessibilityLabel("Done")
            .accessibilityHint("Dismisses the reflection and returns to the previous screen")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background(colorScheme: colorScheme))
    }
}

// MARK: - Response chip

private struct ReflectionChip: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(color.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title)")
        .accessibilityHint("Marks this transaction as \(title.lowercased()) and closes")
    }
}
