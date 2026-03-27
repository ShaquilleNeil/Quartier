//
//  LoginSwitch.swift
//  Quartier
//
//  Created by Team Quartier.
//

import SwiftUI

struct LoginSwitch: View {
    // MARK: - Properties
    @Environment(\.dismiss) var dismiss
    
    // We use the UserType enum instead of a boolean for clarity
    @State private var selectedRole: UserType = .tenant
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            
            // 1. The Switcher Header
            ZStack {
                Color(hex: "f6f7f8")
                    .ignoresSafeArea()
                
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(Color(hex: "0d141b"))
                            .font(.system(size: 16, weight: .medium))
                            .padding(12)
                    }
                    
                    // The Picker
                    Picker("Role", selection: $selectedRole.animation(.easeInOut)) {
                        Text("Tenant").tag(UserType.tenant)
                        Text("Landlord").tag(UserType.landlord)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    
                    Spacer().frame(width: 44)
                }
                .padding(.bottom, 8)
            }
            .frame(height: 60) 
            
            // 2. The Active Screen
            Group {
                if selectedRole == .tenant {
                    TenantLogin()
                        .toolbar(.hidden, for: .navigationBar)
                } else {
                    LandlordLogin()
                        .toolbar(.hidden, for: .navigationBar)
                }
            }
            .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
        .background(Color(hex: "f6f7f8"))
    }
}

#Preview {
    LoginSwitch()
}
