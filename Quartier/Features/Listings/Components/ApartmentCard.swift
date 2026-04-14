//
//  ApartmentCard.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-02-03.
//
import SwiftUI
import FirebaseFirestore
import SDWebImageSwiftUI

struct ApartmentCard: View {
    let listing: Listing
    @EnvironmentObject private var firebase: FirebaseManager
    @EnvironmentObject var coreDataManager: CoreDataManager
    @Environment(\.managedObjectContext) private var context
//    var address: String
    
    var isFavorite: Bool {
        firebase.favoriteIds.contains(listing.id.uuidString)
    }
    
    var body: some View {
        NavigationLink(destination: ApartmentDetailView(listing: listing)) {
            VStack(alignment: .leading, spacing: 12) {
                ZStack(alignment: .topLeading) {
                    if let firstImage = listing.existingImageURLs.first,
                       let url = URL(string: firstImage) {
                        WebImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(height: 200)
                        .clipped()
                        
                    } else {
                        Image("apartment1")
                            .resizable()
                            .scaledToFill()
                            .frame(height: 200)
                            .clipped()
                            
                    }

                    HStack {
                        Spacer()
                        Button(action: {
                            let isFav = firebase.favoriteIds.contains(listing.id.uuidString) // before toggle
                               
                               firebase.saveFavorite(listingId: listing.id.uuidString)
                               
                               if isFav {
                                   coreDataManager.deleteFavorite(id: listing.listingID, context: context)
                               } else {
                                   coreDataManager.saveFavorite(from: listing, context: context)
                               }
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
                    Text(listing.listingName)
                        .font(.headline)
                        .foregroundStyle(.black)
                    HStack {
                        Text("$\(listing.price.formatted(.number.precision(.fractionLength(2))))")
                            .font(.title3.bold())
                            .foregroundColor(.blue)

                        Text("/ mo")
                            .font(.subheadline)
                            .foregroundColor(.gray)

                        Spacer()
                    }

                    Text(listing.address ?? "unknown address ")
                        .font(.subheadline)
                        .foregroundStyle(.black)

                    HStack(spacing: 14) {
                        Label("\(listing.bedrooms) bed", systemImage: "bed.double")
                        Label("\(listing.bathrooms) bath", systemImage: "bathtub")
                        Label("\(listing.squareFeet) sqft", systemImage: "ruler")
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 14)
            }
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.19), radius: 8, x: 0, y: 4)
            .padding(.horizontal)
        }
    }

    private var listingDisplayLocation: String {
        if !listing.address.isEmpty {
            return listing.address
        }
        return "Unknown location"
    }
}


#Preview {
    let sampleListing = Listing(
        listingID: UUID(),
        listingName: "Modern Apartment",
        landLordId: "123",
        price: 1800,
        bedrooms: 2,
        bathrooms: 1,
        address: "10490 avenue curotte"
    )

    ApartmentCard(listing: sampleListing)
        .environmentObject(FirebaseManager())
}
