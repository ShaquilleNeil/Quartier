//
//  User.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-01-28.
//

import Foundation
import Combine

struct User: Identifiable, Equatable {
    let id: String              // Firebase UID
    let email: String
    let name: String
    let profilePic: String?
    let role: UserType
    let createdAt: Date
    let isActive: Bool
    let isRenting: Bool
    let apartmentId: String?
}

