//
//  SignUp.swift
//  Quartier
//
//  Created by Team Quartier.
//

import SwiftUI
import _PhotosUI_SwiftUI
import FirebaseAuth

struct SignUp: View {
    @Environment(\.dismiss) var dismiss

    @State private var selectedRole: UserType = .tenant
    @State private var selectedImage: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "f6f7f8")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        
                        // Header
                        VStack(spacing: 8) {
                            Text("Create Account")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(Color(hex: "111827"))
                            
                            Text("Join the Quartier community today.")
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: "6b7280"))
                        }
                        .padding(.top, 32)
                        .padding(.bottom, 24)
                        
                        // Role Selection
                        Picker("Role", selection: $selectedRole) {
                            ForEach(UserType.allCases, id: \.self) { role in
                                Text(role.rawValue.capitalized).tag(role)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.vertical, 24)
                        
                        // Form Fields
                        VStack(spacing: 16) {
                            
                            PhotosPicker(selection: $selectedImage, matching: .images) {
                                if let data = imageData, let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                } else {
                                    Image(systemName: "person.crop.circle.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 120, height: 120)
                                        .foregroundColor(.gray)
                                }
                            }.onChange(of: selectedImage) { newValue in
                                Task {
                                    if let data = try? await newValue?.loadTransferable(type: Data.self) {
                                        imageData = data
                                    }
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Full Name")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(hex: "374151"))
                                
                                TextField("Enter your full name", text: $fullName)
                                    .modifier(QuartierFieldModifier())
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Email Address")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(hex: "374151"))
                                
                                TextField("name@example.com", text: $email)
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .modifier(QuartierFieldModifier())
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Password")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(hex: "374151"))
                                
                                ZStack(alignment: .trailing) {
                                    if isPasswordVisible {
                                        TextField("Min. 8 characters", text: $password)
                                            .modifier(QuartierFieldModifier())
                                    } else {
                                        SecureField("Min. 8 characters", text: $password)
                                            .modifier(QuartierFieldModifier())
                                    }
                                    
                                    Button(action: { isPasswordVisible.toggle() }) {
                                        Image(systemName: isPasswordVisible ? "eye" : "eye.slash")
                                            .foregroundColor(.gray)
                                            .padding(.trailing, 16)
                                    }
                                }
                            }
                        }
                        
                        // Disclaimer
                        Text("By signing up, you agree to Quartier's [Terms of Service](https://example.com) and [Privacy Policy](https://example.com).")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "9ca3af"))
                            .multilineTextAlignment(.center)
                            .padding(.top, 24)
                            .padding(.horizontal, 24)
                            .tint(Color.quartierBlue)
                        
                        // Submit Button
                        Button(action: handleSignUp) {
                            Text("Sign Up")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.quartierBlue)
                                .cornerRadius(12)
                                .shadow(color: Color.quartierBlue.opacity(0.2), radius: 10, x: 0, y: 4)
                        }
                        .padding(.top, 32)
                        
                        // Footer
                        HStack {
                            Text("Already have an account?")
                                .foregroundColor(Color(hex: "4b5563"))
                            
                            Button("Log In") {
                                dismiss()
                            }
                            .fontWeight(.bold)
                            .foregroundColor(Color.quartierBlue)
                        }
                        .font(.system(size: 14))
                        .padding(.top, 32)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Quartier")
                        .font(.headline)
                        .fontWeight(.bold)
                }
            }
        }
    }
    
    func handleSignUp() {
        authService.register(email: email, password: password, role: selectedRole.rawValue) { success in
            
            guard success else {
                print("sign up failed")
                return
            }
            
            guard let uid = Auth.auth().currentUser?.uid else {
                print("UID missing")
                return
            }

            authService.saveProfile(
                uid: uid,
                name: fullName,
                imageData: imageData
            ) { result in
                switch result {
                case .success:
                    print("User fully created")
                case .failure(let error):
                    print("Profile setup failed:", error)
                }
            }
        }
    }
}

#Preview {
    let firebase = FirebaseManager()
    let auth = AuthService(firebase: firebase)

    return SignUp()
        .environmentObject(firebase)
        .environmentObject(auth)
}
