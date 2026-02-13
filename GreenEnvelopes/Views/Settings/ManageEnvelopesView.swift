//
//  ManageEnvelopesView.swift
//  GreenEnvelopes
//

import SwiftUI
import CoreData

struct ManageEnvelopesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss

    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Envelope.order, ascending: true)])
    private var envelopes: FetchedResults<Envelope>

    @State private var showAddSheet = false
    @State private var envelopeToEdit: EnvelopeWrapper?

    var body: some View {
        List {
            ForEach(envelopes, id: \.objectID) { envelope in
                HStack {
                    Image(systemName: envelope.iconName ?? "envelope.fill")
                        .foregroundStyle(AppColors.primaryAccent)
                    Text(envelope.name ?? "Envelope")
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    envelopeToEdit = EnvelopeWrapper(envelope: envelope)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        delete(envelope)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            .onMove(perform: move)
        }
        .background(AppColors.background(colorScheme: colorScheme))
        .navigationTitle("Manage Envelopes")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                EditButton()
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(AppColors.primaryAccent)
                }
                .accessibilityLabel("Add envelope")
            }
        }
        .sheet(isPresented: $showAddSheet) {
            EnvelopeFormView(envelope: nil, onSave: { showAddSheet = false }, onCancel: { showAddSheet = false })
        }
        .sheet(item: $envelopeToEdit) { wrapper in
            EnvelopeFormView(envelope: wrapper.envelope, onSave: { envelopeToEdit = nil }, onCancel: { envelopeToEdit = nil })
        }
    }

    private func delete(_ envelope: Envelope) {
        viewContext.delete(envelope)
        try? viewContext.save()
    }

    private func move(from source: IndexSet, to destination: Int) {
        var ordered = envelopes.map { $0 }
        ordered.move(fromOffsets: source, toOffset: destination)
        for (i, env) in ordered.enumerated() {
            env.order = Int32(i)
        }
        try? viewContext.save()
    }
}

// Wrap Envelope for sheet(item:) - we need Identifiable
struct EnvelopeWrapper: Identifiable {
    let envelope: Envelope
    var id: NSManagedObjectID { envelope.objectID }
}
