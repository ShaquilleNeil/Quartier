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
    @Published var userDocuments: [UserDocument] = []
    
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
    
    func uploadProfileImage(uid: String, data: Data, completion: @escaping (String?) -> Void) {

        let ref = storage.reference().child("users/\(uid)/profile.jpg")

        ref.putData(data, metadata: nil) { _, error in
            if let error = error {
                print("Upload error:", error)
                completion(nil)
                return
            }

            ref.downloadURL { url, error in
                if let error = error {
                    print("Download URL error:", error)
                    completion(nil)
                    return
                }
                completion(url?.absoluteString)
            }
        }
    }
    
    func saveUser(uid: String, name: String, profilePic: String, email: String, role: String, isRenting: Bool = false, apartmentId: String? = nil, completion: @escaping (Bool) -> Void) {

        let userData: [String: Any] = [
            "id": uid,
            "name": name,
            "profilePic": profilePic,
            "email": email,
            "role": role.lowercased(),
            "isRenting": isRenting,
            "apartmentId": apartmentId ?? "",
            "hasCompletedPreferences": false,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
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
                name: data["name"] as? String ?? "",
                profilePic: data["profilePic"] as? String ?? "",
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
    
    
    func updateUserProfile(
        uid: String,
        name: String,
        profilePic: String?,
        completion: @escaping (Bool) -> Void
    ) {
        var data: [String: Any] = [
            "name": name,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        if let profilePic = profilePic {
            data["profilePic"] = profilePic
        }
        
        db.collection("users").document(uid).updateData(data) { error in
            completion(error == nil)
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
    
    func fetchListingsLandlordPublic(forLandlord uid: String) {
        db.collection("listings")
            .whereField("landLordId", isEqualTo: uid)
            .whereField("status", isEqualTo: "published")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("fetchListingsLandlordPublic error:", error)
                    return
                }
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
    
    func downloadListingImages(forListingId id: String) async -> [URL] {
        let snapshot = try? await db.collection("listings")
            .document(id)
            .getDocument()
        
        let strings = snapshot?.data()?["images"] as? [String] ?? []
        return strings.compactMap { URL(string: $0) }
    }
    
    func totalRentCollected() async -> Double {
        let snapshot = try? await db.collection("listings")
            .whereField("landLordId", isEqualTo: Auth.auth().currentUser?.uid ?? "")
            .whereField("isRented", isEqualTo: true)
            .getDocuments()
        
        let total = snapshot?.documents.reduce(0.0) { sum, doc in
            sum + (doc.data()["price"] as? Double ?? 0)
        } ?? 0
        
        return total
    }
    
    func totalPossibleEarnings() async -> Double {
        let snapshot = try? await db.collection("listings")
            .whereField("landLordId", isEqualTo: Auth.auth().currentUser?.uid ?? "")
            .getDocuments()
        
        let total = snapshot?.documents.reduce(0.0) { sum, doc in
            sum + (doc.data()["price"] as? Double ?? 0)
        } ?? 0
        
        return total
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
                bathrooms: data["bathrooms"] as? Int ?? 0,
                address: data["address"] as? String ?? ""
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
            listing.rentDueDay = data["rentDueDay"] as? Int ?? 1
            
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
           rentDueDay: Int,
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
               "rentDueDay": rentDueDay,
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
                       self.fetchListingsLandlord()
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
    
    func listenToListing(listingId: String, completion: @escaping (Listing?) -> Void) -> ListenerRegistration {

        return db.collection("listings")
            .document(listingId)
            .addSnapshotListener { snapshot, error in

                guard let doc = snapshot, let data = doc.data() else {
                    completion(nil)
                    return
                }

                var listing = Listing(
                    listingName: data["listingName"] as? String ?? "",
                    landLordId: data["landLordId"] as? String ?? "",
                    price: data["price"] as? Double ?? 0,
                    bedrooms: data["bedrooms"] as? Int ?? 0,
                    bathrooms: data["bathrooms"] as? Int ?? 0,
                    address: data["address"] as? String ?? ""
                )

                listing.listingID = UUID(uuidString: doc.documentID) ?? UUID()
                listing.address = data["address"] as? String ?? ""
                listing.existingImageURLs = data["images"] as? [String] ?? []
                listing.rentDueDay = data["rentDueDay"] as? Int ?? 1

                DispatchQueue.main.async {
                    completion(listing)
                }
            }
    }
    
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
    
    func deleteListing(listing: Listing) {
        
        let uid = listing.listingID
        
        db.collection("listings")
            .document(uid.uuidString)
            .delete { error in
                if let error = error {
                    print("Firestore delete error: \(error.localizedDescription)")
                } else {
                    print("Listing \(uid) successfully deleted.")
                    self.fetchListingsLandlord()
                }
            }
    }
    
    
    //MARK: Document CRUD shaquille
    
    
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
    
    func uploadLeaseDocument(fileURL: URL, type: DocumentType, listingId: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
 
        
        let storageRef = storage.reference()
            .child("users/\(uid)/documents/\(listingId)/\(type.rawValue).pdf")

        storageRef.putFile(from: fileURL, metadata: nil) { _, error in
            if let error = error { print("Upload error:", error); return }

            storageRef.downloadURL { url, error in
                if let error = error { print("Download URL error:", error); return }
                guard let downloadURL = url else { return }

                
                self.db.collection("documents")
                    .document("\(listingId)_\(type.rawValue)")
                    .setData([
                        "type": type.rawValue,
                        "url": downloadURL.absoluteString,
                        "listingId": listingId,
                        "landlordId": uid,
                        "status": DocumentStatus.pending.rawValue,
                        "createdAt": FieldValue.serverTimestamp(),
                        "updatedAt": FieldValue.serverTimestamp()
                    ])
            }
        }
    }
    
    
    func fetchLeaseFileName(listingId: String) async -> String? {
        let snapshot = try? await db.collection("documents")
            .document("\(listingId)_lease")
            .getDocument()
        
        guard snapshot?.exists == true else { return nil }
        return snapshot?.data()?["fileName"] as? String ?? "lease.pdf"
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
    
  var documentsListener: ListenerRegistration?

    func startListeningToDocuments() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        documentsListener?.remove()
        documentsListener = db.collection("users")
            .document(uid)
            .collection("documents")
            .addSnapshotListener { snapshot, error in

                guard let documents = snapshot?.documents else {
                    print("Listener error:", error?.localizedDescription ?? "")
                    return
                }

                let fetched = documents.compactMap { doc -> UserDocument? in
                    let data = doc.data()

                    guard let type = data["type"] as? String,
                          let url = data["url"] as? String,
                          let status = data["status"] as? String else {
                        return nil
                    }

                    return UserDocument(
                        type: type,
                        url: url,
                        status: status
                    )
                }

                DispatchQueue.main.async {
                    self.userDocuments = fetched
                }
            }
    }
    
    func loadLeaseDocument(listingId: String) async throws -> URL? {
        let snapshot = try await db.collection("documents")
            .document("\(listingId)_\(DocumentType.lease.rawValue)")
            .getDocument()
        
        guard let urlString = snapshot.data()?["url"] as? String,
              let url = URL(string: urlString) else { return nil }
        
        return url
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
    
    func fetchLandlordProfile(uid: String) async -> (name: String?, photoURL: String?) {
        let snapshot = try? await db.collection("users").document(uid).getDocument()
        let data = snapshot?.data()
        let name = data?["name"] as? String ?? data?["email"] as? String
        let photo = data?["profilePic"] as? String
        return (name, photo)
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
    
    
    
    
    
    
    
    
    // MARK: - Maintenance

    func submitMaintenanceRequest(
        request: MaintenanceRequest,
        photos: [UIImage],
        completion: @escaping (Error?) -> Void
    ) {
        guard let listingId = currentUser?.apartmentId, !listingId.isEmpty else {
            completion(NSError(domain: "Maintenance", code: 0, userInfo: [NSLocalizedDescriptionKey: "No listing found"]))
            return
        }

        uploadListingImages(listingId: UUID(uuidString: listingId) ?? UUID(), images: photos) { photoURLs in
            let data: [String: Any] = [
                "id": request.id.uuidString,
                "listingId": listingId,
                "tenantId": request.tenantId,
                "description": request.description,
                "date": Timestamp(date: request.date),
                "status": request.status.rawValue,
                "photoURLs": photoURLs,
                "createdAt": FieldValue.serverTimestamp()
            ]

            self.db.collection("listings")
                .document(listingId)
                .collection("maintenanceRequests")
                .document(request.id.uuidString)
                .setData(data) { error in
                    completion(error)
                }
        }
    }
    

    func fetchLatestMaintenanceRequest(completion: @escaping (MaintenanceRequest?, String?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(nil, nil)
            return
        }

        db.collection("listings")
            .whereField("landLordId", isEqualTo: uid)
            .getDocuments { snapshot, _ in
                guard let listingIds = snapshot?.documents.map({ $0.documentID }),
                      !listingIds.isEmpty else {
                    completion(nil, nil)
                    return
                }

                var allRequests: [(MaintenanceRequest, String)] = []
                var fetched = 0

                for listingId in listingIds {
                    self.db.collection("listings")
                        .document(listingId)
                        .collection("maintenanceRequests")
                        .order(by: "createdAt", descending: true)
                        .limit(to: 1)
                        .getDocuments { snapshot, _ in

                            if let doc = snapshot?.documents.first {
                                let data = doc.data()

                                if let tenantId = data["tenantId"] as? String,
                                   let description = data["description"] as? String,
                                   let date = (data["date"] as? Timestamp)?.dateValue() {

                                    let request = MaintenanceRequest(
                                        id: UUID(uuidString: doc.documentID) ?? UUID(),
                                        listingId: listingId,
                                        tenantId: tenantId,
                                        description: description,
                                        date: date,
                                        status: MaintenanceStatus(rawValue: data["status"] as? String ?? "pending") ?? .pending,
                                        photoURLs: data["photoURLs"] as? [String] ?? []
                                    )
                                    allRequests.append((request, listingId))
                                }
                            }

                            fetched += 1

                            // once all listings have been checked, return the latest
                            if fetched == listingIds.count {
                                let latest = allRequests.max(by: { $0.0.date < $1.0.date })
                                DispatchQueue.main.async {
                                    completion(latest?.0, latest?.1)
                                }
                            }
                        }
                }
            }
    }

    func resolveMaintenanceRequest(
        listingId: String,
        requestId: String,
        completion: @escaping (Error?) -> Void
    ) {
        db.collection("listings")
            .document(listingId)
            .collection("maintenanceRequests")
            .document(requestId)
            .updateData(["status": MaintenanceStatus.resolved.rawValue]) { error in
                completion(error)
            }
    }
    
    
    
    func fetchMaintenanceRequests(
        listingId: String,
        completion: @escaping ([MaintenanceRequest]) -> Void
    ) {
        db.collection("listings")
            .document(listingId)
            .collection("maintenanceRequests")
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, _ in
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }

                let requests = documents.compactMap { doc -> MaintenanceRequest? in
                    let data = doc.data()

                    guard let tenantId = data["tenantId"] as? String,
                          let description = data["description"] as? String,
                          let date = (data["date"] as? Timestamp)?.dateValue()
                    else { return nil }

                    return MaintenanceRequest(
                        id: UUID(uuidString: doc.documentID) ?? UUID(),
                        listingId: listingId,
                        tenantId: tenantId,
                        description: description,
                        date: date,
                        status: MaintenanceStatus(rawValue: data["status"] as? String ?? "pending") ?? .pending,
                        photoURLs: data["photoURLs"] as? [String] ?? []
                    )
                }

                DispatchQueue.main.async {
                    completion(requests)
                }
            }
    }
    
    
}
    
    
    

