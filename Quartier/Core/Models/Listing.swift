import Foundation
internal import UIKit
import Combine

struct Listing: Identifiable, Codable {

    var id: UUID { listingID }

    var listingID: UUID = UUID()
    var listingName: String = ""
    var landLordId: String = ""
    var tenantId: String = ""

    var price: Double = 0
    var bedrooms: Int = 0
    var bathrooms: Int = 0
    var squareFeet: Int = 0

    var amenities: [String] = []
    var rules: String = ""

    var address: String = ""
    var latitude: Double? = nil
    var longitude: Double? = nil

    var images: [UIImage] = []          // UI-only
    var existingImageURLs: [String] = []

    var status: ListingStatus = .draft
    var isRented: Bool = false

    var createdAt: Date = Date()
    var updatedAt: Date = Date()

   
    init(
        listingID: UUID = UUID(),
        listingName: String,
        landLordId: String,
        price: Double,
        bedrooms: Int,
        bathrooms: Int,
        address: String
    ) {
        self.listingID = listingID
        self.listingName = listingName
        self.landLordId = landLordId
        self.price = price
        self.bedrooms = bedrooms
        self.bathrooms = bathrooms
        self.address = address
    }

    enum CodingKeys: String, CodingKey {
        case listingID
        case listingName
        case landLordId
        case tenantId  
        case price
        case bedrooms
        case bathrooms
        case squareFeet
        case amenities
        case rules
        case address
        case latitude
        case longitude
        case status
        case isRented
        case existingImageURLs
        case createdAt
        case updatedAt
    }
}

enum ListingStatus: String, CaseIterable, Identifiable, Codable {
    case draft
    case published
    
    var id: String { rawValue }
}
