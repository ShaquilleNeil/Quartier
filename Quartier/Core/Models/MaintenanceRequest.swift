//
//  MaintenanceRequest.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-04-09.
//

import Foundation


struct MaintenanceRequest: Identifiable, Codable {
    var id: UUID = UUID()
    var listingId: String
    var tenantId: String
    var description: String
    var date: Date
    var status: MaintenanceStatus = .pending
    var photoURLs: [String] = []
    var createdAt: Date = Date()
}

enum MaintenanceStatus: String, Codable {
    case pending
    case resolved
}
