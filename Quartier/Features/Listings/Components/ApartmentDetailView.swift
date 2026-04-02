//
//  ApartmentDetailView.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-02-06.
//

import SwiftUI
import MapKit
import CoreData
import FirebaseAuth

struct ApartmentDetailView: View {

    let listing: Listing
    @State private var isExpanded = false
    @State private var activeConversation: LDConversation?
    @State private var showChat = false
    @State private var chatError: String?
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var firebase: FirebaseManager

    var body: some View {

        ZStack(alignment: .top) {

            headerImage
            

            ScrollView {

                VStack(spacing: 0) {

                    Spacer()
                        .frame(height: UIScreen.main.bounds.height * 0.42)

                    contentCard
                        .padding(.horizontal)
                       

                }.frame(width: 450)
            }
        }
        .sheet(isPresented: $showChat, onDismiss: {
            activeConversation = nil
        }) {
            if let conv = activeConversation {
                NavigationStack {
                    TenantChatView(conversation: conv)
                        .environment(\.managedObjectContext, viewContext)
                }
            }
        }
        .alert("Message", isPresented: Binding(
            get: { chatError != nil },
            set: { _ in chatError = nil }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(chatError ?? "")
        }
    }

    private func infoColumn(value: Int, title: String) -> some View {
        VStack {
            Text("\(value)")
                .font(.subheadline.bold())

            Text(title)
                .font(.caption)
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity)
    }

    private var apartmentCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: 45.5019, longitude: -73.5674)
    }

    private var contentCard: some View {

        VStack(alignment: .leading, spacing: 10) {

            Text("$\(listing.price.formatted(.number.precision(.fractionLength(2))))/mo")
                .font(.title.bold())

            Text("Apartment Listing")

            HStack {
                Image(systemName: "location.viewfinder")

                Text(listing.address)
                    .font(.subheadline.italic())
                    .foregroundStyle(.gray)
            }

            Divider()

            HStack(spacing: 0) {

                infoColumn(value: listing.bedrooms, title: "BEDROOMS")

                Divider()
                    .frame(height: 50)

                infoColumn(value: listing.bathrooms, title: "BATH")

                Divider()
                    .frame(height: 50)

                infoColumn(value: 0, title: "SQFT")
            }
            .padding()

            Divider()

            Spacer()
                .frame(height: 20)

            Text("About this place")
                .font(.subheadline.bold())

            Text("This apartment offers a comfortable and well-designed living space with plenty of natural light and a practical layout suited for everyday living. The unit features spacious rooms, modern finishes, and convenient access to nearby shops, public transportation, and local amenities.")
                .lineLimit(isExpanded ? nil : 3)
                .font(.body)
                .foregroundStyle(.gray)

            Button(isExpanded ? "Read less" : "Read more") {
                isExpanded.toggle()
            }
            .font(.caption)
            .foregroundStyle(.blue)

            Spacer()
                .frame(height: 20)

            Text("Amenities")
                .font(.subheadline.bold())

            ForEach(listing.amenities, id: \.self) { amenity in
                Text("• \(amenity)")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }

            Spacer()
                .frame(height: 20)

            Text("Location")
                .font(.subheadline.bold())

            MapCard(
                coordinate: apartmentCoordinate,
                locationName: listing.address
            )

            Spacer()

            HStack {

                Spacer()

                Button(action: { contactLandlord() }) {

                    Text("Contact Landlord")
                        .foregroundStyle(.white)
                        .font(.subheadline.bold())
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                        )
                }

                Spacer()
            }
        }
        .padding()
        .background(.background)
        .clipShape(
            RoundedRectangle(cornerRadius: 34)
        )
        .offset(y: -30)
    }

    private var headerImage: some View {

        Group {

            if let firstImage = listing.existingImageURLs.first,
               let url = URL(string: firstImage) {

                AsyncImage(url: url) { phase in

                    switch phase {

                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()

                    case .failure(_):
                        Image("apartment1")
                            .resizable()
                            .scaledToFill()

                    case .empty:
                        ProgressView()

                    @unknown default:
                        Image("apartment1")
                            .resizable()
                            .scaledToFill()
                    }
                }

            } else {

                Image("apartment1")
                    .resizable()
                    .scaledToFill()
            }

        }
        .frame(height: UIScreen.main.bounds.height * 0.5)
        .ignoresSafeArea(edges: .top)
    }

    private func contactLandlord() {
        do {
            let conv = try openOrCreateConversation()
            activeConversation = conv
            showChat = true
        } catch {
            chatError = error.localizedDescription
        }
    }

    private func openOrCreateConversation() throws -> LDConversation {
        let email = (firebase.currentUser?.email ?? Auth.auth().currentUser?.email ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !email.isEmpty else {
            throw NSError(domain: "Quartier", code: 1, userInfo: [NSLocalizedDescriptionKey: "Please sign in to contact landlord."])
        }

        let listingEntity = try ensureListingEntity()
        let tenantEntity = try ensureTenantEntity(email: email)

        let req = NSFetchRequest<LDConversation>(entityName: "LDConversation")
        req.predicate = NSPredicate(format: "listing == %@ AND tenant == %@", listingEntity, tenantEntity)
        req.fetchLimit = 1
        if let existing = try viewContext.fetch(req).first {
            return existing
        }

        let conv = LDConversation(context: viewContext)
        conv.id = UUID()
        conv.listing = listingEntity
        conv.listingId = listingEntity.id
        conv.tenant = tenantEntity
        conv.tenantName = tenantEntity.displayName?.isEmpty == false ? tenantEntity.displayName : email
        conv.lastMessageAt = Date()
        conv.lastMessageText = "Conversation started"
        conv.unreadCount = 0
        try viewContext.save()
        return conv
    }

    private func ensureListingEntity() throws -> LDListing {
        let req = NSFetchRequest<LDListing>(entityName: "LDListing")
        req.predicate = NSPredicate(format: "id == %@", listing.listingID as CVarArg)
        req.fetchLimit = 1
        if let existing = try viewContext.fetch(req).first { return existing }

        let item = LDListing(context: viewContext)
        item.id = listing.listingID
        item.address = listing.address
        item.buildingID = listing.buildingID
        item.landLordID = listing.landLordId
        item.price = listing.price
        item.bedrooms = Int16(listing.bedrooms)
        item.bathrooms = Int16(listing.bathrooms)
        item.squareFeet = Int32(listing.squareFeet)
        item.status = listing.status.rawValue
        item.isRented = listing.isRented
        item.createdAt = Date()
        item.updatedAt = Date()
        return item
    }

    private func ensureTenantEntity(email: String) throws -> LDTenant {
        let req = NSFetchRequest<LDTenant>(entityName: "LDTenant")
        req.predicate = NSPredicate(format: "email == %@", email)
        req.fetchLimit = 1
        if let existing = try viewContext.fetch(req).first { return existing }

        let t = LDTenant(context: viewContext)
        t.id = UUID()
        t.email = email
        t.displayName = firebase.currentUser?.email.components(separatedBy: "@").first ?? "Tenant"
        t.createdAt = Date()
        t.updatedAt = Date()
        return t
    }
}


struct MapCard: View {

    let coordinate: CLLocationCoordinate2D
    let locationName: String

    @State private var region: MKCoordinateRegion

    init(coordinate: CLLocationCoordinate2D,
         locationName: String) {

        self.coordinate = coordinate
        self.locationName = locationName

        _region = State(initialValue:
            MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01,
                                       longitudeDelta: 0.01)
            )
        )
    }

    var body: some View {

        ZStack(alignment: .bottomLeading) {

            Map(position: .constant(.region(region)))
                .allowsHitTesting(false)

            Text(locationName)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .padding(12)
        }
        .frame(height: 140)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.gray.opacity(0.15))
        )
        .shadow(color: .black.opacity(0.08),
                radius: 6, y: 3)
    }
}

extension Listing {
    static var mock: Listing {

        var listing = Listing(
            buildingID: "b1",
            landLordId: "l1",
            price: 1800,
            bedrooms: 2,
            bathrooms: 1
        )

        // Set remaining properties AFTER init
        listing.address = "123 Main St"
        listing.squareFeet = 900
        listing.amenities = ["Washer", "Balcony"]
        listing.existingImageURLs = []
        listing.status = .published
        listing.isRented = false

        return listing
    }
}


#Preview {
    ApartmentDetailView(listing: .mock)
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(FirebaseManager())
}
