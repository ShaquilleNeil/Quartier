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
    @State private var attachedLeaseFileName: String? = nil
    @State private var fieldErrors: [String: String] = [:]

    // MARK: - Environment

    @EnvironmentObject var firebase: FirebaseManager
    @EnvironmentObject var coreDataManager: CoreDataManager
    @Environment(\.managedObjectContext) var viewContext
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = ListingFormViewModel()
    @State private var showDocumentPicker = false
    @State private var selectedDocument: DocumentType?
    

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
                    .background(Color.white)
                    .foregroundStyle(.black)
                if let error = fieldErrors["name"] {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
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
            loadExistingLease()
            loadExistingImages()
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
    
    
    private func validate() -> Bool {
        var errors: [String: String] = [:]

        if listing.listingName.isEmpty {
            errors["name"] = "Name is required"
        }

        if listing.address.isEmpty {
            errors["address"] = "Address is required"
        }

        if listing.price.isZero {
            errors["price"] = "Price must be greater than 0"
        }

        if listing.bedrooms <= 0 {
            errors["bedrooms"] = "Must have at least 1 bedroom"
        }
        
        if listing.squareFeet == 0 {
            errors["squareFeet"] = "Square footage must be greater than 0"
        }

        if listing.bathrooms <= 0 {
            errors["bathrooms"] = "Must have at least 1 bathroom"
        }

        //commented for testing without lease
//        if selectedTenant != nil && attachedLeaseFileName == nil {
//            errors["lease"] = "A lease must be attached when a tenant is assigned"
//        }

        fieldErrors = errors
        return errors.isEmpty
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
                
                ForEach(listing.existingImageURLs.indices, id: \.self) { index in
                    let urlString = listing.existingImageURLs[index]
                    WebImage(url: URL(string: urlString))
                        .resizable()
                        .scaledToFill()
                        .frame(width: 110, height: 110)
                        .clipped()
                        .cornerRadius(12)
                        .onTapGesture {
                            setAsCoverExisting(index: index)
                        }
                }

               
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
    private func loadExistingImages() {
        guard isEditing else { return }
        Task {
            let urls = await firebase.downloadListingImages(forListingId: listing.id.uuidString)
            await MainActor.run {
                listing.existingImageURLs = urls.map { $0.absoluteString }
            }
        }
    }
    private func setAsCoverExisting(index: Int) {
        let selected = listing.existingImageURLs.remove(at: index)
        listing.existingImageURLs.insert(selected, at: 0)
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
        VStack {
            
            TextField("Monthly Price", value: $listing.price, format: .currency(code: "CAD"))
                .modifier(FormCard())
                .keyboardType(.decimalPad)
            if let error = fieldErrors["price"] {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
       
    }
    
    private var addressSection: some View {
        VStack{
            TextField("Address", text: $listing.address)
                .modifier(FormCard())
            
            if let error = fieldErrors["address"] {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }
    
    private var detailsSection: some View {
        VStack {
            HStack {
                StepperCard(title: "Bedrooms", value: $listing.bedrooms)
                StepperCard(title: "Bathrooms", value: $listing.bathrooms)
                
            }
            if let error = fieldErrors["bathrooms"]{
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            } else if let error = fieldErrors["bedrooms"] {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }
    
    private var squareFeetSection: some View {
        VStack {
            HStack {
                Text("Square Feet")
                Spacer()
                TextField("0", value: $listing.squareFeet, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
            }
            .modifier(FormCard())
            if let error = fieldErrors["squareFeet"] {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
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
                    
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                            .foregroundStyle(.blue)
                        
                        Text("Rent Due on Day:")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        
                        Spacer()
                        
                        Picker("Day", selection: $listing.rentDueDay) {
                            ForEach(1...31, id: \.self) { day in
                                Text("\(day)").tag(day)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.blue)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    Spacer()

                    if let fileName = attachedLeaseFileName {
                        leaseChip(fileName: fileName)
                    } else {
                        Button {
                            selectedDocument = .lease
                            showDocumentPicker = true
                        } label: {
                            Text("Attach Lease")
                                .foregroundStyle(.blue)
                        }
                        if let error = fieldErrors["lease"] {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                } else {
                    TenantSearchField(
                        selectedTenant: $selectedTenant,
                        tenants: tenants
                    )
                }
            }
            .fileImporter(
                isPresented: $showDocumentPicker,
                allowedContentTypes: [.pdf, .image],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let fileURL = urls.first,
                          let type = selectedDocument else { return }
                    
                    guard fileURL.startAccessingSecurityScopedResource() else { return }
                        defer { fileURL.stopAccessingSecurityScopedResource() }

                    attachedLeaseFileName = fileURL.lastPathComponent
                    firebase.uploadLeaseDocument(fileURL: fileURL, type: type, listingId: listing.id.uuidString)

                case .failure(let error):
                    print("Error:", error)
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
    
    private func leaseChip(fileName: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "doc.fill")
                .foregroundStyle(.blue)

            Text(fileName)
                .font(.subheadline)
                .lineLimit(1)
                .truncationMode(.middle)
                .foregroundStyle(.primary)

            Button {
                attachedLeaseFileName = nil
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.gray)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.blue.opacity(0.1))
        .clipShape(Capsule())
    }
    
    private func loadExistingLease() {
        guard isEditing else { return }
        Task {
            attachedLeaseFileName = await firebase.fetchLeaseFileName(listingId: listing.id.uuidString)
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
                if !validate() { return }
                    
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

