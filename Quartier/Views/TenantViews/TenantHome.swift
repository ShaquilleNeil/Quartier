//
//  TenantHome.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-01-29.
//

import SwiftUI
import FirebaseFirestore

struct TenantHome: View {
    @State private var showingPreferences = false
    @State private var listings: [Listing] = []
    @EnvironmentObject var firebase: FirebaseManager
    
    var body: some View {
        NavigationStack {
            VStack{
                SearchBar(onFilterTapped: {
                    showingPreferences = true
                })
                
                ScrollView{
                    let columns = [
                        GridItem(.flexible())
                    ]

                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(firebase.allListings) { apartment in
                            ApartmentCard(listing: apartment
                            )
                        }
                    }
                    .padding(.top)

                }
            }
            .onAppear {
                firebase.fetchAllListings()
            }
            .padding()
            // 3. Attach the sheet to show the preferences
            .sheet(isPresented: $showingPreferences) {
                TenantPreferencesView()
            }
        }
    }
}


struct SearchBar: View {
    @State private var searchText: String = ""
    var onFilterTapped: () -> Void //
    
    var body: some View {
        HStack(spacing: 12) {
            
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Brooklyn, NY", text: $searchText)
                    .textInputAutocapitalization(.words)
                    .disableAutocorrection(true)
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(14)
            
            // Preference / filter button
            Button(action: onFilterTapped) {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.blue)
                    .cornerRadius(14)
            }
            .navigationBarBackButtonHidden(true)
            .padding(.horizontal)
        }
    }
    
}
#Preview {
    TenantHome()
        .environmentObject(FirebaseManager())
}
