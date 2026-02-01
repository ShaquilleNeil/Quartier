//
//  LandlordLogin.swift
//  Quartier
//
//  Created by Team Quartier.
//

import SwiftUI

struct LandlordLogin: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "f6f7f8")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        
                        // MARK: Header
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
                                Text("Welcome back Landlord!")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(Color(hex: "0d141b"))
                                
                                Text("Enter your details to manage your listings")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(hex: "4c739a"))
                            }
                        }
                        .padding(.top, 10)
                        .padding(.bottom, 24)
                        
                        // MARK: Fields
                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Email")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(hex: "0d141b"))
                                
                                TextField("Enter your email", text: $email)
                                    .modifier(QuartierFieldModifier())
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
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
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        HStack {
                            Spacer()
                            Button("Forgot Password?") {
                                // TODO: Handle Forgot Password
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color.quartierBlue)
                        }
                        .padding(.top, 12)
                        .padding(.horizontal, 24)
                        
                        // MARK: Login Button
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
                        
                        // MARK: Divider
                        HStack {
                            Rectangle().fill(Color(hex: "cfdbe7")).frame(height: 1)
                            Text("Or continue with")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color(hex: "4c739a"))
                                .padding(.horizontal, 8)
                            Rectangle().fill(Color(hex: "cfdbe7")).frame(height: 1)
                        }
                        .padding(.vertical, 24)
                        .padding(.horizontal, 24)
                        
                        // MARK: Social Buttons
                        VStack(spacing: 12) {
                            SocialButton(text: "Continue with Google", iconName: "globe")
                            SocialButton(text: "Continue with Apple", iconName: "apple.logo", isDark: true)
                        }
                        .padding(.horizontal, 24)
                        
                        // MARK: Footer
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
        // TODO: Call AuthService.login()
        // Pass UserType.landlord
        print("Landlord Login: \(email)")
    }
}

#Preview {
    LandlordLogin()
}
