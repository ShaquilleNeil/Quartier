//
//  FormCard.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-04-03.
//

import SwiftUI


 struct FormCard: ViewModifier {
        func body(content: Content) -> some View {
            content
                .padding()
                .background(.white)
                .cornerRadius(14)
        }
    }
