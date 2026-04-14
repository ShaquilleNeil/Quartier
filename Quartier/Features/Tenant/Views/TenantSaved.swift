//
//  TenantSaved.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-01-29.
//
import SwiftUI
import FirebaseFirestore

struct TenantSaved: View {
    @EnvironmentObject private var firebase: FirebaseManager
    @Environment(\.managedObjectContext) private var context

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \TFavoriteListing.savedAt, ascending: false)]
    ) private var cachedFavorites: FetchedResults<TFavoriteListing>

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible())], spacing: 16) {
                    // Show live data if available, fall back to cache
                    let listings = firebase.savedListings.isEmpty
                        ? cachedFavorites.map { $0.toListing() }
                        : firebase.savedListings

                    ForEach(listings) { apartment in
                        ApartmentCard(listing: apartment)
                    }
                }
                .padding(.top)
            }
            .padding()
            .onAppear {
                firebase.fetchUserFavorites()
            }
        }
    }
}
