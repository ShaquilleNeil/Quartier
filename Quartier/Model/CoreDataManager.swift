//
//  CoreDataManager.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-02-24.
//

import Foundation
import CoreData
import Combine

class CoreDataManager: ObservableObject {
    
    @Published var preferences: TPreferences? = nil
    
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
    ) {
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
    
    
    // MARK: Save Context
    
    private func saveContext(_ context: NSManagedObjectContext) {
        do {
            try context.save()
        } catch {
            fatalError("Core Data save failed: \(error)")
        }
    }
}
