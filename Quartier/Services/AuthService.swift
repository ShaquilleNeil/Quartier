//
//  AuthService.swift
//  Quartier
//

import Foundation
import FirebaseAuth
import Combine

class AuthService: ObservableObject {
    
    // MARK: - Published routing state
    
    @Published var userSession: FirebaseAuth.User?
    @Published var currentUserRole: String?
    @Published var hasCompletedPreferences: Bool = false
    @Published var isRenting: Bool = false
    
    // MARK: - Dependencies
    
    private let firebase: FirebaseManager
    
    // MARK: - Init
    
    init(firebase: FirebaseManager) {
        self.firebase = firebase
        
        // 🔥 Reactive auth listener (canonical Firebase pattern)
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            
            DispatchQueue.main.async {
                self.userSession = user
                
                if user != nil {
                    self.fetchUserData()
                } else {
                    self.resetState()
                }
            }
        }
    }
    
    // MARK: - Login
    
    func login(email: String, password: String, completion: @escaping (Bool) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { _, error in
            if let error = error {
                print("Login error:", error)
                completion(false)
                return
            }

            // 🔥 No manual fetch needed
            // Auth listener will handle Firestore hydration

            completion(true)
        }
    }
    
    // MARK: - Register
    
    func register(email: String, password: String, role: String, completion: @escaping (Bool) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            
            if error != nil {
                completion(false)
                return
            }
            
            guard let uid = result?.user.uid else {
                completion(false)
                return
            }
            
            // Save user doc with lifecycle defaults
            self.firebase.saveUser(uid: uid, email: email, role: role) { success in
                DispatchQueue.main.async {
                    if success {
                        // Auth listener will hydrate everything
                        completion(true)
                    } else {
                        completion(false)
                    }
                }
            }
        }
    }
    
    // MARK: - Fetch Firestore user document
    
    func fetchUserData() {
        guard let uid = userSession?.uid else { return }
        
        firebase.fetchUser(uid: uid) { [weak self] data in
            guard let self else { return }
            
            DispatchQueue.main.async {
                self.currentUserRole = data?["role"] as? String
                self.hasCompletedPreferences = data?["hasCompletedPreferences"] as? Bool ?? false
                self.isRenting = data?["isRenting"] as? Bool ?? false
            }
        }
    }
    
    // MARK: - Logout
    
    func signOut() {
        try? Auth.auth().signOut()
        // Auth listener will reset state automatically
    }
    
    // MARK: - Helpers
    
    private func resetState() {
        self.currentUserRole = nil
        self.hasCompletedPreferences = false
        self.isRenting = false
    }
}
