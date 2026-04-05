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
        NavigationStack {
            VStack(spacing: 0) {
                
                // 1. The Switcher Header
                ZStack {
                    Color(hex: "f6f7f8")
                        .ignoresSafeArea(edges: .top)
                    
                    HStack {
                        // The Picker
                        Picker("Role", selection: $selectedRole.animation(.easeInOut)) {
                            Text("Tenant").tag(UserType.tenant)
                            Text("Landlord").tag(UserType.landlord)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                    }
                    .padding(.bottom, 16)
                }
                .frame(height: 70)
                
                // 2. The Active Screen
                Group {
                    if selectedRole == .tenant {
                        TenantLogin()
                    } else {
                        LandlordLogin()
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
            .background(Color(hex: "f6f7f8"))
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

#Preview {
    LoginSwitch()
}
