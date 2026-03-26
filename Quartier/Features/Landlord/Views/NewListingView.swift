//
//  NewListingView.swift
//  Quartier
//
//  Landlord: add or edit a listing (apartment/property).
//

import SwiftUI
import CoreData

struct NewListingView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    /// nil = create new; non-nil = edit existing
    var existingListing: LDListing?

    @State private var addressLine = ""
    @State private var buildingIDLine = ""
    @State private var priceMonthlyText = ""
    @State private var bedrooms: Int16 = 1
    @State private var bathrooms: Int16 = 1
    @State private var statusRaw: String = "draft"
    @State private var errorMessage: String?
    @State private var isSaving = false

    private let primary = Color(red: 0.17, green: 0.55, blue: 0.93)
    private let statusOptions: [(value: String, label: String)] = [
        ("draft", "Draft"),
        ("active", "Published"),
        ("rented", "Rented"),
    ]
    var body: some View {
        NavigationStack {
            Form {
                Section("Property") {
                    TextField("Address", text: $addressLine)
                        .textInputAutocapitalization(.words)
                    TextField("Building ID", text: $buildingIDLine)
                        .textInputAutocapitalization(.words)
                }

                Section("Rent & Details") {
                    TextField("Monthly rent ($)", text: $priceMonthlyText)
                        .keyboardType(.decimalPad)
                    Stepper("Bedrooms: \(bedrooms)", value: $bedrooms, in: 0...20)
                    Stepper("Bathrooms: \(bathrooms)", value: $bathrooms, in: 0...10)
                }

                Section("Status") {
                    Picker("Status", selection: $statusRaw) {
                        ForEach(statusOptions, id: \.value) { opt in
                            Text(opt.label).tag(opt.value)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if let err = errorMessage {
                    Section {
                        Text(err)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle(existingListing == nil ? "New Listing" : "Edit Listing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(existingListing == nil ? "Add" : "Save") { save() }
                        .disabled(isSaving || addressLine.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear(perform: loadExisting)
        }
    }

    private func loadExisting() {
        guard let listing = existingListing else { return }
        addressLine = listing.address ?? ""
        buildingIDLine = listing.buildingID ?? ""
        priceMonthlyText = listing.price > 0 ? String(format: "%.0f", listing.price) : ""
        bedrooms = listing.bedrooms
        bathrooms = listing.bathrooms
        statusRaw = listing.status ?? "draft"
    }

    private func save() {
        errorMessage = nil
        isSaving = true
        defer { isSaving = false }

        let price: Double
        if let p = Double(priceMonthlyText.trimmingCharacters(in: .whitespacesAndNewlines)), p >= 0 {
            price = p
        } else if !priceMonthlyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Enter a valid rent amount."
            return
        } else {
            price = 0
        }

        let now = Date()
        if let listing = existingListing {
            listing.address = addressLine.trimmingCharacters(in: .whitespacesAndNewlines)
            listing.buildingID = buildingIDLine.trimmingCharacters(in: .whitespacesAndNewlines)
            listing.price = price
            listing.bedrooms = bedrooms
            listing.bathrooms = bathrooms
            listing.status = statusRaw
            listing.updatedAt = now
        } else {
            let listing = LDListing(context: viewContext)
            listing.id = UUID()
            listing.address = addressLine.trimmingCharacters(in: .whitespacesAndNewlines)
            listing.buildingID = buildingIDLine.trimmingCharacters(in: .whitespacesAndNewlines)
            listing.price = price
            listing.bedrooms = bedrooms
            listing.bathrooms = bathrooms
            listing.status = statusRaw
            listing.createdAt = now
            listing.updatedAt = now
        }

        do {
            try viewContext.save()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview("New") {
    NewListingView(existingListing: nil)
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

#Preview("Edit") {
    NewListingView(existingListing: nil)
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
