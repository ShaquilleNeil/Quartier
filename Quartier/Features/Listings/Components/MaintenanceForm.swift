//
//  MaintenanceForm.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-04-09.
//

import SwiftUI
import PhotosUI
import FirebaseAuth

struct MaintenanceForm: View {
    @State private var date: Date = Date()
    @State private var description: String = ""
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var photos: [UIImage] = []
    @State private var isSubmitting = false
    @State private var submitError: String? = nil

    @EnvironmentObject private var firebase: FirebaseManager
    @EnvironmentObject private var authService: AuthService
    @Environment(\.dismiss) var dismiss
    @State private var fieldErrors: [String: String] = [:]

    var body: some View {
        VStack {
            Form {
                Section(header: Text("Maintenance Request Form")) {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TextField("Description", text: $description)
                    if let error = fieldErrors["description"] {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    photoPicker

                    if let error = submitError {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }

                    Button(isSubmitting ? "Submitting..." : "Submit") {
                        Task { await submitRequest() }
                    }
                    .disabled(isSubmitting || description.isEmpty)
                }
            }
        }
    }

    private func submitRequest() async {
        if !validation() { return }
        guard let uid = Auth.auth().currentUser?.uid else {
            submitError = "User not found."
            return
        }

        isSubmitting = true
        submitError = nil

        firebase.fetchUser(uid: uid) { user in
            guard let user = user else {
                submitError = "Could not load user."
                isSubmitting = false
                return
            }

            guard let listingId = user.apartmentId, !listingId.isEmpty else {
                submitError = "No listing found for your account."
                isSubmitting = false
                return
            }

            let request = MaintenanceRequest(
                listingId: listingId,
                tenantId: user.id,
                description: description,
                date: date
            )

            firebase.submitMaintenanceRequest(request: request, photos: photos) { error in
                DispatchQueue.main.async {
                    isSubmitting = false
                    if let error = error {
                        submitError = error.localizedDescription
                    } else {
                        dismiss()
                    }
                }
            }
        }
    }

    private var photoPicker: some View {
        PhotosPicker(
            selection: $selectedItems,
            maxSelectionCount: 10,
            matching: .images
        ) {
            Text("Add Photos")
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(.thinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color(.secondaryLabel))
                        )
                )
        }
        .onChange(of: selectedItems) { newItems in
            for item in newItems {
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        photos.append(image)
                    }
                }
            }
        }
    }
    
    func validation() -> Bool{
        var errors: [String: String] = [:]
        
        if description.isEmpty {
            errors["description"] = "Please enter a description."
        }
        
        fieldErrors = errors
        return errors.isEmpty
    }
}

#Preview {
    MaintenanceForm()
}
