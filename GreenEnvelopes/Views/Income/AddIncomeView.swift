//
//  AddIncomeView.swift
//  GreenEnvelopes
//

import SwiftUI
import CoreData

struct AddIncomeView: View {
    /// When set, income goes directly to this envelope (no distribution UI).
    var preSelectedEnvelope: Envelope? = nil
    var onDismiss: () -> Void

    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.currencyCode) var currencyCode

    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Envelope.order, ascending: true)])
    private var envelopes: FetchedResults<Envelope>

    @State private var amountText = ""
    @State private var date = Date()
    @State private var note = ""
    @State private var allocationAmounts: [NSManagedObjectID: String] = [:]
    @State private var showReflection = false

    private var isSingleEnvelopeMode: Bool { preSelectedEnvelope != nil }

    private var totalIncome: Decimal? {
        guard let d = Decimal(string: amountText.trimmingCharacters(in: .whitespaces)), d > 0 else { return nil }
        return d
    }

    private var totalAllocated: Decimal {
        if isSingleEnvelopeMode { return totalIncome ?? 0 }
        var sum: Decimal = 0
        for (_, str) in allocationAmounts {
            if let d = Decimal(string: str.trimmingCharacters(in: .whitespaces)), d >= 0 {
                sum += d
            }
        }
        return sum
    }

    private var canSave: Bool {
        guard let income = totalIncome else { return false }
        if isSingleEnvelopeMode { return true }
        return totalAllocated == income
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Income") {
                    TextField("Amount", text: $amountText)
                        .keyboardType(.decimalPad)
                        .accessibilityLabel("Income amount")
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                        .accessibilityLabel("Date")
                    TextField("Note (optional)", text: $note)
                        .accessibilityLabel("Note")
                }

                if isSingleEnvelopeMode {
                    // Show target envelope info (read-only)
                    if let env = preSelectedEnvelope {
                        Section("Destination") {
                            Label(env.name ?? "Envelope", systemImage: env.iconName ?? "envelope.fill")
                                .foregroundStyle(AppColors.primaryAccent)
                        }
                    }
                } else {
                    // Distribution mode — multiple envelopes
                    Section {
                        Button("Distribute Evenly") {
                            distributeEvenly()
                        }
                        .foregroundStyle(AppColors.primaryAccent)
                        .disabled(totalIncome == nil || envelopes.isEmpty)
                    } header: {
                        Text("Distribution")
                    } footer: {
                        if let income = totalIncome {
                            Text("Total allocated: \(currency(totalAllocated)) / \(currency(income))")
                                .foregroundStyle(totalAllocated == income ? AppColors.primaryAccent : AppColors.secondaryText)
                        }
                    }

                    Section("Allocate to envelopes") {
                        ForEach(envelopes, id: \.objectID) { env in
                            HStack {
                                Label(env.name ?? "Envelope", systemImage: env.iconName ?? "envelope.fill")
                                Spacer()
                                TextField("0", text: bindingForEnvelope(env))
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 80)
                            }
                        }
                    }
                }
            }
            .navigationTitle(isSingleEnvelopeMode ? "Add Income" : "Add Income")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss(); onDismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveIncome()
                        showReflection = true
                    }
                    .disabled(!canSave)
                    .foregroundStyle(AppColors.primaryAccent)
                }
            }
            .sheet(isPresented: $showReflection) {
                ReflectionView {
                    showReflection = false
                    dismiss()
                    onDismiss()
                }
            }
        }
    }

    private func bindingForEnvelope(_ envelope: Envelope) -> Binding<String> {
        Binding(
            get: { allocationAmounts[envelope.objectID] ?? "" },
            set: { allocationAmounts[envelope.objectID] = $0 }
        )
    }

    private func distributeEvenly() {
        guard let income = totalIncome, !envelopes.isEmpty else { return }
        let count = envelopes.count
        let handler = NSDecimalNumberHandler(roundingMode: .plain, scale: 2, raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false)
        let perEnvelope = (income as NSDecimalNumber).dividing(by: NSDecimalNumber(value: count), withBehavior: handler) as Decimal
        var newAllocations: [NSManagedObjectID: String] = [:]
        var allocated: Decimal = 0
        for (i, env) in envelopes.enumerated() {
            let amount: Decimal
            if i == count - 1 {
                amount = income - allocated
            } else {
                amount = perEnvelope
                allocated += amount
            }
            newAllocations[env.objectID] = "\(amount)"
        }
        allocationAmounts = newAllocations
    }

    private func saveIncome() {
        guard let income = totalIncome else { return }
        let transaction = Transaction(context: viewContext)
        transaction.id = UUID()
        transaction.amount = NSDecimalNumber(decimal: income)
        transaction.type = "income"
        transaction.date = date
        transaction.note = note.isEmpty ? nil : note

        if let env = preSelectedEnvelope {
            // Single envelope mode — all income goes to this envelope
            let alloc = IncomeAllocation(context: viewContext)
            alloc.amount = NSDecimalNumber(decimal: income)
            alloc.transaction = transaction
            alloc.envelope = env
        } else {
            // Distribution mode
            for env in envelopes {
                guard let str = allocationAmounts[env.objectID],
                      let amt = Decimal(string: str.trimmingCharacters(in: .whitespaces)),
                      amt > 0 else { continue }
                let alloc = IncomeAllocation(context: viewContext)
                alloc.amount = NSDecimalNumber(decimal: amt)
                alloc.transaction = transaction
                alloc.envelope = env
            }
        }
        try? viewContext.save()
    }

    private func currency(_ value: Decimal) -> String {
        CurrencySettings.format(value, code: currencyCode)
    }
}
