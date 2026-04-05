//
//  ProfileEditView.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-04-05.
//

import SwiftUI
import PhotosUI
import FirebaseAuth
import SDWebImageSwiftUI

struct ProfileEditView: View {
    
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var firebaseManager: FirebaseManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var selectedImage: PhotosPickerItem?
    @State private var imageData: Data?
    
    @State private var isSaving = false
    @State private var showSuccess = false
    @State private var errorMessage: String?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                // MARK: Header
                VStack(spacing: 8) {
                    Text("Edit Profile")
                        .font(.title2.bold())
                    
                    Text("Update your name and profile photo")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 12)
                
                // MARK: Profile Image
                VStack(spacing: 14) {
                    PhotosPicker(selection: $selectedImage, matching: .images) {
                        ZStack(alignment: .bottomTrailing) {
                            
                            profileImageView
                            
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 34, height: 34)
                                .overlay(
                                    Image(systemName: "camera.fill")
                                        .foregroundColor(.white)
                                        .font(.caption)
                                )
                                .shadow(color: .black.opacity(0.12), radius: 6, y: 2)
                        }
                    }
                    .buttonStyle(.plain)
                    .onChange(of: selectedImage) { newValue in
                        Task {
                            if let data = try? await newValue?.loadTransferable(type: Data.self) {
                                await MainActor.run {
                                    imageData = data
                                }
                            }
                        }
                    }
                    
                    Text("Tap photo to change")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // MARK: Form Card
                VStack(alignment: .leading, spacing: 16) {
                    Text("Profile Details")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Full Name")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.secondary)
                        
                        TextField("Enter your name", text: $name)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(.systemGray6))
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.secondary)
                        
                        Text(authService.userSession?.email ?? "No email")
                            .foregroundColor(.primary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(.systemGray6))
                            )
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
                )
                
                // MARK: Error
                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // MARK: Actions
                VStack(spacing: 12) {
                    Button {
                        saveProfile()
                    } label: {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "checkmark")
                                Text("Save Changes")
                                    .fontWeight(.semibold)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(canSave ? Color.blue : Color.gray.opacity(0.5))
                        )
                    }
                    .disabled(!canSave || isSaving)
                    
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.black)
                }
            }
        }
        .onAppear {
            name = firebaseManager.currentUser?.name ?? ""
        }
        .alert("Profile Updated", isPresented: $showSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your profile has been updated.")
        }
    }
    
    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    @ViewBuilder
    private var profileImageView: some View {
        if let imageData,
           let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 120, height: 120)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 4)
                )
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
            
        } else if let urlString = firebaseManager.currentUser?.profilePic,
                  let url = URL(string: urlString),
                  !urlString.isEmpty {
            WebImage(url: url) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.15))
                    ProgressView()
                }
            }
            .frame(width: 120, height: 120)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 4)
            )
            .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
            
        } else {
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "person.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 42, height: 42)
                    .foregroundColor(.gray)
            }
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 4)
            )
            .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        }
    }
    
    private func saveProfile() {
        guard let uid = Auth.auth().currentUser?.uid else {
            errorMessage = "Could not find signed-in user."
            return
        }
        
        errorMessage = nil
        isSaving = true
        
        authService.saveProfile(
            uid: uid,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            imageData: imageData
        ) { result in
            DispatchQueue.main.async {
                isSaving = false
                
                switch result {
                case .success:
                    firebaseManager.fetchUser(uid: uid) { _ in
                        DispatchQueue.main.async {
                            showSuccess = true
                        }
                    }
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    let firebase = FirebaseManager()
    let auth = AuthService(firebase: firebase)
    
    return NavigationStack {
        ProfileEditView()
            .environmentObject(firebase)
            .environmentObject(auth)
    }
}
