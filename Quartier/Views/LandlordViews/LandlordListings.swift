//
//  LandlordListings.swift
//  Quartier
//
//  Landlord: list and manage listings (drafts and published).
//

import SwiftUI
import CoreData

struct LandlordListings: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \LDListing.address, ascending: true),
            NSSortDescriptor(keyPath: \LDListing.createdAt, ascending: false),
        ],
        animation: .default
    )
    private var listings: FetchedResults<LDListing>

    @State private var showNewListing = false
    @State private var showEditListing = false
    @State private var listingToEdit: LDListing?

    private let primary = Color(red: 0.17, green: 0.55, blue: 0.93)

    var body: some View {
        NavigationStack {
            Group {
                if listings.isEmpty {
                    ContentUnavailableView(
                        "No listings",
                        systemImage: "list.bullet.clipboard",
                        description: Text("Tap + to add a listing.")
                    )
                } else {
                    List {
                        ForEach(listings, id: \.objectID) { listing in
                            Button {
                                listingToEdit = listing
                                showEditListing = true
                            } label: {
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(listing.address ?? "Untitled")
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                        Text(priceText(listing))
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if let status = listing.status, !status.isEmpty {
                                        Text(status)
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Capsule().fill(primary.opacity(0.2)))
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Listings")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showNewListing = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(primary)
                    }
                }
            }
            .sheet(isPresented: $showNewListing) {
                NewListingView(existingListing: nil)
            }
            .sheet(isPresented: $showEditListing) {
                if let listing = listingToEdit {
                    NewListingView(existingListing: listing)
                }
            }
            .onChange(of: showEditListing) { _, visible in
                if !visible { listingToEdit = nil }
            }
        }
    }

    private func priceText(_ listing: LDListing) -> String {
        let p = listing.price
        if p > 0 {
            return String(format: "$%.0f / mo", p)
        }
        return "No price"
    }
}

#Preview {
    LandlordListings()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
