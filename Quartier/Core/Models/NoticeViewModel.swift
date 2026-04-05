//
//  NoticeViewModel.swift
//  Quartier
//
//  Created by user285973 on 4/5/26.
//


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
    private let db = Firestore.firestore()

    func sendNotice(title: String, body: String, scopeAll: Bool, listingIds: [String]) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let collection = db.collection("notices")
        let docRef = collection.document()

        let notice = NoticeEvent(
            id: docRef.documentID,
            landlordId: uid,
            title: title,
            body: body,
            scopeAll: scopeAll,
            listingIds: listingIds,
            createdAt: Date()
        )

        try? docRef.setData(from: notice)
    }
}
