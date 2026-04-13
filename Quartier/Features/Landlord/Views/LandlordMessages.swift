//
//  LandlordMessages.swift
//  Quartier
//
import SwiftUI
import FirebaseAuth

struct LandlordMessages: View {
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
                        Text("Conversations appear when tenants reach out about a listing.")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(viewModel.conversations) { conv in
                            NavigationLink(destination: LandlordChatView(conversation: conv)) {
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
                viewModel.loadConversations(isLandlord: true)
            }
            .onDisappear {
                viewModel.cleanupConversations()
            }
        }
    }
}

struct LandlordChatView: View {
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
        
        .navigationTitle(conversation.listingAddress.isEmpty ? "Tenant" : conversation.listingAddress)
        .navigationBarTitleDisplayMode(.inline)
        
        .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink(destination: TenantProfilePublicView(tenantId: conversation.tenantId)) {
                            HStack(spacing: 4) {
                                Text("Profile")
                                    .font(.subheadline.bold())
                                Image(systemName: "person.crop.circle")
                            }
                        }
                    }
                }
        
        .onAppear {
            if let id = conversation.id {
                viewModel.loadMessages(conversationId: id)
                viewModel.markAsRead(conversationId: id, isLandlord: true)
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
                
                // FIXED: Changed TextEditor to an expanding TextField
                TextField("Type a message...", text: $messageText, axis: .vertical)
                    .font(.system(size: 14))
                    .lineLimit(1...5)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color(uiColor: .secondarySystemBackground))
                    )

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
                .padding(.bottom, 2)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 18)
            .background(.ultraThinMaterial)
        }
    }
}
