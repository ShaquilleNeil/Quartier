//
//  TenantTabView.swift
//  Quartier
//

import SwiftUI

struct TenantTabView: View {
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house.fill"){
                TenantHome()
            }
            Tab("Discover", systemImage: "magnifyingglass"){ 
                TenantDiscover()
            }
            Tab("Saved", systemImage: "bookmark.fill"){
                TenantSaved()
            }
            Tab("Agenda", systemImage: "calendar"){
                TenantSchedule()
            }
            Tab("Profile", systemImage: "person.fill"){
                TenantProfile()
            }
        }
    }
}

#Preview {
    TenantTabView()
}
