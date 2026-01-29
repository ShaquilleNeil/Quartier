//
//  TenantTabView.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-01-29.
//

import SwiftUI

struct TenantTabView: View {
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house.fill"){
                TenantHome()
            }
            Tab("Discover", systemImage: "globe.fill"){
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
