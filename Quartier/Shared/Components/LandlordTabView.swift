//
//  LandlordTabView.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-01-29.
//
// MARK: - LandlordTabView.swift
import SwiftUI

struct LandlordTabView: View {
    @StateObject private var chatVM = ChatViewModel()
    
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house.fill") {
                LandlordHome()
            }
            Tab("Listings", systemImage: "list.bullet.clipboard.fill") {
                LandlordListings()
            }
            Tab("Scheduler", systemImage: "calendar") {
                LandlordSchedule()
            }
            Tab("Messages", systemImage: "message.fill") {
                LandlordMessages()
            }
            .badge(chatVM.totalUnread)
            
            Tab("Profile", systemImage: "person.fill") {
                LandlordProfile(publicView: false)
            }
        }
        .onAppear {
            chatVM.loadConversations(isLandlord: true)
        }
    }
}

#Preview {
    LandlordTabView()
}
