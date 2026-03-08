//
//  LandlordListings.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-01-29.
//

import SwiftUI
import CoreData

struct LandlordListings: View {
    var body: some View {
        MyListingsView()
    }
}

private enum ListingDisplayStatus: String, CaseIterable {
    case published = "Published"
    case draft = "Draft"
    case rented = "Rented"
}

private struct ListingDisplay: Identifiable {
    let id: UUID
    let title: String
    let cityLine: String
    let priceLine: String
    let views: Int
    let leads: Int
    let status: ListingDisplayStatus
    let imageName: String
}

private struct MyListingsView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \LDListing.updatedAt, ascending: false)],
        animation: .default
    )
    private var ldListings: FetchedResults<LDListing>

    private let primary = Color(red: 0.17, green: 0.55, blue: 0.93)

    @State private var searchText: String = ""
    @State private var selectedFilter: Filter = .all
    @State private var showListingForm = false
    @State private var listingToEdit: LDListing?

    enum Filter: String, CaseIterable {
        case all = "All"
        case published = "Published"
        case drafts = "Drafts"
        case rented = "Rented"
    }

    private static func statusFromLD(_ raw: String?) -> ListingDisplayStatus {
        switch raw?.lowercased() {
        case "active": return .published
        case "draft": return .draft
        case "rented", "inactive": return .rented
        default: return .published
        }
    }

    private var displayListings: [ListingDisplay] {
        ldListings.compactMap { ld -> ListingDisplay? in
            guard let id = ld.id else { return nil }
            let beds = Int(ld.beds)
            let baths = ld.baths
            let price = ld.priceMonthly
            let priceLine = String(format: "$%.0f/mo • %d bds • %.0f ba", price, beds, baths)
            return ListingDisplay(
                id: id,
                title: ld.title ?? "Untitled",
                cityLine: ld.cityLine ?? "",
                priceLine: priceLine,
                views: Int(ld.viewsCount),
                leads: Int(ld.leadsCount),
                status: Self.statusFromLD(ld.status),
                imageName: ld.coverImageName ?? "building.2.fill"
            )
        }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {

                    // Header
                    HStack {
                        Circle()
                            .fill(primary.opacity(0.15))
                            .overlay(Image(systemName: "person.fill").foregroundStyle(primary))
                            .frame(width: 40, height: 40)

                        Spacer()

                        Button {} label: {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .padding(10)
                                .background(Circle().fill(Color.primary.opacity(0.06)))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)

                    Text("My Listings")
                        .font(.system(size: 32, weight: .bold))
                        .padding(.horizontal, 16)

                    // Search
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Search listings", text: $searchText)
                            .textInputAutocapitalization(.never)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 14).fill(cardBg))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(border, lineWidth: 1))
                    .padding(.horizontal, 16)

                    // Filter Chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(Filter.allCases, id: \.self) { f in
                                Button {
                                    selectedFilter = f
                                } label: {
                                    Text(f.rawValue)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(selectedFilter == f ? .white : .primary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            Capsule().fill(selectedFilter == f ? primary : chipBg)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    // Cards
                    VStack(spacing: 12) {
                        if filteredListings.isEmpty {
                            emptyState
                        } else {
                            ForEach(filteredListings) { item in
                                Button {
                                    listingToEdit = ldListings.first { $0.id == item.id }
                                    showListingForm = true
                                } label: {
                                    listingCard(item)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button {
                                        listingToEdit = ldListings.first { $0.id == item.id }
                                        showListingForm = true
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    Button(role: .destructive) {
                                        deleteListing(id: item.id)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    Spacer(minLength: 90)
                }
                .padding(.bottom, 14)
            }

            // FAB
            Button {
                listingToEdit = nil
                showListingForm = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(Circle().fill(primary))
                    .shadow(color: primary.opacity(0.25), radius: 12, x: 0, y: 6)
            }
            .padding(.trailing, 18)
            .padding(.bottom, 18)
        }
        .sheet(isPresented: $showListingForm) {
            NewListingView(existingListing: listingToEdit)
                .environment(\.managedObjectContext, viewContext)
        }
    }

    private var filteredListings: [ListingDisplay] {
        var base: [ListingDisplay]
        switch selectedFilter {
        case .all: base = displayListings
        case .published: base = displayListings.filter { $0.status == .published }
        case .drafts: base = displayListings.filter { $0.status == .draft }
        case .rented: base = displayListings.filter { $0.status == .rented }
        }
        let key = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if key.isEmpty { return base }
        return base.filter { $0.title.lowercased().contains(key) || $0.cityLine.lowercased().contains(key) }
    }

    private func deleteListing(id: UUID) {
        guard let listing = ldListings.first(where: { $0.id == id }) else { return }
        viewContext.delete(listing)
        try? viewContext.save()
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "building.2.crop.circle")
                .font(.system(size: 48))
                .foregroundStyle(primary.opacity(0.5))
            Text("No listings yet")
                .font(.system(size: 18, weight: .semibold))
            Text("Tap + to add your first listing")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func listingCard(_ item: ListingDisplay) -> some View {
        let isDraft = item.status == .draft
        let isRented = item.status == .rented

        return HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 14)
                .fill(primary.opacity(0.10))
                .frame(width: 90, height: 90)
                .overlay(
                    Image(systemName: item.imageName)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(primary)
                        .opacity(isRented ? 0.35 : 1)
                )

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(item.title)
                        .font(.system(size: 16, weight: .bold))
                        .lineLimit(1)
                    Spacer()
                    statusBadge(item.status)
                }

                Text(item.cityLine)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text(item.priceLine)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)

                HStack(spacing: 12) {
                    HStack(spacing: 6) {
                        Image(systemName: "eye")
                        Text("\(item.views)")
                    }
                    HStack(spacing: 6) {
                        Image(systemName: "person.2")
                        Text("\(item.leads)")
                    }
                }
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .opacity(isDraft ? 0.45 : 1)
            }

            Spacer()
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(cardBg))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(border, lineWidth: 1))
        .opacity(isRented ? 0.75 : 1)
    }

    private func statusBadge(_ s: ListingDisplayStatus) -> some View {
        let (text, bg, fg): (String, Color, Color) = {
            switch s {
            case .published: return ("Published", Color.green.opacity(0.15), .green)
            case .draft:     return ("Draft",     Color.orange.opacity(0.15), .orange)
            case .rented:    return ("Rented",    Color.gray.opacity(0.18), .secondary)
            }
        }()

        return Text(text)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(fg)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(bg))
    }

    // Theme helpers
    private var bg: Color {
        Color(uiColor: UIColor { tc in
            tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.06, green: 0.10, blue: 0.13, alpha: 1.0)
            : UIColor(red: 0.96, green: 0.97, blue: 0.97, alpha: 1.0)
        })
    }

    private var cardBg: Color { Color(uiColor: .secondarySystemBackground) }
    private var chipBg: Color { Color(uiColor: .tertiarySystemBackground) }
    private var border: Color { Color.primary.opacity(0.08) }
}

#Preview {
    LandlordListings()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
