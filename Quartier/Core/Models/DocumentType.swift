//
//  DocumentType.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-04-01.
//

import SwiftUI


enum DocumentType: String, Codable, CaseIterable {
    case id
    case paystub
    case tax
    case lease
}

enum DocumentStatus: String, Codable {
    case none
    case pending
    case verified
}

struct DocumentItem: Codable {
    let type: DocumentType
    let url: String?
    let status: DocumentStatus
}
