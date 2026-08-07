//
//  DrawerCard.swift
//  Andare
//
//  Created by neg2sode on 2026/8/7.
//

import Foundation

/// The drawer's optional informational cards. Each can be hidden with a long
/// press and restored from Preferences, so the storage keys are shared between
/// the two screens rather than written out as loose strings.
enum DrawerCard: String, CaseIterable, Identifiable {
    case today
    case cadenceSummary

    var id: String { rawValue }

    var storageKey: String {
        switch self {
        case .today: "showTodaySection"
        case .cadenceSummary: "showCadenceSummarySection"
        }
    }

    var title: String {
        switch self {
        case .today: "Today"
        case .cadenceSummary: "Summary"
        }
    }
}
