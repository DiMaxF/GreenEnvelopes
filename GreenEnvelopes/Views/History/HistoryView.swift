//
//  HistoryView.swift
//  GreenEnvelopes
//

import SwiftUI
import CoreData

struct HistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.currencyCode) var currencyCode
    @EnvironmentObject var appState: AppState

    @State private var filter: HistoryFilter = .all
    @State private var searchText = ""
    @State private var items: [HistoryItem] = []
    @State private var hasAnyTransactions = false
    @State private var selectedItem: HistoryItem?

    private var formatter: NumberFormatter {
        CurrencySettings.formatter(code: currencyCode)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Filter", selection: $filter) {
                    ForEach(HistoryFilter.allCases, id: \.self) { f in
                        Text(f.rawValue).tag(f)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                if !hasAnyTransactions {
                    // Truly empty — no transactions at all in the database
                    HistoryEmptyState(goToEnvelopes: { appState.selectedTab = 0 })
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Has transactions — always show the searchable list
                    List {
                        if items.isEmpty {
                            // No results for current search/filter
                            Section {
                                VStack(spacing: 12) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.title)
                                        .foregroundStyle(AppColors.secondaryText.opacity(0.5))
                                    Text("No results found")
                                        .font(.subheadline)
                                        .foregroundStyle(AppColors.secondaryText)
                                    if !searchText.isEmpty {
                                        Text("Try a different search term")
                                            .font(.caption)
                                            .foregroundStyle(AppColors.secondaryText.opacity(0.7))
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                            }
                        } else {
                            ForEach(items) { item in
                                Button {
                                    selectedItem = item
                                } label: {
                                    HistoryRowView(item: item, formatter: formatter)
                                }
                                .accessibilityLabel("\(item.date.formatted(date: .abbreviated, time: .omitted)), \(item.envelopeName ?? "Unknown"), \(formatAmount(item.amount, isIncome: item.isIncome))")
                                .accessibilityHint("Double tap for details")
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .searchable(text: $searchText, prompt: "Search by note or envelope")
                    .refreshable {
                        reloadAll()
                    }
                }
            }
            .background(AppColors.background(colorScheme: colorScheme))
            .navigationTitle("History")
            .toolbar {
                if appState.historyEnvelopeID != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Show All") {
                            appState.historyEnvelopeID = nil
                            reloadAll()
                        }
                        .foregroundStyle(AppColors.primaryAccent)
                    }
                }
            }
            .onAppear { reloadAll() }
            .onChange(of: filter) { _ in loadItems() }
            .onChange(of: searchText) { _ in loadItems() }
            .sheet(item: $selectedItem) { item in
                HistoryDetailSheet(item: item, formatter: formatter)
            }
        }
    }

    // MARK: - Data loading

    /// Full reload: check if any transactions exist at all, then load filtered items
    private func reloadAll() {
        hasAnyTransactions = checkAnyTransactions()
        loadItems()
    }

    /// Load items for current filter/search
    private func loadItems() {
        items = HistoryFetch.items(
            in: viewContext,
            filter: filter,
            envelopeID: appState.historyEnvelopeID,
            searchText: searchText
        )
        // Also refresh the flag in case a transaction was added/removed
        hasAnyTransactions = checkAnyTransactions()
    }

    /// Check whether the database has any transactions at all (ignoring filters)
    private func checkAnyTransactions() -> Bool {
        let allocReq: NSFetchRequest<IncomeAllocation> = IncomeAllocation.fetchRequest()
        allocReq.fetchLimit = 1
        let allocCount = (try? viewContext.count(for: allocReq)) ?? 0
        if allocCount > 0 { return true }

        let trReq: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        trReq.fetchLimit = 1
        let trCount = (try? viewContext.count(for: trReq)) ?? 0
        return trCount > 0
    }

    private func formatAmount(_ value: Decimal, isIncome: Bool) -> String {
        let s = formatter.string(from: NSDecimalNumber(decimal: value)) ?? "$0.00"
        return isIncome ? "+\(s)" : s
    }
}

// MARK: - Subviews

private struct HistoryEmptyState: View {
    var goToEnvelopes: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock")
                .font(.system(size: 60))
                .foregroundStyle(AppColors.secondaryText)
            Text("No transactions yet")
                .font(.title3)
                .fontWeight(.medium)
            Text("Add income or expense from the Envelopes tab.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(AppColors.secondaryText)
                .padding(.horizontal)
            Button("Go to Envelopes", action: goToEnvelopes)
                .buttonStyle(.borderedProminent)
                .tint(AppColors.primaryAccent)
                .padding(.top, 8)
        }
        .padding()
    }
}

private struct HistoryRowView: View {
    let item: HistoryItem
    let formatter: NumberFormatter

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.date, style: .date)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.secondaryText)
                if let name = item.envelopeName {
                    Text(name)
                        .font(.caption)
                        .foregroundStyle(AppColors.primaryAccent)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatAmount(item.amount, isIncome: item.isIncome))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(item.isIncome ? AppColors.primaryAccent : AppColors.critical)
                if let n = item.note, !n.isEmpty {
                    Text(n)
                        .lineLimit(1)
                        .font(.caption)
                        .foregroundStyle(AppColors.secondaryText)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func formatAmount(_ value: Decimal, isIncome: Bool) -> String {
        let s = formatter.string(from: NSDecimalNumber(decimal: value)) ?? "$0.00"
        return isIncome ? "+\(s)" : s
    }
}

private struct HistoryDetailSheet: View {
    let item: HistoryItem
    let formatter: NumberFormatter
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent("Date", value: item.date.formatted(date: .long, time: .shortened))
                    LabeledContent("Type", value: item.detailDescription)
                    LabeledContent("Amount", value: formatter.string(from: NSDecimalNumber(decimal: item.amount)) ?? "")
                        .foregroundStyle(item.isIncome ? AppColors.primaryAccent : AppColors.critical)
                    if let name = item.envelopeName {
                        LabeledContent("Envelope", value: name)
                    }
                }
                if let note = item.note, !note.isEmpty {
                    Section("Note") {
                        Text(note)
                    }
                }
            }
            .background(AppColors.background(colorScheme: colorScheme))
            .navigationTitle("Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(AppColors.primaryAccent)
                }
            }
        }
    }
}
