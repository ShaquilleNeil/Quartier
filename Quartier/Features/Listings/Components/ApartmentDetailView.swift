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
import FirebaseFirestore

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
                        .frame(height: 235)

                    contentCard
                        .padding()

                }.padding()
            }
        }
        .padding()
        .sheet(isPresented: $showChat, onDismiss: {
            activeConversation = nil
        }) {
            if let conv = activeConversation {
                let firebaseConv = Conversation(
                    id: conv.id?.uuidString ?? UUID().uuidString,
                    listingId: listing.listingID.uuidString,
                    listingAddress: listing.address,
                    tenantId: conv.tenant?.id?.uuidString ?? "",
                    landlordId: listing.landLordId,
                    tenantName: "Me",
                    lastMessageText: conv.lastMessageText ?? "",
                    lastMessageAt: conv.lastMessageAt ?? Date()
                )
                
                NavigationStack {
                    TenantChatView(conversation: firebaseConv)
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
        CLLocationCoordinate2D(
            latitude: listing.latitude ?? 45.5019,
            longitude: listing.longitude ?? -73.5674
        )
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

                infoColumn(value: listing.squareFeet, title: "SQFT")
            }
            .padding()

            Divider()

            Spacer()
                .frame(height: 20)

            Text("About this place")
                .font(.subheadline.bold())

            Text(listing.rules.isEmpty ? "This apartment offers a comfortable and well-designed living space with plenty of natural light and a practical layout suited for everyday living." : listing.rules)
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

            // FIXED: MapCard is now defined below
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
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                Spacer()
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 34))
        .offset(y: -30)
    }

    private var headerImage: some View {
        Group {
            if let firstImage = listing.existingImageURLs.first,
               let url = URL(string: firstImage) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure(_):
                        Image(systemName: "house.fill").resizable().scaledToFit().padding()
                    case .empty:
                        ProgressView()
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Image(systemName: "house.fill").resizable().scaledToFit().padding()
            }
        }
        .frame(height: 320)
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.1))
        .clipped()
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
        conv.listingId = listing.listingID
        conv.tenant = tenantEntity
        conv.tenantName = tenantEntity.displayName ?? email
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
        t.displayName = email.components(separatedBy: "@").first ?? "Tenant"
        t.createdAt = Date()
        t.updatedAt = Date()
        return t
    }
}

// FIXED: Re-added MapCard so it is no longer "out of scope"
struct MapCard: View {
    let coordinate: CLLocationCoordinate2D
    let locationName: String
    @State private var position: MapCameraPosition

    init(coordinate: CLLocationCoordinate2D, locationName: String) {
        self.coordinate = coordinate
        self.locationName = locationName
        _position = State(initialValue: .region(MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )))
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Map(position: .constant(position))
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
    }
}
