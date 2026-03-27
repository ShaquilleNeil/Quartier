//
//  NewTaskView.swift
//  Quartier
//
//  Landlord: add or edit a task. Optional link to a listing.
//

import SwiftUI
import CoreData

struct NewTaskView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    var existingTask: LDTask?

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \LDListing.address, ascending: true)],
        animation: .default
    )
    private var allListings: FetchedResults<LDListing>

    @State private var title = ""
    @State private var subtitle = ""
    @State private var dueDate = Date()
    @State private var hasDueDate = true
    @State private var selectedListingID: UUID?
    @State private var errorMessage: String?
    @State private var isSaving = false

    private let primary = Color(red: 0.17, green: 0.55, blue: 0.93)

    var body: some View {
        NavigationStack {
            Form {
                Section("Task") {
                    TextField("Title", text: $title)
                    TextField("Subtitle / note", text: $subtitle)
                    Toggle("Set due date", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker("Due", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    }
                }

                Section("Related listing (optional)") {
                    Picker("Listing", selection: $selectedListingID) {
                        Text("None").tag(nil as UUID?)
                        ForEach(allListings, id: \.objectID) { listing in
                            Text(listing.address ?? "Untitled")
                                .tag(listing.id as UUID?)
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
            .navigationTitle(existingTask == nil ? "New Task" : "Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(existingTask == nil ? "Add" : "Save") { save() }
                        .disabled(isSaving || title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear(perform: loadExisting)
        }
    }

    private func loadExisting() {
        guard let task = existingTask else { return }
        title = task.title ?? ""
        subtitle = task.subtitle ?? ""
        if let d = task.dueDate {
            dueDate = d
            hasDueDate = true
        } else {
            hasDueDate = false
        }
        if let set = task.listing as? Set<LDListing>, let first = set.first {
            selectedListingID = first.id
        } else {
            selectedListingID = nil
        }
    }

    private func save() {
        errorMessage = nil
        isSaving = true
        defer { isSaving = false }

        let listing: LDListing? = selectedListingID.flatMap { id in
            allListings.first { $0.id == id }
        }
        if let task = existingTask {
            task.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            task.subtitle = subtitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : subtitle.trimmingCharacters(in: .whitespacesAndNewlines)
            task.dueDate = hasDueDate ? dueDate : nil
            task.listing = listing.map { NSSet(object: $0) }
        } else {
            let task = LDTask(context: viewContext)
            task.id = UUID()
            task.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            task.subtitle = subtitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : subtitle.trimmingCharacters(in: .whitespacesAndNewlines)
            task.dueDate = hasDueDate ? dueDate : nil
            task.isDone = false
            task.createdAt = Date()
            task.listing = listing.map { NSSet(object: $0) }
        }

        do {
            try viewContext.save()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NewTaskView(existingTask: nil)
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
