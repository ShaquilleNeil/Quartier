//
//  ContentView.swift
//  Quartier
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        Group {
            if authService.userSession != nil {
                // Wait for role to load from Firestore
                if let role = authService.currentUserRole {
                    if role == "tenant" {
                        if authService.hasCompletedPreferences {
                            TenantTabView()
                        } else {
                            TenantPreferencesView()
                        }
                    } else if role == "landlord" {
                        LandlordTabView()
                    }
                } else {
                    VStack {
                        ProgressView()
                        Text("Loading...")
                            .foregroundColor(.gray)
                    }
                }
            } else {
                LoginSwitch()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthService.shared)
}
