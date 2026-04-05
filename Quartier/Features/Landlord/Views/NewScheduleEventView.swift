//
//  NewScheduleEventView.swift
//  Quartier
//
// MARK: - NewScheduleEventView.swift
import SwiftUI
import CoreData
import FirebaseAuth

struct NewScheduleEventView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \LDListing.address, ascending: true)],
        animation: .default
    )
    private var allCoreDataListings: FetchedResults<LDListing>

    @StateObject private var viewModel = ScheduleViewModel()
    
    @State private var title = ""
    @State private var notes = ""
    @State private var startAt = Date()
    @State private var endAt = Date().addingTimeInterval(3600)
    @State private var allDay = false
    @State private var scopeAll = true
    @State private var selectedListingIDs: Set<String> = []
    @State private var errorMessage: String?

    let existingEvent: ScheduleEvent?
    let onSaved: (() -> Void)?

    private let primary = Color(red: 0.17, green: 0.55, blue: 0.93)
    
    // MARK: - Security Filtering
    private var currentUid: String { Auth.auth().currentUser?.uid ?? "" }
    
    private var myListings: [LDListing] {
        allCoreDataListings.filter { $0.landLordID == currentUid }
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

                Section("Visible to") {
                    Picker("Scope", selection: $scopeAll) {
                        Text("All my properties").tag(true)
                        Text("Specific properties").tag(false)
                    }
                    .pickerStyle(.inline)

                    if !scopeAll {
                        // MARK: Only shows user's listings
                        ForEach(myListings, id: \.objectID) { listing in
                            if let id = listing.id?.uuidString {
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
                        
                        if myListings.isEmpty {
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
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
        guard let event = existingEvent else { return }
        title = event.title
        notes = event.notes ?? ""
        startAt = event.startAt
        endAt = event.endAt
        allDay = event.allDay
        scopeAll = event.scopeAll
        selectedListingIDs = Set(event.listingIds)
    }

    private func saveEvent() {
        errorMessage = nil

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

        if !scopeAll && selectedListingIDs.isEmpty {
            errorMessage = "Select at least one property, or choose 'All my properties'."
            return
        }

        viewModel.saveEvent(
            id: existingEvent?.id,
            title: title,
            notes: notes,
            startAt: eventStart,
            endAt: eventEnd,
            allDay: allDay,
            scopeAll: scopeAll,
            listingIds: Array(selectedListingIDs)
        )

        onSaved?()
        dismiss()
    }
}
