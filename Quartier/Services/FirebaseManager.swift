//
//  FirebaseManager.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-01-29.
//

import Foundation
import FirebaseFirestore
import Combine
import FirebaseStorage

class FirebaseManager: ObservableObject {
    private let db = Firestore.firestore()
    @Published var currentUser: User? = nil
    @Published var firebaseListings: [RemoteListing] = []
    private let storage = Storage.storage()
    
    // save to db
    func saveUser(uid: String, email: String, role: String, isRenting: Bool = false, completion: @escaping (Bool) -> Void) {
        let userData: [String: Any] = [
            "id": uid,
            "email": email,
            "role": role,
            "isRenting": isRenting,
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
                // Map Firestore data to our User model if possible
                let id = data["id"] as? String ?? uid
                let email = data["email"] as? String ?? ""
                let roleString = data["role"] as? String ?? "tenant"
                let isRenting = data["isRenting"] as? Bool ?? false
                let isActive = data["isActive"] as? Bool ?? true
                let createdAtTimestamp = data["createdAt"] as? TimeInterval
                let createdAt: Date = createdAtTimestamp != nil ? Date(timeIntervalSince1970: createdAtTimestamp!) : Date()
                let role: UserType = roleString.lowercased() == "landlord" ? .landlord : .tenant
                let user = User(id: id, email: email, role: role, createdAt: createdAt, isActive: isActive, isRenting: isRenting)
                DispatchQueue.main.async {
                    self.currentUser = user
                }
                completion(data)
            } else {
                completion(nil)
            }
        }
    }
    
    func fetchListingsLandord(){
        guard let landLordId = currentUser?.id else { return }
        
        db.collection("listings")
            .whereField("landLordId", isEqualTo: landLordId)
            .getDocuments {
                snapshot, error in
                if let error = error {
                    print("Error fetching landlord listings:", error)
                    return
                }
                
                guard let documents = snapshot?.documents else {return}
                
                let listings = documents.compactMap { doc -> RemoteListing? in
                    let data = doc.data()
                     
                    return RemoteListing(
                                      id: doc.documentID,
                                      buildingId: data["buildingId"] as? String ?? "",
                                      landlordId: data["landLordId"] as? String ?? "",
                                      price: (data["price"] as? NSNumber)?.doubleValue ?? 0,
                                      bedrooms: data["bedrooms"] as? Int ?? 0,
                                      bathrooms: data["bathrooms"] as? Int ?? 0,
                                      amenities: data["amenities"] as? [String] ?? [],
                                      status: data["status"] as? String ?? "",
                                      rules: data["rules"] as? String ?? "",
                                      imageURLs: data["images"] as? [String] ?? [],
                                      address: data["address"] as? String ?? "",
                                      isRented: data["isRented"] as? Bool ?? false
                                  )
                    
                    
                }
                
                DispatchQueue.main.async {
                    self.firebaseListings = listings
                }
            }
    }
    
    //MARK: save a listing
    
    func uploadListingImages(
        listingId: UUID,
        images:[UIImage]
    ) async throws -> [String]
    {
        var urls: [String] = []
        
        for (index, image) in images.enumerated(){
            guard let data = image.jpegData(compressionQuality: 0.8) else { continue }
            
            let ref = storage.reference().child("listings/\(listingId.uuidString)/image_\(index).jpg")
            
            _ = try await ref.putDataAsync(data)
            let downloadURL = try await ref.downloadURL()
            
            urls.append(downloadURL.absoluteString)
            
            
        }
        return urls
    }
    
    
    func saveListing(listingId: UUID, buildingId: String, landLordId: String, price: Double, bedrooms: Int, bathrooms: Int, amenities: [String], status: ListingStatus, rules: String, imageURLs: [String], address: String, isRented: Bool ){
        
        let listingData: [String: Any] = [
            "id": listingId.uuidString,
            "buildingId": buildingId,
            "landLordId": landLordId,
            "price": price,
            "bedrooms": bedrooms,
            "bathrooms": bathrooms,
            "amenities": amenities,
            "status": status.rawValue,
            "rules": rules,
            "images": imageURLs,
            "address": address,
            "isRented": isRented
        ]
        
        db.collection("listings").document(listingId.uuidString).setData(listingData){
            error in
            if let error = error {
                print("Error adding document: \(error)")
            } else {
                print("Document added with ID: \(listingId)")
            }
        }
    }
    
    
    
    func updateListing(
        listingId: String,
        buildingId: String,
        price: Double,
        bedrooms: Int,
        bathrooms: Int,
        amenities: [String],
        rules: String,
        address: String,
        isRented: Bool,
        imageURLs: [String]
    ) {

        let updatedData: [String: Any] = [
            "buildingId": buildingId,
            "price": price,
            "bedrooms": bedrooms,
            "bathrooms": bathrooms,
            "amenities": amenities,
            "rules": rules,
            "address": address,
            "isRented": isRented,
            "images": imageURLs
        ]

        db.collection("listings")
            .document(listingId)
            .updateData(updatedData) { error in
                if let error = error {
                    print("Update failed:", error.localizedDescription)
                } else {
                    print("Listing updated successfully")
                }
            }
    }
    
    
  
}

