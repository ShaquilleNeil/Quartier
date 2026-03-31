//
//  ScheduleEventService.swift
//  Quartier
//
//  Created by Frostmourne on 2026-03-01.
//

import Foundation
import CoreData

final class ScheduleEventService {

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - Public API

    @discardableResult
    func createScheduleEvent(
        title: String,
        notes: String? = nil,
        locationDetail: String? = nil,
        startAt: Date,
        endAt: Date,
        allDay: Bool = false,
        timezone: String? = "America/Montreal",
        recurrenceRule: String? = nil,
        visibility: Int16 = 1,          // 0 landlordOnly, 1 tenantVisible
        tenantRelevant: Bool = true,
        scope: ScheduleScope,
        pushToConversations: Bool = true
    ) throws -> LDScheduleEvent {

        let now = Date()

        let event = LDScheduleEvent(context: context)
        event.id = UUID()
        event.title = title
        event.notes = notes
        event.locationDetail = locationDetail
        event.startAt = startAt
        event.endAt = endAt
        event.allDay = allDay
        event.timezone = timezone
        event.recurrenceRule = recurrenceRule
        event.visibility = visibility
        event.tenantRelevant = tenantRelevant
        event.createdAt = now
        event.updatedAt = now

        // ✅ 你模型里字段叫 syncStatus / version / lastModifiedBy
        event.syncStatus = LDSyncStatus.localOnly.rawValue
        event.version = 1
        event.lastModifiedBy = "landlord"

        // 2) Targets
        switch scope {
        case .all:
            let t = LDScheduleTarget(context: context)
            t.id = UUID()
            t.createdAt = now
            t.scopeType = LDScopeType.all.rawValue
            t.scheduleEvent = event
            t.listing = nil

        case .listings(let listings):
            for listing in listings {
                let t = LDScheduleTarget(context: context)
                t.id = UUID()
                t.createdAt = now
                t.scopeType = LDScopeType.listing.rawValue
                t.scheduleEvent = event
                t.listing = listing
            }
        }

        // 3) 可选：推系统消息（通常 tenantVisible + tenantRelevant 才推）
        if pushToConversations && visibility == 1 && tenantRelevant {
            try pushSystemMessageForSchedule(event, scope: scope, sentAt: now)
        }

        try context.save()
        return event
    }

    @discardableResult
    func updateScheduleEvent(
        _ event: LDScheduleEvent,
        title: String,
        notes: String? = nil,
        locationDetail: String? = nil,
        startAt: Date,
        endAt: Date,
        allDay: Bool = false,
        timezone: String? = "America/Montreal",
        recurrenceRule: String? = nil,
        visibility: Int16 = 1,
        tenantRelevant: Bool = true,
        scope: ScheduleScope
    ) throws -> LDScheduleEvent {
        let now = Date()

        event.title = title
        event.notes = notes
        event.locationDetail = locationDetail
        event.startAt = startAt
        event.endAt = endAt
        event.allDay = allDay
        event.timezone = timezone
        event.recurrenceRule = recurrenceRule
        event.visibility = visibility
        event.tenantRelevant = tenantRelevant
        event.updatedAt = now
        event.version += 1
        event.lastModifiedBy = "landlord"

        if let oldTargets = event.targets as? Set<LDScheduleTarget> {
            for t in oldTargets {
                context.delete(t)
            }
        }

        switch scope {
        case .all:
            let t = LDScheduleTarget(context: context)
            t.id = UUID()
            t.createdAt = now
            t.scopeType = LDScopeType.all.rawValue
            t.scheduleEvent = event
            t.listing = nil
        case .listings(let listings):
            for listing in listings {
                let t = LDScheduleTarget(context: context)
                t.id = UUID()
                t.createdAt = now
                t.scopeType = LDScopeType.listing.rawValue
                t.scheduleEvent = event
                t.listing = listing
            }
        }

        try context.save()
        return event
    }

    /// Safe update path: modify event fields only, keep existing targets/scope unchanged.
    @discardableResult
    func updateScheduleEventBasics(
        _ event: LDScheduleEvent,
        title: String,
        notes: String? = nil,
        locationDetail: String? = nil,
        startAt: Date,
        endAt: Date,
        allDay: Bool = false,
        timezone: String? = "America/Montreal",
        recurrenceRule: String? = nil,
        visibility: Int16 = 1,
        tenantRelevant: Bool = true
    ) throws -> LDScheduleEvent {
        let now = Date()
        event.title = title
        event.notes = notes
        event.locationDetail = locationDetail
        event.startAt = startAt
        event.endAt = endAt
        event.allDay = allDay
        event.timezone = timezone
        event.recurrenceRule = recurrenceRule
        event.visibility = visibility
        event.tenantRelevant = tenantRelevant
        event.updatedAt = now
        event.version += 1
        event.lastModifiedBy = "landlord"
        try context.save()
        return event
    }

    func deleteScheduleEvent(_ event: LDScheduleEvent, removeLinkedMessages: Bool = true) throws {
        if removeLinkedMessages {
            let req = NSFetchRequest<LDMessage>(entityName: "LDMessage")
            req.predicate = NSPredicate(format: "linkedScheduleEvent == %@", event)
            let linked = try context.fetch(req)
            for msg in linked {
                context.delete(msg)
            }
        }

        context.delete(event)
        try context.save()
    }

    // MARK: - Scope
    enum ScheduleScope {
        case all
        case listings([LDListing])
    }

    // MARK: - Private
    private func pushSystemMessageForSchedule(_ event: LDScheduleEvent, scope: ScheduleScope, sentAt: Date) throws {

        let affectedConversations: [LDConversation]

        switch scope {
        case .all:
            affectedConversations = try fetchAllConversations()

        case .listings(let listings):
            var all: [LDConversation] = []
            for listing in listings {
                if let convSet = listing.conversations as? Set<LDConversation> {
                    all.append(contentsOf: convSet)
                }
            }
            affectedConversations = Array(Set(all))
        }

        // 消息文案：你也可以做得更精致，这里先给调试用
        let timeText: String = {
            let f = DateFormatter()
            f.dateStyle = .medium
            f.timeStyle = .short
            return "\(f.string(from: event.startAt ?? sentAt))"
        }()

        for conversation in affectedConversations {
            let msg = LDMessage(context: context)
            msg.id = UUID()
            msg.sentAt = sentAt
            msg.type = LDMessageType.systemSchedule.rawValue
            msg.text = "🗓️ Schedule: \(event.title ?? "") • \(timeText)"
            msg.isFromLandlord = true
            msg.isRead = false

            msg.conversation = conversation
            msg.linkedScheduleEvent = event

            // 更新 conversation 缓存字段
            conversation.lastMessageAt = sentAt
            conversation.lastMessageText = msg.text
            conversation.unreadCount += 1
        }
    }

    private func fetchAllConversations() throws -> [LDConversation] {
        let req = NSFetchRequest<LDConversation>(entityName: "LDConversation")
        return try context.fetch(req)
    }
}
