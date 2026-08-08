//
//  WorkoutCalorieRepairTests.swift
//  AndareTests
//
//  The repair rewrites real stored rides, so it is worth pinning what it does
//  and — more importantly — what it leaves alone.
//

import Testing
import Foundation
import SwiftData
@testable import Andare

@MainActor
struct WorkoutCalorieRepairTests {

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: WorkoutDataModel.self, CadenceSegmentModel.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    @discardableResult
    private func insertWorkout(
        _ context: ModelContext,
        minutes: Double,
        active: Double,
        total: Double
    ) -> WorkoutDataModel {
        let start = Date().addingTimeInterval(-minutes * 60)
        let workout = WorkoutDataModel(
            id: UUID(),
            managementState: .visible,
            mapDisplayContext: .hidden,
            workoutType: .cycling,
            startTime: start,
            endTime: start.addingTimeInterval(minutes * 60),
            logMessages: [],
            averageCadence: 80,
            totalDistance: 1000,
            averageSpeed: 6,
            maxSpeed: 9,
            elevationGain: 10,
            activeCalories: active,
            totalCalories: total,
            cadenceSegments: [],
            notificationIntents: []
        )
        context.insert(workout)
        return workout
    }

    /// The reported case: ride 5 read 154 active / 700 total because it had
    /// banked every earlier ride in the session.
    @Test func anInflatedTotalIsBroughtBackToActivePlusResting() throws {
        let context = try makeContext()
        let workout = insertWorkout(context, minutes: 60, active: 154, total: 700)

        WorkoutCalorieRepair.repair(context: context, weightKg: 70)

        #expect(workout.activeCalories == 154)          // left as recorded
        #expect(abs(workout.totalCalories - 224) < 0.5) // 154 + 70 kcal resting
    }

    /// It is a reconstruction, not a targeted fix: a ride whose total was never
    /// inflated still gets rewritten, because nothing distinguishes the two.
    @Test func aRideThatWasNeverInflatedIsAlsoRewritten() throws {
        let context = try makeContext()
        let workout = insertWorkout(context, minutes: 20, active: 63, total: 77)

        WorkoutCalorieRepair.repair(context: context, weightKg: 70)

        #expect(abs(workout.totalCalories - (63 + 70.0 / 3)) < 0.5)
    }

    @Test func totalIsNeverLeftBelowActive() throws {
        let context = try makeContext()
        let workout = insertWorkout(context, minutes: 45, active: 300, total: 12)

        WorkoutCalorieRepair.repair(context: context, weightKg: 70)

        #expect(workout.totalCalories >= workout.activeCalories)
    }

    @Test func repairIsIdempotent() throws {
        let context = try makeContext()
        let workout = insertWorkout(context, minutes: 60, active: 154, total: 700)

        WorkoutCalorieRepair.repair(context: context, weightKg: 70)
        let once = workout.totalCalories
        WorkoutCalorieRepair.repair(context: context, weightKg: 70)

        #expect(workout.totalCalories == once)
    }

    @Test func theLaunchGateRunsOnceOnly() throws {
        let context = try makeContext()
        let workout = insertWorkout(context, minutes: 60, active: 154, total: 700)
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        defaults.set(70.0, forKey: "userWeightKg")

        WorkoutCalorieRepair.runIfNeeded(context: context, defaults: defaults)
        #expect(abs(workout.totalCalories - 224) < 0.5)

        // A later ride recorded correctly must not be touched again.
        workout.totalCalories = 999
        WorkoutCalorieRepair.runIfNeeded(context: context, defaults: defaults)
        #expect(workout.totalCalories == 999)
    }

    @Test func restingEnergyMatchesTheLiveAccumulator() {
        // Same 1 kcal/kg/h rate CalorieCalculationInputs uses.
        let repaired = WorkoutCalorieRepair.basalCalories(duration: 3600, weightKg: 70)
        let live = CalorieCalculationInputs(
            duration: 3600, speed: nil, cadence: 0, workoutType: .cycling, weight: 70
        ).calculate().basal

        #expect(abs(repaired - live) < 0.0001)
    }
}
