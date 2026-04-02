//
//  LandlordListings.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-01-29.
//

import SwiftUI
import SDWebImageSwiftUI
import FirebaseAuth

struct LandlordListings: View {
    var body: some View {
        MyListingsView()
    }
}

private struct MyListingsView: View {

    private let primary = Color(red: 0.17, green: 0.55, blue: 0.93)
    private var currentUID: String {
        Auth.auth().currentUser?.uid ?? ""
    }

    @State private var searchText: String = ""
    @State private var isAddingListing: Bool = false
    @State private var selectedMode: ListingMode = .drafts
    @EnvironmentObject var firebase: FirebaseManager
    @EnvironmentObject var coreDataManager: CoreDataManager
    @Environment(\.managedObjectContext) var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \LDListing.updatedAt, ascending: false)],
        animation: .default
    )
    private var draftListings: FetchedResults<LDListing>

    enum ListingMode: String, CaseIterable {
        case drafts = "Drafts"
        case published = "Published"
        case rented = "Rented"
    }
    
    private var userDraftListings: [LDListing] {
        draftListings.filter { $0.landLordID == currentUID }
    }

    /// Drafts that are not marked rented (rented drafts appear under Rented).
    private var draftRows: [LDListing] {
        userDraftListings.filter { !$0.isRented }
    }

    /// Rented listings saved only in Core Data / not yet merged into the landlord’s Firebase query result.
    private var rentedDraftsNotOnFirebase: [LDListing] {
        let remoteIds = Set(firebase.firebaseListings.map(\.id))
        return userDraftListings.filter { listing in
            guard listing.isRented, let id = listing.id else { return false }
            return !remoteIds.contains(id.uuidString)
        }
    }

    private func isRemoteListingRented(_ item: RemoteListing) -> Bool {
        item.isEffectivelyRented
    }

    private func isRemoteListingPublished(_ item: RemoteListing) -> Bool {
        item.status.lowercased() == "published" && !isRemoteListingRented(item)
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                bg.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {

                        Text("My Listings")
                            .font(.system(size: 32, weight: .bold))
                            .padding(.horizontal, 16)

                        Picker("", selection: $selectedMode) {
                            ForEach(ListingMode.allCases, id: \.self) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 16)

                        VStack(spacing: 12) {
                            switch selectedMode {
                            case .drafts:
                                draftListView
                            case .published:
                                publishedListView
                            case .rented:
                                rentedListView
                            }
                        }
                        .padding(.horizontal, 16)

                        Spacer(minLength: 90)
                    }
                }

                Button {
                    isAddingListing = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(Circle().fill(primary))
                        .shadow(color: primary.opacity(0.25), radius: 12, x: 0, y: 6)
                }
                .padding(.trailing, 18)
                .padding(.bottom, 18)

                NavigationLink(
                    destination: ListingFormView(),
                    isActive: $isAddingListing
                ) {
                    EmptyView()
                }
            }
        }.onAppear{
            firebase.fetchListingsLandlord()
        }
    }

    // MARK: Draft View (Core Data)

    private var draftListView: some View {
        VStack(spacing: 12) {
            ForEach(draftRows, id: \.objectID) { item in
                NavigationLink(
                    destination: ListingFormView(
                        existingListing: convertDraftToListing(item)
                    )
                ) {
                    draftCard(item, rentedLocal: false)
                }
                .buttonStyle(.plain)
            }
        }
    }
    

    private func convertDraftToListing(_ draft: LDListing) -> Listing {

        let decodedAmenities = draft.amenities as? [String] ?? []

        var listing = Listing(
            listingID: draft.id ?? UUID(),
            buildingID: draft.buildingID ?? "",
            landLordId: draft.landLordID ?? "",
            price: draft.price,
            bedrooms: Int(draft.bedrooms),
            bathrooms: Int(draft.bathrooms)
        )

        listing.amenities = decodedAmenities
        listing.status = .draft
        listing.rules = draft.rules ?? ""
        listing.images = convertDraftImages(draft)
        listing.address = draft.address ?? ""
        listing.isRented = draft.isRented
        listing.existingImageURLs = []

        return listing
    }
    
    private func convertDraftImages(_ draft: LDListing) -> [UIImage] {
        guard let images = draft.draftImages as? Set<DraftImage> else { return [] }

        return images
            .sorted { $0.orderIndex < $1.orderIndex }
            .compactMap { $0.imageData }
            .compactMap { UIImage(data: $0) }
    }
    
    
    
    private func draftCard(_ item: LDListing, rentedLocal: Bool) -> some View {
        HStack(spacing: 14) {

            // Thumbnail
            if let images = item.draftImages as? Set<DraftImage>,
               let first = images.sorted(by: { $0.orderIndex < $1.orderIndex }).first,
               let data = first.imageData,
               let uiImage = UIImage(data: data) {

                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 85, height: 85)
                    .clipped()
                    .cornerRadius(14)

            } else {

                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 85, height: 85)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(.orange)
                    )
            }

            VStack(alignment: .leading, spacing: 8) {

                HStack {
                    Text(item.address ?? "Untitled Draft")
                        .font(.system(size: 17, weight: .semibold))
                        .lineLimit(1)

                    Spacer()

                    Text(rentedLocal ? "Rented (draft)" : "Draft")
                        .font(.system(size: 11, weight: .bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill((rentedLocal ? Color.blue : Color.orange).opacity(0.18))
                        )
                    Button(role: .destructive) {
                        if let id = item.id {
                            coreDataManager.deleteDraft(
                                listingID: id,
                                context: viewContext
                            )
                        }
                    } label: {
                        Image(systemName: "trash")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundColor(.red)
                    }
                }

                Text(formattedPrice(item.price) +
                     " • \(item.bedrooms) bds • \(item.bathrooms) ba")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(.ultraThinMaterial) // glass effect
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(
                    Color.orange.opacity(0.25),
                    lineWidth: 1
                )
        )
        .shadow(
            color: Color.black.opacity(0.08),
            radius: 10,
            x: 0,
            y: 6
        )
    }
    
    private func formattedPrice(_ price: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "CAD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: price)) ?? "$\(price)"
    }

    // MARK: Published View (Firebase placeholder)

    private var publishedListView: some View {
        VStack(spacing: 12) {
            ForEach(firebase.firebaseListings.filter(isRemoteListingPublished)) { item in
                NavigationLink(
                    destination: ListingFormView(
                        existingListing: convertToEditableListing(item)
                    )
                ) {
                    remoteCard(item)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: Rented View (Firebase placeholder)

    private var rentedListView: some View {
        VStack(spacing: 12) {
            ForEach(firebase.firebaseListings.filter(isRemoteListingRented)) { item in
                NavigationLink(
                    destination: ListingFormView(
                        existingListing: convertToEditableListing(item)
                    )
                ) {
                    remoteCard(item)
                }
                .buttonStyle(.plain)
            }
            ForEach(rentedDraftsNotOnFirebase, id: \.objectID) { item in
                NavigationLink(
                    destination: ListingFormView(
                        existingListing: convertDraftToListing(item)
                    )
                ) {
                    draftCard(item, rentedLocal: true)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func remoteCard(_ item: RemoteListing) -> some View {
        
        HStack(spacing: 14) {
          
            
            
            // Thumbnail from URL
            if let firstURL = item.imageURLs.first,
               let url = URL(string: firstURL) {

                WebImage(url: url)
                    .onFailure { error in
                        print("Image load failed:", error.localizedDescription)
                    }
                    .resizable()
                    .indicator(.activity)   // built-in loading spinner
                    .transition(.fade(duration: 0.25))
                    .scaledToFill()
                    .frame(width: 85, height: 85)
                    .clipped()
                    .cornerRadius(14)

            } else {

                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 85, height: 85)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(.gray)
                    )
            }

            VStack(alignment: .leading, spacing: 8) {
                
                HStack {
                    Text(item.address.isEmpty ? "Untitled Listing" : item.address)
                        .font(.system(size: 17, weight: .semibold))
                        .lineLimit(1)

                    Spacer()

                    Text(item.status.capitalized)
                        .font(.system(size: 11, weight: .bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(statusColor(for: item.status).opacity(0.18))
                        )
                }

                Text(formattedPrice(item.price) +
                     " • \(item.bedrooms) bds • \(item.bathrooms) ba")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(
                    statusColor(for: item.status).opacity(0.25),
                    lineWidth: 1
                )
        )
        .shadow(
            color: Color.black.opacity(0.08),
            radius: 10,
            x: 0,
            y: 6
        )
    }

    private func convertToEditableListing(_ remote: RemoteListing) -> Listing {

        var listing = Listing(
            listingID: UUID(uuidString: remote.id) ?? UUID(),
            buildingID: remote.buildingId,
            landLordId: remote.landlordId,
            price: remote.price,
            bedrooms: remote.bedrooms,
            bathrooms: remote.bathrooms
        )

        listing.amenities = remote.amenities
        listing.status = ListingStatus(rawValue: remote.status) ?? .published
        listing.rules = remote.rules
        listing.images = []
        listing.address = remote.address
        listing.isRented = remote.isRented
        listing.existingImageURLs = remote.imageURLs

        return listing
    }
    
    private func statusColor(for status: String) -> Color {
        switch status.lowercased() {
        case "published":
            return .green
        case "rented":
            return .blue
        default:
            return .gray
        }
    }
    // MARK: Theme

    private var bg: Color {
        Color.white
    }

    private var cardBg: Color {
        Color(uiColor: .secondarySystemBackground)
    }
}


#Preview {
    LandlordListings()
        .environmentObject(FirebaseManager())
}
