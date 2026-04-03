//
//  FirebaseManager.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-01-29.
//
import Foundation
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth
import Combine

class FirebaseManager: ObservableObject {
    
    // MARK: - Properties
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    @Published var currentUser: User? = nil
    @Published var allListings: [Listing] = []
    @Published var savedListings: [Listing] = []
    @Published var firebaseListings: [Listing] = []
    @Published var favoriteIds: Set<String> = []
    @Published var userPreferences: Preferences? = nil
    @Published var tenants: [TenantItem] = []
    
    // MARK: - State Management
    
    func clearState() {
        DispatchQueue.main.async {
            self.currentUser = nil
            self.allListings = []
            self.savedListings = []
            self.firebaseListings = []
            self.favoriteIds = []
            self.userPreferences = nil
        }
    }
    
    // MARK: - Helpers
    
    static func firestoreBool(_ value: Any?) -> Bool {
        if let b = value as? Bool { return b }
        if let n = value as? NSNumber { return n.boolValue }
        return false
    }
    
    // MARK: - User Management
    
    func saveUser(uid: String, email: String, role: String, isRenting: Bool = false, apartmentId: String? = nil, completion: @escaping (Bool) -> Void) {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let nameHint = email.split(separator: "@").first.map(String.init) ?? ""

        let userData: [String: Any] = [
            "id": uid,
            "email": email,
            "emailLowercase": normalizedEmail,
            "displayName": nameHint,
            "role": role.lowercased(),
            "isRenting": isRenting,
            "apartmentId": apartmentId ?? "",
            "hasCompletedPreferences": false,
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        db.collection("users").document(uid).setData(userData) { error in
            completion(error == nil)
        }
    }
    
    func fetchUser(uid: String, completion: @escaping (User?) -> Void) {
        db.collection("users").document(uid).getDocument { snapshot, _ in
            guard let data = snapshot?.data() else {
                completion(nil)
                return
            }
            
            let roleString = data["role"] as? String ?? "tenant"
            let user = User(
                id: data["id"] as? String ?? uid,
                email: data["email"] as? String ?? "",
                role: roleString.lowercased() == "landlord" ? .landlord : .tenant,
                createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                isActive: data["isActive"] as? Bool ?? true,
                isRenting: data["isRenting"] as? Bool ?? false,
                apartmentId: data["apartmentId"] as? String ?? ""
            )
            
            DispatchQueue.main.async {
                self.currentUser = user
                completion(user)
            }
        }
    }
    
    func updateUser(uid: String, email: String, role: String, isRenting: Bool, hasCompletedPreferences: Bool, apartmentId: String?) {
        db.collection("users").document(uid).updateData([
            "email": email.lowercased(),
            "role": role.lowercased(),
            "isRenting": isRenting,
            "hasCompletedPreferences": hasCompletedPreferences,
            "apartmentId": apartmentId ?? ""
        ])
    }
    
    func updateUserHasCompletedPreferences() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(uid).updateData(["hasCompletedPreferences": true])
    }
    
    func fetchCurrentUserRent(uid: String, completion: @escaping (Double?) -> Void) {
        fetchUser(uid: uid) { user in
            guard let user = user, user.isRenting, let apartmentId = user.apartmentId, !apartmentId.isEmpty else {
                completion(nil)
                return
            }

            self.db.collection("listings").document(apartmentId).getDocument { snapshot, _ in
                let price = snapshot?.data()?["price"] as? Double
                completion(price)
            }
        }
    }
    
    // MARK: - Listings Management
    
    func fetchListingsLandlord() {
        guard let landLordId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("listings").whereField("landLordId", isEqualTo: landLordId).getDocuments { snapshot, _ in
            guard let documents = snapshot?.documents else { return }
            self.parseListings(documents: documents) { listings in
                DispatchQueue.main.async {
                                     
                                       self.firebaseListings = listings.sorted { $0.updatedAt > $1.updatedAt }
                                   }
            }
        }
    }
    
    func fetchAllListings() {
        db.collection("listings").whereField("isRented", isEqualTo: false).getDocuments { snapshot, _ in
            guard let documents = snapshot?.documents else { return }
            self.parseListings(documents: documents) { listings in
                DispatchQueue.main.async {
                                        self.allListings = listings
                                        self.fetchUserFavorites()
                                    }
            }
        }
    }
    
    private func parseListings(
        documents: [QueryDocumentSnapshot],
        completion: @escaping ([Listing]) -> Void
    ) {
        var fetchedListings: [Listing] = []
        
        for doc in documents {
            let data = doc.data()
            
            var listing = Listing(
                listingName: data["listingName"] as? String ?? "",
                landLordId: data["landLordId"] as? String ?? "",
                price: data["price"] as? Double ?? 0,
                bedrooms: data["bedrooms"] as? Int ?? 0,
                bathrooms: data["bathrooms"] as? Int ?? 0
            )
            
            listing.listingID = UUID(uuidString: doc.documentID) ?? UUID()
            listing.tenantId = data["tenantId"] as? String ?? ""
            
            listing.address = data["address"] as? String ?? ""
            listing.squareFeet = data["squareFeet"] as? Int ?? 0
            listing.isRented = Self.firestoreBool(data["isRented"])
            listing.amenities = data["amenities"] as? [String] ?? []
            listing.rules = data["rules"] as? String ?? ""
            listing.existingImageURLs = data["images"] as? [String] ?? []
            listing.createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
            listing.updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
            
            if let location = data["location"] as? GeoPoint {
                listing.latitude = location.latitude
                listing.longitude = location.longitude
            }
            
            if let statusRaw = data["status"] as? String,
               let st = ListingStatus(rawValue: statusRaw.lowercased()) {
                listing.status = st
            }
            
            fetchedListings.append(listing)
        }
        
        completion(fetchedListings)
    }
    
    
    
    func saveListing(
           listingId: UUID,
           listingName: String,
           landLordId: String,
           tenantId: String,
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
           isRented: Bool,
           completion: ((Result<Void, Error>) -> Void)? = nil
       ) {
           
           var data: [String: Any] = [
               "id": listingId.uuidString,
               "listingName": listingName,
               "landLordId": landLordId,
               "tenantId": tenantId,
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
               "updatedAt": FieldValue.serverTimestamp()
           ]
           
           let ref = db.collection("listings").document(listingId.uuidString)
           
           ref.getDocument { snapshot, _ in
               if snapshot?.exists != true {
                   data["createdAt"] = FieldValue.serverTimestamp()
               }
               
               ref.setData(data, merge: true) { error in
                   if let error = error {
                       completion?(.failure(error))
                   } else {
                       completion?(.success(()))
                   }
               }
           }
       }

    func updateListing(listingId: String, listingName: String, tenantId: String, price: Double, bedrooms: Int, bathrooms: Int, amenities: [String], rules: String, address: String, isRented: Bool, imageURLs: [String], squareFeet: Int, latitude: Double, longitude: Double) {
        let updatedData: [String: Any] = [
            "listingName": listingName,
            "tenantId": tenantId,
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

        db.collection("listings").document(listingId).updateData(updatedData)
    }
    
    // MARK: - Media & Documents
    
    func uploadListingImages(listingId: UUID, images: [UIImage], completion: @escaping ([String]) -> Void) {
        var urls: [String] = []
        var uploadedCount = 0
        let total = images.count

        if total == 0 {
            completion([])
            return
        }

        for (index, image) in images.enumerated() {
            guard let data = image.jpegData(compressionQuality: 0.8) else {
                uploadedCount += 1
                continue
            }

            let ref = storage.reference().child("listings/\(listingId.uuidString)/image_\(index).jpg")
            ref.putData(data, metadata: nil) { _, error in
                if error != nil {
                    uploadedCount += 1
                    if uploadedCount == total { completion(urls) }
                    return
                }

                ref.downloadURL { url, _ in
                    if let url = url {
                        urls.append(url.absoluteString)
                    }
                    uploadedCount += 1
                    if uploadedCount == total {
                        completion(urls)
                    }
                }
            }
        }
    }
    
    func uploadDocument(fileURL: URL, type: DocumentType) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let storageRef = storage.reference().child("users/\(uid)/documents/\(type.rawValue).pdf")

        storageRef.putFile(from: fileURL, metadata: nil) { _, error in
            if let error = error {
                print("Upload error:", error)
                return
            }

            storageRef.downloadURL { url, error in
                if let error = error {
                    print("Download URL error:", error)
                    return
                }

                guard let downloadURL = url else { return }

                self.db.collection("users")
                    .document(uid)
                    .collection("documents")
                    .document(type.rawValue)
                    .setData([
                        "type": type.rawValue,
                        "url": downloadURL.absoluteString,
                        "status": DocumentStatus.pending.rawValue,
                        "createdAt": FieldValue.serverTimestamp(),
                        "updatedAt": FieldValue.serverTimestamp()
                    ])
            }
        }
    }
    
    func deleteDocument(type: DocumentType) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let storageRef = storage.reference().child("users/\(uid)/documents/\(type.rawValue).pdf")

        storageRef.delete { error in
            if let error = error {
                print("Storage delete error:", error)
                return
            }
            
            self.db.collection("users")
                .document(uid)
                .collection("documents")
                .document(type.rawValue)
                .delete { error in
                    if let error = error {
                        print("Firestore delete error:", error)
                    }
                }
        }
    }
    
    // MARK: - Favorites
    
    func saveFavorite(listingId: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let ref = db.collection("users").document(uid).collection("favorites").document(listingId)
        
        ref.getDocument { snapshot, _ in
            if snapshot?.exists == true {
                ref.delete()
            } else {
                ref.setData(["listingId": listingId, "createdAt": FieldValue.serverTimestamp()])
            }
            self.fetchUserFavorites()
        }
    }
    
    func fetchUserFavorites() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(uid).collection("favorites").getDocuments { snapshot, _ in
            let ids = snapshot?.documents.map { $0.documentID } ?? []
            DispatchQueue.main.async {
                self.favoriteIds = Set(ids)
                self.savedListings = self.allListings.filter { ids.contains($0.id.uuidString) }
            }
        }
    }
    
    // MARK: - Preferences
    
    func fetchUserPreferences() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(uid).collection("preferences").document("tenant").getDocument { snapshot, _ in
            guard let data = snapshot?.data() else { return }
            
            let prefs = Preferences(
                locationQuery: data["locationQuery"] as? String ?? "",
                budgetMin: data["budgetMin"] as? Double ?? 0,
                budgetMax: data["budgetMax"] as? Double ?? 5000,
                selectedBedroom: data["selectedBedroom"] as? String ?? "Studio",
                petsAllowed: data["petsAllowed"] as? Bool ?? false,
                fullyFurnished: data["fullyFurnished"] as? Bool ?? false,
                parkingIncluded: data["parkingIncluded"] as? Bool ?? false
            )
            
            DispatchQueue.main.async {
                self.userPreferences = prefs
            }
        }
    }
    
    func savePreferencesFS(preferences: Preferences) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let data: [String: Any] = [
            "locationQuery": preferences.locationQuery,
            "budgetMin": preferences.budgetMin,
            "budgetMax": preferences.budgetMax,
            "selectedBedroom": preferences.selectedBedroom,
            "petsAllowed": preferences.petsAllowed,
            "fullyFurnished": preferences.fullyFurnished,
            "parkingIncluded": preferences.parkingIncluded,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        db.collection("users").document(uid).collection("preferences").document("tenant").setData(data)
        self.updateUserHasCompletedPreferences()
        self.fetchUserPreferences()
    }
    
    func updatePreferencesFS(preferences: Preferences) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let data: [String: Any] = [
            "locationQuery": preferences.locationQuery,
            "budgetMin": preferences.budgetMin,
            "budgetMax": preferences.budgetMax,
            "selectedBedroom": preferences.selectedBedroom,
            "petsAllowed": preferences.petsAllowed,
            "fullyFurnished": preferences.fullyFurnished,
            "parkingIncluded": preferences.parkingIncluded,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        db.collection("users").document(uid).collection("preferences").document("tenant").updateData(data)
        self.fetchUserPreferences()
    }
    
    //MARK: SHAQUILLE
       func fetchAllTenants(completion: @escaping ([TenantItem]) -> Void) {
           db.collection("users")
               .whereField("role", isEqualTo: "tenant")
               .getDocuments { snapshot, error in
                   
                   guard error == nil else {
                       print("Fetch tenants error:", error!.localizedDescription)
                       completion([])
                       return
                   }
                   
                   guard let documents = snapshot?.documents else {
                       completion([])
                       return
                   }
                   
                   let tenants = documents.compactMap { doc -> TenantItem? in
                       let data = doc.data()
                       
                       let email = (data["email"] as? String ?? "")
                           .trimmingCharacters(in: .whitespacesAndNewlines)
                           .lowercased()
                       
                       guard !email.isEmpty else { return nil }
                       
                       return TenantItem(
                           id: doc.documentID,
                           email: email
                       )
                   }
                   .sorted { $0.email < $1.email }
                   
                   completion(tenants)
               }
       }
    
    func assignTenantToListing(
        listingId: String,
        tenantId: String,
        completion: ((Error?) -> Void)? = nil
    )
    {

        let listingRef = db.collection("listings").document(listingId)
        let userRef = db.collection("users").document(tenantId)

        let batch = db.batch()

 
        batch.updateData([
            "tenantId": tenantId,
            "isRented": true,
            "updatedAt": FieldValue.serverTimestamp()
        ], forDocument: listingRef)

       
        batch.updateData([
            "isRenting": true,
            "apartmentId": listingId
        ], forDocument: userRef)

        batch.commit { error in
            completion?(error)
        }
    }
    
    func removeTenantFromListing(listingId: String, previousTenantId: String) {
        
        let batch = db.batch()
        
        let listingRef = db.collection("listings").document(listingId)
        let userRef = db.collection("users").document(previousTenantId)
        
      
        batch.updateData([
            "tenantId": "",
            "isRented": false
        ], forDocument: listingRef)
        
      
        batch.updateData([
            "isRenting": false,
            "apartmentId": ""
        ], forDocument: userRef)
        
        batch.commit { error in
            if let error = error {
                print("Remove tenant error:", error.localizedDescription)
            } else {
                print("Tenant removed successfully")
            }
        }
    }
}
    
    
    
