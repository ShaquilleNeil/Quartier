//
//  NewScheduleEventView.swift
//  Quartier
//
//  Landlord: create schedule event for all, or selected apartments. Visible to tenants when relevant.
//

import SwiftUI
import CoreData

private final class ScheduleSaveGate {
    private static let lock = NSLock()
    private static var busy = false

    static func tryEnter() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard !busy else { return false }
        busy = true
        return true
    }

    static func leave() {
        lock.lock()
        busy = false
        lock.unlock()
    }
}

struct NewScheduleEventView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \LDListing.address, ascending: true)],
        animation: .default
    )
    private var allListings: FetchedResults<LDListing>

    @State private var title = ""
    @State private var notes = ""
    @State private var startAt = Date()
    @State private var endAt = Date().addingTimeInterval(3600)
    @State private var allDay = false
    @State private var scopeAll = true
    @State private var selectedListingIDs: Set<UUID> = []
    @State private var errorMessage: String?
    @State private var isSaving = false
    @State private var didCompleteSave = false
    @State private var didLoadExisting = false

    let existingEvent: LDScheduleEvent?
    let onSaved: (() -> Void)?

    private let primary = Color(red: 0.17, green: 0.55, blue: 0.93)

    init(existingEvent: LDScheduleEvent? = nil, onSaved: (() -> Void)? = nil) {
        self.existingEvent = existingEvent
        self.onSaved = onSaved
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
                        // end same day for all-day
                    } else {
                        DatePicker("Start", selection: $startAt, displayedComponents: [.date, .hourAndMinute])
                        DatePicker("End", selection: $endAt, displayedComponents: [.date, .hourAndMinute])
                    }
                }

                Section("Visible to") {
                    Picker("Scope", selection: $scopeAll) {
                        Text("All apartments").tag(true)
                        Text("Selected apartments").tag(false)
                    }
                    .pickerStyle(.inline)

                    if !scopeAll {
                        ForEach(allListings, id: \.objectID) { listing in
                            if let id = listing.id {
                                Button {
                                    if selectedListingIDs.contains(id) {
                                        selectedListingIDs.remove(id)
                                    } else {
                                        selectedListingIDs.insert(id)
                                    }
                                } label: {
                                    HStack {
                                        Text(listing.address ?? "Untitled")
                                            .foregroundStyle(.primary)
                                        if let b = listing.listingName, !b.isEmpty {
                                            Text("• \(b)")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        if selectedListingIDs.contains(id) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(primary)
                                        }
                                    }
                                }
                            }
                        }
                        if allListings.isEmpty {
                            Text("No listings yet. Add listings in the Listings tab.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if let err = errorMessage {
                    Section {
                        Text(err)
                            .foregroundStyle(.red)
                            .font(.caption)
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
                        .disabled(isSaving || didCompleteSave || title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
                loadExistingIfNeeded()
            }
        }
    }

    private func loadExistingIfNeeded() {
        guard !didLoadExisting, let existingEvent else { return }
        didLoadExisting = true

        title = existingEvent.title ?? ""
        notes = existingEvent.notes ?? ""
        startAt = existingEvent.startAt ?? Date()
        endAt = existingEvent.endAt ?? startAt.addingTimeInterval(3600)
        allDay = existingEvent.allDay

        let targets = existingEvent.targets as? Set<LDScheduleTarget> ?? []
        let hasAll = targets.contains(where: { ($0.scopeType ?? "") == LDScopeType.all.rawValue || $0.listing == nil })
        scopeAll = hasAll
        if !hasAll {
            selectedListingIDs = Set(targets.compactMap { $0.listing?.id })
        }
    }

    private func saveEvent() {
        guard !isSaving, !didCompleteSave else { return }
        guard ScheduleSaveGate.tryEnter() else { return }
        errorMessage = nil
        isSaving = true
        defer { ScheduleSaveGate.leave() }

        var eventStart = startAt
        var eventEnd = endAt
        if allDay {
            eventStart = Calendar.current.startOfDay(for: startAt)
            eventEnd = eventStart.addingTimeInterval(86400 - 1)
        }
        if eventEnd <= eventStart {
            errorMessage = "End must be after start."
            isSaving = false
            didCompleteSave = false
            return
        }

        let scope: ScheduleEventService.ScheduleScope
        if scopeAll {
            scope = .all
        } else {
            let selected = allListings.filter { listing in
                guard let id = listing.id else { return false }
                return selectedListingIDs.contains(id)
            }
            if selected.isEmpty {
                errorMessage = "Select at least one apartment, or use All apartments."
                isSaving = false
                didCompleteSave = false
                return
            }
            scope = .listings(Array(selected))
        }

        let service = ScheduleEventService(context: viewContext)
        let normalizedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedNotes = notes.isEmpty ? nil : notes
        func attemptSave(_ scopeToUse: ScheduleEventService.ScheduleScope) throws {
            if let existingEvent {
                _ = try service.updateScheduleEvent(
                    existingEvent,
                    title: normalizedTitle,
                    notes: normalizedNotes,
                    startAt: eventStart,
                    endAt: eventEnd,
                    allDay: allDay,
                    visibility: 1,
                    tenantRelevant: true,
                    scope: scopeToUse
                )
            } else {
                _ = try service.createScheduleEvent(
                    title: normalizedTitle,
                    notes: normalizedNotes,
                    startAt: eventStart,
                    endAt: eventEnd,
                    allDay: allDay,
                    visibility: 1,
                    tenantRelevant: true,
                    scope: scopeToUse,
                    pushToConversations: true
                )
            }
        }

        do {
            try attemptSave(scope)
            isSaving = false
            didCompleteSave = true
            DispatchQueue.main.async {
                onSaved?()
                dismiss()
            }
        } catch {
            isSaving = false
            didCompleteSave = false
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NewScheduleEventView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
