//
//  NoticeService.swift
//  Quartier
//
//  Created by Frostmourne on 2026-03-01.
//

import Foundation
import CoreData

final class NoticeService {

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - Public API

    /// 创建公告：支持 all / 多个 listing，并可选推送到聊天
    @discardableResult
    func createNotice(
        title: String,
        body: String,
        category: String? = nil,
        priority: Int16 = 0,
        publishAt: Date = Date(),
        expireAt: Date? = nil,
        scope: NoticeScope,
        pushToConversations: Bool = true
    ) throws -> LDNotice {

        let now = Date()

        // 1) 创建 Notice
        let notice = LDNotice(context: context)
        notice.id = UUID()
        notice.title = title
        notice.body = body
        notice.category = category
        notice.priority = priority
        notice.publishAt = publishAt
        notice.expireAt = expireAt
        notice.createdAt = now
        notice.updatedAt = now
        notice.syncStatus = LDSyncStatus.localOnly.rawValue
        notice.version = 1
        notice.lastModifiedBy = "landlord"

        // 2) 创建 Targets
        switch scope {
        case .all:
            let t = LDNoticeTarget(context: context)
            t.id = UUID()
            t.createdAt = now
            t.scopeType = LDScopeType.all.rawValue
            t.notice = notice
            t.listing = nil

        case .listings(let listings):
            for listing in listings {
                let t = LDNoticeTarget(context: context)
                t.id = UUID()
                t.createdAt = now
                t.scopeType = LDScopeType.listing.rawValue
                t.notice = notice
                t.listing = listing
            }
        }

        // 3) 可选：推系统消息到相关 conversations
        if pushToConversations {
            try pushSystemMessageForNotice(notice, scope: scope, sentAt: now)
        }

        // 4) 保存
        try context.save()
        return notice
    }

    // MARK: - Scope

    enum NoticeScope {
        case all
        case listings([LDListing])
    }

    // MARK: - Private

    private func pushSystemMessageForNotice(_ notice: LDNotice, scope: NoticeScope, sentAt: Date) throws {
        // 你现在的数据模型里：LDConversation 有 listing 关系
        // 逻辑：找受影响 listing 的 conversations，每个 conversation 插入一条 systemNotice message

        let affectedConversations: [LDConversation]

        switch scope {
        case .all:
            // 最基础 fetch：取出所有 conversations（因为 all 表示所有 listing）
            affectedConversations = try fetchAllConversations()

        case .listings(let listings):
            // 不用复杂 fetch：直接用关系导航 listing.conversations
            var all: [LDConversation] = []
            for listing in listings {
                if let convSet = listing.conversations as? Set<LDConversation> {
                    all.append(contentsOf: convSet)
                }
            }
            // 去重（避免同一个 conversation 被重复加入）
            affectedConversations = Array(Set(all))
        }

        // 给每个 conversation 插消息
        for conversation in affectedConversations {
            let msg = LDMessage(context: context)
            msg.id = UUID()
            msg.sentAt = sentAt
            msg.type = LDMessageType.systemNotice.rawValue
            msg.text = "📌 Notice: \(notice.title ?? "")"
            msg.isFromLandlord = true
            msg.isRead = false

            msg.conversation = conversation
            msg.linkedNotice = notice

            // 更新 conversation 缓存字段（你前端列表依赖这些）
            conversation.lastMessageAt = sentAt
            conversation.lastMessageText = msg.text
            conversation.unreadCount += 1
        }
    }

    private func fetchAllConversations() throws -> [LDConversation] {
        let req = NSFetchRequest<LDConversation>(entityName: "LDConversation")
        // 这里不加 predicate，不算“复杂 fetch”，只是取全部
        return try context.fetch(req)
    }
}
