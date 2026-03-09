//
//  FirebaseSync.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-03-05.
//
import Foundation
import FirebaseFirestore
import CoreData

final class FirebaseSync {
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private let collectionPath: String
    private var lastSync: Date = Date(timeIntervalSince1970: 0)
    
    
    
    init(collectionPath: String = "listings") {
        self.collectionPath = collectionPath
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
                }

                DispatchQueue.main.async {
                    onApplyingRemote(false)
                    onRemoteApplied()
                }
            }
        }
    }
    
    
    
    //pushUppsert
    func pushUpsert(listing: LDListing){
        guard let id = listing.id?.uuidString else { return }
        let ref = db.collection(collectionPath).document(id)
        ref.setData(serialise(listing: listing), merge: true)
    }
    
    
    
    //push delete
    func pushDelete(listingID: UUID) {
        db.collection(collectionPath).document(listingID.uuidString).delete()
    }
    
    
    
    //upsert(remote -> coredata)
    private func upsert(
        docID: String,
        data: [String: Any],
        into context: NSManagedObjectContext
    ) {
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

        // Conflict guard
        if let remoteUpdatedAt,
           let localUpdatedAt = item.updatedAt,
           localUpdatedAt > remoteUpdatedAt {
            return
        }

        item.buildingID = data["buildingId"] as? String
        item.landLordID = data["landLordId"] as? String
        item.price = data["price"] as? Double ?? 0.0
        item.bedrooms = data["bedrooms"] as? Int16 ?? 0
        item.bathrooms = data["bathrooms"] as? Int16 ?? 0
        item.amenities = (data["amenities"] as? [String] ?? []) as NSObject
        item.status = data["status"] as? String ?? ""
        item.rules = data["rules"] as? String ?? ""
        item.address = data["address"] as? String ?? ""
        item.isRented = data["isRented"] as? Bool ?? false

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
    ){
        guard let uuid = UUID(uuidString: docID) else { return }
        
        let request: NSFetchRequest<LDListing> = LDListing.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)
        
        if let item = try? context.fetch(request).first {
            context.delete(item)
        }
        
    }
    
    
    //serialise (change obj)
    private func serialise(listing: LDListing) -> [String: Any] {
        return [
            "buildingId": listing.buildingID ?? "",
            "landLordId": listing.landLordID ?? "",
            "price": listing.price,
            "bedrooms": listing.bedrooms,
            "bathrooms": listing.bathrooms,
            "amenities": listing.amenities as? [String] ?? [],
            "status": listing.status ?? "",
            "rules": listing.rules ?? "",
            "address": listing.address ?? "",
            "isRented": listing.isRented,

            // Firestore server timestamps (prevents invalid dates)
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]
    }
    
    
    
   
}
