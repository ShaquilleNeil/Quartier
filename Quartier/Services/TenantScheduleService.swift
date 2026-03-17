//
//  TenantScheduleService.swift
//  Quartier
//
//  Created by Frostmourne on 2026-03-01.
//

import Foundation
import CoreData

final class TenantScheduleService {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    /// MVP：获取 tenant 可见的 schedules（all + 当前 tenancy 的 listing）
    func visibleSchedules(for tenant: LDTenant, now: Date = Date()) throws -> [LDScheduleEvent] {

        // 1) 找 active tenancy（最简：取 endDate == nil 且 status == "active"）
        let tenancyReq = NSFetchRequest<LDTenancy>(entityName: "LDTenancy")
        tenancyReq.predicate = NSPredicate(format: "tenant == %@ AND status == %@ AND endDate == nil", tenant, "active")
        tenancyReq.fetchLimit = 1

        guard let tenancy = try context.fetch(tenancyReq).first,
              let myListing = tenancy.listing else {
            return []
        }

        // 2) 拿所有 ScheduleTargets（MVP：数量不大时OK）
        let targetReq = NSFetchRequest<LDScheduleTarget>(entityName: "LDScheduleTarget")
        let targets = try context.fetch(targetReq)

        // 3) 过滤：scopeType == all 或 listing == myListing
        let matchedEvents: [LDScheduleEvent] = targets.compactMap { t in
            guard let event = t.scheduleEvent else { return nil }
            // tenantVisible + tenantRelevant
            guard event.visibility == 1, event.tenantRelevant == true else { return nil }

            if t.scopeType == LDScopeType.all.rawValue {
                return event
            }
            if t.scopeType == LDScopeType.listing.rawValue, t.listing == myListing {
                return event
            }
            return nil
        }

        // 4) 去重 + 按 startAt 排序 + 只取未来事件（可选）
        // 4) 去重：按 event.id 去重（✅ 最可靠）
        var dict: [UUID: LDScheduleEvent] = [:]
        for e in matchedEvents {
            if let id = e.id {
                dict[id] = e
            }
        }
        let unique = Array(dict.values)

        // 5) 过滤未来 + 排序
        let upcoming = unique.filter { e in
            guard let endAt = e.endAt else { return true }
            return endAt >= now
        }
        return upcoming.sorted { ($0.startAt ?? now) < ($1.startAt ?? now) }
    }
}
