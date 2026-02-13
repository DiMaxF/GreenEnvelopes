//
//  HomeView.swift
//  GreenEnvelopes
//

import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.colorScheme) var colorScheme
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Envelope.order, ascending: true)])
    private var envelopes: FetchedResults<Envelope>

    @State private var showSettings = false
    @State private var showNewEnvelopeSheet = false

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 160), spacing: 16)]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background(colorScheme: colorScheme)
                    .ignoresSafeArea()
                Group {
                    if envelopes.isEmpty {
                        EmptyEnvelopesView {
                            showNewEnvelopeSheet = true
                        }
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Your envelopes")
                                    .font(.headline)
                                    .foregroundStyle(AppColors.secondaryText)
                                Text("Tap to open")
                                    .font(.caption)
                                    .foregroundStyle(AppColors.secondaryText.opacity(0.7))
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 8)

                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(envelopes, id: \.objectID) { envelope in
                                    NavigationLink(destination: EnvelopeDetailView(envelope: envelope)) {
                                        EnvelopeCardView(envelope: envelope, balance: envelope.balance(in: viewContext))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                            .padding(.bottom, 24)
                        }
                    }
                }
            }
            .navigationTitle("Green Envelopes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            showNewEnvelopeSheet = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(AppColors.primaryAccent)
                        }
                        .accessibilityLabel("New envelope")
                        .accessibilityHint("Opens form to create a new envelope")

                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                        }
                        .accessibilityLabel("Settings")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showNewEnvelopeSheet) {
                EnvelopeFormView(envelope: nil, onSave: { showNewEnvelopeSheet = false }, onCancel: { showNewEnvelopeSheet = false })
            }
        }
    }
}
