//
//  ApartmentCard.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-02-03.
//

import SwiftUI
import FirebaseFirestore

struct ApartmentCard: View {
    let listing: Listing
    @EnvironmentObject private var firebase: FirebaseManager
    
    var body: some View {
        // This view is a reusable card; do not embed a NavigationStack here to avoid nested stacks.
        NavigationLink(destination: ApartmentDetailView(listing: listing)) {
            VStack(alignment: .leading, spacing: 12) {
                // Image section
                ZStack(alignment: .topLeading) {
                    if let firstImage = listing.existingImageURLs.first,
                       let url = URL(string: firstImage) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(height: 200)
                        .clipped()
                        .cornerRadius(16)
                    } else {
                        Image("apartment1")
                            .resizable()
                            .scaledToFill()
                            .frame(height: 200)
                            .clipped()
                            .cornerRadius(16)
                    }

                    // Favorite button
                    HStack {
                        Spacer()
                        Button(action: {
                            firebase.saveFavorite(listingId: listing.id.uuidString)
                        }) {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.black.opacity(0.4))
                                .clipShape(Circle())
                        }
                        .padding(12)
                    }
                }

                // Info section
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("$\(listing.price.formatted(.number.precision(.fractionLength(2))))")
                            .font(.title3.bold())
                            .foregroundColor(.blue)

                        Text("/ mo")
                            .font(.subheadline)
                            .foregroundColor(.gray)

                        Spacer()
                    }

                    // Use a safe fallback for location text in case the Listing type doesn't have `location`
                    // If your model has a different property name (e.g., address/city), replace below accordingly.
                    Text(listingDisplayLocation)
                        .font(.headline)

                    HStack(spacing: 14) {
                        Label("\(listing.bedrooms) bed", systemImage: "bed.double")
                        Label("\(listing.bathrooms) bath", systemImage: "bathtub")
//                        Label("\(listing.sqft) sqft", systemImage: "ruler")
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 14)
            }
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
            .padding(.horizontal)
        }
    }

    // Derive a display location string defensively to avoid compile errors when `Listing` lacks `location`.
    private var listingDisplayLocation: String {
        // Try to reflect common property names safely.
        // Replace with your actual property once confirmed, e.g., `listing.location`.
        // For now, attempt to read via Mirror; if not found, return a placeholder.
        let mirror = Mirror(reflecting: listing)
        if let value = mirror.children.first(where: { $0.label == "location" })?.value as? String {
            return value
        }
        if let value = mirror.children.first(where: { $0.label == "address" })?.value as? String {
            return value
        }
        if let value = mirror.children.first(where: { $0.label == "city" })?.value as? String {
            return value
        }
        return ""
    }
}

#Preview {

    var mock = Listing(
        buildingID: "building1",
        landLordId: "landlord1",
        price: 1800,
        bedrooms: 2,
        bathrooms: 1
    )

    mock.address = "123 Main St, Montreal, QC"
    mock.amenities = ["Washer/Dryer", "Dishwasher", "Balcony"]
    mock.existingImageURLs = [
        "https://images.unsplash.com/photo-1560448204-e02f11c3d0e2"
    ]
    mock.squareFeet = 850

    return ApartmentDetailView(listing: mock)
}

