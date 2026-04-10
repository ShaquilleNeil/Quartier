//
//  TenantTabView.swift
//  Quartier
//
// MARK: - TenantTabView.swift
import SwiftUI
import Combine

struct TenantTabView: View {
    @EnvironmentObject var authService: AuthService
    @State private var selectedTab: TenantTab = .home

    @StateObject private var chatVM = ChatViewModel()
    
    var body: some View {
        TabView {
            Group {
                if authService.isRenting {
                    TenantRentedDash()
                } else {
                    TenantHome(selectedTab: .constant(.home))
                }
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }

            TenantDiscover()
                .tabItem {
                    Label("Discover", systemImage: "magnifyingglass")
                }

            TenantSaved()
                .tabItem {
                    Label("Saved", systemImage: "bookmark.fill")
                }

            TenantMessages()
                .tabItem {
                    Label("Messages", systemImage: "message.fill")
                }
            .badge(chatVM.totalUnread)

            TenantProfile()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
        .onAppear {
            chatVM.loadConversations(isLandlord: false)
        }
    }
}

#Preview {
    let firebase = FirebaseManager()
    let auth = AuthService(firebase: firebase)

    return TenantTabView()
        .environmentObject(firebase)
        .environmentObject(auth)
}

