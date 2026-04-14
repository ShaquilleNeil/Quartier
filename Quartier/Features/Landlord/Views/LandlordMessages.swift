//
//  LandlordMessages.swift
//  Quartier
//
import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import SDWebImageSwiftUI

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
                                ConversationRow(conversation: conv, primary: primary, isLandlord: true)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    if let id = conv.id {
                                        viewModel.deleteConversation(conversationId: id)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
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
                fetchTenantProfiles()
            }
            .onChange(of: viewModel.conversations) { _, _ in
                fetchTenantProfiles()
            }
            .onDisappear {
                viewModel.cleanupConversations()
            }
        }
    }
    
    private func fetchTenantProfiles() {
        for i in viewModel.conversations.indices {
            let conv = viewModel.conversations[i]
            guard conv.tenantPhoto == nil, !conv.tenantId.isEmpty else { continue }
            
            Task {
                let snapshot = try? await Firestore.firestore()
                    .collection("users")
                    .document(conv.tenantId)
                    .getDocument()
                if let data = snapshot?.data(),
                   let idx = viewModel.conversations.firstIndex(where: { $0.id == conv.id }) {
                    viewModel.conversations[idx].tenantPhoto = data["profilePic"] as? String
                }
            }
        }
    }
}

struct LandlordChatView: View {
    let conversation: Conversation
    @StateObject private var viewModel = ChatViewModel()
    @State private var messageText = ""
    @State private var tenantPhoto: String? = nil
    @State private var tenantName: String? = nil
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
        .navigationTitle(conversation.tenantName.isEmpty ? "Tenant" : conversation.tenantName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(destination: TenantProfilePublicView(tenantId: conversation.tenantId)) {
                    HStack(spacing: 8) {
                        if let name = tenantName {
                            Text(name)
                                .font(.subheadline.bold())
                                .foregroundStyle(.primary)
                        }
                        
                        if let photoURL = tenantPhoto, let url = URL(string: photoURL) {
                            WebImage(url: url) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                Circle()
                                    .fill(primary.opacity(0.12))
                                    .overlay(Image(systemName: "person.fill").foregroundStyle(primary))
                            }
                            .frame(width: 34, height: 34)
                            .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(primary.opacity(0.12))
                                .frame(width: 34, height: 34)
                                .overlay(Image(systemName: "person.fill").foregroundStyle(primary))
                        }
                    }
                }
            }
        }
        .onAppear {
            if let id = conversation.id {
                viewModel.loadMessages(conversationId: id)
                viewModel.markAsRead(conversationId: id, isLandlord: true)
            }
            Task {
                let snapshot = try? await Firestore.firestore()
                    .collection("users")
                    .document(conversation.tenantId)
                    .getDocument()
                if let data = snapshot?.data() {
                    tenantPhoto = data["profilePic"] as? String
                    let email = data["email"] as? String ?? ""
                    tenantName = data["name"] as? String ?? email.components(separatedBy: "@").first
                }
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

