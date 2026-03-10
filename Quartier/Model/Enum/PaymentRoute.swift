//
//  PaymentRoute.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-02-26.
//


enum PaymentRoute: Identifiable {
    case methods
    case addCard
    
    var id: String {
        switch self {
        case .methods: return "methods"
        case .addCard: return "addCard"
        }
    }
}

