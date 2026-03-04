//
//  ContentView.swift
//  Quartier
//

import SwiftUI

struct ContentView: View {
<<<<<<< HEAD
    @State private var showTenant: Bool = true

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {

                NavigationLink(destination: LandlordTabView()) {
                    Text("landlord")
                }

                NavigationLink(destination: TenantTabView()) {
                    Text("tenant")
                }

=======
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
>>>>>>> origin/main
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
<<<<<<< HEAD
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
=======
        .environmentObject(AuthService.shared)
>>>>>>> origin/main
}
