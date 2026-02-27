//
//  RemoteListing.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-02-27.
//


struct RemoteListing: Identifiable {
    let id: String
    let buildingId: String
    let landlordId: String
    let price: Double
    let bedrooms: Int
    let bathrooms: Int
    let amenities: [String]
    let status: String
    let rules: String
    let imageURLs: [String]
    let address: String
    let isRented: Bool
}
