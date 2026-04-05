//
//  TenantRentedDash.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-02-26.
//
import SwiftUI
import SDWebImageSwiftUI
import FirebaseFirestore

struct TenantRentedDash: View {
    @EnvironmentObject private var auth: AuthService
    @EnvironmentObject private var firebase: FirebaseManager
    @State private var listener: ListenerRegistration?
    @State private var listing: Listing?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                HeaderView(
                    title: headerTitle,
                    subtitle: subtitleLine
                )

                RentStatusCard(
                    price: listing?.price ?? 0,
                    address: listing?.address ?? auth.rentedAddress ?? "Your rental",
                    imageURL: listing?.existingImageURLs.first
                )

                QuickActionsGrid()

                UpdatesSection()
            }
            .padding()
        }
        .background(Color(.systemGray6))
        .onAppear {
           loadListing()
        }
        .onChange(of: firebase.currentUser?.apartmentId) { _, newValue in
            guard let id = newValue, !id.isEmpty else { return }
            loadListing()
        }
        .onDisappear {
            listener?.remove()
        }
        .onChange(of: auth.rentedListingId) { _, _ in
            loadListing()
        }
    }

    private var headerTitle: String {
        if let a = listing?.address, !a.isEmpty { return a }
        if let a = auth.rentedAddress, !a.isEmpty { return a }
        return "Your rental"
    }

    private var subtitleLine: String {
        if let b = listing?.listingName, !b.isEmpty {
            return "Building \(b)"
        }
        return "Quartier tenant"
    }

    private func loadListing() {
        guard let id = auth.rentedListingId, !id.isEmpty else {
            listing = nil
            return
        }

        listener?.remove()

        listener = firebase.listenToListing(listingId: id) { updated in
            self.listing = updated
        }
    }
}

private struct HeaderView: View {
    let title: String
    let subtitle: String

    var body: some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 48, height: 48)
                .foregroundColor(.gray)

            VStack(alignment: .leading, spacing: 2) {
                Text("QUARTIER")
                    .font(.caption)
                    .foregroundColor(.gray)

                Text(title)
                    .font(.headline)
                    .lineLimit(2)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "bell.fill")
                .font(.title3)
        }
    }
}

private struct RentStatusCard: View {
    let price: Double
    let address: String
    let imageURL: String?

    @State private var isPresentingPayRent = false

    private var monthYear: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: Date())
    }

    private var priceFormatted: String {
        guard price > 0 else { return "—" }
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "CAD"
        return f.string(from: NSNumber(value: price)) ?? "$\(price)"
    }

    var body: some View {
        VStack(spacing: 0) {

            Group {
                if let s = imageURL, let url = URL(string: s) {
                    WebImage(url: url)
                        .resizable()
                        .indicator(.activity)
                        .scaledToFill()
                } else {
                    Image("apartment1")
                        .resizable()
                        .scaledToFill()
                }
            }
            .frame(height: 180)
            .clipped()

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Rent Status")
                            .font(.headline)

                        Text(monthYear)
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    VStack(alignment: .trailing) {
                        Text(priceFormatted)
                            .font(.title2.bold())
                            .foregroundColor(.red)

                        Text("Monthly rent")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }

                Text(address)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                Button {
                    self.isPresentingPayRent = true
                } label: {
                    Text("Pay Now")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .padding()
        }
        .background(.white)
        .cornerRadius(16)
        .shadow(radius: 4)
        .sheet(isPresented: $isPresentingPayRent) {
            Text("Pay Rent View")
        }
    }
}

private struct QuickActionsGrid: View {

    let items = [
        ("Lease", "doc.text.fill"),
        ("Emergency", "exclamationmark.triangle.fill"),
        ("Maintenance", "wrench.fill"),
        ("Upcoming", "calendar")
    ]

    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("QUICK ACTIONS")
                .font(.caption)
                .foregroundColor(.gray)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(items, id: \.0) { item in
                    QuickActionCard(title: item.0, icon: item.1)
                }
            }
        }
    }
}

private struct QuickActionCard: View {
    let title: String
    let icon: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .frame(width: 56, height: 56)
                .background(Color(.systemGray5))
                .clipShape(Circle())

            Text(title)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
        .background(.white)
        .cornerRadius(16)
    }
}

private struct UpdatesSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Building Updates")
                    .font(.title3.bold())

                Spacer()

                Text("View All")
                    .foregroundColor(.red)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    UpdateCard()
                    UpdateCard()
                }
            }
        }
    }
}

private struct UpdateCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ELEVATOR SERVICE")
                .font(.caption)
                .foregroundColor(.gray)

            Text("Elevator B Maintenance")
                .font(.headline)

            Text("Regular inspection scheduled for tomorrow…")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .frame(width: 260)
        .background(.white)
        .cornerRadius(16)
    }
}
