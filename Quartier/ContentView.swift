//
//  ContentView.swift
//  Quartier
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.managedObjectContext) private var viewContext

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
    }
}

#Preview {
    let firebase = FirebaseManager()
    let auth = AuthService(firebase: firebase)

    return ContentView()
        .environmentObject(firebase)
        .environmentObject(auth)
}
