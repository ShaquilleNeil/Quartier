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
    
    var body: some View {
        NavigationStack {
            VStack  {
                ScrollView{
                    let columns = [
                        GridItem(.flexible())
                    ]

                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(firebase.savedListings) { apartment in
                            ApartmentCard(listing: apartment)
                        }
                    }
                    .padding(.top)
                }
            }
            .onAppear {
                firebase.fetchUserFavorites()
            }
            .padding()
        }
    }
}
