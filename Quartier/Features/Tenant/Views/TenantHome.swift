//
//  TenantHome.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-01-29.
//
import SwiftUI
import FirebaseFirestore
import CoreData

struct TenantHome: View {
    @State private var showingPreferences = false
    @State private var searchText: String = ""
    @EnvironmentObject var firebase: FirebaseManager
    @EnvironmentObject var coreDataManager: CoreDataManager
    
    @Environment(\.managedObjectContext) private var context
    
    var isFilterActive: Bool {
        coreDataManager.preferences != nil
    }
    
    var filteredListings: [Listing] {
        var results = firebase.allListings
        
        if !searchText.isEmpty {
            results = results.filter { listing in
                listing.address.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        if let prefs = coreDataManager.preferences {
            results = results.filter { listing in
                let priceOk = listing.price >= prefs.budgetMin && listing.price <= prefs.budgetMax
                
                let bedsOk: Bool
                let targetBeds = prefs.selectedBedroom ?? "Studio"
                if targetBeds == "Studio" {
                    bedsOk = listing.bedrooms == 0
                } else if targetBeds == "3+" {
                    bedsOk = listing.bedrooms >= 3
                } else if let exactBeds = Int(targetBeds) {
                    bedsOk = listing.bedrooms == exactBeds
                } else {
                    bedsOk = true
                }
                
                return priceOk && bedsOk
            }
        }
        
        return results
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                SearchBar(searchText: $searchText, onFilterTapped: {
                    showingPreferences = true
                })
                
                if isFilterActive {
                    HStack {
                        Text("Preferences Applied")
                            .font(.caption.bold())
                            .foregroundColor(.blue)
                        
                        Spacer()
                        
                        Button(action: clearPreferences) {
                            Text("Clear Filters")
                                .font(.caption.bold())
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.horizontal, 8)
                }
                
                ScrollView{
                    let columns = [
                        GridItem(.flexible())
                    ]

                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(filteredListings) { apartment in
                            ApartmentCard(listing: apartment)
                        }
                    }
                    .padding(.top)
                }
            }
            .onAppear {
                firebase.fetchAllListings()
                coreDataManager.loadPreferences(context)
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .sheet(isPresented: $showingPreferences) {
                TenantPreferencesView()
            }
        }
    }

    private func clearPreferences() {
        if let prefs = coreDataManager.preferences {
            context.delete(prefs)
            try? context.save()
            coreDataManager.preferences = nil
        }
    }
}

struct SearchBar: View {
    @Binding var searchText: String
    var onFilterTapped: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search neighborhoods...", text: $searchText)
                    .textInputAutocapitalization(.words)
                    .disableAutocorrection(true)
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(14)
            
            Button(action: onFilterTapped) {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.blue)
                    .cornerRadius(14)
            }
            .navigationBarBackButtonHidden(true)
        }
    }
}


