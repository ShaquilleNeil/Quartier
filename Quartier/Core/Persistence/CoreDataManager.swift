//
//  CoreDataManager.swift
//  Quartier
//

import Foundation
import Combine
import CoreData
import FirebaseAuth
import FirebaseFirestore
internal import UIKit

class CoreDataManager: ObservableObject {

    @Published var preferences: TPreferences? = nil
    @Published var listings: [LDListing] = []

    init(_ context: NSManagedObjectContext) {
        loadPreferences(context)
    }

    // Load preferences from CoreData
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
        let request = LDListing.fetchRequest()
        do {
            listings = try context.fetch(request)
        } catch {
            print("Failed to fetch listings: \(error)")
        }
    }

    func fetchDraft(listingID: UUID, context: NSManagedObjectContext) -> LDListing? {
        let request = LDListing.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", listingID as CVarArg)
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

    // Save tenant preferences locally and push to Firebase
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

        // Push to Firebase
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

    // Save a listing draft locally in CoreData
    func saveDraft(from listing: Listing, context: NSManagedObjectContext) {
        let existing = fetchDraft(listingID: listing.listingID, context: context)
        let entity = existing ?? LDListing(context: context)

        if entity.id == nil {
            entity.id = listing.listingID
            entity.createdAt = Date()
        }

        entity.buildingID = listing.buildingID
        entity.landLordID = listing.landLordId
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

        // Replace existing draft images
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
        loadListings(context)
    }

    // Delete a draft from CoreData
    func deleteDraft(listingID: UUID, context: NSManagedObjectContext) {
        let request = LDListing.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", listingID as CVarArg)
        do {
            let drafts = try context.fetch(request)
            for draft in drafts {
                context.delete(draft)
            }
            try context.save()
            loadListings(context)
        } catch {
            print("Failed to delete draft:", error)
        }
    }

    private func saveContext(_ context: NSManagedObjectContext) {
        do {
            try context.save()
        } catch {
            fatalError("Core Data save failed: \(error)")
        }
    }
}
