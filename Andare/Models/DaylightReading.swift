//
//  DaylightReading.swift
//  Andare
//
//  Created by neg2sode on 2026/8/9.
//

import Foundation

/// Where the drawer's daylight figure came from.
///
/// Every Andare workout is outdoors, so time spent riding is time spent in
/// daylight. When Health has nothing to give — the read was denied, or nothing
/// is recording it — that stands in better than a dash, provided the tile says
/// it was worked out rather than measured.
enum DaylightReading: Equatable {
    /// Read from Health.
    case measured(minutes: Double)
    /// Inferred from outdoor workout time.
    case estimated(minutes: Double)
    /// Health gave nothing and there was no workout to infer from.
    case unavailable

    /// - Parameters:
    ///   - healthMinutes: nil when the read failed or was never permitted.
    ///   - workoutMinutes: time spent working out over the same window.
    static func resolve(healthMinutes: Double?, workoutMinutes: Double) -> DaylightReading {
        // A zero from Health is as uninformative as no reading at all: both
        // mean nothing was recorded, and a ride we know about beats both.
        if (healthMinutes ?? 0) <= 0 {
            return workoutMinutes > 0 ? .estimated(minutes: workoutMinutes) : .unavailable
        }
        return .measured(minutes: healthMinutes ?? 0)
    }

    var minutes: Double? {
        switch self {
        case .measured(let minutes), .estimated(let minutes): minutes
        case .unavailable: nil
        }
    }

    var isEstimated: Bool { self == .estimated(minutes: minutes ?? 0) }
}
