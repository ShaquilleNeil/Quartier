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
    @State private var listings: [Listing] = []
    
    var body: some View {
        VStack  {
            ScrollView{
                let columns = [
                    GridItem(.flexible())
                ]

                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(firebase.allListings.filter {
                        firebase.favoriteIds.contains($0.listingID.uuidString)
                    }) { apartment in
                        ApartmentCard(listing: apartment)
                    }                }
                .padding(.top)

            }
        }
        .onAppear {
            firebase.fetchUserFavorites()
        }
        .padding()
        
            
      
    }
}

#Preview {
    TenantSaved()
}
