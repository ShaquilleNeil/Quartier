//
//  ScheduleViewModel.swift
//  Quartier
//
//  Created by user285973 on 4/5/26.
//
// MARK: - ScheduleViewModel.swift
import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import Combine

struct ScheduleEvent: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var landlordId: String
    var title: String
    var notes: String?
    var startAt: Date
    var endAt: Date
    var allDay: Bool
    var scopeAll: Bool
    var listingIds: [String]
}

@MainActor
class ScheduleViewModel: ObservableObject {
    @Published var events: [ScheduleEvent] = []
    
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    func loadEvents() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        listener = db.collection("schedules")
            .whereField("landlordId", isEqualTo: uid)
            .order(by: "startAt", descending: false)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching schedule: \(error.localizedDescription)")
                    return
                }
                guard let documents = snapshot?.documents else { return }
                // Real-time sync from Firebase
                self.events = documents.compactMap { try? $0.data(as: ScheduleEvent.self) }
            }
    }
    
    func saveEvent(id: String?, title: String, notes: String?, startAt: Date, endAt: Date, allDay: Bool, scopeAll: Bool, listingIds: [String]) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let collection = db.collection("schedules")
        let docRef = id != nil ? collection.document(id!) : collection.document()
        
        let event = ScheduleEvent(
            id: docRef.documentID,
            landlordId: uid,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes?.trimmingCharacters(in: .whitespacesAndNewlines),
            startAt: startAt,
            endAt: endAt,
            allDay: allDay,
            scopeAll: scopeAll,
            listingIds: listingIds
        )
        
        // MARK: Optimistic UI Update
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            events[index] = event
        } else {
            events.append(event)
        }
        events.sort { $0.startAt < $1.startAt }
        
        try? docRef.setData(from: event)
    }
    
    func deleteEvent(_ event: ScheduleEvent) {
        guard let id = event.id else { return }
        
        // MARK: Optimistic UI Delete (Instant visual remove)
        withAnimation {
            events.removeAll { $0.id == id }
        }

        db.collection("schedules").document(id).delete()
    }
    
    func cleanup() {
        listener?.remove()
    }
}
