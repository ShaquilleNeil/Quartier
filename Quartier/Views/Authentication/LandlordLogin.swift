//
//  LandlordLogin.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-01-29.
//

import SwiftUI

struct LandlordLogin: View {
    var body: some View {
        VStack{
            Text("Landlord login")
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
                        .background(Color.orange)
                        .cornerRadius(10)
                }
            }
        }.padding()
    }
}

#Preview {
    LandlordLogin()
}
