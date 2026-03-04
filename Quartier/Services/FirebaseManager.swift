//
//  FirebaseManager.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-01-29.
//
import Foundation
import FirebaseFirestore

class FirebaseManager {
    static let shared = FirebaseManager()
    private let db = Firestore.firestore()
    
    // save to db
    func saveUser(uid: String, email: String, role: String, completion: @escaping (Bool) -> Void) {
        let userData: [String: Any] = [
            "id": uid,
            "email": email,
            "role": role,
            "hasCompletedPreferences": false // Default to false for new users
        ]
        
        db.collection("users").document(uid).setData(userData) { error in
            if let error = error {
                print("db error: \(error.localizedDescription)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    // get from db
    func fetchUser(uid: String, completion: @escaping ([String: Any]?) -> Void) {
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let data = snapshot?.data() {
                completion(data)
            } else {
                completion(nil)
            }
        }
    }
}
