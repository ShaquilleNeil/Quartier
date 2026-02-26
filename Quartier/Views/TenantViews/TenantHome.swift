//
//  TenantHome.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-01-29.
//

import SwiftUI

struct TenantHome: View {
    @State private var showingPreferences = false
    
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
                        ForEach(1...10, id: \.self) { apartment in
                            ApartmentCard(
                                imageName: "apartment1",
                                isNew: true,
                                rating: 4.8,
                                beds: 2,
                                baths: 1,
                                sqft: 950,
                                price: 1400.00,
                                location: "Montreal"
                            )
                        }
                    }
                    .padding(.top)

                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack{
                        Button {
                            // TODO: Open chat view
                        } label: {
                            Image(systemName: "bell.fill")
                        }
                        
                        Button {
                            // TODO: Open chat view
                        } label: {
                            Image(systemName: "bubble.left.and.bubble.right")
                        }
                    }
                    
                }
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
<<<<<<< Updated upstream
            Button(action: onFilterTapped) {
=======
            NavigationLink(destination: TenantPreferencesView()) {
>>>>>>> Stashed changes
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.blue)
                    .cornerRadius(14)
            }.navigationBarBackButtonHidden(true)
        }
        .padding(.horizontal)
    }
}


#Preview {
    TenantHome()
}
