//
//  WorkoutCalorieRepair.swift
//  Andare
//
//  Created by neg2sode on 2026/8/8.
//

import Foundation
import SwiftData

/// Rewrites the total calories of workouts recorded before the accumulator was
/// fixed.
///
/// `RideSessionManager` used to keep `totalCalories` as its own running sum,
/// and `resetSessionState()` never cleared it — so every ride after the first
/// in an app session banked all the earlier ones. Those numbers are already in
/// SwiftData and would otherwise stay wrong forever.
///
/// This is a **reconstruction, not a measurement**: it recomputes resting energy
/// from the stored duration and today's body weight, which is not what was
/// recorded at the time. It therefore also changes rides whose totals were never
/// inflated. Active calories are left exactly as recorded — correcting those for
/// the MET change would need each segment's MET, which is not persisted.
enum WorkoutCalorieRepair {
    static let versionKey = "workoutCalorieRepairVersion"
    static let currentVersion = 1

    @MainActor
    static func runIfNeeded(context: ModelContext, defaults: UserDefaults = .standard) {
        guard defaults.integer(forKey: versionKey) < currentVersion else { return }

        let weight = defaults.object(forKey: "userWeightKg") as? Double ?? 70.0
        repair(context: context, weightKg: weight)

        defaults.set(currentVersion, forKey: versionKey)
    }

    /// Separated from the launch gate so it can be tested against an in-memory
    /// container without touching `UserDefaults`.
    @MainActor
    static func repair(context: ModelContext, weightKg: Double) {
        guard let workouts = try? context.fetch(FetchDescriptor<WorkoutDataModel>()) else { return }

        for workout in workouts {
            workout.totalCalories = workout.activeCalories + basalCalories(
                duration: workout.duration,
                weightKg: weightKg
            )
        }

        try? context.save()
    }

    /// The same 1 kcal·kg⁻¹·h⁻¹ resting rate the live accumulator uses.
    static func basalCalories(duration: TimeInterval, weightKg: Double) -> Double {
        max(duration, 0) / 3600.0 * weightKg
    }
}
