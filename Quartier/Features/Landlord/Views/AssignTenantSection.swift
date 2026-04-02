import SwiftUI
import FirebaseFirestore

struct FirebaseTenantPickerItem: Identifiable, Hashable {
    let id: String
    let email: String
    let displayName: String

    var pickerLabel: String {
        if displayName.isEmpty { return email }
        return "\(displayName) — \(email)"
    }
}

struct AssignTenantSection: View {
    @EnvironmentObject private var firebase: FirebaseManager

    let listingId: String
    @Binding var isRented: Bool
    var onChange: () -> Void

    @State private var selectedTenantId = ""
    @State private var isBusy = false
    @State private var errorMessage: String?

    @State private var isLoadingRemote = true
    @State private var listingExistsOnFirebase = false
    @State private var boundTenantUserId: String?
    @State private var boundTenantEmail: String?

    @State private var tenants: [FirebaseTenantPickerItem] = []
    @State private var isLoadingTenants = false
    @State private var tenantsLoadError: String?

    private var hasLinkedTenant: Bool {
        guard let u = boundTenantUserId, !u.isEmpty else { return false }
        return true
    }

    private var canAssign: Bool {
        listingExistsOnFirebase
            && !hasLinkedTenant
            && !selectedTenantId.isEmpty
            && !isBusy
    }

    private var canEndTenancy: Bool {
        listingExistsOnFirebase && (hasLinkedTenant || isRented) && !isBusy
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tenant")
                .font(.headline)

            if isLoadingRemote {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Loading binding…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                if !listingExistsOnFirebase {
                    Text("This listing is not on Firebase yet. Publish or save to sync, then you can bind a tenant account.")
                        .font(.caption)
                        .foregroundStyle(.orange)
                } else if hasLinkedTenant {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Bound tenant")
                            .font(.subheadline.weight(.semibold))
                        if let em = boundTenantEmail, !em.isEmpty {
                            Text(em)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Linked (tenant email unavailable)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                } else {
                    Text("Select a registered tenant from your Firebase users (role: tenant).")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if isLoadingTenants {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("Loading tenant list…")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else if let tenantsLoadError {
                        Text(tenantsLoadError)
                            .font(.caption)
                            .foregroundStyle(.red)
                    } else if tenants.isEmpty {
                        Text("No tenant users found. Add documents under `users` with field `role` = \"tenant\" and a non-empty `email`.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Tenant", selection: $selectedTenantId) {
                            Text("Choose a tenant…").tag("")
                            ForEach(tenants) { t in
                                Text(t.pickerLabel).tag(t.id)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                }
            }

            HStack(spacing: 12) {
                Button {
                    assign()
                } label: {
                    if isBusy {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Bind tenant")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canAssign)

                Button(role: .destructive) {
                    removeTenant()
                } label: {
                    if isBusy {
                        ProgressView()
                    } else {
                        Text("End binding")
                    }
                }
                .buttonStyle(.bordered)
                .disabled(!canEndTenancy)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding()
        .background(Color(.systemGray5).opacity(0.5))
        .cornerRadius(16)
        .onAppear {
            refreshRemoteBinding(showSpinner: true)
            loadTenantsFromFirebase()
        }
    }

    private func refreshRemoteBinding(showSpinner: Bool) {
        if showSpinner { isLoadingRemote = true }
        Firestore.firestore().collection("listings").document(listingId).getDocument { snapshot, _ in
            let tid = snapshot?.data()?["currentTenantUserId"] as? String
            
            if let tenantId = tid, !tenantId.isEmpty {
                Firestore.firestore().collection("users").document(tenantId).getDocument { userSnap, _ in
                    DispatchQueue.main.async {
                        if showSpinner { isLoadingRemote = false }
                        listingExistsOnFirebase = snapshot?.exists ?? false
                        boundTenantUserId = tenantId
                        boundTenantEmail = userSnap?.data()?["email"] as? String
                    }
                }
            } else {
                DispatchQueue.main.async {
                    if showSpinner { isLoadingRemote = false }
                    listingExistsOnFirebase = snapshot?.exists ?? false
                    boundTenantUserId = nil
                    boundTenantEmail = nil
                }
            }
        }
    }

    private func loadTenantsFromFirebase() {
        isLoadingTenants = true
        tenantsLoadError = nil
        Firestore.firestore().collection("users").whereField("role", isEqualTo: "tenant").getDocuments { snapshot, error in
            DispatchQueue.main.async {
                isLoadingTenants = false
                if let error = error {
                    tenantsLoadError = error.localizedDescription
                    tenants = []
                    return
                }
                tenants = snapshot?.documents.compactMap { doc -> FirebaseTenantPickerItem? in
                    let data = doc.data()
                    let email = data["email"] as? String ?? ""
                    if email.isEmpty { return nil }
                    let name = data["displayName"] as? String ?? ""
                    return FirebaseTenantPickerItem(id: doc.documentID, email: email, displayName: name)
                } ?? []
            }
        }
    }

    private func assign() {
        errorMessage = nil
        isBusy = true
        
        let db = Firestore.firestore()
        let batch = db.batch()
        
        let listingRef = db.collection("listings").document(listingId)
        let tenantRef = db.collection("users").document(selectedTenantId)
        
        batch.updateData(["isRented": true, "currentTenantUserId": selectedTenantId, "updatedAt": FieldValue.serverTimestamp()], forDocument: listingRef)
        batch.updateData(["isRenting": true, "rentedListingId": listingId], forDocument: tenantRef)
        
        batch.commit { error in
            DispatchQueue.main.async {
                isBusy = false
                if let error = error {
                    errorMessage = error.localizedDescription
                } else {
                    isRented = true
                    selectedTenantId = ""
                    loadTenantsFromFirebase()
                    refreshRemoteBinding(showSpinner: false)
                    onChange()
                }
            }
        }
    }

    private func removeTenant() {
        errorMessage = nil
        isBusy = true
        
        guard let tid = boundTenantUserId, !tid.isEmpty else {
            isBusy = false
            return
        }
        
        let db = Firestore.firestore()
        let batch = db.batch()
        
        let listingRef = db.collection("listings").document(listingId)
        let tenantRef = db.collection("users").document(tid)
        
        batch.updateData(["isRented": false, "currentTenantUserId": FieldValue.delete(), "updatedAt": FieldValue.serverTimestamp()], forDocument: listingRef)
        batch.updateData(["isRenting": false, "rentedListingId": FieldValue.delete()], forDocument: tenantRef)
        
        batch.commit { error in
            DispatchQueue.main.async {
                isBusy = false
                if let error = error {
                    errorMessage = error.localizedDescription
                } else {
                    isRented = false
                    boundTenantUserId = nil
                    boundTenantEmail = nil
                    loadTenantsFromFirebase()
                    refreshRemoteBinding(showSpinner: false)
                    onChange()
                }
            }
        }
    }
}
