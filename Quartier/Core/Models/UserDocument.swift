//
//  UserDocument.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-04-04.
//


struct UserDocument: Identifiable {
    var id: String { type }
    let type: String
    let url: String
    let status: String
}