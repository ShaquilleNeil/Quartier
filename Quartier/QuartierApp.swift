//
//  QuartierApp.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-01-28.
//

import SwiftUI
import FirebaseCore
import CoreData

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // init firebase
       
        return true
    }
}

@main
struct QuartierApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @StateObject private var fireBase = FirebaseManager()
    @StateObject private var authService: AuthService

    let persistenceController = PersistenceController.shared
    @StateObject private var coreDataManager: CoreDataManager

    init() {
        FirebaseApp.configure()
        let ctx = PersistenceController.shared.container.viewContext
        _coreDataManager = StateObject(wrappedValue: CoreDataManager(ctx))

        let firebase = FirebaseManager()
        _fireBase = StateObject(wrappedValue: firebase)
        _authService = StateObject(wrappedValue: AuthService(firebase: firebase))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(fireBase)
                .environmentObject(authService)
                .environmentObject(coreDataManager)
                .environment(\.managedObjectContext,
                              persistenceController.container.viewContext)
        }
    }
}
