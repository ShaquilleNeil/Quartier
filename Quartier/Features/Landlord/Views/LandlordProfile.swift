//
//  LandlordProfile.swift
//  Quartier
//

import SwiftUI
import FirebaseAuth
import UniformTypeIdentifiers
internal import FirebaseFirestoreInternal
import SDWebImageSwiftUI

struct LandlordProfile: View {
    var landlordId: String = ""
    
    @State private var landlordUser: User? = nil
    @State var publicView: Bool?
    
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var firebaseManager: FirebaseManager

    @State private var profileEdit = false
    @State private var showDocumentPicker = false
    @State private var selectedDocument: DocumentType?
    @State private var showOptions = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

               
                    ProfileHeaderView(
                        userEmail: publicView == true ? (landlordUser?.email ?? "") : (authService.userSession?.email ?? ""),
                        profileURL: publicView == true ? landlordUser?.profilePic : firebaseManager.currentUser?.profilePic,
                        name: publicView == true ? (landlordUser?.name ?? "Landlord") : (firebaseManager.currentUser?.name ?? "User")
                    )
                    if(publicView == false){
                        Button {
                            profileEdit = true
                        } label: {
                            Text("Edit Profile")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .navigationDestination(isPresented: $profileEdit) {
                            ProfileEditView()
                        }
                    }
        
                    LandlordDocumentsSection(
                        isUploaded: isUploaded,
                        onSelect: { type in
                            selectedDocument = type
                            if isUploaded(type) { showOptions = true } else { showDocumentPicker = true }
                        },
                        publicView: publicView,
                        landlordId: publicView == true ? landlordId : (firebaseManager.currentUser?.id ?? "")
                    )

                    if(publicView == false){
                        Button("Log Out") {
                            authService.signOut()
                        }
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }.padding(.horizontal)
        
            }
            .onAppear {
                firebaseManager.startListeningToDocuments()
                if publicView == true {
                    firebaseManager.fetchUser(uid: landlordId) { user in
                        landlordUser = user
                    }
                } else {
                    if let uid = authService.userSession?.uid {
                        firebaseManager.fetchUser(uid: uid) { _ in }
                    }
                }
            }
            .onDisappear {
                firebaseManager.documentsListener?.remove()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .fileImporter(
                isPresented: $showDocumentPicker,
                allowedContentTypes: [.pdf, .image],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let fileURL = urls.first,
                          let type = selectedDocument else { return }

                    firebaseManager.uploadDocument(fileURL: fileURL, type: type)

                case .failure(let error):
                    print("Error:", error)
                }
            }
            .confirmationDialog("Document Options", isPresented: $showOptions) {
                Button("Replace") {
                    showDocumentPicker = true
                }
                Button("Delete", role: .destructive) {
                    guard let type = selectedDocument else { return }
                    firebaseManager.deleteDocument(type: type)
                }
            }
        }
    }

    private func isUploaded(_ type: DocumentType) -> Bool {
        firebaseManager.userDocuments.contains {
            $0.type == type.rawValue
        }
    }
}

private struct LandlordDocumentsSection: View {
    let isUploaded: (DocumentType) -> Bool
    let onSelect: (DocumentType) -> Void
    var publicView: Bool?
    let landlordId: String  // ← needed to fetch listings for a specific landlord

    @EnvironmentObject private var firebaseManager: FirebaseManager

    private func status(for type: DocumentType) -> DocumentStatus {
        isUploaded(type) ? .pending : .none
    }

    private var completedCount: Int {
        DocumentType.allCases.filter { isUploaded($0) }.count
    }

    private var landlordListings: [Listing] {
        firebaseManager.firebaseListings.filter { $0.landLordId == landlordId }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            if publicView == false {
                HStack {
                    Text("Verification Documents")
                        .font(.headline)
                    Spacer()
                    Text("\(completedCount)/3 Completed")
                        .foregroundColor(.blue)
                        .font(.subheadline)
                }

                DocumentRow(title: "Government ID", status: status(for: .id)) {
                    onSelect(.id)
                }
                DocumentRow(title: "Proof of Ownership", status: status(for: .tax)) {
                    onSelect(.tax)
                }
                DocumentRow(title: "Insurance Certificate", status: status(for: .paystub)) {
                    onSelect(.paystub)
                }

            } else {
                // MARK: Public view — landlord's listings
                Text("Listings")
                    .font(.headline)

                if landlordListings.isEmpty {
                    Text("No listings available.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ScrollView {
                        
                        ForEach(landlordListings) { listing in
                            NavigationLink(destination: ApartmentDetailView(listing: listing)) {
                                RemoteListingCard(listing: listing)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                }
                
            }
        }
        .onAppear {
            firebaseManager.fetchListingsLandlordPublic(forLandlord: landlordId)
        }
    }
}

struct RemoteListingCard: View {
    let listing: Listing

    var body: some View {
        HStack(spacing: 14) {
            if let firstURL = listing.existingImageURLs.first,
               let url = URL(string: firstURL) {
                WebImage(url: url)
                    .resizable()
                    .indicator(.activity)
                    .transition(.fade(duration: 0.25))
                    .scaledToFill()
                    .frame(width: 85, height: 85)
                    .clipped()
                    .cornerRadius(14)
            } else {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 85, height: 85)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(.gray)
                    )
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(listing.address.isEmpty ? "Untitled Listing" : listing.address)
                        .font(.system(size: 17, weight: .semibold))
                        .lineLimit(1)
                    Spacer()
                    Text(listing.status.rawValue.capitalized)
                        .font(.system(size: 11, weight: .bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(statusColor.opacity(0.18)))
                }
                Text(formattedPrice + " • \(listing.bedrooms) bds • \(listing.bathrooms) ba")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 22).fill(.ultraThinMaterial))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(statusColor.opacity(0.25), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 6)
    }

    private var statusColor: Color {
        switch listing.status.rawValue.lowercased() {
        case "published": return .green
        case "rented": return .blue
        default: return .gray
        }
    }

    private var formattedPrice: String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "CAD"
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: listing.price)) ?? "$\(listing.price)"
    }
}

private struct DocumentRow: View {
    let title: String
    let status: DocumentStatus
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "doc.fill")
                    )

                VStack(alignment: .leading) {
                    Text(title)
                        .font(.headline)

                    Text(status.displayText)
                        .font(.subheadline)
                        .foregroundColor(status.color)
                }

                Spacer()

                Circle()
                    .fill(status.color)
                    .frame(width: 24, height: 24)
                    .overlay {
                        Image(systemName: status.icon)
                            .foregroundStyle(.white)
                    }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
            )
            .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }
}


    

#Preview {
    let firebase = FirebaseManager()
    let auth = AuthService(firebase: firebase)

    return LandlordProfile(publicView: true)
        .environmentObject(firebase)
        .environmentObject(auth)
}
