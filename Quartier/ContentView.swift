//
//  ContentView.swift
//  Quartier
//

import SwiftUI
import CoreData

struct ContentView: View {
    @EnvironmentObject var authService: AuthService

    var body: some View {
        Group {
            if authService.userSession != nil {
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
        .padding()
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthService.shared)
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
