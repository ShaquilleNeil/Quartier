import Foundation
internal import UIKit
//
//  Listing.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-02-26.
//


struct Listing {
    var listingID: UUID = UUID()
    var buildingID: String = ""
    var landLordId: String = ""
    var price: Double = 0
    var bedrooms: Int = 0
    var bathrooms: Int = 0
    var amenities: [String] = []
    var status: ListingStatus = .draft
    var rules: String = ""
    var images: [UIImage] = []
    var address: String = ""
    var isRented: Bool = false
    var existingImageURLs: [String] = []
   
}

enum ListingStatus: String, CaseIterable, Identifiable {
    case draft
    case published
    
    var id: String { rawValue }
}

