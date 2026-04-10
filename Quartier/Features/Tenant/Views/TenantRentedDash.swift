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
                                            imageURL: listing?.existingImageURLs.first,
                                            listing: listing 
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
    let listing: Listing?

    @State private var isPresentingPayRent = false
    @State private var isPaidThisMonth = false

    private var monthYear: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: Date())
    }
    
    // MARK: - to track month's payment
    private var paymentKey: String {
        let listingId = listing?.listingID.uuidString ?? "unknown"
        return "rent_paid_\(listingId)_\(monthYear)"
    }

    private var priceFormatted: String {
        guard price > 0 else { return "—" }
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "CAD"
        return f.string(from: NSNumber(value: price)) ?? "$\(price)"
    }
    
    private var daysUntilRentDue: Int {
        let dueDay = listing?.rentDueDay ?? 1
        let calendar = Calendar.current
        let now = Date()
        
        let components = calendar.dateComponents([.year, .month, .day], from: now)
        guard let currentYear = components.year, let currentMonth = components.month, let currentDay = components.day else { return 0 }
        
        var dueComponents = DateComponents(year: currentYear, month: currentMonth, day: dueDay)
        
        if currentDay > dueDay {
            dueComponents.month = currentMonth + 1
        }
        
        guard let nextDueDate = calendar.date(from: dueComponents) else { return 0 }
        
        let diff = calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: nextDueDate))
        return diff.day ?? 0
    }
    
    private var nextDueDateFormatted: String {
            let dueDay = listing?.rentDueDay ?? 1
            let calendar = Calendar.current
            let now = Date()
            
            var components = calendar.dateComponents([.year, .month], from: now)
            components.day = dueDay
            
            if isPaidThisMonth || (calendar.component(.day, from: now) > dueDay) {
                components.month = (components.month ?? 0) + 1
            }
            
            guard let nextDate = calendar.date(from: components) else { return "" }
            
            let f = DateFormatter()
            f.dateFormat = "MMM d"
            return f.string(from: nextDate)
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
                            .foregroundColor(.gray)
                        Text("Monthly rent")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }

                HStack {
                    Text(address)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    // MARK: - countdown of payment and next due date
                                        if isPaidThisMonth {
                                            VStack(alignment: .trailing, spacing: 2) {
                                                Text("Paid for \(monthYear.components(separatedBy: " ").first ?? "")")
                                                    .font(.caption.bold())
                                                    .foregroundStyle(.green)

                                                Text("Next due: \(nextDueDateFormatted)")
                                                    .font(.caption2)
                                                    .foregroundStyle(.secondary)
                                            }
                                        } else if daysUntilRentDue == 0 {
                        Text("Due Today!")
                            .font(.caption.bold())
                            .foregroundStyle(.red)
                    } else {
                        Text("Due in \(daysUntilRentDue) days")
                            .font(.caption)
                            .foregroundStyle(daysUntilRentDue <= 5 ? .red : .orange)
                    }
                }

                // MARK: - Dynamic Payment Button
                Button {
                    self.isPresentingPayRent = true
                } label: {
                    Text(isPaidThisMonth ? "Paid" : "Pay Now")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isPaidThisMonth ? Color.green : Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(isPaidThisMonth)
            }
            .padding()
        }
        .background(.white)
        .cornerRadius(16)
        .shadow(radius: 4)
        .onAppear {
            isPaidThisMonth = UserDefaults.standard.bool(forKey: paymentKey)
        }
        .sheet(isPresented: $isPresentingPayRent) {
            PayRentView(amount: price) {
                UserDefaults.standard.set(true, forKey: paymentKey)
                isPaidThisMonth = true
            }
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

// MARK: - Pay Rent View
private struct PayRentView: View {
    let amount: Double
    let onPaymentSuccess: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var cardName = ""
    @State private var cardNumber = ""
    @State private var expiry = ""
    @State private var cvv = ""
    @State private var isProcessing = false
    
    private var formattedAmount: String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "CAD"
        return f.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: 8) {
                        Text("Amount Due")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(formattedAmount)
                            .font(.system(size: 36, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                
                Section("Card Details") {
                    TextField("Name on Card", text: $cardName)
                        .textContentType(.name)
                    
                    TextField("Card Number", text: $cardNumber)
                        .keyboardType(.numberPad)
                    
                    HStack {
                        TextField("MM/YY", text: $expiry)
                            .keyboardType(.numberPad)
                        Divider()
                        TextField("CVV", text: $cvv)
                            .keyboardType(.numberPad)
                    }
                }
            }
            .navigationTitle("Pay Rent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(isProcessing)
                }
            }

            .safeAreaInset(edge: .bottom) {
                Button {
                    processPayment()
                } label: {
                    if isProcessing {
                        ProgressView().tint(.white)
                    } else {
                        Text("Pay \(formattedAmount)")
                            .fontWeight(.bold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isFormValid ? Color.blue : Color.gray.opacity(0.5))
                .foregroundColor(.white)
                .cornerRadius(14)
                .padding(.horizontal)
                .padding(.bottom, 8)
                .disabled(!isFormValid || isProcessing)
            }
        }
    }
    
    private var isFormValid: Bool {
        !cardName.isEmpty && !cardNumber.isEmpty && !expiry.isEmpty && !cvv.isEmpty
    }
    
    private func processPayment() {
        isProcessing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isProcessing = false
            onPaymentSuccess()
            dismiss()
        }
    }
}
