//
//  Tenant.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-01-28.
//

import Foundation

struct Tenant: Identifiable, Equatable {
    let id: String              // same as User.id
    let firstName: String
    let lastName: String
    let phone: String?
    let profileImage: String?
    let preferences: TenantPreferences
}


struct TenantPreferences: Codable, Equatable {
    let minPrice: Int?
    let maxPrice: Int?
    let minBedrooms: Int?
    let petsAllowed: Bool?
    let furnished: Bool?
    let preferredLocation: LocationPreference?
    let moveInDate: Date?
}

struct LocationPreference: Codable, Equatable {
    let latitude: Double
    let longitude: Double
    let radiusInKm: Double
}

