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
    var lastMessageText: String
    var lastMessageAt: Date
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
    
//    func sendMessage(conversationId: String, text: String) {
//        guard let uid = Auth.auth().currentUser?.uid else { return }
//        let msg = ChatMessage(conversationId: conversationId, senderId: uid, text: text, sentAt: Date())
//        
//        let docRef = db.collection("conversations").document(conversationId).collection("messages").document()
//        try? docRef.setData(from: msg)
//        
//        db.collection("conversations").document(conversationId).updateData([
//            "lastMessageText": text,
//            "lastMessageAt": FieldValue.serverTimestamp()
//        ])
//    }
    
    
    
    
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

        let conversationData: [String: Any] = [
            "listingId": listingId,
            "listingAddress": listingAddress,
            "tenantId": tenantId,
            "landlordId": landlordId,
            "tenantName": tenantName,
            "lastMessageText": trimmed,
            "lastMessageAt": FieldValue.serverTimestamp()
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
    
    
    
    
    
    
    
    func cleanupMessages() {
        messagesListener?.remove()
    }
    
    func cleanupConversations() {
        convosListener?.remove()
    }
}
