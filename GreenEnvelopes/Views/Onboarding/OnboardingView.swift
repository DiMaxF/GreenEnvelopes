//
//  OnboardingView.swift
//  GreenEnvelopes
//

import SwiftUI

struct OnboardingView: View {
    var onComplete: () -> Void
    @Environment(\.colorScheme) var colorScheme
    @State private var currentPage = 0

    private let pages: [(title: String, text: String, imageName: String)] = [
        ("Budget with envelopes", "Assign money to envelopes and spend from them. Each envelope is a category for your money.", "salary"),
        ("Create and fill envelopes", "Create envelopes in Settings, then add income and distribute it across your envelopes.", "dollar"),
        ("Track spending and insights", "See your history, track where money goes, and view simple charts of your balance and spending.", "insight"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    VStack(spacing: 24) {
                        Image(page.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 220, maxHeight: 180)
                            .accessibilityHidden(true)
                        Text(page.title)
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .accessibilityAddTraits(.isHeader)
                        Text(page.text)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(AppColors.secondaryText)
                            .padding(.horizontal, 32)
                    }
                    .padding(.vertical, 40)
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            if currentPage == pages.count - 1 {
                Button {
                    UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                    onComplete()
                } label: {
                    Text("Get Started")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                }
                .background(AppColors.primaryAccent)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
                .shadow(color: AppColors.primaryAccent.opacity(0.4), radius: 12, x: 0, y: 6)
                .accessibilityLabel("Get Started")
                .accessibilityHint("Finishes onboarding and opens the app")
            } else {
                Button {
                    withAnimation { currentPage += 1 }
                } label: {
                    HStack(spacing: 8) {
                        Text("Next")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Image(systemName: "arrow.right")
                            .font(.title3.bold())
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                }
                .background(AppColors.primaryAccent)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
                .shadow(color: AppColors.primaryAccent.opacity(0.35), radius: 8, x: 0, y: 4)
                .accessibilityLabel("Next")
                .accessibilityHint("Goes to next onboarding screen")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background(colorScheme: colorScheme))
    }
}
