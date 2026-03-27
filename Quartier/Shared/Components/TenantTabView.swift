//
//  TenantTabView.swift
//  Quartier
//

import SwiftUI
import Combine

struct TenantTabView: View {
    
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        TabView {
            
            Group {
                if authService.isRenting {
                    TenantRentedDash()
                } else {
                    TenantHome()
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

            TenantSchedule()
                .tabItem {
                    Label("Agenda", systemImage: "calendar")
                }

            TenantProfile()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
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

