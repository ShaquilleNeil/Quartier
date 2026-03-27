//
//  DesignHelpers.swift
//  Quartier
//
//  Created by Team Quartier.
//

import SwiftUI

// MARK: - Shared View Modifiers

struct QuartierFieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 16)
            .frame(height: 50)
            .background(Color.white)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(hex: "e5e7eb"), lineWidth: 1)
            )
    }
}

// MARK: - Shared Components

struct SocialButton: View {
    let text: String
    let iconName: String
    var isDark: Bool = false
    
    var body: some View {
        Button(action: {}) {
            HStack {
                Image(systemName: iconName)
                    .font(.system(size: 16))
                Text(text)
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(isDark ? .white : Color(hex: "0d141b"))
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(isDark ? Color(hex: "0d141b") : .white)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isDark ? .clear : Color(hex: "cfdbe7"), lineWidth: 1)
            )
        }
    }
}

// MARK: - Color Extension

extension Color {
    static let quartierBlue = Color(hex: "2b8cee")
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
