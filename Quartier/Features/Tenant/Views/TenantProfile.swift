//
//  TenantProfile.swift
//  Quartier
//

import SwiftUI
import FirebaseAuth
import UniformTypeIdentifiers

struct TenantProfile: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var firebaseManager: FirebaseManager

    @State private var showingPreferences = false
    @State private var showDocumentPicker = false
    @State private var selectedDocument: DocumentType?
    @State private var uploadedDocs: [DocumentType: Bool] = [:]
    @State private var showOptions = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    ProfileHeaderView(
                        userEmail: authService.userSession?.email ?? "Tenant User"
                    )

                    Button(action: {}) {
                        Text("Edit Profile")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    SearchPreferencesCard {
                        showingPreferences = true
                    }

                    DocumentsSection(uploadedDocs: uploadedDocs) { type in
                        selectedDocument = type

                        if uploadedDocs[type] == true {
                            showOptions = true
                        } else {
                            showDocumentPicker = true
                        }
                    }

                    Button(action: {
                        authService.signOut()
                    }) {
                        Text("Logout")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 200, height: 50)
                            .background(Color.red)
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingPreferences) {
                TenantPreferencesView()
            }
            .fileImporter(
                isPresented: $showDocumentPicker,
                allowedContentTypes: [.pdf, .image],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let fileURL = urls.first else { return }
                    guard let type = selectedDocument else { return }

                    print("Selected:", fileURL)

                    firebaseManager.uploadDocument(fileURL: fileURL, type: type)

                    // No listener version: update local UI immediately
                    uploadedDocs[type] = true

                case .failure(let error):
                    print("Error:", error)
                }
            }
            .confirmationDialog("Document Options", isPresented: $showOptions) {
                Button("View") {
                    print("View current document")
                }

                Button("Replace") {
                    showDocumentPicker = true
                }

                Button("Delete", role: .destructive) {
                    guard let type = selectedDocument else { return }

                    firebaseManager.deleteDocument(type: type)

                    // No listener version: update local UI immediately
                    uploadedDocs[type] = false
                }
            }
        }
    }
}

//////////////////////////////////////////////////////////////////
// MARK: Profile Header
//////////////////////////////////////////////////////////////////

private struct ProfileHeaderView: View {
    let userEmail: String

    var body: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 120, height: 120)
                    .overlay(
                        Image(systemName: "person.fill")
                            .resizable()
                            .scaledToFit()
                            .padding(30)
                            .foregroundColor(.gray)
                    )

                Circle()
                    .fill(Color.blue)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.white)
                            .font(.caption)
                    )
            }

            Text(userEmail)
                .font(.title3.bold())

            Text("Verified Tenant • Member since 2026")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                Badge(text: "ID Verified")
                Badge(text: "Income Verified")
            }
        }
    }
}

private struct Badge: View {
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.blue)

            Text(text)
                .font(.caption)
                .foregroundColor(.blue)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.blue.opacity(0.1))
        .clipShape(Capsule())
    }
}

//////////////////////////////////////////////////////////////////
// MARK: Search Preferences Card
//////////////////////////////////////////////////////////////////

private struct SearchPreferencesCard: View {
    let onUpdate: () -> Void

    var body: some View {
        Button(action: onUpdate) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Housing Preferences")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("Edit your budget, location, and needs")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "slider.horizontal.3")
                    .font(.title2)
                    .foregroundColor(.blue)
                    .padding(10)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
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

//////////////////////////////////////////////////////////////////
// MARK: Documents Section
//////////////////////////////////////////////////////////////////

private struct DocumentsSection: View {
    let uploadedDocs: [DocumentType: Bool]
    let onSelect: (DocumentType) -> Void

    private func status(for type: DocumentType) -> DocumentStatus {
        if uploadedDocs[type] == true {
            return .pending
        } else {
            return .none
        }
    }

    private var completedCount: Int {
        uploadedDocs.values.filter { $0 }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("My Documents")
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
                title: "Recent Paystubs",
                status: status(for: .paystub)
            ) {
                onSelect(.paystub)
            }

            DocumentRow(
                title: "Tax Returns (W2)",
                status: status(for: .tax)
            ) {
                onSelect(.tax)
            }
        }
    }
}

//////////////////////////////////////////////////////////////////
// MARK: Document Row
//////////////////////////////////////////////////////////////////

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

//////////////////////////////////////////////////////////////////
// MARK: Document Status UI Mapping
//////////////////////////////////////////////////////////////////

extension DocumentStatus {
    var displayText: String {
        switch self {
        case .none:
            return "Not yet uploaded"
        case .pending:
            return "Uploaded"
        case .verified:
            return "Verified"
        }
    }

    var color: Color {
        switch self {
        case .none:
            return .red
        case .pending:
            return .green
        case .verified:
            return .green
        }
    }

    var icon: String {
        switch self {
        case .none:
            return "xmark.circle"
        case .pending, .verified:
            return "checkmark"
        }
    }
}

#Preview {
    let firebase = FirebaseManager()
    let auth = AuthService(firebase: firebase)

    return TenantProfile()
        .environmentObject(firebase)
        .environmentObject(auth)
}
