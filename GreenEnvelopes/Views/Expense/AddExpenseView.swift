//
//  AddExpenseView.swift
//  GreenEnvelopes
//

import SwiftUI
import CoreData

struct AddExpenseView: View {
    var preSelectedEnvelope: Envelope? = nil
    var onDismiss: () -> Void
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.currencyCode) var currencyCode

    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Envelope.order, ascending: true)])
    private var envelopes: FetchedResults<Envelope>

    @State private var selectedEnvelopeID: NSManagedObjectID?
    @State private var amountText = ""
    @State private var date = Date()
    @State private var note = ""
    @State private var showReflection = false

    private var selectedEnvelope: Envelope? {
        guard let id = selectedEnvelopeID else { return nil }
        return try? viewContext.existingObject(with: id) as? Envelope
    }

    private var balance: Decimal {
        guard let env = selectedEnvelope else { return 0 }
        return env.balance(in: viewContext)
    }

    private var amount: Decimal? {
        guard let d = Decimal(string: amountText.trimmingCharacters(in: .whitespaces)), d > 0 else { return nil }
        return d
    }

    private var canSave: Bool {
        amount != nil && selectedEnvelope != nil
    }

    private var balanceWarning: BalanceWarning {
        guard let amt = amount else { return .none }
        if balance <= 0 && amt > 0 { return .critical }
        if balance < amt { return .warning }
        return .none
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Amount") {
                    TextField("0", text: $amountText)
                        .keyboardType(.decimalPad)
                        .accessibilityLabel("Expense amount")
                }

                Section("Envelope") {
                    Picker("From envelope", selection: $selectedEnvelopeID) {
                        Text("Select…").tag(nil as NSManagedObjectID?)
                        ForEach(envelopes, id: \.objectID) { env in
                            HStack {
                                Text(env.name ?? "Envelope")
                                Text("(\(currency(env.balance(in: viewContext))))")
                                    .foregroundStyle(AppColors.secondaryText)
                            }
                            .tag(env.objectID as NSManagedObjectID?)
                        }
                    }
                    if selectedEnvelope != nil {
                        HStack {
                            Text("Balance")
                            Spacer()
                            Text(currency(balance))
                                .foregroundStyle(balanceWarning == .critical ? AppColors.critical : (balanceWarning == .warning ? AppColors.warning : .primary))
                        }
                        if balanceWarning != .none {
                            Text(balanceWarning.message)
                                .font(.caption)
                                .foregroundStyle(balanceWarning == .critical ? AppColors.critical : AppColors.warning)
                        }
                    }
                }

                Section("Date") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
                Section("Note (optional)") {
                    TextField("Note", text: $note)
                }
            }
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss(); onDismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveExpense()
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
            .onAppear {
                if let pre = preSelectedEnvelope {
                    selectedEnvelopeID = pre.objectID
                }
            }
        }
    }

    private func saveExpense() {
        guard let amt = amount, let env = selectedEnvelope else { return }
        let t = Transaction(context: viewContext)
        t.id = UUID()
        t.amount = NSDecimalNumber(decimal: amt)
        t.type = "expense"
        t.date = date
        t.note = note.isEmpty ? nil : note
        t.envelope = env
        try? viewContext.save()
    }

    private func currency(_ value: Decimal) -> String {
        CurrencySettings.format(value, code: currencyCode)
    }
}

enum BalanceWarning {
    case none, warning, critical
    var message: String {
        switch self {
        case .none: return ""
        case .warning: return "Balance is less than the expense amount."
        case .critical: return "Envelope is empty or overspent."
        }
    }
}
