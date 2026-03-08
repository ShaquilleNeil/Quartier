//
//  LandlordMessages.swift
//  Quartier
//
//  Landlord: conversation list + chat with tenants. Data from Core Data (LDConversation, LDMessage).
//

import SwiftUI
import CoreData

struct LandlordMessages: View {
    var body: some View {
        ConversationListView()
    }
}

// MARK: - Conversation list (inbox)
private struct ConversationListView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \LDConversation.lastMessageAt, ascending: false)],
        animation: .default
    )
    private var conversations: FetchedResults<LDConversation>

    private let primary = Color(red: 0.17, green: 0.55, blue: 0.93)

    var body: some View {
        NavigationStack {
            ZStack {
                bg.ignoresSafeArea()
                if conversations.isEmpty {
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
                        ForEach(conversations, id: \.objectID) { conv in
                            NavigationLink {
                                LandlordChatView(conversation: conv)
                                    .environment(\.managedObjectContext, viewContext)
                            } label: {
                                ConversationRow(conversation: conv, primary: primary)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Messages")
        }
    }

    private var bg: Color {
        Color(uiColor: UIColor { tc in
            tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.06, green: 0.10, blue: 0.13, alpha: 1.0)
            : UIColor(red: 0.96, green: 0.97, blue: 0.97, alpha: 1.0)
        })
    }
}

private struct ConversationRow: View {
    let conversation: LDConversation
    let primary: Color

    private var title: String {
        let listingTitle = conversation.listing?.title ?? "Listing"
        if let name = conversation.tenantName, !name.isEmpty {
            return "\(name) · \(listingTitle)"
        }
        return listingTitle
    }

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(primary.opacity(0.12))
                .frame(width: 48, height: 48)
                .overlay(Image(systemName: "person.fill").foregroundStyle(primary))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(1)
                Text(conversation.lastMessageText ?? "No messages")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            if let date = conversation.lastMessageAt {
                Text(relativeTime(date))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            if conversation.unreadCount > 0 {
                Text("\(conversation.unreadCount)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(primary))
            }
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

// MARK: - Chat view (one conversation)
struct LandlordChatView: View {
    @Environment(\.managedObjectContext) private var viewContext
    let conversation: LDConversation

    @State private var messageText = ""

    private let primary = Color(red: 0.17, green: 0.55, blue: 0.93)

    private var sortedMessages: [LDMessage] {
        let set = conversation.messages as? Set<LDMessage> ?? []
        return set.sorted { ($0.sentAt ?? .distantPast) < ($1.sentAt ?? .distantPast) }
    }

    private var chatTitle: String {
        if let name = conversation.tenantName, !name.isEmpty {
            return name
        }
        return conversation.listing?.title ?? "Chat"
    }

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
            VStack(spacing: 0) {
                chatTopBar
                Divider().opacity(0.2)

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(Array(sortedMessages.enumerated()), id: \.offset) { _, msg in
                                messageRow(msg)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }
                    .onChange(of: sortedMessages.count) { _, count in
                        if count > 0 {
                            withAnimation {
                                proxy.scrollTo(count - 1, anchor: .bottom)
                            }
                        }
                    }
                }

                inputBar
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            markConversationRead()
        }
    }

    private var chatTopBar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(chatTitle)
                    .font(.system(size: 16, weight: .bold))
                if let listing = conversation.listing?.title {
                    Text(listing)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    @ViewBuilder
    private func messageRow(_ msg: LDMessage) -> some View {
        let isSystem = (msg.type == LDMessageType.systemNotice.rawValue || msg.type == LDMessageType.systemSchedule.rawValue)
        let isOut = msg.isFromLandlord

        if isSystem {
            HStack {
                Spacer()
                Text(msg.text ?? "")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color(uiColor: .tertiarySystemBackground)))
                Spacer()
            }
            .padding(.vertical, 4)
        } else if isOut {
            VStack(alignment: .trailing, spacing: 4) {
                Text(msg.text ?? "")
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 14).fill(primary))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                if let sentAt = msg.sentAt {
                    Text(formatTime(sentAt))
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 2)
        } else {
            HStack(alignment: .bottom, spacing: 10) {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 32, height: 32)
                    .overlay(Image(systemName: "person.fill").foregroundStyle(.secondary))
                VStack(alignment: .leading, spacing: 4) {
                    Text(msg.text ?? "")
                        .font(.system(size: 14))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color(uiColor: .secondarySystemBackground)))
                    if let sentAt = msg.sentAt {
                        Text(formatTime(sentAt))
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                            .padding(.leading, 6)
                    }
                }
                Spacer(minLength: 40)
            }
            .padding(.vertical, 2)
        }
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
                    sendMessage()
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

    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: date)
    }

    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let msg = LDMessage(context: viewContext)
        msg.id = UUID()
        msg.text = text
        msg.sentAt = Date()
        msg.type = LDMessageType.text.rawValue
        msg.isFromLandlord = true
        msg.isRead = false
        msg.conversation = conversation

        conversation.lastMessageAt = msg.sentAt
        conversation.lastMessageText = text
        conversation.unreadCount += 1

        do {
            try viewContext.save()
            messageText = ""
        } catch {
            // could show error
        }
    }

    private func markConversationRead() {
        conversation.unreadCount = 0
        try? viewContext.save()
    }

    private var bg: Color {
        Color(uiColor: UIColor { tc in
            tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.06, green: 0.10, blue: 0.13, alpha: 1.0)
            : UIColor(red: 0.96, green: 0.97, blue: 0.97, alpha: 1.0)
        })
    }
}

#Preview {
    LandlordMessages()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
