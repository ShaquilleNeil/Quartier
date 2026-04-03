//
//  AmenityToggleRow.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-04-03.
//

import SwiftUI


  struct AmenityToggleRow: View {
        let title: String
        let selected: Bool
        let tap: () -> Void
        
        var body: some View {
            HStack {
                Text(title)
                Spacer()
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(selected ? .blue : .gray)
            }
            .padding()
            .background(.white)
            .cornerRadius(14)
            .onTapGesture(perform: tap)
        }
    }
