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
    var createdAt: Date?
}

@MainActor
class ScheduleViewModel: ObservableObject {
    @Published var events: [ScheduleEvent] = []
    @Published var hasUnread: Bool = false
    
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var scopeAllListener: ListenerRegistration?
    
    func loadEvents() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        listener = db.collection("schedules")
            .whereField("landlordId", isEqualTo: uid)
            .order(by: "startAt", descending: false)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                self.events = documents.compactMap { try? $0.data(as: ScheduleEvent.self) }
            }
    }
    
    func loadTenantEvents(listingId: String) {
        cleanup()
        
        listener = db.collection("schedules")
            .whereField("listingIds", arrayContains: listingId)
            .addSnapshotListener { snapshot, _ in
                self.mergeTenantEvents(snapshot: snapshot)
            }
            
        scopeAllListener = db.collection("schedules")
            .whereField("scopeAll", isEqualTo: true)
            .addSnapshotListener { snapshot, _ in
                self.mergeTenantEvents(snapshot: snapshot)
            }
    }
    
    private func mergeTenantEvents(snapshot: QuerySnapshot?) {
        guard let docs = snapshot?.documents else { return }
        let newEvents = docs.compactMap { try? $0.data(as: ScheduleEvent.self) }
        
        for event in newEvents {
            if let idx = events.firstIndex(where: { $0.id == event.id }) {
                events[idx] = event
            } else {
                events.append(event)
            }
        }
        events.sort { $0.startAt < $1.startAt }

        let lastViewed = UserDefaults.standard.object(forKey: "lastViewedSchedule") as? Date ?? Date(timeIntervalSince1970: 0)
        self.hasUnread = events.contains { ($0.createdAt ?? $0.startAt) > lastViewed }
    }
    
    func saveEvent(id: String?, title: String, notes: String?, startAt: Date, endAt: Date, allDay: Bool, scopeAll: Bool, listingIds: [String]) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let collection = db.collection("schedules")
        let docRef = id != nil ? collection.document(id!) : collection.document()
        
        let event = ScheduleEvent(
            id: docRef.documentID, landlordId: uid, title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes?.trimmingCharacters(in: .whitespacesAndNewlines), startAt: startAt, endAt: endAt,
            allDay: allDay, scopeAll: scopeAll, listingIds: listingIds, createdAt: Date() // MARK: Record creation time
        )
        
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
        withAnimation { events.removeAll { $0.id == id } }
        db.collection("schedules").document(id).delete()
    }

    func markAsViewed() {
        UserDefaults.standard.set(Date(), forKey: "lastViewedSchedule")
        self.hasUnread = false
    }
    
    func cleanup() {
        listener?.remove()
        scopeAllListener?.remove()
    }
}
