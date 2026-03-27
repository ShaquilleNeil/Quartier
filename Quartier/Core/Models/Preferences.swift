//
//  Preferences.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-03-09.
//


struct Preferences: Codable {
    var locationQuery: String
    var budgetMin: Double
    var budgetMax: Double
    var selectedBedroom: String
    var petsAllowed: Bool
    var fullyFurnished: Bool
    var parkingIncluded: Bool
}
