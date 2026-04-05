import SwiftUI
import Firebase
import Combine
import PhotosUI
import FirebaseAuth
import SDWebImageSwiftUI
import CoreLocation
import CoreData

struct ListingFormView: View {

    // MARK: - State

    @State private var listing: Listing
    let isEditing: Bool

    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var showDraftSavedAlert = false

    @State private var tenants: [TenantItem] = []
    @State private var selectedTenant: TenantItem? = nil
    @State private var originalTenantId: String = ""

    // MARK: - Environment

    @EnvironmentObject var firebase: FirebaseManager
    @EnvironmentObject var coreDataManager: CoreDataManager
    @Environment(\.managedObjectContext) var viewContext
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = ListingFormViewModel()


    // MARK: - Constants

    let allAmenities = ["Air Conditioning", "WiFi", "Parking", "Pet Friendly", "Laundry"]

    // MARK: - Init

    init(existingListing: Listing? = nil) {
        if let existing = existingListing {
            _listing = State(initialValue: existing)
            isEditing = true
        } else {
            _listing = State(initialValue: Listing(
                listingName: "",
                landLordId: "",
                price: 0,
                bedrooms: 0,
                bathrooms: 0,
                address: ""
            ))
            isEditing = false
        }
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                photoPicker
                imagePreviewRow
                TextField("Name", text: $listing.listingName)
                priceSection
                addressSection
                detailsSection
                squareFeetSection
                amenitiesSection
                tenantSection
                rulesSection
                actionButtons
            }
            .padding()
        }
        .onAppear {
            viewModel.configure(firebase: firebase, coreData: coreDataManager)
            setupView()
        }
        .onChange(of: selectedTenant) { tenant in
            listing.tenantId = tenant?.id ?? ""
        }
        .navigationTitle(isEditing ? "Edit Listing" : "New Listing")
        .background(Color(.systemGray6))
        .alert("Draft Saved", isPresented: $showDraftSavedAlert) {
            Button("OK") { dismiss() }
        }
        .alert("Listing Published", isPresented: $viewModel.showPublishSuccess) {
            Button("OK") { dismiss() }
        }
        .alert("Publish Failed", isPresented: Binding(
            get: { viewModel.publishError != nil },
            set: { _ in viewModel.publishError = nil }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.publishError ?? "")
        }
    }
    
    
    private var photoPicker: some View {
        PhotosPicker(
            selection: $selectedItems,
            maxSelectionCount: 10,
            matching: .images
        ) {
            Text("Select Photos")
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
                        listing.images.append(image)
                    }
                }
            }
        }
    }
    
    private var imagePreviewRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(listing.images.indices, id: \.self) { index in
                    Image(uiImage: listing.images[index])
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
    
    private func setupView() {
        firebase.fetchAllTenants { items in
            tenants = items
            originalTenantId = listing.tenantId

            if !listing.tenantId.isEmpty {
                selectedTenant = items.first { $0.id == listing.tenantId }
            }
        }
    }
    
    private func toggleAmenity(_ amenity: String) {
        if listing.amenities.contains(amenity) {
            listing.amenities.removeAll { $0 == amenity }
        } else {
            listing.amenities.append(amenity)
        }
    }
    
    private func setAsCover(index: Int) {
        let selected = listing.images.remove(at: index)
        listing.images.insert(selected, at: 0)
    }
    
    private var priceSection: some View {
        TextField("Monthly Price", value: $listing.price, format: .currency(code: "CAD"))
            .modifier(FormCard())
            .keyboardType(.decimalPad)
    }
    
    private var addressSection: some View {
        TextField("Address", text: $listing.address)
            .modifier(FormCard())
    }
    
    private var detailsSection: some View {
        HStack {
            StepperCard(title: "Bedrooms", value: $listing.bedrooms)
            StepperCard(title: "Bathrooms", value: $listing.bathrooms)
        }
    }
    
    private var squareFeetSection: some View {
        HStack {
            Text("Square Feet")
            Spacer()
            TextField("0", value: $listing.squareFeet, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
        }
        .modifier(FormCard())
    }
    
    private var amenitiesSection: some View {
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
    }
    
    
    private var tenantSection: some View {
        VStack(spacing: 12) {
            Text("Assign To a Tenant")

            if let tenant = selectedTenant {
                selectedTenantChip(tenant)
            } else {
                TenantSearchField(
                    selectedTenant: $selectedTenant,
                    tenants: tenants
                )
            }
        }
    }
    
    
    
    private func selectedTenantChip(_ tenant: TenantItem) -> some View {
        HStack {
            Text(tenant.email)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.1))
                .clipShape(Capsule())

            Button {
                selectedTenant = nil
                listing.tenantId = ""
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
            }
        }
    }
    
    private var rulesSection: some View {
        VStack(alignment: .leading) {
            Text("Rules").font(.headline)

            TextEditor(text: $listing.rules)
                .frame(height: 120)
                .modifier(FormCard())
        }
    }
    
    
    private var actionButtons: some View {
        HStack {

            Button("Save as Draft") {
                listing.status = .draft
                viewModel.saveDraft(listing: listing, context: viewContext)
                showDraftSavedAlert = true
            }

            Spacer()

            Button(isEditing ? "Update" : "Publish") {
                viewModel.publish(
                    listing: listing,
                    selectedTenant: selectedTenant,
                    originalTenantId: originalTenantId,
                    context: viewContext,
                    existingImageURLs: listing.existingImageURLs
                ) { updated in
                    listing = updated
                    originalTenantId = updated.tenantId
                }
            }
            .disabled(viewModel.isPublishing)
        }
    }
    
    
}
