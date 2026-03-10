//
//  RemoteListing.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-02-27.
//

import Foundation

struct RemoteListing: Identifiable {

    let id: String
    let buildingId: String
    let landlordId: String

    let price: Double
    let bedrooms: Int
    let bathrooms: Int
    let squareFeet: Int

    let amenities: [String]
    let rules: String

    let imageURLs: [String]

    let address: String
    let latitude: Double
    let longitude: Double

    let status: String
    let isRented: Bool

    let createdAt: Date
    let updatedAt: Date
}
