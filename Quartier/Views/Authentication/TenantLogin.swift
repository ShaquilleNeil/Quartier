//
//  TenantLogin.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-01-29.
//

import SwiftUI

struct TenantLogin: View {
    var body: some View {
        VStack{
            Text("Tenant login")
            Form{
                TextField("Email", text: .constant(""))
                SecureField("Password", text: .constant(""))
                Button(action: {
                    // action here
                }) {
                    Text("Login")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .cornerRadius(10)
                }
            }
        }.padding()
    }
}

#Preview {
    TenantLogin()
}
