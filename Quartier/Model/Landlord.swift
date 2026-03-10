//
//  Landlord.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-01-28.
//

import Foundation
import Combine


struct Landlord: Identifiable, Equatable {
    let id: String              // same as User.id
    let firstName: String
    let lastName: String
    let phone: String
    let address: String
    let profileImage: String?
    let listingIDs: [String]    
}
