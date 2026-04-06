//
//  FirebaseSync.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-03-05.
//
import Foundation
import FirebaseFirestore
import CoreData
import FirebaseAuth

final class FirebaseSync {
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var preferencesListener: ListenerRegistration?
    private let collectionPath: String
    private var lastSync: Date = Date(timeIntervalSince1970: 0)
    
    
    
    init(collectionPath: String = "listings") {
        self.collectionPath = collectionPath
        self.lastSync = UserDefaults.standard.object(forKey: "firestoreLastSync_\(collectionPath)") as? Date ?? Date(timeIntervalSince1970: 0)
    }
    

    deinit {
        listener?.remove()
    }
    
    
    
    func stopListening() {
        listener?.remove()
        listener = nil
    }
    
    
    //start listening
    func startListening(
        context: NSManagedObjectContext,
        onApplyingRemote: @escaping (Bool) -> Void,
        onRemoteApplied: @escaping () -> Void
    ) {

        stopListening()

        let query = db.collection(collectionPath)
            .whereField("updatedAt", isGreaterThan: lastSync)

        listener = query.addSnapshotListener { [weak self] snapshot, error in
            guard let self else { return }

            if let error {
                print("Firestore listener error:", error)
                return
            }

            guard let snapshot else { return }

            DispatchQueue.main.async {
                onApplyingRemote(true)
            }

            context.perform {

                for change in snapshot.documentChanges {

                    let doc = change.document
                    let docID = doc.documentID

                    switch change.type {

                    case .added, .modified:
                        self.upsert(
                            docID: docID,
                            data: doc.data(),
                            into: context
                        )

                    case .removed:
                        self.delete(
                            docID: docID,
                            from: context
                        )
                    }
                }

                do {
                    try context.save()
                } catch {
                    print("CoreData save failed:", error)
                }

                // update checkpoint
                if let updated = (snapshot.documents.last?.data()["updatedAt"] as? Timestamp)?.dateValue() {
                        self.lastSync = updated
                        UserDefaults.standard.set(updated, forKey: "firestoreLastSync_\(self.collectionPath)")
                    }


                DispatchQueue.main.async {
                    onApplyingRemote(false)
                    onRemoteApplied()
                }
            }
        }
    }
    
    
    
    func stopListeningPreferences() {
        preferencesListener?.remove()
        preferencesListener = nil
    }
    
    //pushUppsert
    func pushUpsert(listing: LDListing){
        guard listing.status != "draft" else {
            print("Skipping Firebase upsert for draft")
            return }
        guard let id = listing.id?.uuidString else { return }
        let ref = db.collection(collectionPath).document(id)
        ref.setData(serialise(listing: listing), merge: true)
    }
    
    
    
    //push delete
    func pushDelete(listing: LDListing) {
        guard listing.status != "draft" else {
            print("Skipping Firebase delete for draft")
            return
        }
        guard let id = listing.id else { return }
        
        db.collection(collectionPath).document(id.uuidString).delete()
    }
    
    
    
    //upsert(remote -> coredata)
    private func upsert(
        docID: String,
        data: [String: Any],
        into context: NSManagedObjectContext
    )
    {
        if let status = data["status"] as? String,
              status == "draft" {
               print("Skipping remote draft from Firebase")
               return
           }
        
        guard let uuid = UUID(uuidString: docID) else { return }

        let request: NSFetchRequest<LDListing> = LDListing.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)

        let remoteUpdatedAt = (data["updatedAt"] as? Timestamp)?.dateValue()

        let item: LDListing

        if let existing = try? context.fetch(request).first {
            item = existing
        } else {
            item = LDListing(context: context)
            item.id = uuid
        }

     
        if let remoteUpdatedAt,
           let localUpdatedAt = item.updatedAt,
           localUpdatedAt > remoteUpdatedAt {
            return
        }

        item.listingName = data["listingName"] as? String
        item.landLordID = data["landLordId"] as? String
        item.tenantID = data["tenantId"] as? String
        item.price = data["price"] as? Double ?? 0.0
        item.bedrooms = data["bedrooms"] as? Int16 ?? 0
        item.bathrooms = data["bathrooms"] as? Int16 ?? 0
        item.amenities = (data["amenities"] as? [String] ?? []) as NSObject
        item.status = data["status"] as? String ?? ""
        item.rules = data["rules"] as? String ?? ""
        item.address = data["address"] as? String ?? ""
        item.isRented = FirebaseManager.firestoreBool(data["isRented"])

        if let updatedAt = remoteUpdatedAt {
            item.updatedAt = updatedAt
        }

        if let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() {
            item.createdAt = createdAt
        }
    }
    
    
    //delete
    private func delete(
        docID: String,
        from context: NSManagedObjectContext
    ) {
        guard let uuid = UUID(uuidString: docID) else { return }

        let request: NSFetchRequest<LDListing> = LDListing.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)

        if let item = try? context.fetch(request).first {

            if item.status == "draft" {
                print("Skipping delete: local draft")
                return
            }

            context.delete(item)
        }
    }
    
    
    //serialise (change obj)
    private func serialise(listing: LDListing) -> [String: Any] {
        var data: [String: Any] = [
            
            "listingName": listing.listingName ?? "",
            "landLordId": listing.landLordID ?? "",
            "tenantId": listing.tenantID ?? "",
            "price": listing.price,
            "bedrooms": listing.bedrooms,
            "bathrooms": listing.bathrooms,
            "amenities": listing.amenities as? [String] ?? [],
            "status": listing.status ?? "",
            "rules": listing.rules ?? "",
            "address": listing.address ?? "",
            "isRented": listing.isRented,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        if listing.createdAt == nil {
            data["createdAt"] = FieldValue.serverTimestamp()
        }
        return data
            
        
    }
    
    
    
    
    //MARK: Preferences
    
    
    func startListeningPreferences(context: NSManagedObjectContext) {

        guard let uid = Auth.auth().currentUser?.uid else { return }

        preferencesListener?.remove()

        preferencesListener = db.collection("users")
            .document(uid)
            .collection("preferences")
            .document("tenant")
            .addSnapshotListener { [weak self] snapshot, error in

                guard let self else { return }

                if let error {
                    print("Preferences listener error:", error)
                    return
                }

                guard let data = snapshot?.data() else { return }

                context.perform {

                    let preferences = Preferences(
                        locationQuery: data["locationQuery"] as? String ?? "",
                        budgetMin: data["budgetMin"] as? Double ?? 0,
                        budgetMax: data["budgetMax"] as? Double ?? 0,
                        selectedBedroom: data["selectedBedroom"] as? String ?? "Studio",
                        petsAllowed: data["petsAllowed"] as? Bool ?? false,
                        fullyFurnished: data["fullyFurnished"] as? Bool ?? false,
                        parkingIncluded: data["parkingIncluded"] as? Bool ?? false
                    )

                    self.upsertPreferencesLocal(
                        preferences: preferences,
                        context: context
                    )
                }
            }
    }
    
    
    private func serialisePreferences(preferences: Preferences) -> [String: Any] {
        return [
            "budgetMax": preferences.budgetMax,
            "budgetMin": preferences.budgetMin,
            "fullyFurnished": preferences.fullyFurnished,
            "locationQuery": preferences.locationQuery,
            "parkingIncluded": preferences.parkingIncluded,
            "petsAllowed": preferences.petsAllowed,
            "selectedBedroom": preferences.selectedBedroom,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]
    }
    
    
    
    func upsertPreferencesFS(preferences: Preferences) {

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
                "updatedAt": FieldValue.serverTimestamp()
            ], merge: true)
    }
    
    func pushUpsertPreferences(preferences: Preferences) {
        
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

        db.collection("users")
            .document(uid)
            .collection("preferences")
            .document("tenant")
            .setData(data, merge: true)
    }
   
    
    
    private func upsertPreferencesLocal(
        preferences: Preferences,
        context: NSManagedObjectContext
    ) {

        let request: NSFetchRequest<TPreferences> = TPreferences.fetchRequest()
        request.fetchLimit = 1

        let item: TPreferences

        if let existing = try? context.fetch(request).first {
            item = existing
        } else {
            item = TPreferences(context: context)
        }

        item.locationQuery = preferences.locationQuery
        item.budgetMin = preferences.budgetMin
        item.budgetMax = preferences.budgetMax
        item.selectedBedroom = preferences.selectedBedroom
        item.petsAllowed = preferences.petsAllowed
        item.fullyFurnished = preferences.fullyFurnished
        item.parkingIncluded = preferences.parkingIncluded

        try? context.save()
    }
    
}
