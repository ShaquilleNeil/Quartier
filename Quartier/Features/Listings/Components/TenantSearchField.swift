//
//  TenantSearchField.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-04-03.
//

import SwiftUI


struct TenantSearchField: View {

    @Binding var selectedTenant: TenantItem?
    let tenants: [TenantItem]

    @State private var searchText = ""
    @State private var filteredTenants: [TenantItem] = []
    @State private var showDropdown = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {

            TextField("Search Tenants...", text: $searchText)
                .padding()
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .onChange(of: searchText) { _ in
                    filterTenants()
                }

            if showDropdown {
                ScrollView {
                    VStack(spacing: 0) {

                        ForEach(filteredTenants.prefix(8)) { tenant in
                            Text(tenant.email)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.white)
                                .onTapGesture {
                                    selectedTenant = tenant
                                    searchText = tenant.email
                                    showDropdown = false
                                }

                            Divider()
                        }
                    }
                }
                .frame(maxHeight: 200)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(radius: 6)
            }
        }
        .zIndex(1)
    }

    private func filterTenants() {
        guard !searchText.isEmpty else {
            filteredTenants = []
            showDropdown = false
            return
        }

        filteredTenants = tenants.filter {
            $0.email.lowercased().contains(searchText.lowercased())
        }

        showDropdown = !filteredTenants.isEmpty
    }
}
