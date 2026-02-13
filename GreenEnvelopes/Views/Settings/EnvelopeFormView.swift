//
//  EnvelopeFormView.swift
//  GreenEnvelopes
//

import SwiftUI
import CoreData

struct EnvelopeFormView: View {
    var envelope: Envelope?
    var onSave: () -> Void
    var onCancel: () -> Void
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) var colorScheme

    @State private var name: String = ""
    @State private var selectedIconName: String = "envelope.fill"

    private var isEditing: Bool { envelope != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Envelope name", text: $name)
                }
                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 5), spacing: 12) {
                        ForEach(EnvelopeIcons.all, id: \.self) { iconName in
                            ZStack {
                                Circle()
                                    .fill(selectedIconName == iconName ? AppColors.primaryAccent.opacity(0.3) : Color.clear)
                                    .frame(width: 44, height: 44)
                                Image(systemName: iconName)
                                    .font(.title2)
                                    .foregroundStyle(selectedIconName == iconName ? AppColors.primaryAccent : .primary)
                            }
                            .frame(width: 44, height: 44)
                            .contentShape(Circle())
                            .onTapGesture {
                                selectedIconName = iconName
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle(isEditing ? "Edit Envelope" : "New Envelope")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                        onSave()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .foregroundStyle(AppColors.primaryAccent)
                }
            }
            .onAppear {
                if let e = envelope {
                    name = e.name ?? ""
                    selectedIconName = e.iconName ?? "envelope.fill"
                }
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        if let e = envelope {
            e.name = trimmed
            e.iconName = selectedIconName
        } else {
            let e = Envelope(context: viewContext)
            e.id = UUID()
            e.name = trimmed
            e.iconName = selectedIconName
            let req = Envelope.fetchRequest()
            e.order = Int32((try? viewContext.count(for: req)) ?? 0)
            e.createdAt = Date()
        }
        try? viewContext.save()
    }
}
