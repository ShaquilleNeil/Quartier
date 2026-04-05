//
//  LandlordSchedule.swift
//  Quartier
//

import SwiftUI
import CoreData

struct LandlordSchedule: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @StateObject private var viewModel = ScheduleViewModel()

    @FetchRequest(
        sortDescriptors: [],
        animation: .default
    )
    private var allCoreDataListings: FetchedResults<LDListing>

    @State private var selectedDate: Date = Date()
    @State private var showNewEvent = false
    @State private var editingEvent: ScheduleEvent?
    
    private let primary = Color(red: 0.17, green: 0.55, blue: 0.93)

    private var eventsOnSelectedDay: [ScheduleEvent] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: selectedDate)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start
        return viewModel.events.filter { event in
            return event.startAt >= start && event.startAt < end
        }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
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

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Appointments")
                            .font(.system(size: 18, weight: .bold))

                        if eventsOnSelectedDay.isEmpty {
                            Text("No events on this day")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 12)
                        } else {
                            ForEach(eventsOnSelectedDay) { event in
                                scheduleRow(
                                    title: event.title,
                                    address: getAddress(for: event),
                                    time: formatEventTime(event)
                                )
                                .overlay(alignment: .trailing) {
                                    HStack(spacing: 10) {
                                        Button {
                                            editingEvent = event
                                        } label: {
                                            Image(systemName: "pencil")
                                                .foregroundStyle(primary)
                                        }
                                        .buttonStyle(.plain)

                                        Button(role: .destructive) {
                                            viewModel.deleteEvent(event)
                                        } label: {
                                            Image(systemName: "trash")
                                                .foregroundStyle(.red)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.trailing, 4)
                                }
                            }
                        }
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 18).fill(cardBg))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(border, lineWidth: 1))
                    .padding(.horizontal, 16)

                    Spacer(minLength: 80)
                }
                .padding(.bottom, 18)
            }

            Button {
                showNewEvent = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(Circle().fill(primary))
                    .shadow(color: primary.opacity(0.25), radius: 12, x: 0, y: 6)
            }
            .padding(.trailing, 18)
            .padding(.bottom, 18)
        }
        // MARK: - Added Missing Triggers
        .onAppear {
            viewModel.loadEvents()
        }
        .onDisappear {
            viewModel.cleanup()
        }
        .sheet(isPresented: $showNewEvent) {
            NewScheduleEventView(existingEvent: nil) {
                showNewEvent = false
            }
            .environment(\.managedObjectContext, viewContext)
        }
        .sheet(item: $editingEvent) { event in
            NewScheduleEventView(existingEvent: event) {
                editingEvent = nil
            }
            .environment(\.managedObjectContext, viewContext)
        }
    }

    private func getAddress(for event: ScheduleEvent) -> String {
        if event.scopeAll { return "All Properties" }
        if event.listingIds.isEmpty { return "No linked property" }
        
        let matchedListings = allCoreDataListings.filter { listing in
            guard let id = listing.id?.uuidString else { return false }
            return event.listingIds.contains(id)
        }
        
        if matchedListings.isEmpty { return "Multiple Properties" }
        if matchedListings.count == 1 { return matchedListings.first?.address ?? "Unknown Address" }
        return "\(matchedListings.first?.address ?? "Multiple") + \(matchedListings.count - 1) more"
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

    private func scheduleRow(title: String, address: String, time: String) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 12)
                .fill(primary.opacity(0.12))
                .frame(width: 44, height: 44)
                .overlay(Image(systemName: "calendar").foregroundStyle(primary))

            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 14, weight: .semibold))
                Text(address).font(.system(size: 12)).foregroundStyle(primary)
                Text(time).font(.system(size: 11)).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }

    private var bg: Color { Color(uiColor: .systemGroupedBackground) }
    private var cardBg: Color { Color(uiColor: .secondarySystemBackground) }
    private var border: Color { Color.primary.opacity(0.08) }
}
