//
//  ContentView.swift
//  Quartier
//

import SwiftUI

struct ContentView: View {
<<<<<<< Updated upstream
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
=======
    @State private var showTenant: Bool = true
    @Environment(\.managedObjectContext) private var viewContext

//    @FetchRequest(
//        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
//        animation: .default)
//    private var items: FetchedResults<Item>

    var body: some View {
        
        NavigationStack{
            NavigationLink(destination: LandlordTabView()) {
                Text("landlord")
            }
            
            
            NavigationLink(destination: TenantTabView()) {
                Text("tenant")
            }
        }
        
      
       
    }

 
>>>>>>> Stashed changes
}

#Preview {
    ContentView()
        .environmentObject(AuthService.shared)
}
