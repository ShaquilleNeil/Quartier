//
//  NewTenantEventView.swift
//  Quartier
//
//  Tenant: create a personal schedule reminder (stored locally in CoreData).
//

import SwiftUI
import CoreData

struct NewTenantEventView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var notes = ""
    @State private var startAt = Date()
    @State private var endAt = Date().addingTimeInterval(3600)
    @State private var allDay = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Event") {
                    TextField("Title", text: $title)
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                    Toggle("All day", isOn: $allDay)
                    DatePicker(
                        "Date",
                        selection: $startAt,
                        displayedComponents: allDay ? .date : [.date, .hourAndMinute]
                    )
                    if !allDay {
                        DatePicker("End", selection: $endAt, displayedComponents: [.date, .hourAndMinute])
                    }
                }
            }
            .navigationTitle("Personal Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveEvent() }
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    func saveEvent() {
        let event = LDScheduleEvent(context: viewContext)
        event.id = UUID()
        event.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        event.notes = notes.isEmpty ? nil : notes
        event.startAt = startAt
        event.endAt = allDay
            ? Calendar.current.startOfDay(for: startAt).addingTimeInterval(86399)
            : endAt
        event.allDay = allDay
        event.createdAt = Date()
        event.updatedAt = Date()
        event.lastModifiedBy = "tenant"
        event.tenantRelevant = false
        event.visibility = 0
        event.syncStatus = LDSyncStatus.localOnly.rawValue
        event.version = 1

        try? viewContext.save()
        dismiss()
    }
}

#Preview {
    NewTenantEventView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
