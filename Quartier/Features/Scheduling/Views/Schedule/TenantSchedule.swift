//
//  TenantSchedule.swift
//  Quartier
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct TenantSchedule: View {
    // MARK: - Properties
    @StateObject private var scheduleVM = ScheduleViewModel()
    @EnvironmentObject var auth: AuthService
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedDate = Date()

    // MARK: - Computed Properties
    private var eventsOnSelectedDay: [ScheduleEvent] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: selectedDate)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start
        return scheduleVM.events.filter { $0.startAt >= start && $0.startAt < end }
    }

    // MARK: - Body
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // MARK: Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Schedule")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                        }
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)

                    // MARK: Calendar Picker
                    DatePicker("", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 18).fill(Color(.secondarySystemBackground)))
                        .padding(.horizontal, 16)

                    // MARK: Events List
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Appointments")
                            .font(.system(size: 18, weight: .bold))
                            .padding(.horizontal, 16)

                        if eventsOnSelectedDay.isEmpty {
                            Text("No events scheduled for this day.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                        } else {
                            ForEach(eventsOnSelectedDay) { event in
                                ScheduleCard(
                                    title: event.title,
                                    subtitle: formatEventTime(event),
                                    notes: event.notes
                                )
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                }
                .padding(.bottom, 32)
            }
        }
        .navigationBarHidden(true)
        // MARK: - Lifecycle Modifiers
        .onAppear {
            if let id = auth.rentedListingId {
                scheduleVM.loadTenantEvents(listingId: id)
            }
        }
    }
    
    // MARK: - Helper Methods
        private func formatEventTime(_ event: ScheduleEvent) -> String {
            let formatter = DateFormatter()
            if event.allDay {
                formatter.dateStyle = .medium
                formatter.timeStyle = .none
                return "\(formatter.string(from: event.startAt)) • All day"
            } else {
                formatter.dateStyle = .medium
                formatter.timeStyle = .short
                return formatter.string(from: event.startAt)
            }
        }
}

// MARK: - Subviews
private struct ScheduleCard: View {
    let title: String
    let subtitle: String
    let notes: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.blue)
            
            if let notes = notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
}
