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

class CoreDataManager: ObservableObject {
    
    @Published var preferences: TPreferences? = nil
    @Published var listings: [LDListing] = []
    
    init(_ context: NSManagedObjectContext) {
        loadPreferences(context)
    }
    
    // MARK: Load
    
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
    
    func fetchDraft(
        listingID: UUID,
        context: NSManagedObjectContext
    ) -> LDListing? {
        
        let request = LDListing.fetchRequest()
        
        request.predicate = NSPredicate(
            format: "id == %@",
            listingID as CVarArg
        )
        
        do {
            let results = try context.fetch(request)
            return results.first
        } catch {
            print("Failed to fetch draft: \(error)")
            return nil
        }
    }
    
    // MARK: Save / Update
    
    func savePreferences(
        locationQuery: String,
        budgetMin: Double,
        budgetMax: Double,
        selectedBedroom: String,
        petsAllowed: Bool,
        fullyFurnished: Bool,
        parkingIncluded: Bool,
        _ context: NSManagedObjectContext
    )
    {
        let existing = preferences ?? TPreferences(context: context)
        
        if existing.id == nil {
            existing.id = UUID()
            existing.createdAt = Date()
        }
        
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
    }
    
    
    func saveDraft(
        from listing: Listing,
        context: NSManagedObjectContext
    )
    {
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
        entity.status = listing.status.rawValue
        entity.rules = listing.rules
        entity.address = listing.address
        entity.isRented = listing.isRented
        entity.updatedAt = Date()
        
        if let data = try? JSONEncoder().encode(listing.amenities),
           let jsonString = String(data: data, encoding: .utf8){
            entity.amenities = jsonString
        }
            
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
        
    }
    
    
    // MARK: Save Context
    
    private func saveContext(_ context: NSManagedObjectContext) {
        do {
            try context.save()
        } catch {
            fatalError("Core Data save failed: \(error)")
        }
    }
}
