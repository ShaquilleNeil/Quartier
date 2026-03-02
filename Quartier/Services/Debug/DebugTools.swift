//
//  DebugTools.swift
//  Quartier
//
//  Created by Frostmourne on 2026-03-02.
//

import Foundation
import CoreData

enum DebugTools {

    // MARK: - Seed

    static func seedListingAndConversation(context: NSManagedObjectContext) {
        let now = Date()

        let listing = LDListing(context: context)
        listing.id = UUID()
        listing.title = "Unit 1206"
        listing.cityLine = "Montreal"
        listing.priceMonthly = 1800
        listing.beds = 2
        listing.baths = 1
        listing.status = "active"
        listing.createdAt = now
        listing.updatedAt = now

        let convo = LDConversation(context: context)
        convo.id = UUID()
        convo.createdAt = now
        convo.lastMessageAt = now
        convo.lastMessageText = "Conversation seeded"
        convo.tenantName = "Test Tenant"
        convo.unreadCount = 0
        convo.listing = listing

        do {
            try context.save()
            print("✅ Seeded listing + conversation")
        } catch {
            print("❌ Seed failed:", error)
        }
    }

    static func seedTenantAndTenancy(context: NSManagedObjectContext) {
        do {
            let listings = try context.fetch(NSFetchRequest<LDListing>(entityName: "LDListing"))
            guard let listing = listings.first else {
                print("❌ No listing found. Seed listing first.")
                return
            }

            let now = Date()

            let tenant = LDTenant(context: context)
            tenant.id = UUID()
            tenant.displayName = "Test Tenant"
            tenant.email = "tenant@test.com"
            tenant.createdAt = now
            tenant.updatedAt = now

            let tenancy = LDTenancy(context: context)
            tenancy.id = UUID()
            tenancy.startDate = now.addingTimeInterval(-86400)
            tenancy.endDate = nil
            tenancy.status = "active"
            tenancy.createdAt = now
            tenancy.updatedAt = now
            tenancy.tenant = tenant
            tenancy.listing = listing

            try context.save()
            print("✅ Seeded tenant + active tenancy -> listing:", listing.title ?? "-")
        } catch {
            print("❌ Seed tenant/tenancy failed:", error)
        }
    }

    // MARK: - Create Notice / Schedule

    static func createNoticeAll(context: NSManagedObjectContext) {
        let service = NoticeService(context: context)

        do {
            _ = try service.createNotice(
                title: "Water Shutdown",
                body: "Tomorrow 9:00–12:00. Please prepare.",
                category: "maintenance",
                priority: 1,
                publishAt: Date(),
                expireAt: nil,
                scope: .all,
                pushToConversations: true
            )
            print("✅ Notice created (ALL) + pushed messages")
        } catch {
            print("❌ Create notice failed:", error)
        }
    }

    static func createScheduleAll(context: NSManagedObjectContext) {
        let service = ScheduleEventService(context: context)

        let start = Date().addingTimeInterval(3600)
        let end = start.addingTimeInterval(3600)

        do {
            _ = try service.createScheduleEvent(
                title: "Fire Alarm Inspection",
                notes: "Please ensure access to unit.",
                locationDetail: "Lobby / Unit door",
                startAt: start,
                endAt: end,
                allDay: false,
                visibility: 1,
                tenantRelevant: true,
                scope: .all,
                pushToConversations: true
            )
            print("✅ Schedule created (ALL) + pushed messages")
        } catch {
            print("❌ Create schedule failed:", error)
        }
    }

    // MARK: - Print / Inspect

    static func printCounts(context: NSManagedObjectContext) {
        do {
            let notices = try context.fetch(NSFetchRequest<LDNotice>(entityName: "LDNotice"))
            let noticeTargets = try context.fetch(NSFetchRequest<LDNoticeTarget>(entityName: "LDNoticeTarget"))
            let messages = try context.fetch(NSFetchRequest<LDMessage>(entityName: "LDMessage"))
            let convos = try context.fetch(NSFetchRequest<LDConversation>(entityName: "LDConversation"))
            let listings = try context.fetch(NSFetchRequest<LDListing>(entityName: "LDListing"))
            let schedules = try context.fetch(NSFetchRequest<LDScheduleEvent>(entityName: "LDScheduleEvent"))
            let scheduleTargets = try context.fetch(NSFetchRequest<LDScheduleTarget>(entityName: "LDScheduleTarget"))

            print("🏠 listings:", listings.count)
            print("💬 conversations:", convos.count)
            print("🧾 notices:", notices.count)
            print("🎯 noticeTargets:", noticeTargets.count)
            print("✉️ messages:", messages.count)
            print("🗓️ schedules:", schedules.count)
            print("🎯 scheduleTargets:", scheduleTargets.count)

            if let c = convos.first {
                print("💬 lastMessage:", c.lastMessageText ?? "-", "unread:", c.unreadCount)
            }
        } catch {
            print("❌ debug fetch failed:", error)
        }
    }

    static func tenantVisibleSchedules(context: NSManagedObjectContext) {
        do {
            let tenantReq = NSFetchRequest<LDTenant>(entityName: "LDTenant")
            tenantReq.fetchLimit = 1

            guard let tenant = try context.fetch(tenantReq).first else {
                print("❌ No tenant found. Seed tenant + tenancy first.")
                return
            }

            let service = TenantScheduleService(context: context)
            let events = try service.visibleSchedules(for: tenant)

            if events.isEmpty {
                print("⚠️ Tenant sees 0 schedules.")
                let tReq = NSFetchRequest<LDScheduleTarget>(entityName: "LDScheduleTarget")
                let targets = try context.fetch(tReq)
                print("Targets count:", targets.count)
                for t in targets {
                    print("Target scope:", t.scopeType ?? "-", "listing:", t.listing?.title ?? "nil", "event:", t.scheduleEvent?.title ?? "nil")
                }
                return
            }

            print("✅ Tenant sees schedules:", events.count)
            for e in events {
                print("•", e.title ?? "-", "| visibility:", e.visibility, "| tenantRelevant:", e.tenantRelevant)
            }

        } catch {
            print("❌ tenantVisibleSchedules error:", error)
        }
    }

    // MARK: - Reset DB

    static func resetDatabase(context: NSManagedObjectContext) {
        do {
            try batchDelete(entityName: "LDMessage", context: context)
            try batchDelete(entityName: "LDConversation", context: context)
            try batchDelete(entityName: "LDNoticeTarget", context: context)
            try batchDelete(entityName: "LDNotice", context: context)
            try batchDelete(entityName: "LDScheduleTarget", context: context)
            try batchDelete(entityName: "LDScheduleEvent", context: context)
            try batchDelete(entityName: "LDTenancy", context: context)
            try batchDelete(entityName: "LDTenant", context: context)
            try batchDelete(entityName: "LDListing", context: context)

            try context.save()
            print("🧹✅ Database reset complete.")
        } catch {
            print("🧹❌ Reset failed:", error)
        }
    }

    private static func batchDelete(entityName: String, context: NSManagedObjectContext) throws {
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        let request = NSBatchDeleteRequest(fetchRequest: fetch)
        request.resultType = .resultTypeObjectIDs

        let result = try context.execute(request) as? NSBatchDeleteResult
        let objectIDs = result?.result as? [NSManagedObjectID] ?? []
        let changes: [AnyHashable: Any] = [NSDeletedObjectsKey: objectIDs]
        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context])
    }
}
