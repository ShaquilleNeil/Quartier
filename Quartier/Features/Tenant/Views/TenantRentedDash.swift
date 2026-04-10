//
//  TenantRentedDash.swift
//  Quartier
//

import SwiftUI
import SDWebImageSwiftUI
import FirebaseFirestore

struct TenantRentedDash: View {
    // MARK: - Environment & State Objects
    @EnvironmentObject private var auth: AuthService
    @EnvironmentObject private var firebase: FirebaseManager
    
    @StateObject private var chatVM = ChatViewModel()
    @StateObject private var scheduleVM = ScheduleViewModel()
    @StateObject private var noticeVM = NoticeViewModel()

    // MARK: - State Properties
    @State private var listener: ListenerRegistration?
    @State private var listing: Listing?

    // MARK: - Computed Properties
    private var upcomingEvent: ScheduleEvent? {
        let now = Date()
        return scheduleVM.events.first { $0.endAt >= now }
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

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // MARK: Header Section
                    HeaderView(
                        title: headerTitle,
                        subtitle: subtitleLine
                    )

                    // MARK: Rent Status Section
                    RentStatusCard(
                        price: listing?.price ?? 0,
                        address: listing?.address ?? auth.rentedAddress ?? "Your rental",
                        imageURL: listing?.existingImageURLs.first
                    )

                    // MARK: Quick Actions Section
                                        QuickActionsGrid(listingId: auth.rentedListingId ?? "")
                                            .environmentObject(scheduleVM)

                    // MARK: Upcoming Event Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Upcoming Event")
                            .font(.system(size: 18, weight: .bold))

                        if let event = upcomingEvent {
                            NavigationLink(destination: TenantSchedule()) {
                                HStack(spacing: 16) {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.orange.opacity(0.12))
                                        .frame(width: 48, height: 48)
                                        .overlay(Image(systemName: "calendar").foregroundStyle(.orange))

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(event.title)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundStyle(.primary)
                                            .lineLimit(1)
                                        Text(formatEventTime(event))
                                            .font(.system(size: 14))
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(.secondary)
                                }
                                .padding(14)
                                .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemBackground)))
                            }
                        } else {
                            Text("No upcoming events scheduled.")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(16)
                                .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemBackground)))
                        }
                    }

                    // MARK: Messages Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Messages")
                            .font(.system(size: 18, weight: .bold))

                        NavigationLink(destination: TenantMessages()) {
                            HStack(spacing: 16) {
                                Circle()
                                    .fill(Color.blue.opacity(0.12))
                                    .frame(width: 48, height: 48)
                                    .overlay(Image(systemName: "message.fill").foregroundStyle(.blue))

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Pending Messages")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(.primary)
                                    
                                    if chatVM.conversations.isEmpty {
                                        Text("No new messages")
                                            .font(.system(size: 14))
                                            .foregroundStyle(.secondary)
                                    } else {
                                        Text("You have \(chatVM.conversations.count) active chats")
                                            .font(.system(size: 14))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemBackground)))
                        }
                    }

                    // MARK: Announcements Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Announcements")
                                .font(.title3.bold())
                            Spacer()
                        }

                        if noticeVM.notices.isEmpty {
                            Text("No new announcements.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .padding(.top, 4)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(noticeVM.notices) { notice in
                                        NoticeCard(notice: notice)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.top, 8)
                }
                .padding()
            }
            .background(Color(.systemGray6))
        }
        // MARK: - Lifecycle Modifiers
        .onAppear {
            loadListing()
            chatVM.loadConversations(isLandlord: false)
            if let id = auth.rentedListingId {
                scheduleVM.loadTenantEvents(listingId: id)
                noticeVM.loadTenantNotices(listingId: id)
            }
        }
        .onChange(of: firebase.currentUser?.apartmentId) { _, newValue in
            guard let id = newValue, !id.isEmpty else { return }
            loadListing()
        }
        .onDisappear {
            listener?.remove()
            chatVM.cleanupConversations()
            scheduleVM.cleanup()
            noticeVM.cleanup()
        }
        .onChange(of: auth.rentedListingId) { _, id in
            loadListing()
            if let id = id {
                scheduleVM.loadTenantEvents(listingId: id)
                noticeVM.loadTenantNotices(listingId: id)
            }
        }
    }

    // MARK: - Helper Methods
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

        private func formatEventTime(_ event: ScheduleEvent) -> String {
            let formatter = DateFormatter()
            if event.allDay {
                formatter.dateStyle = .medium
                formatter.timeStyle = .none
                return "\(formatter.string(from: event.startAt)) • All day"
            } else {
                formatter.dateStyle = .medium
                formatter.timeStyle = .short
                return formatter.string(from: event.startAt)
            }
        }
}

// MARK: - Subviews
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
    let listingId: String
    @EnvironmentObject private var firebase: FirebaseManager
    @EnvironmentObject private var scheduleVM: ScheduleViewModel

    @State private var leaseURL: URL?
    @State private var showLease = false
    @State private var isLoadingLease = false
    @State private var showNoLeaseAlert = false

    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("QUICK ACTIONS")
                .font(.caption)
                .foregroundColor(.gray)

            LazyVGrid(columns: columns, spacing: 12) {
                // Lease button loads and presents the PDF
                Button {
                    Task {
                        isLoadingLease = true
                        leaseURL = try? await firebase.loadLeaseDocument(listingId: listingId)
                        isLoadingLease = false
                        if leaseURL != nil {
                            showLease = true
                        } else {
                            showNoLeaseAlert = true
                        }
                    }
                } label: {
                    if isLoadingLease {
                        QuickActionCard(title: "Loading...", icon: "hourglass")
                    } else {
                        QuickActionCard(title: "Lease", icon: "doc.text.fill")
                    }
                }
                .buttonStyle(.plain)
                .alert("No Lease Found", isPresented: $showNoLeaseAlert) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("Your landlord hasn't uploaded a lease yet.")
                }

                QuickActionCard(title: "Emergency", icon: "exclamationmark.triangle.fill")
                
                NavigationLink(destination: MaintenanceForm()) {
                    QuickActionCard(title: "Maintenance", icon: "wrench.fill")
                }
                .buttonStyle(.plain)

                NavigationLink(destination: TenantSchedule()) {
                    QuickActionCard(title: "Upcoming", icon: "calendar")
                        .overlay(alignment: .topTrailing) {
                            if scheduleVM.hasUnread {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 14, height: 14)
                                    .overlay(Circle().stroke(Color(.systemGray6), lineWidth: 2))
                                    .offset(x: -8, y: 8)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $showLease) {
            if let url = leaseURL {
                SafariView(url: url) // or PDFKitView — see below
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

private struct NoticeCard: View {
    let notice: NoticeEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ANNOUNCEMENT")
                .font(.caption)
                .foregroundColor(.red)
                .fontWeight(.bold)

            Text(notice.title)
                .font(.headline)
                .foregroundColor(.primary)

            Text(notice.body)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding()
        .frame(width: 260, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
}
