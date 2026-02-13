//
//  TransferView.swift
//  GreenEnvelopes
//

import SwiftUI
import CoreData

struct TransferView: View {
    let sourceEnvelope: Envelope
    var onDismiss: () -> Void
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Envelope.order, ascending: true)])
    private var envelopes: FetchedResults<Envelope>

    @State private var targetEnvelopeID: NSManagedObjectID?
    @State private var amountText = ""
    @State private var note = ""

    private var targetEnvelope: Envelope? {
        guard let id = targetEnvelopeID else { return nil }
        return try? viewContext.existingObject(with: id) as? Envelope
    }

    private var amount: Decimal? {
        guard let d = Decimal(string: amountText.trimmingCharacters(in: .whitespaces)) else { return nil }
        return d > 0 ? d : nil
    }

    private var canSave: Bool {
        amount != nil && targetEnvelope != nil && targetEnvelope?.objectID != sourceEnvelope.objectID
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("From") {
                    Label(sourceEnvelope.name ?? "Envelope", systemImage: sourceEnvelope.iconName ?? "envelope.fill")
                }
                Section("To") {
                    Picker("Envelope", selection: $targetEnvelopeID) {
                        Text("Select…").tag(nil as NSManagedObjectID?)
                        ForEach(envelopes.filter { $0.objectID != sourceEnvelope.objectID }, id: \.objectID) { env in
                            Text(env.name ?? "Envelope").tag(env.objectID as NSManagedObjectID?)
                        }
                    }
                }
                Section("Amount") {
                    TextField("0", text: $amountText)
                        .keyboardType(.decimalPad)
                }
                Section("Note (optional)") {
                    TextField("Note", text: $note)
                }
            }
            .navigationTitle("Transfer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss(); onDismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Transfer") { performTransfer(); dismiss(); onDismiss() }
                        .disabled(!canSave)
                        .foregroundStyle(AppColors.primaryAccent)
                }
            }
        }
    }

    private func performTransfer() {
        guard let amt = amount, let target = targetEnvelope else { return }
        let t = Transaction(context: viewContext)
        t.id = UUID()
        t.amount = NSDecimalNumber(decimal: amt)
        t.type = "transfer"
        t.date = Date()
        t.note = note.isEmpty ? nil : note
        t.sourceEnvelope = sourceEnvelope
        t.targetEnvelope = target
        try? viewContext.save()
    }
}
