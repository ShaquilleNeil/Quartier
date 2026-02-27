//
//  ListingFormView.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-02-26.
//


import SwiftUI
import Firebase
import Combine
import PhotosUI
import FirebaseAuth
import SDWebImageSwiftUI

struct ListingFormView: View {

    @State private var listing: Listing
    let isEditing: Bool

    @EnvironmentObject var firebase: FirebaseManager
    @State private var selectedItems: [PhotosPickerItem] = []
    @EnvironmentObject var coreDataManager: CoreDataManager
    @Environment(\.managedObjectContext) var viewContext
    @Environment(\.dismiss) var dismiss

    @State private var showDraftSavedAlert = false
    @State private var isPublishing = false
    @State private var showPublishSuccess = false
    @State private var publishError: String? = nil

    let allAmenities = ["Air Conditioning","WiFi","Parking","Pet Friendly","Laundry"]

    init(existingListing: Listing? = nil) {
        if let existing = existingListing {
            _listing = State(initialValue: existing)
            isEditing = true
        } else {
            _listing = State(initialValue: Listing())
            isEditing = false
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                PhotosPicker(
                    selection: $selectedItems,
                    maxSelectionCount: 10,
                    matching: .images
                ){
                    Text("Select Photos")
                        .padding(10)
                        .background{
                            RoundedRectangle(cornerRadius: 15)
                                .fill(.thinMaterial)
                                .stroke(Color(.secondaryLabel), lineWidth: 1)
                              
                        }
                }.onChange(of: selectedItems) { newItems in
                    for item in newItems {
                        Task {
                            if let data = try? await item.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                listing.images.append(uiImage)
                            }
                        }
                    }
                }
                
                
                if !listing.existingImageURLs.isEmpty || !listing.images.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {

                            // Existing remote images
                            ForEach(Array(listing.existingImageURLs.enumerated()), id: \.offset) { index, urlString in
                                if let url = URL(string: urlString) {
                                    ZStack(alignment: .topTrailing) {

                                        WebImage(url: url)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 110, height: 110)
                                            .clipped()
                                            .cornerRadius(12)

                                        if index == 0 && listing.images.isEmpty {
                                            Text("Cover")
                                                .font(.caption2.bold())
                                                .padding(6)
                                                .background(.black.opacity(0.7))
                                                .foregroundColor(.white)
                                                .cornerRadius(8)
                                                .padding(6)
                                        }
                                    }
                                }
                            }

                            // Newly selected images
                            ForEach(Array(listing.images.enumerated()), id: \.offset) { index, image in
                                ZStack(alignment: .topTrailing) {

                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 110, height: 110)
                                        .clipped()
                                        .cornerRadius(12)
                                        .onTapGesture {
                                            setAsCover(index: index)
                                        }

                                    if listing.existingImageURLs.isEmpty && index == 0 {
                                        Text("Cover")
                                            .font(.caption2.bold())
                                            .padding(6)
                                            .background(.black.opacity(0.7))
                                            .foregroundColor(.white)
                                            .cornerRadius(8)
                                            .padding(6)
                                    }
                                }
                            }
                        }
                    }
                }
                // BUILDING
                TextField("Building ID", text: $listing.buildingID)
                    .modifier(FormCard())
                
                // PRICE
                TextField("Monthly Price", value: $listing.price, format: .currency(code: "CAD"))
                    .modifier(FormCard())
                    .keyboardType(.decimalPad)
                
                TextField("Address", text: $listing.address)
                    .modifier(FormCard())
                
                // BED / BATH
                HStack {
                    StepperCard(title: "Bedrooms", value: $listing.bedrooms)
                    StepperCard(title: "Bathrooms", value: $listing.bathrooms)
                }
                
                // AMENITIES
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
                
                // RULES
                VStack(alignment: .leading) {
                    Text("Rules").font(.headline)
                    TextEditor(text: $listing.rules)
                        .frame(height: 120)
                        .modifier(FormCard())
                }
                
                // ACTIONS
                HStack {
                    
                    Button("Save as Draft") {
                        listing.status = .draft
                        print("Images count before save:", listing.images.count)
                        saveDraftListing()
                        showDraftSavedAlert = true
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    Button(isEditing ? "Update" : "Publish") {
                        listing.status = .published
                        print("Saving listing for user:", firebase.currentUser?.id ?? "nil")
                        publishListing()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
        .navigationTitle("Listing")
        .background(Color(.systemGray6))
        .alert("Draft Saved", isPresented: $showDraftSavedAlert) {
            Button("OK") {
                dismiss()
            }
        }
        .alert("Listing Published", isPresented: $showPublishSuccess) {
            Button("OK") {
                dismiss()
            }
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
    
    func setAsCover(index: Int) {
        let selected = listing.images.remove(at: index)
        listing.images.insert(selected, at: 0)
    }
}

struct AmenityToggleRow: View {
    let title: String
    let selected: Bool
    let tap: () -> Void
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Image(systemName: selected ? "checkmark.circle.fill" : "circle")
        }
        .padding()
        .background(.white)
        .cornerRadius(14)
        .onTapGesture(perform: tap)
    }
}


extension ListingFormView {
    func toggleAmenity(_ amenity: String) {
        if listing.amenities.contains(amenity) {
            listing.amenities.removeAll { $0 == amenity }
        } else {
            listing.amenities.append(amenity)
        }
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

extension ListingFormView {
    
    func publishListing() {
        listing.landLordId = firebase.currentUser?.id ?? ""
        isPublishing = true

        if isEditing {

            Task {
                do {
                    let newURLs = try await firebase.uploadListingImages(
                        listingId: listing.listingID,
                        images: listing.images
                    )

                    let allURLs = listing.existingImageURLs + newURLs

                    firebase.updateListing(
                        listingId: listing.listingID.uuidString,
                        buildingId: listing.buildingID,
                        price: listing.price,
                        bedrooms: listing.bedrooms,
                        bathrooms: listing.bathrooms,
                        amenities: listing.amenities,
                        rules: listing.rules,
                        address: listing.address,
                        isRented: listing.isRented,
                        imageURLs: allURLs
                    )

                    await MainActor.run {
                        isPublishing = false
                        showPublishSuccess = true
                    }

                } catch {
                    await MainActor.run {
                        isPublishing = false
                        publishError = error.localizedDescription
                    }
                }
            }

            return
        }

        // NEW LISTING FLOW (your existing upload + save)
        Task {
            do {
                let urls = try await firebase.uploadListingImages(
                    listingId: listing.listingID,
                    images: listing.images
                )

                firebase.saveListing(
                    listingId: listing.listingID,
                    buildingId: listing.buildingID,
                    landLordId: listing.landLordId,
                    price: listing.price,
                    bedrooms: listing.bedrooms,
                    bathrooms: listing.bathrooms,
                    amenities: listing.amenities,
                    status: listing.status,
                    rules: listing.rules,
                    imageURLs: urls,
                    address: listing.address,
                    isRented: listing.isRented
                )

                await MainActor.run {
                    isPublishing = false
                    showPublishSuccess = true
                }

            } catch {
                await MainActor.run {
                    isPublishing = false
                    publishError = error.localizedDescription
                }
            }
        }
    }
    
    
    func saveDraftListing() {
        listing.landLordId = firebase.currentUser?.id ?? ""
        coreDataManager.saveDraft(from: listing, context: viewContext)
    }
}


#Preview {
    ListingFormView()
}

