//
//  ListingFormView.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-02-26.
//


import SwiftUI
import Firebase
import SwiftUI
import Firebase
import Combine
import PhotosUI
import FirebaseAuth
import SDWebImageSwiftUI
import CoreLocation

struct ListingFormView: View {

    // MARK: - Properties & Environment Variables
    
    @State private var listing: Listing
    let isEditing: Bool

    @EnvironmentObject var firebase: FirebaseManager
    @EnvironmentObject var coreDataManager: CoreDataManager
    @Environment(\.managedObjectContext) var viewContext
    @Environment(\.dismiss) var dismiss

    // MARK: - UI State Variables
    
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var showDraftSavedAlert = false
    @State private var isPublishing = false
    @State private var showPublishSuccess = false
    @State private var publishError: String? = nil

    let allAmenities = ["Air Conditioning", "WiFi", "Parking", "Pet Friendly", "Laundry"]

    // MARK: - Initialization
    
    init(existingListing: Listing? = nil) {
        if let existing = existingListing {
            _listing = State(initialValue: existing)
            isEditing = true
        } else {
            _listing = State(initialValue: Listing(
                buildingID: "",
                landLordId: "",
                price: 0,
                bedrooms: 0,
                bathrooms: 0
            ))
            isEditing = false
        }
    }
    
    // MARK: - Main Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                photoPicker
                imagePreviewRow
                
                TextField("Monthly Price", value: $listing.price, format: .currency(code: "CAD"))
                    .modifier(FormCard())
                    .keyboardType(.decimalPad)
                
                TextField("Address", text: $listing.address)
                    .modifier(FormCard())
                
                HStack {
                    StepperCard(title: "Bedrooms", value: $listing.bedrooms)
                    StepperCard(title: "Bathrooms", value: $listing.bathrooms)
                }
                
                // Fixed Square Feet UI
                HStack {
                    Text("Square Feet")
                    Spacer()
                    TextField("0", value: $listing.squareFeet, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }
                .modifier(FormCard())
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Amenities").font(.headline)
                    ForEach(allAmenities, id: \.self) { amenity in
                        AmenityToggleRow(
                            title: amenity,
                            selected: listing.amenities.contains(amenity)
                        ) {
                            toggleAmenity(amenity)
                        }
                    }
                }
                
                Toggle("Rented", isOn: $listing.isRented)
                    .toggleStyle(SwitchToggleStyle())
                
                VStack(alignment: .leading) {
                    Text("Rules").font(.headline)
                    TextEditor(text: $listing.rules)
                        .frame(height: 120)
                        .modifier(FormCard())
                }
                
                HStack {
                    Button("Save as Draft") {
                        listing.status = .draft
                        saveDraftListing()
                        showDraftSavedAlert = true
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    Button(isEditing ? "Update" : "Publish") {
                        publishListing()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(Auth.auth().currentUser == nil || isPublishing)
                }
            }
            .padding()
        }
        .navigationTitle(isEditing ? "Edit Listing" : "New Listing")
        .background(Color(.systemGray6))
        .alert("Draft Saved", isPresented: $showDraftSavedAlert) {
            Button("OK") { dismiss() }
        }
        .alert("Listing Published", isPresented: $showPublishSuccess) {
            Button("OK") { dismiss() }
        }
        .alert("Publish Failed", isPresented: Binding(
            get: { publishError != nil },
            set: { _ in publishError = nil }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(publishError ?? "")
        }
    }
    
    // MARK: - Private Subviews
    
    private var photoPicker: some View {
        PhotosPicker(
            selection: $selectedItems,
            maxSelectionCount: 10,
            matching: .images
        ){
            Text("Select Photos")
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(.thinMaterial)
                        .stroke(Color(.secondaryLabel), lineWidth: 1)
                )
        }
        .onChange(of: selectedItems) { newItems in
            for item in newItems {
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        await MainActor.run {
                            listing.images.append(uiImage)
                        }
                    }
                }
            }
        }
    }

    private var imagePreviewRow: some View {
        Group {
            if !listing.existingImageURLs.isEmpty || !listing.images.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(listing.existingImageURLs.enumerated()), id: \.offset) { index, urlString in
                            if let url = URL(string: urlString) {
                                WebImage(url: url)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 110, height: 110)
                                    .clipped()
                                    .cornerRadius(12)
                            }
                        }

                        ForEach(Array(listing.images.enumerated()), id: \.offset) { index, image in
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 110, height: 110)
                                .clipped()
                                .cornerRadius(12)
                                .onTapGesture {
                                    setAsCover(index: index)
                                }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Action Methods
    
    private func setAsCover(index: Int) {
        let selected = listing.images.remove(at: index)
        listing.images.insert(selected, at: 0)
    }
    
    private func toggleAmenity(_ amenity: String) {
        if listing.amenities.contains(amenity) {
            listing.amenities.removeAll { $0 == amenity }
        } else {
            listing.amenities.append(amenity)
        }
    }
    
    private func geocodeAddress(_ address: String) async throws -> CLLocationCoordinate2D {
        let geocoder = CLGeocoder()
        let placemarks = try await geocoder.geocodeAddressString(address)

        guard let location = placemarks.first?.location else {
            throw NSError(domain: "GeocodeError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not find coordinates for this address."])
        }

        return location.coordinate
    }
    
    // MARK: - Save & Publish Logic
    
    private func saveDraftListing() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        listing.landLordId = uid
        coreDataManager.saveDraft(from: listing, context: viewContext)
    }

    private func publishListing() {
        guard let uid = Auth.auth().currentUser?.uid else {
            publishError = "User not authenticated. Please sign in again."
            return
        }
        
        listing.landLordId = uid
        isPublishing = true
        let wasDraft = (listing.status == .draft)
        listing.status = .published

        Task {
            do {
                if listing.latitude == nil || listing.longitude == nil {
                    let coord = try await geocodeAddress(listing.address)
                    listing.latitude = coord.latitude
                    listing.longitude = coord.longitude
                }
                
                firebase.uploadListingImages(listingId: listing.listingID, images: listing.images) { newURLs in
                    let finalURLs = listing.existingImageURLs + newURLs
                    
                    DispatchQueue.main.async {
                        firebase.saveListing(
                            listingId: listing.listingID,
                            buildingId: listing.buildingID,
                            landLordId: listing.landLordId,
                            price: listing.price,
                            squareFeet: listing.squareFeet,
                            latitude: listing.latitude ?? 0,
                            longitude: listing.longitude ?? 0,
                            bedrooms: listing.bedrooms,
                            bathrooms: listing.bathrooms,
                            amenities: listing.amenities,
                            status: listing.status,
                            rules: listing.rules,
                            imageURLs: finalURLs,
                            address: listing.address,
                            isRented: listing.isRented
                        )
                        
                        if wasDraft {
                            coreDataManager.deleteDraft(
                                listingID: listing.listingID,
                                context: viewContext,
                                pushRemote: false
                            )
                        }

                        firebase.fetchListingsLandlord()
                        isPublishing = false
                        showPublishSuccess = true
                    }
                }
            } catch {
                await MainActor.run {
                    isPublishing = false
                    publishError = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct AmenityToggleRow: View {
    let title: String
    let selected: Bool
    let tap: () -> Void
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(selected ? .blue : .gray)
        }
        .padding()
        .background(.white)
        .cornerRadius(14)
        .onTapGesture(perform: tap)
    }
}

struct StepperCard: View {
    let title: String
    @Binding var value: Int
    
    var body: some View {
        VStack {
            Text(title)
            
            HStack {
                Button { if value > 0 { value -= 1 } } label: {
                    Image(systemName: "minus.circle")
                }
                
                Text("\(value)")
                    .font(.title3.bold())
                    .frame(minWidth: 40)
                
                Button { value += 1 } label: {
                    Image(systemName: "plus.circle")
                }
            }
        }
        .padding()
        .background(.white)
        .cornerRadius(14)
    }
}

struct FormCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(.white)
            .cornerRadius(14)
    }
}
