//
//  QuartierApp.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-01-28.
//

import SwiftUI
import CoreData
import Firebase

@main
struct QuartierApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
