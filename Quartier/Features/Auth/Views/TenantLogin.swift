//
//  TenantLogin.swift
//  Quartier
//
//  Created by Team Quartier.
//

import SwiftUI

struct TenantLogin: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService
    
    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    @State private var fieldErrors: [String: String] = [:]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "f6f7f8")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        
                        VStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.quartierBlue)
                                    .frame(width: 48, height: 48)
                                    .shadow(color: Color.quartierBlue.opacity(0.2), radius: 8, x: 0, y: 4)
                                
                                Image(systemName: "building.2.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(spacing: 4) {
                                Text("Welcome back Tenant!")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(Color(hex: "0d141b"))
                                
                                Text("Enter your details to access your account")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(hex: "4c739a"))
                            }
                        }
                        .padding(.top, 10)
                        .padding(.bottom, 24)
                        
                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Email")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(hex: "0d141b"))
                               
                                TextField("Enter your email", text: $email)
                                    .modifier(QuartierFieldModifier())
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                
                                if let error = fieldErrors["email"] {
                                    Text(error)
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                }
                                
                               
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Password")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(hex: "0d141b"))
                                
                                ZStack(alignment: .trailing) {
                                    if isPasswordVisible {
                                        TextField("Enter your password", text: $password)
                                            .modifier(QuartierFieldModifier())
                                    } else {
                                        SecureField("Enter your password", text: $password)
                                            .modifier(QuartierFieldModifier())
                                    }
                                    
                                    
                                    Button(action: { isPasswordVisible.toggle() }) {
                                        Image(systemName: isPasswordVisible ? "eye" : "eye.slash")
                                            .foregroundColor(Color(hex: "4c739a"))
                                            .padding(.trailing, 16)
                                    }
                                }
                                
                                if let error = fieldErrors["password"] {
                                    Text(error)
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        
                       
                        
                        HStack {
                            Spacer()
                            Button("Forgot Password?") {
                                // todo
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color.quartierBlue)
                        }
                        .padding(.top, 12)
                        .padding(.horizontal, 24)
                        
                        Button(action: handleLogin) {
                            Text("Log In")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.quartierBlue)
                                .cornerRadius(10)
                                .shadow(color: Color.quartierBlue.opacity(0.1), radius: 4, x: 0, y: 2)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        
                        
                        HStack {
                            Text("New to Quartier?")
                                .foregroundColor(Color(hex: "4c739a"))
                            
                            NavigationLink {
                                SignUp()
                                    .navigationBarBackButtonHidden(true)
                            } label: {
                                Text("Create an account")
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.quartierBlue)
                            }
                        }
                        .font(.system(size: 14))
                        .padding(.top, 24)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
    }
    
    func handleLogin() {
        if !validate() { return }
        authService.login(email: email, password: password) { success in
            if success {
                print("logged in tenant!")
            } else {
                print("login failed")
            }
        }
    }
    
    
    
    
    func validate()-> Bool {
        var errors: [String: String] = [:]
        
        if email.isEmpty {
            errors["email"] = "Email is required"
        }
        if password.isEmpty {
            errors["password"] = "Password is required"
        }
        
        fieldErrors = errors
        return errors.isEmpty
    }
}



#Preview {
    let firebase = FirebaseManager()
    let auth = AuthService(firebase: firebase)

    return TenantLogin()
        .environmentObject(firebase)
        .environmentObject(auth)
}
