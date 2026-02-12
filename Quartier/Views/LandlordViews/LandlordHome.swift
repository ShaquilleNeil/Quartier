//
//  LandlordHome.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-01-29.
//

import SwiftUI

struct LandlordHome: View {
    var body: some View {
        LandlordDashboardView()
    }
}

// MARK: - Dashboard (mapped from HTML "Landlord Dashboard")
private struct LandlordDashboardView: View {

    enum Mode: String, CaseIterable { case landlord = "Landlord", tenant = "Tenant" }

    @State private var mode: Mode = .landlord

    private let primary = Color(red: 0.17, green: 0.55, blue: 0.93)

    private var metrics: [MetricCard] = [
        .init(icon: "house.fill", iconColor: .blue, title: "Active", value: "12",
              subText: "+2%", subTextColor: .green, isHighlighted: false),
        .init(icon: "calendar.badge.checkmark", iconColor: .orange, title: "Visits", value: "5",
              subText: "+1 today", subTextColor: .blue, isHighlighted: false),
        .init(icon: "creditcard.fill", iconColor: .blue, title: "Total Earnings", value: "$14,250.00",
              subText: "+8.4%", subTextColor: .green, isHighlighted: true),
    ]

    private let inquiries: [Inquiry] = [
        .init(name: "Sarah Jenkins", subtitle: "Studio in Plateau • Montreal", timeAgo: "2m ago", hasUnreadDot: true),
        .init(name: "Marc Antoine", subtitle: "2BR Modern Loft • Downtown", timeAgo: "45m ago", hasUnreadDot: false),
    ]

    private let tasks: [TaskItem] = [
        .init(title: "Sign lease renewal - Apt 4B", subtitle: "Due tomorrow", isDone: true),
        .init(title: "Fix leaking tap - Unit 12", subtitle: "Maintenance request", isDone: false),
        .init(title: "Verify insurance - 890 Rue Peel", subtitle: "Compliance check", isDone: false),
    ]

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 14) {

                    // Top Bar
                    HStack(spacing: 12) {
                        Circle()
                            .fill(primary.opacity(0.15))
                            .overlay(Image(systemName: "person.fill").foregroundStyle(primary))
                            .frame(width: 40, height: 40)
                            .overlay(Circle().stroke(primary.opacity(0.2), lineWidth: 2))

                        Text("Quartier")
                            .font(.system(size: 18, weight: .bold))

                        Spacer()

                        Button {} label: {
                            Image(systemName: "bell")
                                .font(.system(size: 20, weight: .semibold))
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)

                    // Mode Toggle
                    HStack {
                        HStack(spacing: 0) {
                            ForEach(Mode.allCases, id: \.self) { m in
                                Button {
                                    mode = m
                                } label: {
                                    Text(m.rawValue)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(mode == m ? .primary : .secondary)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 36)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(mode == m ? cardBg : .clear)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(4)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(chipBg)
                        )
                    }
                    .padding(.horizontal, 16)

                    // Metrics
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            metricSmall(metrics[0])
                            metricSmall(metrics[1])
                        }
                        metricBig(metrics[2])
                    }
                    .padding(.horizontal, 16)

                    // Recent Inquiries
                    VStack(spacing: 10) {
                        HStack {
                            Text("Recent Inquiries")
                                .font(.system(size: 20, weight: .bold))
                            Spacer()
                            Button("View All") {}
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(primary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 6)

                        VStack(spacing: 10) {
                            ForEach(inquiries) { item in
                                inquiryRow(item)
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    // Tasks
                    VStack(spacing: 10) {
                        HStack {
                            Text("Tasks")
                                .font(.system(size: 20, weight: .bold))
                            Spacer()
                            Text("\(tasks.filter { !$0.isDone }.count) PENDING")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(primary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Capsule().fill(primary.opacity(0.12)))
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 6)

                        VStack(spacing: 10) {
                            ForEach(tasks) { t in
                                taskRow(t)
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    Spacer(minLength: 16)
                }
                .padding(.bottom, 18)
            }
        }
    }

    // MARK: - UI Helpers
    private var bg: Color {
        Color(uiColor: UIColor { tc in
            tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.06, green: 0.10, blue: 0.13, alpha: 1.0)
            : UIColor(red: 0.96, green: 0.97, blue: 0.97, alpha: 1.0)
        })
    }

    private var cardBg: Color { Color(uiColor: .secondarySystemBackground) }
    private var chipBg: Color { Color(uiColor: .tertiarySystemBackground) }
    private var border: Color { Color.primary.opacity(0.08) }

    private func metricSmall(_ m: MetricCard) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: m.icon)
                    .foregroundStyle(m.iconColor)
                    .font(.system(size: 16, weight: .semibold))
                Text(m.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Text(m.value)
                .font(.system(size: 26, weight: .bold))

            HStack(spacing: 6) {
                if m.subText.contains("%") {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 12, weight: .semibold))
                }
                Text(m.subText)
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(m.subTextColor)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14).fill(cardBg))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(border, lineWidth: 1))
    }

    private func metricBig(_ m: MetricCard) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: m.icon)
                        .foregroundStyle(primary)
                        .font(.system(size: 16, weight: .semibold))
                    Text(m.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(m.subText)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.green)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.green.opacity(0.12)))
            }

            Text(m.value)
                .font(.system(size: 30, weight: .bold))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14).fill(primary.opacity(0.10)))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(primary.opacity(0.22), lineWidth: 1))
    }

    private func inquiryRow(_ item: Inquiry) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.gray.opacity(0.20))
                .overlay(Image(systemName: "person.crop.circle.fill").foregroundStyle(.secondary))
                .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name).font(.system(size: 16, weight: .semibold)).lineLimit(1)
                Text(item.subtitle).font(.system(size: 12)).foregroundStyle(.secondary).lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text(item.timeAgo).font(.system(size: 10)).foregroundStyle(.secondary)
                if item.hasUnreadDot {
                    Circle().fill(primary).frame(width: 8, height: 8)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 14).fill(cardBg))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(border, lineWidth: 1))
    }

    private func taskRow(_ t: TaskItem) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(t.isDone ? primary : Color.gray.opacity(0.35), lineWidth: 2)
                    .frame(width: 22, height: 22)
                if t.isDone {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(primary)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(t.title).font(.system(size: 14, weight: .medium)).lineLimit(1)
                Text(t.subtitle).font(.system(size: 10)).foregroundStyle(.secondary).lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.gray.opacity(0.7))
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(cardBg))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(border, lineWidth: 1))
    }
}

// MARK: - Small Models
private struct MetricCard: Identifiable {
    let id = UUID()
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let subText: String
    let subTextColor: Color
    let isHighlighted: Bool
}

private struct Inquiry: Identifiable {
    let id = UUID()
    let name: String
    let subtitle: String
    let timeAgo: String
    let hasUnreadDot: Bool
}

private struct TaskItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let isDone: Bool
}

#Preview {
    LandlordHome()
}

