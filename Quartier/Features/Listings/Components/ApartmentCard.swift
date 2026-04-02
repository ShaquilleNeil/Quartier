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
    
    var isFavorite: Bool {
        firebase.favoriteIds.contains(listing.id.uuidString)
    }
    
    var body: some View {
        NavigationLink(destination: ApartmentDetailView(listing: listing)) {
            VStack(alignment: .leading, spacing: 12) {
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

                    HStack {
                        Spacer()
                        Button(action: {
                            firebase.saveFavorite(listingId: listing.id.uuidString)
                        }) {
                            Image(systemName: isFavorite ? "heart.fill" : "heart")
                                .foregroundColor(isFavorite ? .red : .white)
                                .padding(10)
                                .background(Color.black.opacity(0.4))
                                .clipShape(Circle())
                        }
                        .padding(12)
                    }
                }

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

                    Text(listingDisplayLocation)
                        .font(.headline)

                    HStack(spacing: 14) {
                        Label("\(listing.bedrooms) bed", systemImage: "bed.double")
                        Label("\(listing.bathrooms) bath", systemImage: "bathtub")
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

    private var listingDisplayLocation: String {
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
