//
//  WeekStart.swift
//  Andare
//
//  Created by neg2sode on 2026/8/9.
//

import Foundation

/// Which day the drawer's weekly scope begins on.
///
/// The system default follows the device locale, which is right for most
/// people and wrong for anyone whose training week disagrees with their
/// region's calendar — a Sunday-start locale empties the week view every
/// Sunday morning, taking six days of workouts out of view with it.
enum WeekStart: String, CaseIterable, Identifiable, Codable {
    case system
    case sunday
    case monday
    case saturday

    static let storageKey = "weekStartPreference"

    var id: String { rawValue }

    /// `Calendar.firstWeekday` numbering: 1 is Sunday through 7 is Saturday.
    /// nil means "whatever the locale says".
    var firstWeekday: Int? {
        switch self {
        case .system: nil
        case .sunday: 1
        case .monday: 2
        case .saturday: 7
        }
    }

    var label: String {
        switch self {
        case .system: "System"
        case .sunday: "Sunday"
        case .monday: "Monday"
        case .saturday: "Saturday"
        }
    }

    /// What the row shows on the right: "System (Monday)" so the choice is not
    /// a mystery until you change it.
    var displayLabel: String {
        guard self == .system else { return label }
        let resolved = WeekStart.allCases.first { $0.firstWeekday == Calendar.current.firstWeekday }
        guard let resolved else { return label }
        return "\(label) (\(resolved.label))"
    }

    /// A calendar honouring this preference, for `DrawerScope` to slice weeks with.
    var calendar: Calendar {
        var calendar = Calendar.current
        if let firstWeekday { calendar.firstWeekday = firstWeekday }
        return calendar
    }
}
