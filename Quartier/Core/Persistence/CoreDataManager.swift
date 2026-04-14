//
//  CoreDataManager.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-02-24.
//
import Foundation
import CoreData
import Combine
internal import UIKit
import FirebaseAuth
import FirebaseFirestore

class CoreDataManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var preferences: TPreferences? = nil
    @Published var listings: [LDListing] = []
    
    private let sync = FirebaseSync(collectionPath: "listings")
    private var isApplyingRemoteChanges = false
    
    // MARK: - Initialization
    
    init(_ context: NSManagedObjectContext) {
        loadPreferences(context)
        
        sync.startListening(
            context: context
        ) { [weak self] applying in
            DispatchQueue.main.async {
                self?.isApplyingRemoteChanges = applying
            }
        } onRemoteApplied: { [weak self] in
            DispatchQueue.main.async {
                guard let self else { return }
                self.loadListings(context)
            }
        }
        
        sync.startListeningPreferences(context: context)
    }
    
    // MARK: - Load Operations
    
    func loadPreferences(_ context: NSManagedObjectContext) {
        let request = TPreferences.fetchRequest()
        request.fetchLimit = 1
        
        do {
            preferences = try context.fetch(request).first
        } catch {
            fatalError("Failed to fetch preferences: \(error)")
        }
    }
    
    func loadListings(_ context: NSManagedObjectContext) {
        guard let currentUID = Auth.auth().currentUser?.uid else {
            listings = []
            return
        }

        let request: NSFetchRequest<LDListing> = LDListing.fetchRequest()
        request.predicate = NSPredicate(format: "landLordID == %@", currentUID)
        request.sortDescriptors = [
            NSSortDescriptor(key: "updatedAt", ascending: false)
        ]

        do {
            listings = try context.fetch(request)
        } catch {
            print("Failed to fetch listings: \(error)")
        }
    }
    
    // MARK: - Fetch Operations
    
    func fetchDraft(listingID: UUID, context: NSManagedObjectContext) -> LDListing? {
        guard let currentUID = Auth.auth().currentUser?.uid else { return nil }

        let request: NSFetchRequest<LDListing> = LDListing.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(
            format: "id == %@ AND landLordID == %@",
            listingID as CVarArg,
            currentUID
        )

        do {
            return try context.fetch(request).first
        } catch {
            print("Failed to fetch draft: \(error)")
            return nil
        }
    }
    
    func fetchPreferences(for userId: UUID, context: NSManagedObjectContext) -> TPreferences? {
        let request: NSFetchRequest<TPreferences> = TPreferences.fetchRequest()
        request.predicate = NSPredicate(format: "currentUserUUID == %@", userId as CVarArg)
        request.fetchLimit = 1
        
        do {
            return try context.fetch(request).first
        } catch {
            print("Failed to fetch preferences:", error)
            return nil
        }
    }
    
    // MARK: - Save & Update Operations
    
    func savePreferences(
        userId: UUID? = nil,
        locationQuery: String,
        budgetMin: Double,
        budgetMax: Double,
        selectedBedroom: String,
        petsAllowed: Bool,
        fullyFurnished: Bool,
        parkingIncluded: Bool,
        _ context: NSManagedObjectContext
    ) {
        let existing = preferences ?? TPreferences(context: context)
        
        if existing.id == nil {
            existing.id = UUID()
            existing.createdAt = Date()
        }
        
        existing.userID = userId
        existing.locationQuery = locationQuery
        existing.budgetMin = budgetMin
        existing.budgetMax = budgetMax
        existing.selectedBedroom = selectedBedroom
        existing.petsAllowed = petsAllowed
        existing.fullyFurnished = fullyFurnished
        existing.parkingIncluded = parkingIncluded
        existing.updatedAt = Date()
        
        saveContext(context)
        loadPreferences(context)
        
        if !isApplyingRemoteChanges {
            guard let uid = Auth.auth().currentUser?.uid else { return }

            let data: [String: Any] = [
                "locationQuery": locationQuery,
                "budgetMin": budgetMin,
                "budgetMax": budgetMax,
                "selectedBedroom": selectedBedroom,
                "petsAllowed": petsAllowed,
                "fullyFurnished": fullyFurnished,
                "parkingIncluded": parkingIncluded
            ]

            Firestore.firestore()
                .collection("users")
                .document(uid)
                .collection("preferences")
                .document("tenant")
                .setData(data)
        }
    }
    
    func saveDraft(from listing: Listing, context: NSManagedObjectContext) {
        guard let currentUID = Auth.auth().currentUser?.uid else { return }

        let existing = fetchDraft(listingID: listing.listingID, context: context)
        let entity = existing ?? LDListing(context: context)

        if entity.id == nil {
            entity.id = listing.listingID
            entity.createdAt = Date()
        }

        entity.landLordID = currentUID
        entity.listingName = listing.listingName
        entity.tenantID = listing.tenantId
        entity.price = listing.price
        entity.bedrooms = Int16(listing.bedrooms)
        entity.bathrooms = Int16(listing.bathrooms)
        entity.squareFeet = Int32(listing.squareFeet)
        entity.status = listing.status.rawValue
        entity.latitude = listing.latitude ?? 0
        entity.longitude = listing.longitude ?? 0
        entity.rules = listing.rules
        entity.address = listing.address
        entity.isRented = listing.isRented
        entity.updatedAt = Date()
        entity.amenities = listing.amenities as NSObject

        if let oldImages = entity.draftImages as? Set<DraftImage> {
            for image in oldImages {
                context.delete(image)
            }
        }

        for (index, uiImage) in listing.images.enumerated() {
            guard let data = uiImage.jpegData(compressionQuality: 0.8) else { continue }

            let draftImage = DraftImage(context: context)
            draftImage.id = UUID()
            draftImage.orderIndex = Int16(index)
            draftImage.imageData = data
            draftImage.lDListing = entity
        }

        saveContext(context)

        if !isApplyingRemoteChanges {
            sync.pushUpsert(listing: entity)
        }

        loadListings(context)
    }
    
    // MARK: - Delete Operations
    
    func deleteDraft(listingID: UUID, context: NSManagedObjectContext, pushRemote: Bool = false) {
        guard let currentUID = Auth.auth().currentUser?.uid else { return }

        let request: NSFetchRequest<LDListing> = LDListing.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(
            format: "id == %@ AND landLordID == %@",
            listingID as CVarArg,
            currentUID
        )

        do {
            guard let item = try context.fetch(request).first else { return }

            let shouldPushRemoteDelete = pushRemote && !isApplyingRemoteChanges && item.status != "draft"

            if shouldPushRemoteDelete {
                sync.pushDelete(listing: item)
            }

            context.delete(item)
            try context.save()
            loadListings(context)

        } catch {
            print("Failed to delete draft: \(error)")
        }
    }
    
    // MARK: - Favorites

    func saveFavorite(from listing: Listing, context: NSManagedObjectContext) {
        // Avoid duplicates
        guard fetchFavorite(id: listing.listingID, context: context) == nil else { return }

        let entity = TFavoriteListing(context: context)
        entity.id = listing.listingID
        entity.listingName = listing.listingName
        entity.address = listing.address
        entity.price = listing.price
        entity.bedrooms = Int16(listing.bedrooms)
        entity.bathrooms = Int16(listing.bathrooms)
        entity.imageURLs = listing.existingImageURLs as NSObject
        entity.latitude = listing.latitude ?? 0
        entity.longitude = listing.longitude ?? 0
        entity.isRented = listing.isRented
        entity.landlordId = listing.landLordId ?? ""
        entity.savedAt = Date()

        saveContext(context)
        print("Saved favorite: \(listing.listingName)")
        let check = loadFavorites(context: context)
        print("Favorites in Core Data: \(check.map { $0.listingName })")
    }

    func deleteFavorite(id: UUID, context: NSManagedObjectContext) {
        guard let item = fetchFavorite(id: id, context: context) else { return }
        context.delete(item)
        saveContext(context)
    }

    func fetchFavorite(id: UUID, context: NSManagedObjectContext) -> TFavoriteListing? {
        let request: NSFetchRequest<TFavoriteListing> = TFavoriteListing.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return try? context.fetch(request).first
    }

    func loadFavorites(context: NSManagedObjectContext) -> [TFavoriteListing] {
        let request: NSFetchRequest<TFavoriteListing> = TFavoriteListing.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "savedAt", ascending: false)]
        return (try? context.fetch(request)) ?? []
    }
    
    // MARK: - Context Helpers
    
    private func saveContext(_ context: NSManagedObjectContext) {
        do {
            try context.save()
        } catch {
            fatalError("Core Data save failed: \(error)")
        }
    }
    
    
    
}


extension TFavoriteListing {
    func toListing() -> Listing {
        var listing = Listing(
            listingID: self.id ?? UUID(),
            listingName: self.listingName ?? "",
            landLordId: self.landlordId ?? "",
            price: self.price,
            bedrooms: Int(self.bedrooms),
            bathrooms: Int(self.bathrooms),
            address: self.address ?? ""
        )
        listing.existingImageURLs = self.imageURLs as? [String] ?? []
        listing.latitude = self.latitude
        listing.longitude = self.longitude
        listing.isRented = self.isRented
        return listing
    }
}
