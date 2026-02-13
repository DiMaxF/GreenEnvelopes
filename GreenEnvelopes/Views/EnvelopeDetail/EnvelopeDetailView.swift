//
//  EnvelopeDetailView.swift
//  GreenEnvelopes
//

import SwiftUI
import CoreData

struct EnvelopeDetailView: View {
    let envelope: Envelope
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.currencyCode) var currencyCode
    @EnvironmentObject var appState: AppState

    @State private var showSpendSheet = false
    @State private var showTransferSheet = false
    @State private var showAddIncomeSheet = false
    @State private var detailRefreshID = UUID()

    private var balance: Decimal { envelope.balance(in: viewContext) }
    private var recentItems: [EnvelopeTransactionItem] {
        envelope.recentTransactionItems(in: viewContext, limit: 10)
    }

    private var balanceColor: Color {
        if balance <= 0 { return AppColors.critical }
        let prog = progressValue(balance)
        if prog < 0.25 { return AppColors.warning }
        return AppColors.primaryAccent
    }

    private var heroGradient: LinearGradient {
        let colors: [Color]
        if balance <= 0 {
            colors = [AppColors.critical.opacity(0.9), AppColors.critical.opacity(0.6)]
        } else if progressValue(balance) < 0.25 {
            colors = [AppColors.warning.opacity(0.85), AppColors.warning.opacity(0.5)]
        } else {
            colors = [AppColors.primaryAccent, AppColors.deepGreen]
        }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // MARK: - Hero card
                VStack(spacing: 16) {
                    // Icon badge
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.2))
                            .frame(width: 72, height: 72)
                        Image(systemName: envelope.iconName ?? "envelope.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.white)
                    }
                    .padding(.top, 8)

                    // Balance
                    Text(currencyString(balance))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .accessibilityLabel("Balance \(currencyString(balance))")

                    // Progress bar
                    VStack(spacing: 6) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(.white.opacity(0.25))
                                    .frame(height: 8)
                                Capsule()
                                    .fill(.white)
                                    .frame(width: geo.size.width * progressValue(balance), height: 8)
                            }
                        }
                        .frame(height: 8)

                        HStack {
                            Text(progressLabel)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.8))
                            Spacer()
                            Text("\(Int(progressValue(balance) * 100))%")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity)
                .background(heroGradient)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: balanceColor.opacity(0.35), radius: 12, x: 0, y: 6)
                .padding(.horizontal)
                .padding(.top, 8)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(envelope.name ?? "Envelope"), balance \(currencyString(balance)), \(Int(progressValue(balance) * 100)) percent remaining")

                // MARK: - Action buttons (symmetric)
                HStack(spacing: 12) {
                    ActionButton(
                        title: "Spend",
                        icon: "arrow.up.circle.fill",
                        color: AppColors.primaryAccent
                    ) {
                        showSpendSheet = true
                    }
                    .accessibilityHint("Opens form to add an expense from this envelope")

                    ActionButton(
                        title: "Transfer",
                        icon: "arrow.left.arrow.right.circle.fill",
                        color: AppColors.deepGreen
                    ) {
                        showTransferSheet = true
                    }
                    .accessibilityHint("Opens form to transfer money to another envelope")
                }
                .padding(.horizontal)
                .padding(.top, 20)

                // MARK: - Recent transactions
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Recent transactions")
                            .font(.headline)
                        Spacer()
                        Button {
                            appState.historyEnvelopeID = envelope.objectID
                            appState.selectedTab = 2
                        } label: {
                            Text("See all")
                                .font(.subheadline)
                                .foregroundStyle(AppColors.primaryAccent)
                        }
                        .accessibilityHint("Switches to History tab filtered by this envelope")
                    }
                    .padding(.horizontal)

                    if recentItems.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "tray")
                                .font(.title)
                                .foregroundStyle(AppColors.secondaryText.opacity(0.5))
                            Text("No transactions yet")
                                .font(.subheadline)
                                .foregroundStyle(AppColors.secondaryText)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(Array(recentItems.enumerated()), id: \.element.id) { index, item in
                                TransactionRow(item: item, currencyCode: currencyCode)
                                if index < recentItems.count - 1 {
                                    Divider()
                                        .padding(.leading, 44)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                        .background(Color(UIColor.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                    }
                }
                .padding(.top, 24)

                Spacer(minLength: 40)
            }
            .id(detailRefreshID)
        }
        .background(AppColors.background(colorScheme: colorScheme))
        .navigationTitle(envelope.name ?? "Envelope")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddIncomeSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(AppColors.primaryAccent)
                }
                .accessibilityLabel("Add income")
                .accessibilityHint("Opens form to add income to this envelope")
            }
        }
        .sheet(isPresented: $showSpendSheet) {
            AddExpenseView(preSelectedEnvelope: envelope, onDismiss: { showSpendSheet = false })
        }
        .sheet(isPresented: $showTransferSheet) {
            TransferView(sourceEnvelope: envelope, onDismiss: { showTransferSheet = false })
        }
        .sheet(isPresented: $showAddIncomeSheet) {
            AddIncomeView(preSelectedEnvelope: envelope, onDismiss: { showAddIncomeSheet = false })
        }
        .onChange(of: showSpendSheet) { isShowing in if !isShowing { refreshDetail() } }
        .onChange(of: showTransferSheet) { isShowing in if !isShowing { refreshDetail() } }
        .onChange(of: showAddIncomeSheet) { isShowing in if !isShowing { refreshDetail() } }
    }

    // MARK: - Helpers

    private func refreshDetail() {
        viewContext.refresh(envelope, mergeChanges: true)
        detailRefreshID = UUID()
    }

    private var progressLabel: String {
        if let target = envelope.targetAmountValue, target > 0 {
            return "\(currencyString(balance)) of \(currencyString(target))"
        }
        return "Balance"
    }

    private func progressValue(_ balance: Decimal) -> CGFloat {
        guard let target = envelope.targetAmountValue, target > 0 else { return 1 }
        let b = NSDecimalNumber(decimal: balance).doubleValue
        let t = target as NSDecimalNumber
        return CGFloat(min(1, max(0, b / t.doubleValue)))
    }

    private func currencyString(_ value: Decimal) -> String {
        CurrencySettings.format(value, code: currencyCode)
    }
}

// MARK: - Symmetric action button

private struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundStyle(color)
            .background(color.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Transaction row

private struct TransactionRow: View {
    let item: EnvelopeTransactionItem
    let currencyCode: String

    private var isPositive: Bool { item.amount >= 0 }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isPositive ? AppColors.primaryAccent.opacity(0.15) : AppColors.critical.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: isPositive ? "arrow.down.left" : "arrow.up.right")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(isPositive ? AppColors.primaryAccent : AppColors.critical)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.type.capitalized)
                    .font(.subheadline)
                    .fontWeight(.medium)
                if let n = item.note, !n.isEmpty {
                    Text(n)
                        .font(.caption)
                        .foregroundStyle(AppColors.secondaryText)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(formatAmount(item.amount))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(isPositive ? AppColors.primaryAccent : AppColors.critical)
                Text(item.date, style: .date)
                    .font(.caption2)
                    .foregroundStyle(AppColors.secondaryText)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private func formatAmount(_ value: Decimal) -> String {
        let f = CurrencySettings.formatter(code: currencyCode)
        f.positivePrefix = "+"
        return f.string(from: NSDecimalNumber(decimal: value)) ?? CurrencySettings.format(value, code: currencyCode)
    }
}
