//
//  MaintenanceListView.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-04-09.
//

import SwiftUI
import SDWebImageSwiftUI

struct MaintenanceListView: View {
    let listingId: String

    @EnvironmentObject private var firebase: FirebaseManager
    @State private var requests: [MaintenanceRequest] = []
    @State private var searchText: String = ""

    private var filtered: [MaintenanceRequest] {
        if searchText.isEmpty { return requests }
        return requests.filter {
            $0.description.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if requests.isEmpty {
                    Text("No maintenance requests yet.")
                        .foregroundStyle(.secondary)
                        .padding(.top, 40)
                } else {
                    ForEach(filtered) { request in
                        NavigationLink(destination: MaintenanceDetailView(
                            request: request,
                            listingId: listingId,
                            onResolved: { loadRequests() }
                        )) {
                            MaintenanceCard(request: request)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .searchable(text: $searchText, prompt: "Search requests")
        .navigationTitle("Maintenance")
        .background(Color(.systemGray6))
        .onAppear { loadRequests() }
    }

    private func loadRequests() {
        firebase.fetchMaintenanceRequests(listingId: listingId) { fetched in
            DispatchQueue.main.async {
                requests = fetched
            }
        }
    }
}

// MARK: - MaintenanceCard

struct MaintenanceCard: View {
    let request: MaintenanceRequest

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: request.date)
    }

    var body: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 12)
                .fill(request.status == .pending ? Color.orange.opacity(0.12) : Color.green.opacity(0.12))
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: request.status == .pending ? "wrench.fill" : "checkmark.circle.fill")
                        .foregroundStyle(request.status == .pending ? .orange : .green)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(request.description)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text(formattedDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            StatusBadge(status: request.status)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemBackground)))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - StatusBadge

struct StatusBadge: View {
    let status: MaintenanceStatus

    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(status == .pending ? Color.orange.opacity(0.15) : Color.green.opacity(0.15))
            .foregroundStyle(status == .pending ? .orange : .green)
            .clipShape(Capsule())
    }
}

// MARK: - MaintenanceDetailView

struct MaintenanceDetailView: View {
    let request: MaintenanceRequest
    let listingId: String
    let onResolved: () -> Void

    @EnvironmentObject private var firebase: FirebaseManager
    @Environment(\.dismiss) var dismiss
    @State private var isResolving = false
    @State private var resolveError: String? = nil

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateStyle = .long
        f.timeStyle = .short
        return f.string(from: request.date)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // Status + Date
                HStack {
                    StatusBadge(status: request.status)
                    Spacer()
                    Text(formattedDate)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Description
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.headline)
                    Text(request.description)
                        .font(.body)
                        .foregroundStyle(.primary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemBackground)))

                // Photos
                if !request.photoURLs.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Photos")
                            .font(.headline)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(request.photoURLs, id: \.self) { urlString in
                                    WebImage(url: URL(string: urlString))
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 140, height: 140)
                                        .clipped()
                                        .cornerRadius(12)
                                }
                            }
                        }
                    }
                }

                // Error
                if let error = resolveError {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }

                // Resolve Button
                if request.status == .pending {
                    Button {
                        isResolving = true
                        firebase.resolveMaintenanceRequest(
                            listingId: listingId,
                            requestId: request.id.uuidString
                        ) { error in
                            DispatchQueue.main.async {
                                isResolving = false
                                if let error = error {
                                    resolveError = error.localizedDescription
                                } else {
                                    onResolved()
                                    dismiss()
                                }
                            }
                        }
                    } label: {
                        Text(isResolving ? "Resolving..." : "Mark as Resolved")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundStyle(.white)
                            .cornerRadius(12)
                    }
                    .disabled(isResolving)
                }
            }
            .padding()
        }
        .navigationTitle("Request Detail")
        .background(Color(.systemGray6))
    }
}
