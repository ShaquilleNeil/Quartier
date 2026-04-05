//
//  LandlordProfile.swift
//  Quartier
//

import SwiftUI
import FirebaseAuth
import UniformTypeIdentifiers
internal import FirebaseFirestoreInternal

struct LandlordProfile: View {
    
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
                        userEmail: authService.userSession?.email ?? "",
                        profileURL: firebaseManager.currentUser?.profilePic,
                        name: firebaseManager.currentUser?.name ?? "User"
                    )

                   
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

        
                    LandlordDocumentsSection(isUploaded: isUploaded) { type in
                        selectedDocument = type
                        
                        if isUploaded(type) {
                            showOptions = true
                        } else {
                            showDocumentPicker = true
                        }
                    }

                
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
                .padding()
            }
            .onAppear {
                firebaseManager.startListeningToDocuments()

                if let uid = authService.userSession?.uid {
                    firebaseManager.fetchUser(uid: uid) { _ in }
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

    private func status(for type: DocumentType) -> DocumentStatus {
        isUploaded(type) ? .pending : .none
    }

    private var completedCount: Int {
        DocumentType.allCases.filter { isUploaded($0) }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            HStack {
                Text("Verification Documents")
                    .font(.headline)

                Spacer()

                Text("\(completedCount)/3 Completed")
                    .foregroundColor(.blue)
                    .font(.subheadline)
            }

            DocumentRow(
                title: "Government ID",
                status: status(for: .id)
            ) {
                onSelect(.id)
            }

            DocumentRow(
                title: "Proof of Ownership",
                status: status(for: .tax) // reuse type
            ) {
                onSelect(.tax)
            }

            DocumentRow(
                title: "Insurance Certificate",
                status: status(for: .paystub) // reuse type
            ) {
                onSelect(.paystub)
            }
        }
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

    return LandlordProfile()
        .environmentObject(firebase)
        .environmentObject(auth)
}
