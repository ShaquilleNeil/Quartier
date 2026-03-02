//
//  ContentView.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-01-28.
//

import SwiftUI
import CoreData

struct ContentView: View {
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

            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
