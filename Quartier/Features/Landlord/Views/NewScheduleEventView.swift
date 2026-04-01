//
//  NewScheduleEventView.swift
//  Quartier
//
//  Landlord: create or edit a schedule event. Visible to tenants via Firestore.
//

import SwiftUI
import CoreData
import FirebaseFirestore
import FirebaseAuth

struct NewScheduleEventView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var firebase: FirebaseManager

    @State private var title = ""
    @State private var notes = ""
    @State private var startAt = Date()
    @State private var endAt = Date().addingTimeInterval(3600)
    @State private var allDay = false
    @State private var scopeAll = true
    // Stores Firebase listing IDs (String) for selected published listings
    @State private var selectedListingIDs: Set<String> = []
    @State private var errorMessage: String?
    @State private var isSaving = false
    @State private var didLoadExisting = false

    let existingEvent: LDScheduleEvent?
    let onSaved: (() -> Void)?

    let primary = Color(red: 0.17, green: 0.55, blue: 0.93)

    init(existingEvent: LDScheduleEvent? = nil, onSaved: (() -> Void)? = nil) {
        self.existingEvent = existingEvent
        self.onSaved = onSaved
    }

    // Tenants assigned to the selected listings
    var targetTenantIds: [String] {
        guard !scopeAll else { return [] }
        return firebase.firebaseListings
            .filter { selectedListingIDs.contains($0.id) }
            .compactMap { $0.currentTenantUserId }
            .filter { !$0.isEmpty }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Event") {
                    TextField("Title", text: $title)
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                    Toggle("All day", isOn: $allDay)
                    if allDay {
                        DatePicker("Date", selection: $startAt, displayedComponents: .date)
                    } else {
                        DatePicker("Start", selection: $startAt, displayedComponents: [.date, .hourAndMinute])
                        DatePicker("End", selection: $endAt, displayedComponents: [.date, .hourAndMinute])
                    }
                }

                // MARK: - Scope Picker

                Section("Visible to") {
                    Picker("Scope", selection: $scopeAll) {
                        Text("All tenants").tag(true)
                        Text("Selected apartments").tag(false)
                    }
                    .pickerStyle(.inline)

                    if !scopeAll {
                        if firebase.firebaseListings.isEmpty {
                            Text("No published listings yet.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(firebase.firebaseListings) { listing in
                                Button {
                                    if selectedListingIDs.contains(listing.id) {
                                        selectedListingIDs.remove(listing.id)
                                    } else {
                                        selectedListingIDs.insert(listing.id)
                                    }
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(listing.address.isEmpty ? "Untitled" : listing.address)
                                                .foregroundStyle(.primary)
                                            // Show whether a tenant is currently assigned
                                            if let tenantId = listing.currentTenantUserId, !tenantId.isEmpty {
                                                Text("Tenant assigned")
                                                    .font(.caption)
                                                    .foregroundStyle(.green)
                                            } else {
                                                Text("No tenant")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                        Spacer()
                                        if selectedListingIDs.contains(listing.id) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(primary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                if let err = errorMessage {
                    Section {
                        Text(err).foregroundStyle(.red).font(.caption)
                    }
                }
            }
            .navigationTitle(existingEvent == nil ? "New Schedule" : "Edit Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(existingEvent == nil ? "Save" : "Update") { saveEvent() }
                        .disabled(isSaving || title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onChange(of: scopeAll) { _, isAll in
                if isAll { selectedListingIDs.removeAll() }
            }
            .onChange(of: allDay) { _, isAllDay in
                if isAllDay {
                    endAt = Calendar.current.startOfDay(for: startAt).addingTimeInterval(86400 - 1)
                }
            }
            .onAppear {
                firebase.fetchListingsLandord()
                loadExistingIfNeeded()
            }
        }
    }

    // MARK: - Load Existing

    private func loadExistingIfNeeded() {
        guard !didLoadExisting, let existingEvent else { return }
        didLoadExisting = true

        title = existingEvent.title ?? ""
        notes = existingEvent.notes ?? ""
        startAt = existingEvent.startAt ?? Date()
        endAt = existingEvent.endAt ?? startAt.addingTimeInterval(3600)
        allDay = existingEvent.allDay

        let targets = existingEvent.targets as? Set<LDScheduleTarget> ?? []
        let hasAll = targets.contains(where: { ($0.scopeType ?? "") == LDScopeType.all.rawValue })
        scopeAll = hasAll
        if !hasAll {
            // Match CoreData listing IDs to Firebase listing IDs
            selectedListingIDs = Set(targets.compactMap { $0.listing?.id?.uuidString })
        }
    }

    // MARK: - Save

    private func saveEvent() {
        guard !isSaving else { return }
        errorMessage = nil
        isSaving = true

        var eventStart = startAt
        var eventEnd = endAt
        if allDay {
            eventStart = Calendar.current.startOfDay(for: startAt)
            eventEnd = eventStart.addingTimeInterval(86400 - 1)
        }
        guard eventEnd > eventStart else {
            errorMessage = "End must be after start."
            isSaving = false
            return
        }

        // For ScheduleEventService (CoreData + conversation messages), use .all scope
        // Tenant-specific filtering is handled by targetTenantIds in Firestore
        let service = ScheduleEventService(context: viewContext)
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanNotes = notes.isEmpty ? nil : notes

        do {
            let event: LDScheduleEvent
            if let existingEvent {
                event = try service.updateScheduleEvent(
                    existingEvent,
                    title: cleanTitle,
                    notes: cleanNotes,
                    startAt: eventStart,
                    endAt: eventEnd,
                    allDay: allDay,
                    visibility: 1,
                    tenantRelevant: true,
                    scope: .all
                )
            } else {
                event = try service.createScheduleEvent(
                    title: cleanTitle,
                    notes: cleanNotes,
                    startAt: eventStart,
                    endAt: eventEnd,
                    allDay: allDay,
                    visibility: 1,
                    tenantRelevant: true,
                    scope: .all,
                    pushToConversations: true
                )
            }

            // Push to Firestore with tenant binding
            pushToFirestore(event: event, start: eventStart, end: eventEnd)

            isSaving = false
            onSaved?()
            dismiss()

        } catch {
            isSaving = false
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Firestore Push

    private func pushToFirestore(event: LDScheduleEvent, start: Date, end: Date) {
        guard let eventId = event.id?.uuidString else { return }

        let data: [String: Any] = [
            "title": event.title ?? "",
            "notes": event.notes ?? "",
            "startAt": Timestamp(date: start),
            "endAt": Timestamp(date: end),
            "allDay": event.allDay,
            // "all" = visible to all tenants; "listings" = specific tenants only
            "scope": scopeAll ? "all" : "listings",
            "listingIds": scopeAll ? [] : Array(selectedListingIDs),
            // Direct tenant ID binding — this is what TenantSchedule queries by
            "targetTenantIds": targetTenantIds,
            "tenantRelevant": true,
            "createdAt": FieldValue.serverTimestamp()
        ]

        Firestore.firestore()
            .collection("scheduleEvents")
            .document(eventId)
            .setData(data, merge: true)
    }
}


#Preview {
    NewScheduleEventView()
        .environmentObject(FirebaseManager())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
