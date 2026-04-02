//
//  TenantMessages.swift
//  Quartier
//
import SwiftUI
import FirebaseAuth

struct TenantMessages: View {
    @StateObject private var viewModel = ChatViewModel()
    private let primary = Color(red: 0.17, green: 0.55, blue: 0.93)
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                if viewModel.conversations.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "message")
                            .font(.system(size: 48))
                            .foregroundStyle(primary.opacity(0.5))
                        Text("No conversations yet")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Tap Contact Landlord on a listing to start chatting.")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(viewModel.conversations) { conv in
                            NavigationLink(destination: TenantChatView(conversation: conv)) {
                                ConversationRow(conversation: conv, primary: primary)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Messages")
            .onAppear {
                viewModel.loadConversations(isLandlord: false)
            }
            .onDisappear {
                viewModel.cleanupConversations()
            }
        }
    }
}

struct TenantChatView: View {
    let conversation: Conversation
    @StateObject private var viewModel = ChatViewModel()
    @State private var messageText = ""
    private let primary = Color(red: 0.17, green: 0.55, blue: 0.93)
    private let currentUid = Auth.auth().currentUser?.uid ?? ""
    
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack(spacing: 0) {
                Divider().opacity(0.2)
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(viewModel.messages) { msg in
                                messageBubble(msg)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }
                    .onChange(of: viewModel.messages.count) { _, _ in
                        if let lastId = viewModel.messages.last?.id {
                            withAnimation {
                                proxy.scrollTo(lastId, anchor: .bottom)
                            }
                        }
                    }
                }
                inputBar
            }
        }
        .navigationTitle(conversation.listingAddress.isEmpty ? "Chat" : conversation.listingAddress)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let id = conversation.id {
                viewModel.loadMessages(conversationId: id)
            }
        }
        .onDisappear {
            viewModel.cleanupMessages()
        }
    }
    
    @ViewBuilder
    private func messageBubble(_ msg: ChatMessage) -> some View {
        let isOut = msg.senderId == currentUid
        
        HStack {
            if isOut { Spacer(minLength: 40) }
            
            Text(msg.text)
                .font(.system(size: 14))
                .foregroundStyle(isOut ? .white : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isOut ? primary : Color(uiColor: .secondarySystemBackground))
                )
            
            if !isOut { Spacer(minLength: 40) }
        }
        .padding(.vertical, 2)
        .id(msg.id)
    }
    
    private var inputBar: some View {
        VStack(spacing: 0) {
            Divider().opacity(0.2)
            HStack(alignment: .bottom, spacing: 10) {
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(uiColor: .secondarySystemBackground))
                    TextEditor(text: $messageText)
                        .font(.system(size: 14))
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .frame(minHeight: 40, maxHeight: 120)
                    if messageText.isEmpty {
                        Text("Type a message...")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary.opacity(0.7))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                    }
                }
                Button {
                    if let id = conversation.id {
                        viewModel.sendMessage(
                            conversationId: id,
                            listingId: conversation.listingId,
                            listingAddress: conversation.listingAddress,
                            tenantId: conversation.tenantId,
                            landlordId: conversation.landlordId,
                            tenantName: conversation.tenantName,
                            text: messageText
                        )
                        messageText = ""
                    }
                } label: {
                    Circle()
                        .fill(primary)
                        .frame(width: 40, height: 40)
                        .overlay(Image(systemName: "paperplane.fill").foregroundStyle(.white))
                }
                .buttonStyle(.plain)
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 18)
            .background(.ultraThinMaterial)
        }
    }
}

struct ConversationRow: View {
    let conversation: Conversation
    let primary: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(primary.opacity(0.12))
                .frame(width: 48, height: 48)
                .overlay(Image(systemName: "person.fill").foregroundStyle(primary))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(conversation.listingAddress.isEmpty ? "Listing" : conversation.listingAddress)
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(1)
                Text(conversation.lastMessageText)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer()
            Text(relativeTime(conversation.lastMessageAt))
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }
    
    private func relativeTime(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) {
            let f = DateFormatter()
            f.timeStyle = .short
            return f.string(from: date)
        }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        let f = DateFormatter()
        f.dateStyle = .short
        return f.string(from: date)
    }
}
