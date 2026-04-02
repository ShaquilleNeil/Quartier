//
//  AssignTenantSection.swift
//  Quartier
//

import SwiftUI

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
        firebase.fetchListingTenantBinding(listingId: listingId) { exists, uid, email in
            if showSpinner { isLoadingRemote = false }
            listingExistsOnFirebase = exists
            boundTenantUserId = uid
            boundTenantEmail = email
        }
    }

    private func loadTenantsFromFirebase() {
        isLoadingTenants = true
        tenantsLoadError = nil
        firebase.fetchTenantsForLandlordPicker { result in
            isLoadingTenants = false
            switch result {
            case .success(let items):
                tenants = items
            case .failure(let err):
                tenants = []
                tenantsLoadError = err.localizedDescription
            }
        }
    }

    private func assign() {
        errorMessage = nil
        isBusy = true
        firebase.assignTenantToListing(listingId: listingId, tenantUserId: selectedTenantId) { result in
            isBusy = false
            switch result {
            case .success:
                isRented = true
                selectedTenantId = ""
                loadTenantsFromFirebase()
                refreshRemoteBinding(showSpinner: false)
                onChange()
            case .failure(let err):
                errorMessage = err.localizedDescription
            }
        }
    }

    private func removeTenant() {
        errorMessage = nil
        isBusy = true
        firebase.removeTenantFromListing(listingId: listingId) { result in
            isBusy = false
            switch result {
            case .success:
                isRented = false
                boundTenantUserId = nil
                boundTenantEmail = nil
                loadTenantsFromFirebase()
                refreshRemoteBinding(showSpinner: false)
                onChange()
            case .failure(let err):
                errorMessage = err.localizedDescription
            }
        }
    }
}
