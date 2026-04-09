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
    @State private var fieldErrors: [String: String] = [:]
    
    var body: some View {
        ZStack {
            Color(hex: "f6f7f8")
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Header
                    VStack(spacing: 8) {
                        Text("Create Account")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color(hex: "111827"))
                    }
                    .padding(.top, 40)
                    
                    Picker("Role", selection: $selectedRole) {
                        ForEach(UserType.allCases, id: \.self) { role in
                            Text(role.rawValue.capitalized).tag(role)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 8)
                    
                    // Avatar
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
                    }
                    .onChange(of: selectedImage) { newValue in
                        Task {
                            if let data = try? await newValue?.loadTransferable(type: Data.self) {
                                imageData = data
                            }
                        }
                    }
                    
                    // Form Fields
                    VStack(spacing: 20) {
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Full Name")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(hex: "374151"))
                            
                            TextField("Enter your full name", text: $fullName)
                                .modifier(QuartierFieldModifier())
                            
                            if let error = fieldErrors["fullName"] {
                                Text(error)
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Email Address")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(hex: "374151"))
                            
                            TextField("name@example.com", text: $email)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .modifier(QuartierFieldModifier())
                            
                            if let error = fieldErrors["email"] {
                                Text(error)
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
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
                            
                            if let error = fieldErrors["password"] {
                                Text(error)
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                    
                    
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
                    .padding(.top, 16)
                    
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
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
                .padding(.horizontal, 24)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
    }
    
    func handleSignUp() {
        if !validate() { return }
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
    
    
    func validate()-> Bool {
        var errors: [String: String] = [:]
        
        if fullName.isEmpty {
            errors["fullName"] = "Full name is required"
        }
        
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

    return SignUp()
        .environmentObject(firebase)
        .environmentObject(auth)
}
