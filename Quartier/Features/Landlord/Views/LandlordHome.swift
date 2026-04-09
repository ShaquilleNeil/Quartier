// MARK: - LandlordHome.swift
import SwiftUI
import CoreData
import FirebaseAuth

struct LandlordHome: View {
    var body: some View {
        NavigationStack {
            LandlordDashboardView()
        }
    }
}

private struct LandlordDashboardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @StateObject private var chatVM = ChatViewModel()
    @StateObject private var scheduleVM = ScheduleViewModel()
    @State private var totalRent = 0.0
    @State private var totalPossible = 0.0
    @EnvironmentObject var firebaseManager: FirebaseManager

    @FetchRequest(
        sortDescriptors: [],
        animation: .default
    )
    private var allCoreDataListings: FetchedResults<LDListing>

    @State private var latestRequest: MaintenanceRequest? = nil
    @State private var latestRequestListingId: String? = nil
    @State private var showNewNotice = false

    private let primary = Color(red: 0.17, green: 0.55, blue: 0.93)
    private var cardBg: Color { Color(uiColor: .secondarySystemBackground) }
    private var border: Color { Color.primary.opacity(0.08) }

    private var currentUid: String { Auth.auth().currentUser?.uid ?? "" }
    
    private var myListings: [Listing] {
        firebaseManager.firebaseListings
    }

    var occupantsCount: Int {
        firebaseManager.firebaseListings.filter { $0.isRented }.count
    }

    var upcomingEvent: ScheduleEvent? {
        let now = Date()
        return scheduleVM.events.first { event in
            return event.endAt >= now
        }
    }

    var greetingName: String {
        if let name = Auth.auth().currentUser?.displayName, !name.isEmpty {
            return name.components(separatedBy: " ").first ?? "there"
        }
        return "there"
    }

    private var earningsPercent: Double {
        guard totalPossible > 0 else { return 0.0 }
        return (totalRent / totalPossible) * 100
    }
    
    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    
                    // MARK: - Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Hey \(greetingName)!")
                                .font(.system(size: 28, weight: .bold))
                            Text("Here is your property overview.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button { showNewNotice = true } label: {
                            Image(systemName: "bell.badge.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(primary)
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(primary.opacity(0.12)))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)

                    // MARK: - Stats Grid
                    HStack(spacing: 12) {
                        statCard(title: "Properties", value: "\(myListings.count)", icon: "building.2.fill", color: primary)
                        statCard(title: "Occupied", value: "\(occupantsCount)", icon: "person.2.fill", color: .green)
                    }
                    .padding(.horizontal, 16)

                    // MARK: - Earnings Card
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total Earnings")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.secondary)
                            Text(String(format: "CA$%.0f / $%.0f", totalRent, totalPossible))
                                .font(.headline.weight(.bold))
                        }
                        Spacer()
                       
                        Text(String(format: "%.1f%%", earningsPercent))
                                .font(.caption.weight(.bold))
                                .foregroundStyle( earningsPercent < 50 ? .red : .green)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(Color.gray.opacity(0.12)))
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 16).fill(cardBg))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(border, lineWidth: 1))
                    .padding(.horizontal, 16)

                    // MARK: - Messages
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Messages")
                            .font(.system(size: 18, weight: .bold))
                            .padding(.horizontal, 16)

                        NavigationLink(destination: LandlordMessages()) {
                            HStack(spacing: 16) {
                                Circle()
                                    .fill(primary.opacity(0.12))
                                    .frame(width: 48, height: 48)
                                    .overlay(Image(systemName: "bubble.left.and.bubble.right.fill").foregroundStyle(primary))

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Active Conversations")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(.primary)
                                    
                                    if chatVM.conversations.isEmpty {
                                        Text("No pending messages")
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
                            .background(RoundedRectangle(cornerRadius: 16).fill(cardBg))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(border, lineWidth: 1))
                        }
                        .padding(.horizontal, 16)
                    }

                    // MARK: - Upcoming Event
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Upcoming Event")
                            .font(.system(size: 18, weight: .bold))
                            .padding(.horizontal, 16)

                        if let event = upcomingEvent {
                            NavigationLink(destination: LandlordSchedule().environmentObject(scheduleVM)) {
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
                                .background(RoundedRectangle(cornerRadius: 16).fill(cardBg))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(border, lineWidth: 1))
                            }
                            .padding(.horizontal, 16)
                        } else {
                            Text("No upcoming events scheduled.")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(16)
                                .background(RoundedRectangle(cornerRadius: 16).fill(cardBg))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(border, lineWidth: 1))
                                .padding(.horizontal, 16)
                        }
                    }

//                    Spacer(minLength: 40)
                    
                    
               
                                        VStack(alignment: .leading, spacing: 10) {
                                            HStack {
                                                Text("Maintenance")
                                                    .font(.system(size: 18, weight: .bold))
                                                Spacer()
                                                if let listingId = latestRequestListingId {
                                                    NavigationLink(destination: MaintenanceListView(listingId: listingId)) {
                                                        Text("View All")
                                                            .font(.subheadline)
                                                            .foregroundStyle(primary)
                                                    }
                                                }
                                            }
                                            .padding(.horizontal, 16)

                                            if let request = latestRequest, let listingId = latestRequestListingId {
                                                NavigationLink(destination: MaintenanceDetailView(
                                                    request: request,
                                                    listingId: listingId,
                                                    onResolved: {
                                                        firebaseManager.fetchLatestMaintenanceRequest { req, lid in
                                                            latestRequest = req
                                                            latestRequestListingId = lid
                                                        }
                                                    }
                                                )) {
                                                    MaintenanceCard(request: request)
                                                        .padding(.horizontal, 16)
                                                }
                                                .buttonStyle(.plain)
                                            } else {
                                                Text("No maintenance requests.")
                                                    .font(.system(size: 14))
                                                    .foregroundStyle(.secondary)
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                    .padding(16)
                                                    .background(RoundedRectangle(cornerRadius: 16).fill(cardBg))
                                                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(border, lineWidth: 1))
                                                    .padding(.horizontal, 16)
                                            }
                                        }

                                        Spacer(minLength: 40)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showNewNotice) {
            NewNoticeView()
                .environment(\.managedObjectContext, viewContext)
        }
        .onAppear {
            Task{
                chatVM.loadConversations(isLandlord: true)
                scheduleVM.loadEvents()
                totalRent = await firebaseManager.totalRentCollected()
                totalPossible = await firebaseManager.totalPossibleEarnings()
                firebaseManager.fetchListingsLandlord()
                firebaseManager.fetchLatestMaintenanceRequest { req, lid in
                    latestRequest = req
                    latestRequestListingId = lid
                }
            }
        }
        .onDisappear {
            chatVM.cleanupConversations()
            scheduleVM.cleanup()
        }
    }

    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.system(size: 18, weight: .semibold))
                Spacer()
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(cardBg))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(border, lineWidth: 1))
    }

    // MARK: - Helper Methods
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
