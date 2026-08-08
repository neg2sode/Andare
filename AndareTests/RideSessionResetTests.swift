//
//  RideSessionResetTests.swift
//  AndareTests
//
//  The calorie bug was not arithmetic — it was a field missing from
//  `resetSessionState()`, so a second ride in one app session inherited the
//  first one's energy. Nothing guarded that.
//

import Testing
import Foundation
@testable import Andare

@MainActor
struct RideSessionResetTests {

    @Test func resettingClearsEveryAccumulator() {
        let manager = RideSessionManager(workoutType: .cycling)

        manager.activeCalories = 154
        manager.basalCalories = 60
        manager.totalDistance = 4_512
        manager.elevationGain = 38
        manager.maxSpeed = 9.4
        manager.averageCadence = 83
        manager.averageSpeed = 6.2

        manager.resetSessionState()

        #expect(manager.activeCalories == 0)
        #expect(manager.basalCalories == 0)
        #expect(manager.totalCalories == 0)
        #expect(manager.totalDistance == 0)
        #expect(manager.elevationGain == 0)
        #expect(manager.maxSpeed == nil)
        #expect(manager.averageCadence == nil)
        #expect(manager.averageSpeed == nil)
    }

    /// Total is derived, not accumulated, so it cannot survive a reset the way
    /// a second running sum did.
    @Test func totalAlwaysTracksItsParts() {
        let manager = RideSessionManager(workoutType: .cycling)

        manager.activeCalories = 100
        manager.basalCalories = 25
        #expect(manager.totalCalories == 125)

        manager.activeCalories = 0
        #expect(manager.totalCalories == 25)
    }
}
