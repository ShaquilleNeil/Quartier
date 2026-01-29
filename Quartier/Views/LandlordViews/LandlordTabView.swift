//
//  LandlordTabView.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-01-29.
//

import SwiftUI

struct LandlordTabView: View {
    var body: some View {
        TabView{
            Tab("Home", systemImage: "house.fill"){
                LandlordHome()
            }
            Tab("Listings", systemImage: "list.bullet.clipboard.fill"){
                LandlordListings()
            }
            Tab("Scheduler", systemImage: "calendar"){
                LandlordSchedule()
            }
            Tab("Messages", systemImage: "message.fill"){
                LandlordMessages()
            }
            Tab("Profile", systemImage: "person.fill"){
                LandlordProfile()
            }
        }
    }
}

#Preview {
    LandlordTabView()
}
