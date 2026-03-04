//
//  NewNoticeView.swift
//  Quartier
//
//  Landlord: send notice to all, or to selected apartments.
//

import SwiftUI
import CoreData

struct NewNoticeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \LDListing.title, ascending: true)],
        animation: .default
    )
    private var allListings: FetchedResults<LDListing>

    @State private var title = ""
    @State private var bodyText = ""
    @State private var scopeAll = true
    @State private var selectedListingIDs: Set<UUID> = []
    @State private var errorMessage: String?
    @State private var isSending = false

    private let primary = Color(red: 0.17, green: 0.55, blue: 0.93)

    var body: some View {
        NavigationStack {
            Form {
                Section("Notice") {
                    TextField("Title", text: $title)
                    TextField("Message", text: $bodyText, axis: .vertical)
                        .lineLimit(5...10)
                }

                Section("Send to") {
                    Picker("Scope", selection: $scopeAll) {
                        Text("All apartments").tag(true)
                        Text("Selected apartments").tag(false)
                    }
                    .pickerStyle(.inline)

                    if !scopeAll {
                        ForEach(allListings, id: \.objectID) { listing in
                            let id = listing.id ?? UUID()
                            Button {
                                if selectedListingIDs.contains(id) {
                                    selectedListingIDs.remove(id)
                                } else {
                                    selectedListingIDs.insert(id)
                                }
                            } label: {
                                HStack {
                                    Text(listing.title ?? "Untitled")
                                        .foregroundStyle(.primary)
                                    if let city = listing.cityLine, !city.isEmpty {
                                        Text("• \(city)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if selectedListingIDs.contains(id) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(primary)
                                    }
                                }
                            }
                        }
                        if allListings.isEmpty {
                            Text("No listings yet. Add listings in the Listings tab.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if let err = errorMessage {
                    Section {
                        Text(err)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Send Notice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send") { sendNotice() }
                        .disabled(isSending || title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onChange(of: scopeAll) { _, isAll in
                if isAll { selectedListingIDs.removeAll() }
            }
        }
    }

    private func sendNotice() {
        errorMessage = nil
        isSending = true
        defer { isSending = false }

        let scope: NoticeService.NoticeScope
        if scopeAll {
            scope = .all
        } else {
            let selected = allListings.filter { listing in
                guard let id = listing.id else { return false }
                return selectedListingIDs.contains(id)
            }
            if selected.isEmpty {
                errorMessage = "Select at least one apartment, or use All apartments."
                return
            }
            scope = .listings(Array(selected))
        }

        do {
            let service = NoticeService(context: viewContext)
            _ = try service.createNotice(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                body: bodyText.trimmingCharacters(in: .whitespacesAndNewlines),
                scope: scope,
                pushToConversations: true
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NewNoticeView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
