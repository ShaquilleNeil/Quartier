//
//  TenantSchedule.swift
//  Quartier
//

import SwiftUI
import CoreData
import FirebaseFirestore

struct TenantSchedule: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.managedObjectContext) private var viewContext

    @State private var selectedDate = Date()
    @State private var landlordEvents: [LandlordScheduleEvent] = []
    @State private var showNewEvent = false

    // Tenant's own personal reminders stored locally in CoreData
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "startAt", ascending: true)],
        predicate: NSPredicate(format: "lastModifiedBy == %@", "tenant"),
        animation: .default
    )
    private var myEvents: FetchedResults<LDScheduleEvent>

    let primary = Color(red: 0.17, green: 0.55, blue: 0.93)

    // MARK: - Computed

    // All events (landlord + personal) for the selected day
    var eventsOnSelectedDay: [ScheduleEntry] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: selectedDate)
        let end = cal.date(byAdding: .day, value: 1, to: start) ?? start

        var entries: [ScheduleEntry] = []

        for e in landlordEvents {
            if e.startAt >= start && e.startAt < end {
                entries.append(ScheduleEntry(
                    id: e.id,
                    title: e.title,
                    timeText: formatTime(e.startAt, e.endAt, e.allDay),
                    notes: e.notes,
                    isPersonal: false
                ))
            }
        }

        for e in myEvents {
            guard let s = e.startAt else { continue }
            if s >= start && s < end {
                entries.append(ScheduleEntry(
                    id: e.id?.uuidString ?? UUID().uuidString,
                    title: e.title ?? "Event",
                    timeText: formatTime(s, e.endAt, e.allDay),
                    notes: e.notes ?? "",
                    isPersonal: true
                ))
            }
        }

        return entries.sorted { $0.timeText < $1.timeText }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Color(.systemBackground).ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Schedule")
                            .font(.system(size: 28, weight: .bold))
                            .padding(.horizontal, 16)

                        DatePicker("", selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .padding(.horizontal, 16)

                        Divider()

                        // MARK: - Event List

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Events")
                                .font(.system(size: 18, weight: .bold))
                                .padding(.horizontal, 16)

                            if eventsOnSelectedDay.isEmpty {
                                Text("No events on this day")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                            } else {
                                ForEach(eventsOnSelectedDay) { entry in
                                    eventCard(entry)
                                        .padding(.horizontal, 16)
                                }
                            }
                        }

                        Spacer(minLength: 80)
                    }
                    .padding(.bottom, 18)
                }

                // Add personal reminder button
                Button {
                    showNewEvent = true
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
            .navigationBarHidden(true)
        }
        .onAppear {
            loadLandlordEvents()
        }
        .sheet(isPresented: $showNewEvent) {
            NewTenantEventView()
                .environment(\.managedObjectContext, viewContext)
        }
    }

    // MARK: - Event Card

    func eventCard(_ entry: ScheduleEntry) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 4)
                .fill(entry.isPersonal ? Color.green : primary)
                .frame(width: 4, height: 50)

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.title)
                    .font(.system(size: 15, weight: .semibold))
                Text(entry.timeText)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                if !entry.notes.isEmpty {
                    Text(entry.notes)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Text(entry.isPersonal ? "Personal" : "From landlord")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(entry.isPersonal ? .green : primary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill((entry.isPersonal ? Color.green : primary).opacity(0.12)))
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(uiColor: .secondarySystemBackground)))
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
    }

    // MARK: - Load Landlord Events from Firestore

    func loadLandlordEvents() {
        let db = Firestore.firestore()
        let rentedListingId = authService.rentedListingId
        var results: [LandlordScheduleEvent] = []
        let group = DispatchGroup()

        // Events visible to all tenants
        group.enter()
        db.collection("scheduleEvents")
            .whereField("scope", isEqualTo: "all")
            .whereField("tenantRelevant", isEqualTo: true)
            .getDocuments { snapshot, _ in
                for doc in snapshot?.documents ?? [] {
                    if let event = LandlordScheduleEvent(doc: doc) {
                        results.append(event)
                    }
                }
                group.leave()
            }

        // Events for this tenant's specific listing
        if let listingId = rentedListingId {
            group.enter()
            db.collection("scheduleEvents")
                .whereField("scope", isEqualTo: "listings")
                .whereField("listingIds", arrayContains: listingId)
                .whereField("tenantRelevant", isEqualTo: true)
                .getDocuments { snapshot, _ in
                    for doc in snapshot?.documents ?? [] {
                        if let event = LandlordScheduleEvent(doc: doc) {
                            results.append(event)
                        }
                    }
                    group.leave()
                }
        }

        group.notify(queue: .main) {
            // Remove duplicates
            var seen = Set<String>()
            self.landlordEvents = results.filter { seen.insert($0.id).inserted }
        }
    }

    // MARK: - Helpers

    func formatTime(_ start: Date, _ end: Date?, _ allDay: Bool) -> String {
        if allDay { return "All day" }
        let f = DateFormatter()
        f.timeStyle = .short
        var text = f.string(from: start)
        if let end = end {
            text += " – \(f.string(from: end))"
        }
        return text
    }
}


// MARK: - Models

struct LandlordScheduleEvent {
    let id: String
    let title: String
    let notes: String
    let startAt: Date
    let endAt: Date?
    let allDay: Bool

    init?(doc: QueryDocumentSnapshot) {
        let data = doc.data()
        guard let title = data["title"] as? String,
              let startTimestamp = data["startAt"] as? Timestamp else { return nil }
        self.id = doc.documentID
        self.title = title
        self.notes = data["notes"] as? String ?? ""
        self.startAt = startTimestamp.dateValue()
        self.endAt = (data["endAt"] as? Timestamp)?.dateValue()
        self.allDay = data["allDay"] as? Bool ?? false
    }
}

struct ScheduleEntry: Identifiable {
    let id: String
    let title: String
    let timeText: String
    let notes: String
    let isPersonal: Bool
}


#Preview {
    TenantSchedule()
        .environmentObject(AuthService(firebase: FirebaseManager()))
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
