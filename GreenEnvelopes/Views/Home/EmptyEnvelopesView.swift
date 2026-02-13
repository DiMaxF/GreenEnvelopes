//
//  EmptyEnvelopesView.swift
//  GreenEnvelopes
//

import SwiftUI

struct EmptyEnvelopesView: View {
    var onAdd: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray.full")
                .font(.system(size: 60))
                .foregroundStyle(AppColors.secondaryText)
            Text("Create your first envelope to start budgeting")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundStyle(AppColors.secondaryText)
                .padding(.horizontal)
            Text("Create envelopes in Settings, then add income to fill them.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(AppColors.secondaryText)
                .padding(.horizontal)
            Button(action: onAdd) {
                Image(systemName: "plus.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(AppColors.primaryAccent)
            }
            .padding(.top, 8)
            .accessibilityLabel("Add envelope")
            .accessibilityHint("Opens form to create your first envelope")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
