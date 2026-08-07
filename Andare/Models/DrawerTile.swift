//
//  DrawerTile.swift
//  Andare
//
//  Created by neg2sode on 2026/8/7.
//

import SwiftUI

/// How a tile condenses a multi-day scope into one number.
///
/// What "average" divides by depends on the metric — see `DrawerTile.averageBasis`.
enum Aggregation: String, Codable, CaseIterable, Identifiable {
    case total
    case average

    var id: String { rawValue }

    var label: String {
        switch self {
        case .total: "Total"
        case .average: "Average"
        }
    }
}

/// What an average means for a given metric. Steps accumulate whether or not you
/// ride, so their average is per day; ride distance only exists on days you rode,
/// where a per-day average would silently divide by rest days.
enum AverageBasis {
    case perDay
    case perWorkout
}

/// One card in the drawer's grid.
///
/// - Important: raw values are persisted in `UserDefaults` as part of the saved
///   layout, so they are frozen once shipped — the same rule that applies to
///   `CadenceZone.normal`'s `"Normal"`. Rename a case freely; never its raw value.
enum DrawerTile: String, Codable, CaseIterable, Identifiable {
    case daylight
    case steps
    case walkingDistance
    case cadence
    case rideDistance
    case rideDuration

    var id: String { rawValue }

    /// The cadence tile is a sentence, not a number, and needs the full width.
    var isWide: Bool { self == .cadence }

    /// A count of workouts off cadence has no meaningful average.
    var supportsAggregation: Bool { self != .cadence }

    var defaultAggregation: Aggregation {
        switch self {
        case .daylight: .average
        default: .total
        }
    }

    var averageBasis: AverageBasis {
        switch self {
        case .daylight, .steps, .walkingDistance: .perDay
        case .rideDistance, .rideDuration, .cadence: .perWorkout
        }
    }

    /// Name shown in the customization editor, where there is no scope context.
    var editorTitle: String {
        switch self {
        case .daylight: "Time in Daylight"
        case .steps: "Steps"
        case .walkingDistance: "Walking Distance"
        case .cadence: "Cadence"
        case .rideDistance: "Workout Distance"
        case .rideDuration: "Workout Time"
        }
    }

    var icon: String {
        switch self {
        case .daylight: "sun.max.fill"
        case .steps: "shoeprints.fill"
        case .walkingDistance: "figure.walk"
        case .cadence: "gauge.with.dots.needle.50percent"
        case .rideDistance: "point.topleft.down.to.point.bottomright.curvepath.fill"
        case .rideDuration: "clock.fill"
        }
    }

    var iconTint: Color {
        switch self {
        case .daylight: .orange
        case .steps: .cadenceColour
        case .walkingDistance: .distanceColour
        case .cadence: .cadenceColour
        case .rideDistance: .distanceColour
        case .rideDuration: .durationColour
        }
    }

    /// Whether the tile reads from HealthKit rather than from stored workouts.
    var isHealthKitBacked: Bool {
        switch self {
        case .daylight, .steps, .walkingDistance: true
        case .cadence, .rideDistance, .rideDuration: false
        }
    }

    /// The card's caption, which changes with scope so the tile says a different
    /// thing rather than silently swapping a number under a fixed label.
    func label(scope: DrawerScope, aggregation: Aggregation) -> String {
        guard scope == .week, aggregation == .average else { return editorTitle }

        switch (self, averageBasis) {
        case (.daylight, _): return "Daily Avg. Daylight"
        case (.steps, _): return "Daily Avg. Steps"
        case (.walkingDistance, _): return "Daily Avg. Walking"
        case (.rideDistance, _): return "Avg. per Workout"
        case (.rideDuration, _): return "Avg. Workout Time"
        case (.cadence, _): return editorTitle
        }
    }
}
