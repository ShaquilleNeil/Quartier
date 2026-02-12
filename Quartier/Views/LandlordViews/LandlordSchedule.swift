//
//  LandlordSchedule.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-01-29.
//

import SwiftUI

struct LandlordSchedule: View {
    @State private var selectedDate: Date = Date()
    private let primary = Color(red: 0.17, green: 0.55, blue: 0.93)

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("Scheduler")
                            .font(.system(size: 20, weight: .bold))
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Select a date")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.secondary)

                        DatePicker("Schedule", selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 18).fill(cardBg))
                            .overlay(RoundedRectangle(cornerRadius: 18).stroke(border, lineWidth: 1))
                    }
                    .padding(.horizontal, 16)

                    // Placeholder “Appointments”
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Appointments")
                            .font(.system(size: 18, weight: .bold))

                        scheduleRow(title: "Viewing • Unit 4B", subtitle: "2:00 PM • Sarah Jenkins")
                        scheduleRow(title: "Maintenance • Unit 12", subtitle: "4:30 PM • Plumbing")
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 18).fill(cardBg))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(border, lineWidth: 1))
                    .padding(.horizontal, 16)

                    Spacer(minLength: 20)
                }
                .padding(.bottom, 18)
            }
        }
    }

    private func scheduleRow(title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 12)
                .fill(primary.opacity(0.12))
                .frame(width: 44, height: 44)
                .overlay(Image(systemName: "calendar").foregroundStyle(primary))

            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 14, weight: .semibold))
                Text(subtitle).font(.system(size: 11)).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }

    private var bg: Color {
        Color(uiColor: UIColor { tc in
            tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.06, green: 0.10, blue: 0.13, alpha: 1.0)
            : UIColor(red: 0.96, green: 0.97, blue: 0.97, alpha: 1.0)
        })
    }

    private var cardBg: Color { Color(uiColor: .secondarySystemBackground) }
    private var border: Color { Color.primary.opacity(0.08) }
}

#Preview {
    LandlordSchedule()
}
