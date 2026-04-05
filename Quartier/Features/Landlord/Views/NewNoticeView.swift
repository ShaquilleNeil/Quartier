//
//  NewNoticeView.swift
//  Quartier
//
//  Landlord: send notice to all, or to selected apartments.
//
// MARK: - NewNoticeView.swift
import SwiftUI
import CoreData
import FirebaseAuth

struct NewNoticeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \LDListing.address, ascending: true)],
        animation: .default
    )
    private var allCoreDataListings: FetchedResults<LDListing>

    @StateObject private var viewModel = NoticeViewModel()

    @State private var title = ""
    @State private var bodyText = ""
    @State private var scopeAll = true
    @State private var selectedListingIDs: Set<String> = []
    @State private var errorMessage: String?
    @State private var isSending = false

    private let primary = Color(red: 0.17, green: 0.55, blue: 0.93)

    // MARK: - Security Filtering
    private var currentUid: String { Auth.auth().currentUser?.uid ?? "" }
    
    private var myListings: [LDListing] {
        allCoreDataListings.filter { $0.landLordID == currentUid }
    }

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
                        Text("All my properties").tag(true)
                        Text("Specific properties").tag(false)
                    }
                    .pickerStyle(.inline)

                    if !scopeAll {
                        ForEach(myListings, id: \.objectID) { listing in
                            if let id = listing.id?.uuidString {
                                Button {
                                    if selectedListingIDs.contains(id) {
                                        selectedListingIDs.remove(id)
                                    } else {
                                        selectedListingIDs.insert(id)
                                    }
                                } label: {
                                    HStack {
                                        Text(listing.address ?? "Untitled")
                                            .foregroundStyle(.primary)
                                        Spacer()
                                        if selectedListingIDs.contains(id) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(primary)
                                        }
                                    }
                                }
                            }
                        }
                        
                        if myListings.isEmpty {
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

        if !scopeAll && selectedListingIDs.isEmpty {
            errorMessage = "Select at least one property, or use 'All my properties'."
            return
        }

        viewModel.sendNotice(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            body: bodyText.trimmingCharacters(in: .whitespacesAndNewlines),
            scopeAll: scopeAll,
            listingIds: Array(selectedListingIDs)
        )
        
        dismiss()
    }
}
