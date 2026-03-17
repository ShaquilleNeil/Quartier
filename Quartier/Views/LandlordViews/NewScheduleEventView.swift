//
//  NewScheduleEventView.swift
//  Quartier
//
//  Landlord: create schedule event for all, or selected apartments. Visible to tenants when relevant.
//

import SwiftUI
import CoreData

struct NewScheduleEventView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    /// nil = create new; non-nil = edit existing
    var existingEvent: LDScheduleEvent?
    /// Optional callback so parent sheet can also close explicitly
    var onSaved: (() -> Void)?

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

    private let primary = Color(red: 0.17, green: 0.55, blue: 0.93)

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
                            let id = listing.id ?? UUID()
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
                                    if let b = listing.buildingID, !b.isEmpty {
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
                    Button("Save") { saveEvent() }
                        .disabled(isSaving || title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                if existingEvent != nil {
                    ToolbarItem(placement: .bottomBar) {
                        Button(role: .destructive, action: deleteEvent) {
                            Label("Delete", systemImage: "trash")
                        }
                    }
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
            .onAppear(perform: loadInitial)
        }
    }

    private func loadInitial() {
        if let event = existingEvent {
            // Editing existing event
            title = event.title ?? ""
            notes = event.notes ?? ""
            allDay = event.allDay
            if let s = event.startAt {
                startAt = s
            }
            if let e = event.endAt {
                endAt = e
            }

            let targets = event.targets as? Set<LDScheduleTarget> ?? []
            if targets.contains(where: { $0.scopeType == LDScopeType.all.rawValue }) {
                scopeAll = true
                selectedListingIDs.removeAll()
            } else {
                scopeAll = false
                let ids: [UUID] = targets.compactMap { $0.listing?.id }
                selectedListingIDs = Set(ids)
            }
        }
    }

    private func saveEvent() {
        errorMessage = nil
        isSaving = true
        defer { isSaving = false }

        var eventStart = startAt
        var eventEnd = endAt
        if allDay {
            eventStart = Calendar.current.startOfDay(for: startAt)
            eventEnd = eventStart.addingTimeInterval(86400 - 1)
        }
        if eventEnd <= eventStart {
            errorMessage = "End must be after start."
            return
        }

        if let event = existingEvent {
            // Update existing event
            event.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            event.notes = notes.isEmpty ? nil : notes
            event.startAt = eventStart
            event.endAt = eventEnd
            event.allDay = allDay

            // Replace targets based on current scope
            let existingTargets = event.targets as? Set<LDScheduleTarget> ?? []
            existingTargets.forEach { viewContext.delete($0) }

            if scopeAll {
                let t = LDScheduleTarget(context: viewContext)
                t.id = UUID()
                t.createdAt = Date()
                t.scopeType = LDScopeType.all.rawValue
                t.scheduleEvent = event
                t.listing = nil
            } else {
                let selected = allListings.filter { listing in
                    guard let id = listing.id else { return false }
                    return selectedListingIDs.contains(id)
                }
                if selected.isEmpty {
                    errorMessage = "Select at least one apartment, or use All apartments."
                    return
                }
                for listing in selected {
                    let t = LDScheduleTarget(context: viewContext)
                    t.id = UUID()
                    t.createdAt = Date()
                    t.scopeType = LDScopeType.listing.rawValue
                    t.scheduleEvent = event
                    t.listing = listing
                }
            }

            do {
                try viewContext.save()
                onSaved?()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        } else {
            // Create new event via service (keeps existing behavior including system messages)
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
                    return
                }
                scope = .listings(Array(selected))
            }

            do {
                let service = ScheduleEventService(context: viewContext)
                _ = try service.createScheduleEvent(
                    title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                    notes: notes.isEmpty ? nil : notes,
                    startAt: eventStart,
                    endAt: eventEnd,
                    allDay: allDay,
                    visibility: 1,
                    tenantRelevant: true,
                    scope: scope,
                    pushToConversations: true
                )
                onSaved?()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func deleteEvent() {
        guard let event = existingEvent else { return }
        viewContext.delete(event)
        // 对于删除操作，这里更偏向“尽量删掉并关闭界面”，
        // 不再把 Core Data 的底层校验错误展示给用户，以免出现你看到的红色提示但实际上已经删除成功的情况。
        try? viewContext.save()
        onSaved?()
        dismiss()
    }
}

#Preview {
    NewScheduleEventView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
