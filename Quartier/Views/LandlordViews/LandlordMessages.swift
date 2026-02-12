//
//  LandlordMessages.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-01-29.
//

import SwiftUI

struct LandlordMessages: View {
    var body: some View {
        ContactChatView()
    }
}

private enum ChatItem: Identifiable {
    case meta(String)
    case day(String, primary: Bool)
    case inText(text: String, time: String)
    case inDoc(fileName: String, sizeText: String, time: String)
    case outText(text: String, time: String, read: Bool)
    case outImage(fileName: String, time: String, read: Bool)
    case typing

    var id: String {
        switch self {
        case .meta(let t): return "meta-\(t)"
        case .day(let t, _): return "day-\(t)"
        case .inText(let t, let time): return "in-\(time)-\(t.hashValue)"
        case .inDoc(let f, _, let time): return "doc-\(time)-\(f)"
        case .outText(let t, let time, _): return "out-\(time)-\(t.hashValue)"
        case .outImage(let f, let time, _): return "img-\(time)-\(f)"
        case .typing: return "typing"
        }
    }
}

private struct ContactChatView: View {

    private let primary = Color(red: 0.17, green: 0.55, blue: 0.93)

    @State private var messageText: String = ""

    private let items: [ChatItem] = [
        .meta("Skyline Apartments - Unit 4B"),
        .day("Yesterday", primary: false),
        .inText(text: "Hi there! I've uploaded the lease agreement for your review. Let me know if you have any questions.", time: "4:12 PM"),
        .inDoc(fileName: "Lease_Agreement_Unit4B.pdf", sizeText: "2.4 MB • PDF", time: "4:12 PM"),
        .day("Today", primary: true),
        .outText(text: "Thanks! I'll review it tonight and sign it by tomorrow morning.", time: "9:45 AM", read: true),
        .outImage(fileName: "Photo_Deposit_Receipt.jpg", time: "10:02 AM", read: true),
        .typing
    ]

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                Divider().opacity(0.2)

                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(items) { item in
                            row(item)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }

                inputBar
            }
        }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(primary.opacity(0.12))
                .frame(width: 40, height: 40)
                .overlay(Image(systemName: "person.fill").foregroundStyle(primary))

            VStack(alignment: .leading, spacing: 2) {
                Text("Marcus Thompson")
                    .font(.system(size: 14, weight: .bold))
                Text("PROPERTY MANAGER")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .tracking(1.2)
            }

            Spacer()

            Button {} label: {
                Circle()
                    .fill(primary.opacity(0.10))
                    .frame(width: 40, height: 40)
                    .overlay(Image(systemName: "info.circle").foregroundStyle(primary))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    @ViewBuilder
    private func row(_ item: ChatItem) -> some View {
        switch item {
        case .meta(let text):
            HStack {
                Spacer()
                Text(text)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(.thinMaterial))
                    .overlay(Capsule().stroke(Color.primary.opacity(0.08), lineWidth: 1))
                Spacer()
            }
            .padding(.vertical, 6)

        case .day(let text, let isPrimary):
            HStack(spacing: 12) {
                Rectangle().fill(Color.primary.opacity(0.10)).frame(height: 1)
                Text(text.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(isPrimary ? primary : .secondary)
                    .tracking(2)
                Rectangle().fill(Color.primary.opacity(0.10)).frame(height: 1)
            }
            .padding(.vertical, 10)

        case .inText(let text, let time):
            HStack(alignment: .bottom, spacing: 10) {
                Circle()
                    .fill(Color.gray.opacity(0.20))
                    .frame(width: 32, height: 32)
                    .overlay(Image(systemName: "person.fill").foregroundStyle(.secondary))

                VStack(alignment: .leading, spacing: 4) {
                    Text(text)
                        .font(.system(size: 14))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color(uiColor: .secondarySystemBackground)))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.primary.opacity(0.06), lineWidth: 1))

                    Text(time).font(.system(size: 10)).foregroundStyle(.secondary).padding(.leading, 6)
                }

                Spacer(minLength: 40)
            }
            .padding(.vertical, 2)

        case .inDoc(let fileName, let sizeText, let time):
            HStack(alignment: .bottom, spacing: 10) {
                Circle()
                    .fill(Color.gray.opacity(0.20))
                    .frame(width: 32, height: 32)
                    .overlay(Image(systemName: "person.fill").foregroundStyle(.secondary))

                VStack(alignment: .leading, spacing: 6) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(primary.opacity(0.12))
                                .frame(width: 40, height: 40)
                                .overlay(Image(systemName: "doc.text").foregroundStyle(primary))

                            VStack(alignment: .leading, spacing: 3) {
                                Text(fileName).font(.system(size: 14, weight: .semibold)).lineLimit(1)
                                Text(sizeText).font(.system(size: 11)).foregroundStyle(.secondary)
                            }

                            Spacer()
                        }

                        Button {} label: {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.down.circle")
                                Text("Download").font(.system(size: 12, weight: .bold))
                            }
                            .foregroundStyle(primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color(uiColor: .tertiarySystemBackground)))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color(uiColor: .secondarySystemBackground)))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.primary.opacity(0.06), lineWidth: 1))

                    Text(time).font(.system(size: 10)).foregroundStyle(.secondary).padding(.leading, 6)
                }

                Spacer(minLength: 40)
            }
            .padding(.vertical, 2)

        case .outText(let text, let time, let read):
            VStack(alignment: .trailing, spacing: 4) {
                Text(text)
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 14).fill(primary))
                    .shadow(color: primary.opacity(0.18), radius: 8, x: 0, y: 4)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                HStack(spacing: 6) {
                    Text(time).font(.system(size: 10)).foregroundStyle(.secondary)
                    if read {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(primary)
                    }
                }
                .padding(.trailing, 6)
            }
            .padding(.vertical, 2)

        case .outImage(let fileName, let time, let read):
            VStack(alignment: .trailing, spacing: 6) {
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(primary.opacity(0.10))
                        .frame(height: 160)
                        .overlay(Image(systemName: "photo").font(.system(size: 28, weight: .semibold)).foregroundStyle(primary))

                    HStack {
                        Text(fileName)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                        Spacer()
                    }
                    .padding(10)
                    .background(primary)
                }
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(primary, lineWidth: 2))
                .shadow(color: primary.opacity(0.18), radius: 10, x: 0, y: 4)
                .frame(maxWidth: 300, alignment: .trailing)

                HStack(spacing: 6) {
                    Text(time).font(.system(size: 10)).foregroundStyle(.secondary)
                    if read {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(primary)
                    }
                }
                .padding(.trailing, 6)
            }
            .padding(.vertical, 2)

        case .typing:
            HStack(spacing: 10) {
                Circle()
                    .fill(Color.gray.opacity(0.20))
                    .frame(width: 32, height: 32)
                    .overlay(Image(systemName: "person.fill").foregroundStyle(.secondary))

                TypingDots()
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color(uiColor: .secondarySystemBackground)))

                Spacer(minLength: 40)
            }
            .opacity(0.75)
            .padding(.vertical, 2)
        }
    }

    private var inputBar: some View {
        VStack(spacing: 0) {
            Divider().opacity(0.2)

            HStack(alignment: .bottom, spacing: 10) {
                HStack(spacing: 6) {
                    Button {} label: {
                        Circle().fill(Color.primary.opacity(0.08))
                            .frame(width: 40, height: 40)
                            .overlay(Image(systemName: "plus.circle").foregroundStyle(.secondary))
                    }.buttonStyle(.plain)

                    Button {} label: {
                        Circle().fill(Color.primary.opacity(0.08))
                            .frame(width: 40, height: 40)
                            .overlay(Image(systemName: "photo").foregroundStyle(.secondary))
                    }.buttonStyle(.plain)
                }

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
                    messageText = ""
                } label: {
                    Circle().fill(primary)
                        .frame(width: 40, height: 40)
                        .overlay(Image(systemName: "paperplane.fill").foregroundStyle(.white))
                        .shadow(color: primary.opacity(0.22), radius: 10, x: 0, y: 4)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 18)
            .background(.ultraThinMaterial)
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

private struct TypingDots: View {
    @State private var animate = false

    var body: some View {
        HStack(spacing: 6) {
            dot(delay: 0.0)
            dot(delay: 0.2)
            dot(delay: 0.4)
        }
        .onAppear {
            animate = true
        }
    }

    private func dot(delay: Double) -> some View {
        Circle()
            .fill(Color.secondary.opacity(0.6))
            .frame(width: 6, height: 6)
            .offset(y: animate ? -4 : 0)
            .animation(
                .easeInOut(duration: 0.6)
                    .repeatForever(autoreverses: true)
                    .delay(delay),
                value: animate
            )
    }
}

#Preview {
    LandlordMessages()
}
