//
//  LoginSwitch.swift
//  Quartier
//
//  Created by Team Quartier.
//

import SwiftUI

struct LoginSwitch: View {
    @State private var selectedRole: UserType = .tenant
    
    var body: some View {
        ZStack {
            Color(hex: "f6f7f8")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Role switcher at the top
                Picker("Role", selection: $selectedRole.animation(.easeInOut)) {
                    Text("Tenant").tag(UserType.tenant)
                    Text("Landlord").tag(UserType.landlord)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 8)

                // Active screen fills the rest
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
        }
    }
}

#Preview {
    LoginSwitch()
}
