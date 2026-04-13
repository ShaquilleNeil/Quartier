//
//  AuthService.swift
//  Quartier
//
import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

class AuthService: ObservableObject {
    
    // MARK: - Published Routing State
    
    @Published var userSession: FirebaseAuth.User?
    @Published var currentUserRole: String?
    @Published var hasCompletedPreferences: Bool = false
    @Published var isRenting: Bool = false
    @Published var rentedListingId: String?
    @Published var rentedAddress: String?

    // MARK: - Dependencies

 let firebase: FirebaseManager
    private let db = Firestore.firestore()
    private var userDocListener: ListenerRegistration?
    
    // MARK: - Init
    
    init(firebase: FirebaseManager) {
        self.firebase = firebase
        
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }

            DispatchQueue.main.async {
                self.userSession = user
                self.userDocListener?.remove()
                self.userDocListener = nil

                if let user = user {
                    self.attachUserDocumentListener(uid: user.uid)
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
            completion(true)
        }
    }
    
    // MARK: - Register
    
    func register(email: String, password: String, role: String, completion: @escaping (Bool) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            
            if let error = error {
                print("Register error:", error)
                completion(false)
                return
            }
            
            guard let uid = result?.user.uid else {
                completion(false)
                return
            }
            
            let defaultName = email.components(separatedBy: "@").first ?? ""
            
            self.firebase.saveUser(
                uid: uid,
                name: defaultName,
                profilePic: "",
                email: email,
                role: role
            ) { success in
                DispatchQueue.main.async {
                    completion(success)
                }
            }
        }
    }
    
    func resetPassword(email: String, completion: @escaping (Bool, String?) -> Void) {
            Auth.auth().sendPasswordReset(withEmail: email) { error in
                if let error = error {
                    completion(false, error.localizedDescription)
                } else {
                    completion(true, nil)
                }
            }
        }
    
    func saveProfile(
        uid: String,
        name: String,
        imageData: Data?,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        
        if let imageData = imageData {
            firebase.uploadProfileImage(uid: uid, data: imageData) { url in
                
                guard let url = url else {
                    completion(.failure(NSError(domain: "Upload failed", code: 0)))
                    return
                }

                self.firebase.updateUserProfile(
                    uid: uid,
                    name: name,
                    profilePic: url
                ) { success in
                    success
                    ? completion(.success(()))
                    : completion(.failure(NSError(domain: "Update failed", code: 0)))
                }
            }

        } else {
            
            firebase.updateUserProfile(
                uid: uid,
                name: name,
                profilePic: nil // won't overwrite
            ) { success in
                success
                ? completion(.success(()))
                : completion(.failure(NSError(domain: "Update failed", code: 0)))
            }
        }
    }
    
    // MARK: - Document Listener
    
    private func attachUserDocumentListener(uid: String) {
        userDocListener = db.collection("users").document(uid).addSnapshotListener { [weak self] snapshot, _ in
            guard let self else { return }
            guard let data = snapshot?.data() else {
                if snapshot?.exists == false {

                    try? Auth.auth().signOut()
                    self.resetState()
                    return
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
        
        if let lid = data["apartmentId"] as? String, !lid.isEmpty {
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
        firebase.clearState() 
    }
}
