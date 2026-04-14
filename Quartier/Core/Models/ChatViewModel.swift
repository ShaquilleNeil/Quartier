// MARK: - ChatViewModel.swift
import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import Combine

struct Conversation: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var listingId: String
    var listingAddress: String
    var tenantId: String
    var landlordId: String
    var tenantName: String
    var landlordName: String?
    var landlordPhoto: String?
    var tenantPhoto: String?
    var lastMessageText: String
    var lastMessageAt: Date
    var landlordUnreadCount: Int?
    var tenantUnreadCount: Int?
}

struct ChatMessage: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var conversationId: String
    var senderId: String
    var text: String
    var sentAt: Date
}

@MainActor
class ChatViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var messages: [ChatMessage] = []
    @Published var totalUnread: Int = 0
    
    private let db = Firestore.firestore()
    private var convosListener: ListenerRegistration?
    private var messagesListener: ListenerRegistration?
    
    func loadConversations(isLandlord: Bool) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let field = isLandlord ? "landlordId" : "tenantId"
        
        convosListener = db.collection("conversations")
            .whereField(field, isEqualTo: uid)
            .order(by: "lastMessageAt", descending: true)
            .addSnapshotListener { snapshot, _ in
                guard let documents = snapshot?.documents else { return }
                self.conversations = documents.compactMap { try? $0.data(as: Conversation.self) }
                
                self.totalUnread = self.conversations.reduce(0) { sum, conv in
                    let count = isLandlord ? (conv.landlordUnreadCount ?? 0) : (conv.tenantUnreadCount ?? 0)
                    return sum + count
                }
            }
    }
    
    func loadMessages(conversationId: String) {
        messagesListener = db.collection("conversations").document(conversationId).collection("messages")
            .order(by: "sentAt", descending: false)
            .addSnapshotListener { snapshot, _ in
                guard let documents = snapshot?.documents else { return }
                self.messages = documents.compactMap { try? $0.data(as: ChatMessage.self) }
            }
    }
    
    func sendMessage(
        conversationId: String,
        listingId: String,
        listingAddress: String,
        tenantId: String,
        landlordId: String,
        tenantName: String,
        text: String
    ) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let conversationRef = db.collection("conversations").document(conversationId)
        let messageRef = conversationRef.collection("messages").document()

        let isLandlordSender = uid == landlordId

        let conversationData: [String: Any] = [
            "listingId": listingId,
            "listingAddress": listingAddress,
            "tenantId": tenantId,
            "landlordId": landlordId,
            "tenantName": tenantName,
            "lastMessageText": trimmed,
            "lastMessageAt": FieldValue.serverTimestamp(),
            "landlordUnreadCount": isLandlordSender ? 0 : FieldValue.increment(Int64(1)),
            "tenantUnreadCount": isLandlordSender ? FieldValue.increment(Int64(1)) : 0
        ]

        let messageData: [String: Any] = [
            "conversationId": conversationId,
            "senderId": uid,
            "text": trimmed,
            "sentAt": FieldValue.serverTimestamp()
        ]

        let batch = db.batch()
        batch.setData(conversationData, forDocument: conversationRef, merge: true)
        batch.setData(messageData, forDocument: messageRef)

        batch.commit { error in
            if let error = error {
                print("sendMessage error:", error.localizedDescription)
            }
        }
    }
    
    // MARK: - Clear read badge for the tenant tab view
    func markAsRead(conversationId: String, isLandlord: Bool) {
        let fieldToClear = isLandlord ? "landlordUnreadCount" : "tenantUnreadCount"
        db.collection("conversations").document(conversationId).updateData([
            fieldToClear: 0
        ])
    }
    
    func cleanupMessages() {
        messagesListener?.remove()
    }
    
    func cleanupConversations() {
        convosListener?.remove()
    }
    
    func deleteConversation(conversationId: String) {
        db.collection("conversations").document(conversationId).delete()
    }
}
