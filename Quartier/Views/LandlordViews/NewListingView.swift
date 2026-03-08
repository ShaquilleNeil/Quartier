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

    @State private var title = ""
    @State private var cityLine = ""
    @State private var priceMonthlyText = ""
    @State private var beds: Int16 = 1
    @State private var baths: Double = 1
    @State private var statusRaw: String = "draft"
    @State private var coverImageName = "building.2.fill"
    @State private var errorMessage: String?
    @State private var isSaving = false

    private let primary = Color(red: 0.17, green: 0.55, blue: 0.93)
    private let statusOptions: [(value: String, label: String)] = [
        ("draft", "Draft"),
        ("active", "Published"),
        ("rented", "Rented"),
    ]
    private let imageOptions = ["building.2.fill", "building.fill", "house.fill", "house"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Property") {
                    TextField("Title / Address", text: $title)
                        .textInputAutocapitalization(.words)
                    TextField("City / Area", text: $cityLine)
                        .textInputAutocapitalization(.words)
                }

                Section("Rent & Details") {
                    TextField("Monthly rent ($)", text: $priceMonthlyText)
                        .keyboardType(.decimalPad)
                    Stepper("Bedrooms: \(beds)", value: Binding(
                        get: { Int(beds) },
                        set: { beds = Int16(max(0, $0)) }
                    ), in: 0...20)
                    Stepper("Bathrooms: \(baths, specifier: "%.1f")", value: $baths, in: 0...10, step: 0.5)
                }

                Section("Status") {
                    Picker("Status", selection: $statusRaw) {
                        ForEach(statusOptions, id: \.value) { opt in
                            Text(opt.label).tag(opt.value)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Cover icon") {
                    Picker("Icon", selection: $coverImageName) {
                        ForEach(imageOptions, id: \.self) { name in
                            HStack {
                                Image(systemName: name)
                                Text(name)
                            }
                            .tag(name)
                        }
                    }
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
                        .disabled(isSaving || title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear(perform: loadExisting)
        }
    }

    private func loadExisting() {
        guard let listing = existingListing else { return }
        title = listing.title ?? ""
        cityLine = listing.cityLine ?? ""
        priceMonthlyText = listing.priceMonthly > 0 ? String(format: "%.0f", listing.priceMonthly) : ""
        beds = listing.beds
        baths = listing.baths
        statusRaw = listing.status ?? "draft"
        coverImageName = listing.coverImageName ?? "building.2.fill"
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
            listing.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            listing.cityLine = cityLine.trimmingCharacters(in: .whitespacesAndNewlines)
            listing.priceMonthly = price
            listing.beds = beds
            listing.baths = baths
            listing.status = statusRaw
            listing.coverImageName = coverImageName
            listing.updatedAt = now
        } else {
            let listing = LDListing(context: viewContext)
            listing.id = UUID()
            listing.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            listing.cityLine = cityLine.trimmingCharacters(in: .whitespacesAndNewlines)
            listing.priceMonthly = price
            listing.beds = beds
            listing.baths = baths
            listing.status = statusRaw
            listing.coverImageName = coverImageName
            listing.viewsCount = 0
            listing.leadsCount = 0
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
