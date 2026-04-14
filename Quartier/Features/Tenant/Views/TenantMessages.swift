//
//  TenantMessages.swift
//  Quartier
//
import SwiftUI
import FirebaseAuth
import SDWebImageSwiftUI

struct TenantMessages: View {
    @StateObject private var viewModel = ChatViewModel()
    @EnvironmentObject var firebase: FirebaseManager
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
                viewModel.loadConversations(isLandlord: false)
                fetchLandlordProfiles()
            }
            .onDisappear {
                viewModel.cleanupConversations()
            }
            .onChange(of: viewModel.conversations) { _, _ in
                fetchLandlordProfiles()
            }
        }
    }
    
    private func fetchLandlordProfiles() {
        for i in viewModel.conversations.indices {
            let conv = viewModel.conversations[i]
            guard conv.landlordName == nil, !conv.landlordId.isEmpty else { continue }
            
            Task {
                let profile = await firebase.fetchLandlordProfile(uid: conv.landlordId)
                if let idx = viewModel.conversations.firstIndex(where: { $0.id == conv.id }) {
                    viewModel.conversations[idx].landlordName = profile.name
                    viewModel.conversations[idx].landlordPhoto = profile.photoURL
                }
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
    @State private var landlordPhoto: String? = nil
       @State private var landlordName: String? = nil
    @EnvironmentObject var firebase: FirebaseManager 
    
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(destination: LandlordProfile(
                    landlordId: conversation.landlordId,
                    publicView: true
                )) {
                    HStack(spacing: 8) {
                        if let name = landlordName {
                            Text(name)
                                .font(.subheadline.bold())
                                .foregroundStyle(.primary)
                        }
                        
                        if let photoURL = landlordPhoto, let url = URL(string: photoURL) {
                            WebImage(url: url) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                Circle()
                                    .fill(Color.blue.opacity(0.12))
                                    .overlay(Image(systemName: "person.fill").foregroundStyle(.blue))
                            }
                            .frame(width: 34, height: 34)
                            .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color.blue.opacity(0.12))
                                .frame(width: 34, height: 34)
                                .overlay(Image(systemName: "person.fill").foregroundStyle(.blue))
                        }
                    }
                }
            }
        }
        .navigationTitle({
            if let name = conversation.landlordName, !name.isEmpty {
                return "\(name) · \(conversation.listingAddress)"
            }
            return conversation.listingAddress.isEmpty ? "Chat" : conversation.listingAddress
        }())
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let id = conversation.id {
                viewModel.loadMessages(conversationId: id)
                viewModel.markAsRead(conversationId: id, isLandlord: false)
            }
            
            Task {
                   let profile = await firebase.fetchLandlordProfile(uid: conversation.landlordId)
                   landlordPhoto = profile.photoURL
                   landlordName = profile.name
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
                            tenantId: currentUid,
                            landlordId: conversation.landlordId,
                            tenantName: "Tenant",
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

struct ConversationRow: View {
    let conversation: Conversation
    let primary: Color
    var isLandlord: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            let photoURL = isLandlord ? conversation.tenantPhoto : conversation.landlordPhoto
            
            if let photoURL, let url = URL(string: photoURL) {
                WebImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Circle().fill(primary.opacity(0.12))
                        .overlay(Image(systemName: "person.fill").foregroundStyle(primary))
                }
                .frame(width: 48, height: 48)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(primary.opacity(0.12))
                    .frame(width: 48, height: 48)
                    .overlay(Image(systemName: "person.fill").foregroundStyle(primary))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                let title: String = {
                    if isLandlord {
                        // Landlord sees: "Tenant Name · Listing Address"
                        let name = conversation.tenantName.isEmpty ? nil : conversation.tenantName
                        if let name {
                            return "\(name) · \(conversation.listingAddress)"
                        }
                        return conversation.listingAddress.isEmpty ? "Listing" : conversation.listingAddress
                    } else {
                        // Tenant sees: "Landlord Name · Listing Address"
                        if let name = conversation.landlordName, !name.isEmpty {
                            return "\(name) · \(conversation.listingAddress)"
                        }
                        return conversation.listingAddress.isEmpty ? "Listing" : conversation.listingAddress
                    }
                }()
                
                Text(title)
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
            let f = DateFormatter(); f.timeStyle = .short; return f.string(from: date)
        }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        let f = DateFormatter(); f.dateStyle = .short; return f.string(from: date)
    }
}
