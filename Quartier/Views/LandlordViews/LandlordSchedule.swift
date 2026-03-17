//
//  LandlordSchedule.swift
//  Quartier
//
//  Created by Shaquille O Neil on 2026-01-29.
//

import SwiftUI
import CoreData

struct LandlordSchedule: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \LDScheduleEvent.startAt, ascending: true)],
        animation: .default
    )
    private var allEvents: FetchedResults<LDScheduleEvent>

    @State private var selectedDate: Date = Date()
    @State private var showNewEvent = false
    @State private var showEditEvent = false
    @State private var eventToEdit: LDScheduleEvent?
    private let primary = Color(red: 0.17, green: 0.55, blue: 0.93)

    private var eventsOnSelectedDay: [LDScheduleEvent] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: selectedDate)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start
        return allEvents.filter { event in
            guard let s = event.startAt else { return false }
            return s >= start && s < end
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
                            ForEach(eventsOnSelectedDay, id: \.objectID) { event in
                                Button {
                                    eventToEdit = event
                                    showEditEvent = true
                                } label: {
                                    scheduleRow(
                                        title: event.title ?? "Event",
                                        subtitle: formatEventTime(event)
                                    )
                                }
                                .buttonStyle(.plain)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        deleteEvent(event)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
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
        .sheet(isPresented: $showNewEvent) {
            NewScheduleEventView(onSaved: { showNewEvent = false })
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(isPresented: $showEditEvent) {
            if let event = eventToEdit {
                NewScheduleEventView(existingEvent: event, onSaved: { showEditEvent = false })
                    .environment(\.managedObjectContext, viewContext)
            }
        }
        .onChange(of: showEditEvent) { _, visible in
            if !visible { eventToEdit = nil }
        }
    }

    private func formatEventTime(_ event: LDScheduleEvent) -> String {
        guard let start = event.startAt else { return "" }
        if event.allDay {
            return "All day"
        }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        var text = formatter.string(from: start)
        if let end = event.endAt {
            text += " – \(formatter.string(from: end))"
        }
        return text
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

    private func deleteEvent(_ event: LDScheduleEvent) {
        viewContext.delete(event)
        do {
            try viewContext.save()
        } catch {
            print("Failed to delete event:", error)
        }
    }
}

#Preview {
    LandlordSchedule()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
