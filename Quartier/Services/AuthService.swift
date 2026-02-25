//
//  AuthService.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-01-29.
//
import Foundation
import FirebaseAuth

class AuthService: ObservableObject {
    @Published var userSession: FirebaseAuth.User?
    @Published var currentUserRole: String?
    @Published var hasCompletedPreferences: Bool = false // NEW
    
    static let shared = AuthService()
    
    init() {
        self.userSession = Auth.auth().currentUser
        if userSession != nil {
            fetchUserData()
        }
    }
    
    // login
    func login(email: String, password: String, completion: @escaping (Bool) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if error != nil {
                completion(false)
                return
            }
            self.userSession = result?.user
            self.fetchUserData()
            completion(true)
        }
    }
    
    // signup
    func register(email: String, password: String, role: String, completion: @escaping (Bool) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if error != nil {
                completion(false)
                return
            }
            
            guard let uid = result?.user.uid else { return }
            
            FirebaseManager.shared.saveUser(uid: uid, email: email, role: role) { success in
                if success {
                    self.userSession = result?.user
                    self.currentUserRole = role
                    self.hasCompletedPreferences = false
                    completion(true)
                } else {
                    completion(false)
                }
            }
        }
    }
    
    // get extra user info
    func fetchUserData() {
        guard let uid = userSession?.uid else { return }
        FirebaseManager.shared.fetchUser(uid: uid) { data in
            DispatchQueue.main.async {
                self.currentUserRole = data?["role"] as? String
                self.hasCompletedPreferences = data?["hasCompletedPreferences"] as? Bool ?? false
            }
        }
    }
    
    // logout
    func signOut() {
        try? Auth.auth().signOut()
        self.userSession = nil
        self.currentUserRole = nil
        self.hasCompletedPreferences = false
    }
}
