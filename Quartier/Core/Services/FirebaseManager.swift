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

/// One row in the landlord “pick a tenant” list (`users` collection, `role == "tenant"`).
struct FirebaseTenantPickerItem: Identifiable, Hashable {
    let id: String
    let email: String
    let displayName: String

    var pickerLabel: String {
        if displayName.isEmpty { return email }
        return "\(displayName) — \(email)"
    }
}

class FirebaseManager: ObservableObject {
    /// Firestore may return Bool or NSNumber for boolean fields.
    static func firestoreBool(_ value: Any?) -> Bool {
        if let b = value as? Bool { return b }
        if let n = value as? NSNumber { return n.boolValue }
        return false
    }

    private let db = Firestore.firestore()
    @Published var currentUser: User? = nil
    @Published var firebaseListings: [RemoteListing] = []
    private let storage = Storage.storage()
    @Published var allListings: [Listing] = []
    @Published var favoriteIds: Set<String> = []
    
    // save to db

    func saveUser(
        uid: String,
        email: String,
        role: String,
        isRenting: Bool = false,
        apartmentId: String? = nil,
        completion: @escaping (Bool) -> Void
    ) {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let nameHint = email.split(separator: "@").first.map(String.init) ?? ""

        let userData: [String: Any] = [
            "id": uid,
            "email": email,
            "emailLowercase": normalizedEmail,
            "displayName": nameHint,
            "role": role,
            "isRenting": isRenting,
            "apartmentId": apartmentId ?? "",
            "hasCompletedPreferences": false
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
        // Use Auth uid — `currentUser` from Firestore may still be nil right after sign-in.
        guard let landLordId = Auth.auth().currentUser?.uid else { return }
        let collection = db.collection("listings")
        let group = DispatchGroup()
        var mergedById: [String: RemoteListing] = [:]

        func merge(_ docs: [QueryDocumentSnapshot]) {
            for doc in docs {
                if let item = Self.parseRemoteListing(document: doc) {
                    mergedById[item.id] = item
                }
            }
        }

        group.enter()
        collection.whereField("landLordId", isEqualTo: landLordId).getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching landlord listings (landLordId):", error)
            } else {
                merge(snapshot?.documents ?? [])
            }
            group.leave()
        }

        // Backward compatibility: some docs may use landlordId (lowercase L in middle).
        group.enter()
        collection.whereField("landlordId", isEqualTo: landLordId).getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching landlord listings (landlordId):", error)
            } else {
                merge(snapshot?.documents ?? [])
            }
            group.leave()
        }

        group.notify(queue: .main) {
            let merged = Array(mergedById.values)
                .sorted { $0.updatedAt > $1.updatedAt }
            if !merged.isEmpty {
                self.firebaseListings = merged
                return
            }

            // Fallback: in some projects/rules setups, equality queries may return empty unexpectedly.
            // Fetch all visible listings and filter by owner on client side.
            collection.getDocuments { snapshot, error in
                if let error = error {
                    print("Fallback fetch listings failed:", error)
                    self.firebaseListings = []
                    return
                }
                let filtered = (snapshot?.documents ?? [])
                    .compactMap { Self.parseRemoteListing(document: $0) }
                    .filter { item in
                        item.landlordId == landLordId
                    }
                    .sorted { $0.updatedAt > $1.updatedAt }
                self.firebaseListings = filtered
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

                    listing.listingID = UUID(uuidString: doc.documentID) ?? listing.listingID
                    
                    listing.buildingID = data["buildingId"] as? String ?? ""
                    listing.landLordId = data["landLordId"] as? String ?? ""
                    listing.price = data["price"] as? Double ?? 0
                    listing.bedrooms = data["bedrooms"] as? Int ?? 0
                    listing.bathrooms = data["bathrooms"] as? Int ?? 0
                    listing.address = data["address"] as? String ?? ""
                    listing.squareFeet = data["squareFeet"] as? Int ?? 0
                    listing.isRented = Self.firestoreBool(data["isRented"])
                    if let statusRaw = data["status"] as? String,
                       let st = ListingStatus(rawValue: statusRaw.lowercased()) {
                        listing.status = st
                    }
                    
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
        isRented: Bool,
        completion: ((Result<Void, Error>) -> Void)? = nil
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
        
        db.collection("listings").document(listingId.uuidString).setData(listingData, merge: true) { error in
            if let error = error {
                print("Error adding document: \(error)")
                completion?(.failure(error))
            } else {
                print("Document added with ID: \(listingId)")
                completion?(.success(()))
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

    // MARK: - Tenant assignment

    /// Loads a single published listing from Firestore (e.g. tenant rented home).
    func fetchListingById(listingId: String, completion: @escaping (RemoteListing?) -> Void) {
        db.collection("listings").document(listingId).getDocument { snapshot, error in
            if let error = error {
                print("fetchListingById:", error.localizedDescription)
                completion(nil)
                return
            }
            guard let snapshot, snapshot.exists,
                  let listing = Self.parseRemoteListing(document: snapshot) else {
                completion(nil)
                return
            }
            DispatchQueue.main.async {
                completion(listing)
            }
        }
    }

    /// Firestore listing presence plus bound tenant uid / email (for landlord UI). Reading `users/{tenant}` may fail under strict rules.
    func fetchListingTenantBinding(
        listingId: String,
        completion: @escaping (_ listingExists: Bool, _ tenantUserId: String?, _ tenantEmail: String?) -> Void
    ) {
        db.collection("listings").document(listingId).getDocument { snapshot, _ in
            guard snapshot?.exists == true, let data = snapshot?.data() else {
                completion(false, nil, nil)
                return
            }
            let tid = (data["currentTenantUserId"] as? String)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if tid.isEmpty {
                DispatchQueue.main.async {
                    completion(true, nil, nil)
                }
                return
            }
            self.db.collection("users").document(tid).getDocument { snap2, _ in
                let email = snap2?.data()?["email"] as? String
                DispatchQueue.main.async {
                    completion(true, tid, email)
                }
            }
        }
    }

    /// Tenant profiles for the landlord UI. Query: `users` where `role == "tenant"`.
    /// **Firestore:** create a composite index if the console asks; **rules** must allow the signed-in landlord to read these documents (see inline comment on `assignTenantToListing`).
    func fetchTenantsForLandlordPicker(limit: Int = 150, completion: @escaping (Result<[FirebaseTenantPickerItem], Error>) -> Void) {
        db.collection("users")
            .whereField("role", isEqualTo: "tenant")
            .limit(to: limit)
            .getDocuments { snapshot, error in
                if let error = error {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                    return
                }
                let items: [FirebaseTenantPickerItem] = (snapshot?.documents ?? []).compactMap { doc in
                    let data = doc.data()
                    let email = (data["email"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !email.isEmpty else { return nil }
                    let name = (data["displayName"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                    return FirebaseTenantPickerItem(id: doc.documentID, email: email, displayName: name)
                }
                .sorted { $0.pickerLabel.localizedCaseInsensitiveCompare($1.pickerLabel) == .orderedAscending }

                DispatchQueue.main.async {
                    completion(.success(items))
                }
            }
    }

    /// Bind a tenant by Firebase Auth uid (preferred for picker UI).
    func assignTenantToListing(listingId: String, tenantUserId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let tid = tenantUserId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !tid.isEmpty else {
            completion(.failure(Self.assignError("Select a tenant.")))
            return
        }
        guard let landlordUid = Auth.auth().currentUser?.uid else {
            completion(.failure(Self.assignError("You must be signed in as a landlord.")))
            return
        }

        let listingRef = db.collection("listings").document(listingId)
        listingRef.getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let snapshot, snapshot.exists,
                  let data = snapshot.data(),
                  let owner = data["landLordId"] as? String,
                  owner == landlordUid else {
                completion(.failure(Self.assignError("You don't own this listing or it isn't on Firebase yet.")))
                return
            }

            let address = data["address"] as? String ?? ""
            let existingTenant = data["currentTenantUserId"] as? String

            self.db.collection("users").document(tid).getDocument { tSnap, _ in
                guard let tSnap, tSnap.exists, let tData = tSnap.data() else {
                    completion(.failure(Self.assignError("Could not load this tenant account.")))
                    return
                }
                self.commitAssignTenantBatch(
                    listingRef: listingRef,
                    address: address,
                    existingTenantUserId: existingTenant,
                    tenantUid: tid,
                    tenantUserData: tData,
                    completion: completion
                )
            }
        }
    }

    /// Assign by email (legacy); resolves uid then uses the same batch as `assignTenantToListing(listingId:tenantUserId:)`.
    func assignTenantToListing(listingId: String, tenantEmail rawEmail: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let emailLower = rawEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let rawTrimmed = rawEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !emailLower.isEmpty else {
            completion(.failure(Self.assignError("Enter the tenant's email.")))
            return
        }
        guard let landlordUid = Auth.auth().currentUser?.uid else {
            completion(.failure(Self.assignError("You must be signed in as a landlord.")))
            return
        }

        let listingRef = db.collection("listings").document(listingId)
        listingRef.getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let snapshot, snapshot.exists,
                  let data = snapshot.data(),
                  let owner = data["landLordId"] as? String,
                  owner == landlordUid else {
                completion(.failure(Self.assignError("You don't own this listing or it isn't on Firebase yet.")))
                return
            }

            let address = data["address"] as? String ?? ""
            let existingTenant = data["currentTenantUserId"] as? String

            self.findTenantUser(emailLower: emailLower, rawTrimmed: rawTrimmed) { tenantUid, tenantData, findError in
                if let findError = findError {
                    completion(.failure(findError))
                    return
                }
                guard let tenantUid, let tenantData else {
                    completion(.failure(Self.assignError("No tenant account found for this email.")))
                    return
                }
                self.commitAssignTenantBatch(
                    listingRef: listingRef,
                    address: address,
                    existingTenantUserId: existingTenant,
                    tenantUid: tenantUid,
                    tenantUserData: tenantData,
                    completion: completion
                )
            }
        }
    }

    private func commitAssignTenantBatch(
        listingRef: DocumentReference,
        address: String,
        existingTenantUserId: String?,
        tenantUid: String,
        tenantUserData: [String: Any],
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let landlordUid = Auth.auth().currentUser?.uid else {
            completion(.failure(Self.assignError("You must be signed in as a landlord.")))
            return
        }
        if tenantUid == landlordUid {
            completion(.failure(Self.assignError("You can't assign yourself as the tenant.")))
            return
        }
        let role = (tenantUserData["role"] as? String ?? "").lowercased()
        guard role == "tenant" else {
            completion(.failure(Self.assignError("This account is not registered as a tenant.")))
            return
        }
        if let existing = existingTenantUserId, !existing.isEmpty, existing != tenantUid {
            completion(.failure(Self.assignError("This unit already has a tenant. Remove them before assigning someone else.")))
            return
        }

        let listingId = listingRef.documentID
        let prefs = tenantUserData["hasCompletedPreferences"] as? Bool ?? false
        let tenantRef = db.collection("users").document(tenantUid)
        let batch = db.batch()

        batch.updateData([
            "isRenting": true,
            "rentedListingId": listingId,
            "rentedAddress": address,
            "hasCompletedPreferences": prefs
        ], forDocument: tenantRef)

        batch.updateData([
            "isRented": true,
            "currentTenantUserId": tenantUid,
            "updatedAt": FieldValue.serverTimestamp()
        ], forDocument: listingRef)

        batch.commit { err in
            if let err = err {
                completion(.failure(err))
            } else {
                completion(.success(()))
            }
        }
    }

    /// Ends tenancy on this listing and clears rental flags on the tenant user (if linked).
    func removeTenantFromListing(listingId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let landlordUid = Auth.auth().currentUser?.uid else {
            completion(.failure(Self.assignError("You must be signed in.")))
            return
        }
        let listingRef = db.collection("listings").document(listingId)
        listingRef.getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let snapshot, snapshot.exists,
                  let data = snapshot.data(),
                  let owner = data["landLordId"] as? String,
                  owner == landlordUid else {
                completion(.failure(Self.assignError("You don't own this listing.")))
                return
            }

            let tenantUid = data["currentTenantUserId"] as? String ?? ""
            let batch = self.db.batch()

            batch.updateData([
                "isRented": false,
                "currentTenantUserId": FieldValue.delete(),
                "updatedAt": FieldValue.serverTimestamp()
            ], forDocument: listingRef)

            if !tenantUid.isEmpty {
                let tenantRef = self.db.collection("users").document(tenantUid)
                batch.updateData([
                    "isRenting": false,
                    "rentedListingId": FieldValue.delete(),
                    "rentedAddress": FieldValue.delete()
                ], forDocument: tenantRef)
            }

            batch.commit { err in
                if let err = err {
                    completion(.failure(err))
                } else {
                    completion(.success(()))
                }
            }
        }
    }

    private func findTenantUser(
        emailLower: String,
        rawTrimmed: String,
        completion: @escaping (String?, [String: Any]?, Error?) -> Void
    ) {
        db.collection("users")
            .whereField("emailLowercase", isEqualTo: emailLower)
            .limit(to: 1)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(nil, nil, error)
                    return
                }
                if let doc = snapshot?.documents.first {
                    completion(doc.documentID, doc.data(), nil)
                    return
                }

                self.db.collection("users")
                    .whereField("email", isEqualTo: emailLower)
                    .limit(to: 1)
                    .getDocuments { snap2, err2 in
                        if let err2 = err2 {
                            completion(nil, nil, err2)
                            return
                        }
                        if let doc = snap2?.documents.first {
                            completion(doc.documentID, doc.data(), nil)
                            return
                        }

                        self.db.collection("users")
                            .whereField("email", isEqualTo: rawTrimmed)
                            .limit(to: 1)
                            .getDocuments { snap3, err3 in
                                if let err3 = err3 {
                                    completion(nil, nil, err3)
                                    return
                                }
                                if let doc = snap3?.documents.first {
                                    completion(doc.documentID, doc.data(), nil)
                                } else {
                                    completion(nil, nil, nil)
                                }
                            }
                    }
            }
    }

    private static func assignError(_ message: String) -> NSError {
        NSError(domain: "Quartier", code: 4001, userInfo: [NSLocalizedDescriptionKey: message])
    }

    private static func parseRemoteListing(document: DocumentSnapshot) -> RemoteListing? {
        guard document.exists, let data = document.data() else { return nil }
        let location = data["location"] as? GeoPoint
        let latitude = location?.latitude ?? 0
        let longitude = location?.longitude ?? 0
        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
        return RemoteListing(
            id: document.documentID,
            buildingId: data["buildingId"] as? String ?? "",
            landlordId: (data["landLordId"] as? String) ?? (data["landlordId"] as? String) ?? "",
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
            isRented: Self.firestoreBool(data["isRented"]),
            currentTenantUserId: data["currentTenantUserId"] as? String,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

