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
import FirebaseAuth

class FirebaseManager: ObservableObject {
    private let db = Firestore.firestore()
    @Published var currentUser: User? = nil
    @Published var firebaseListings: [RemoteListing] = []
    private let storage = Storage.storage()
    @Published var allListings: [Listing] = []
    @Published var favoriteIds: Set<String> = []
    
    // save to db
    func saveUser(uid: String, email: String, role: String, isRenting: Bool = false, apartmentId: String? = nil, completion: @escaping (Bool) -> Void) {
        let userData: [String: Any] = [
            "id": uid,
            "email": email,
            "role": role,
            "isRenting": isRenting,
            "apartmentId": apartmentId ?? "",
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
                let apartmentId = data["apartmentId"] as? String ?? ""

                let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()

                let role: UserType = roleString.lowercased() == "landlord" ? .landlord : .tenant

                let user = User(
                    id: id,
                    email: email,
                    role: role,
                    createdAt: createdAt,
                    isActive: isActive,
                    isRenting: isRenting,
                    apartmentId: apartmentId
                )
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

                    let location = data["location"] as? GeoPoint
                    let latitude = location?.latitude ?? 0
                    let longitude = location?.longitude ?? 0

                    let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                    let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()

                    return RemoteListing(
                        id: doc.documentID,
                        buildingId: data["buildingId"] as? String ?? "",
                        landlordId: data["landLordId"] as? String ?? "",
                        price: (data["price"] as? NSNumber)?.doubleValue ?? 0,
                        bedrooms: data["bedrooms"] as? Int ?? 0,
                        bathrooms: data["bathrooms"] as? Int ?? 0,
                        squareFeet: data["squareFeet"] as? Int ?? 0,
                        amenities: data["amenities"] as? [String] ?? [],
                        rules: data["rules"] as? String ?? "",
                        imageURLs: data["images"] as? [String] ?? [],
                        address: data["address"] as? String ?? "",
                        latitude: latitude,
                        longitude: longitude,
                        status: data["status"] as? String ?? "",
                        isRented: data["isRented"] as? Bool ?? false,
                        createdAt: createdAt,
                        updatedAt: updatedAt
                    )
                }
                
                DispatchQueue.main.async {
                    self.firebaseListings = listings
                }
            }
    }
    
    func fetchAllListings(){
        db.collection("listings")
            .getDocuments { snapshot, error in
                
                guard let documents = snapshot?.documents else { return }
                
                var fetchedListings: [Listing] = []
                
                for doc in documents {
                    let data = doc.data()
                    
                    var listing = Listing(
                        buildingID: "",
                        landLordId: "",
                        price: 0,
                        bedrooms: 0,
                        bathrooms: 0
                    )
                    
                    listing.buildingID = data["buildingId"] as? String ?? ""
                    listing.landLordId = data["landLordId"] as? String ?? ""
                    listing.price = data["price"] as? Double ?? 0
                    listing.bedrooms = data["bedrooms"] as? Int ?? 0
                    listing.bathrooms = data["bathrooms"] as? Int ?? 0
                    listing.address = data["address"] as? String ?? ""
                    listing.squareFeet = data["squareFeet"] as? Int ?? 0
                    listing.isRented = data["isRented"] as? Bool ?? false
                    
                    listing.amenities = data["amenities"] as? [String] ?? []
                    listing.rules = data["rules"] as? String ?? ""
                    
                    if let location = data["location"] as? GeoPoint {
                        listing.latitude = location.latitude
                        listing.longitude = location.longitude
                    }
                    
                    // image URLs from Firestore
                    listing.existingImageURLs = data["images"] as? [String] ?? []
                    
                    fetchedListings.append(listing)
                }
                
                self.allListings = fetchedListings
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
    
    
    func saveListing(
        listingId: UUID,
        buildingId: String,
        landLordId: String,
        price: Double,
        squareFeet: Int,
        latitude: Double,
        longitude: Double,
        bedrooms: Int,
        bathrooms: Int,
        amenities: [String],
        status: ListingStatus,
        rules: String,
        imageURLs: [String],
        address: String,
        isRented: Bool
    )
    {
        
        let listingData: [String: Any] = [
            "id": listingId.uuidString,
            "buildingId": buildingId,
            "landLordId": landLordId,
            "price": price,
            "squareFeet": squareFeet,
            "bedrooms": bedrooms,
            "bathrooms": bathrooms,
            "amenities": amenities,
            "status": status.rawValue,
            "rules": rules,
            "images": imageURLs,
            "address": address,
            "location": GeoPoint(latitude: latitude, longitude: longitude),
            "isRented": isRented,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
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
    

    func updateUser(uid: String, email: String, role: String, isRenting: Bool, hasCompletedPreferences: Bool, apartmentId: String? ){
        db.collection("users")
            .document(uid)
            .updateData([
                "id": uid,
                "email": email,
                "role": role,
                "isRenting": isRenting,
                "hasCompletedPreferences": hasCompletedPreferences,
                "apartmendId": apartmentId ?? ""
            ])
    }
    
    
    func updateUserHasCompletedPreferences() {

        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("users")
            .document(uid)
            .updateData([
                "hasCompletedPreferences": true
            ])
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
        imageURLs: [String],
        squareFeet: Int,
        latitude: Double,
        longitude: Double
    )
    {

        let updatedData: [String: Any] = [
            "buildingId": buildingId,
            "price": price,
            "squareFeet": squareFeet,
            "bedrooms": bedrooms,
            "bathrooms": bathrooms,
            "amenities": amenities,
            "rules": rules,
            "address": address,
            "location": GeoPoint(latitude: latitude, longitude: longitude),
            "isRented": isRented,
            "images": imageURLs,
            "updatedAt": FieldValue.serverTimestamp()
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
    
    func saveFavorite(listingId: String){
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let ref = db.collection("users")
            .document(uid)
            .collection("favorites")
            .document(listingId)
        
        ref.getDocument {
            snapshot, _ in
            if snapshot?.exists == true {
                ref.delete()
            } else {
                ref.setData( [
                    "listingId": listingId,
                    "createdAt": FieldValue.serverTimestamp()
                ])
            }
        }
    }
    
    func fetchUserFavorites(){
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users")
            .document(uid)
            .collection("favorites")
            .getDocuments {
                snapshot, _ in
                
                let ids = snapshot?.documents.map { $0.documentID } ?? []
                
                DispatchQueue.main.async {
                    self.favoriteIds = Set(ids)
                }
            }
    }
    
    //MARK: Save Preferences
    
    func savePreferencesFS(preferences: Preferences) {
        
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("users")
            .document(uid)
            .collection("preferences")
            .document("tenant")
            .setData([
                "locationQuery": preferences.locationQuery,
                "budgetMin": preferences.budgetMin,
                "budgetMax": preferences.budgetMax,
                "selectedBedroom": preferences.selectedBedroom,
                "petsAllowed": preferences.petsAllowed,
                "fullyFurnished": preferences.fullyFurnished,
                "parkingIncluded": preferences.parkingIncluded,
                "createdAt": FieldValue.serverTimestamp(),
                "updatedAt": FieldValue.serverTimestamp()
            ])
    }
    
    
    func updatePreferencesFS(preferences: Preferences) {
        
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("users")
            .document(uid)
            .collection("preferences")
            .document("tenant")
            .updateData([
                "locationQuery": preferences.locationQuery,
                "budgetMin": preferences.budgetMin,
                "budgetMax": preferences.budgetMax,
                "selectedBedroom": preferences.selectedBedroom,
                "petsAllowed": preferences.petsAllowed,
                "fullyFurnished": preferences.fullyFurnished,
                "parkingIncluded": preferences.parkingIncluded,
                "updatedAt": FieldValue.serverTimestamp()
            ])
    }
    
    
    
  
}

