//
//  TenantMessages.swift
//  Quartier
//

import SwiftUI
import CoreData
import FirebaseAuth

struct TenantMessages: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var firebase: FirebaseManager

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \LDConversation.lastMessageAt, ascending: false)],
        animation: .default
    )
    private var allConversations: FetchedResults<LDConversation>

    private let primary = Color(red: 0.17, green: 0.55, blue: 0.93)

    private var currentEmailLower: String {
        (firebase.currentUser?.email ?? Auth.auth().currentUser?.email ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    private var conversations: [LDConversation] {
        guard !currentEmailLower.isEmpty else { return Array(allConversations) }
        return allConversations.filter { conv in
            let email = (conv.tenant?.email ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            return email == currentEmailLower
        }
    }

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
                        Text("Tap Contact Landlord on a listing to start chatting.")
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
                                TenantChatView(conversation: conv)
                                    .environment(\.managedObjectContext, viewContext)
                            } label: {
                                TenantConversationRow(conversation: conv, primary: primary)
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

private struct TenantConversationRow: View {
    let conversation: LDConversation
    let primary: Color

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(primary.opacity(0.12))
                .frame(width: 48, height: 48)
                .overlay(Image(systemName: "building.2.fill").foregroundStyle(primary))

            VStack(alignment: .leading, spacing: 4) {
                Text(conversation.listing?.address ?? "Listing")
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

struct TenantChatView: View {
    @Environment(\.managedObjectContext) private var viewContext
    let conversation: LDConversation

    @State private var messageText = ""
    private let primary = Color(red: 0.17, green: 0.55, blue: 0.93)

    private var sortedMessages: [LDMessage] {
        let set = conversation.messages as? Set<LDMessage> ?? []
        return set.sorted { ($0.sentAt ?? .distantPast) < ($1.sentAt ?? .distantPast) }
    }

    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground).ignoresSafeArea()
            VStack(spacing: 0) {
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
        .navigationTitle(conversation.listing?.address ?? "Chat")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func messageRow(_ msg: LDMessage) -> some View {
        let isSystem = (msg.type == LDMessageType.systemNotice.rawValue || msg.type == LDMessageType.systemSchedule.rawValue)
        let isOut = !msg.isFromLandlord

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
            Text(msg.text ?? "")
                .font(.system(size: 14))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 14).fill(primary))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.vertical, 2)
        } else {
            HStack {
                Text(msg.text ?? "")
                    .font(.system(size: 14))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color(uiColor: .secondarySystemBackground)))
                Spacer(minLength: 40)
            }
            .padding(.vertical, 2)
        }
    }

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextEditor(text: $messageText)
                .font(.system(size: 14))
                .scrollContentBackground(.hidden)
                .frame(minHeight: 40, maxHeight: 120)
                .padding(.horizontal, 8)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color(uiColor: .secondarySystemBackground)))
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

    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let msg = LDMessage(context: viewContext)
        msg.id = UUID()
        msg.text = text
        msg.sentAt = Date()
        msg.type = LDMessageType.text.rawValue
        msg.isFromLandlord = false
        msg.isRead = false
        msg.conversation = conversation

        conversation.lastMessageAt = msg.sentAt
        conversation.lastMessageText = text

        do {
            try viewContext.save()
            messageText = ""
        } catch {
            // no-op for now
        }
    }
}

