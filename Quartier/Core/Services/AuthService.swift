//
//  AuthService.swift
//  Quartier
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

class AuthService: ObservableObject {
    
    // MARK: - Published routing state
    
    @Published var userSession: FirebaseAuth.User?
    @Published var currentUserRole: String?
    @Published var hasCompletedPreferences: Bool = false
    @Published var isRenting: Bool = false
    @Published var rentedListingId: String?
    @Published var rentedAddress: String?

    // MARK: - Dependencies

    private let firebase: FirebaseManager
    private let db = Firestore.firestore()
    private var userDocListener: ListenerRegistration?
    
    // MARK: - Init
    
    init(firebase: FirebaseManager) {
        self.firebase = firebase
        
        // 🔥 Reactive auth listener (canonical Firebase pattern)
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }

            DispatchQueue.main.async {
                self.userSession = user
                self.userDocListener?.remove()
                self.userDocListener = nil

                if let user = user {
                    self.attachUserDocumentListener(uid: user.uid)
                    self.firebase.fetchUser(uid: user.uid) { _ in }
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
                if let data {
                    self.applyUserDocument(data)
                }
            }
        }
    }

    private func attachUserDocumentListener(uid: String) {
        userDocListener = db.collection("users").document(uid).addSnapshotListener { [weak self] snapshot, _ in
            guard let self else { return }
            guard let data = snapshot?.data() else {
                if snapshot?.exists == false {
                    DispatchQueue.main.async {
                        self.applyUserDocument([:])
                    }
                }
                return
            }
            DispatchQueue.main.async {
                self.applyUserDocument(data)
            }
        }
    }

    private func applyUserDocument(_ data: [String: Any]) {
        currentUserRole = data["role"] as? String
        hasCompletedPreferences = data["hasCompletedPreferences"] as? Bool ?? false
        isRenting = data["isRenting"] as? Bool ?? false
        if let lid = data["rentedListingId"] as? String, !lid.isEmpty {
            rentedListingId = lid
        } else {
            rentedListingId = nil
        }
        if let addr = data["rentedAddress"] as? String, !addr.isEmpty {
            rentedAddress = addr
        } else {
            rentedAddress = nil
        }
    }
    
    // MARK: - Logout
    
    func signOut() {
        try? Auth.auth().signOut()
        // Auth listener will reset state automatically
    }
    
    // MARK: - Helpers
    
    private func resetState() {
        userDocListener?.remove()
        userDocListener = nil
        currentUserRole = nil
        hasCompletedPreferences = false
        isRenting = false
        rentedListingId = nil
        rentedAddress = nil
    }
}
