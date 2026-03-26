//
//  LDConstants.swift
//  Quartier
//
//  Created by Frostmourne on 2026-03-01.
//

import Foundation

enum LDScopeType: String {
    case all
    case listing
}

enum LDMessageType: String {
    case text
    case systemNotice
    case systemSchedule
}

enum LDSyncStatus: Int16 {
    case localOnly = 0
    case pendingUpload = 1
    case synced = 2
    case conflict = 3
}
