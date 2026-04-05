//
//  NoticeViewModel.swift
//  Quartier
//
//  Created by user285973 on 4/5/26.
// MARK: - NoticeViewModel.swift
import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import Combine

struct NoticeEvent: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var landlordId: String
    var title: String
    var body: String
    var scopeAll: Bool
    var listingIds: [String]
    var createdAt: Date
}

@MainActor
class NoticeViewModel: ObservableObject {
    @Published var notices: [NoticeEvent] = []
    
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var scopeAllListener: ListenerRegistration?

    func sendNotice(title: String, body: String, scopeAll: Bool, listingIds: [String]) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let collection = db.collection("notices")
        let docRef = collection.document()

        let notice = NoticeEvent(
            id: docRef.documentID, landlordId: uid, title: title, body: body,
            scopeAll: scopeAll, listingIds: listingIds, createdAt: Date()
        )
        try? docRef.setData(from: notice)
    }

    func loadTenantNotices(listingId: String) {
        cleanup()
        
        listener = db.collection("notices")
            .whereField("listingIds", arrayContains: listingId)
            .addSnapshotListener { snapshot, _ in
                self.mergeTenantNotices(snapshot: snapshot)
            }
            
        scopeAllListener = db.collection("notices")
            .whereField("scopeAll", isEqualTo: true)
            .addSnapshotListener { snapshot, _ in
                self.mergeTenantNotices(snapshot: snapshot)
            }
    }
    
    private func mergeTenantNotices(snapshot: QuerySnapshot?) {
        guard let docs = snapshot?.documents else { return }
        let newNotices = docs.compactMap { try? $0.data(as: NoticeEvent.self) }
        
        for notice in newNotices {
            if let idx = notices.firstIndex(where: { $0.id == notice.id }) {
                notices[idx] = notice
            } else {
                notices.append(notice)
            }
        }
        notices.sort { $0.createdAt > $1.createdAt }
    }

    func cleanup() {
        listener?.remove()
        scopeAllListener?.remove()
    }
}
