//
//  CalorieCalculationTests.swift
//  AndareTests
//
//  Energy per segment is pure arithmetic, and it was wrong in three separate
//  ways at once — resting energy skipped when GPS dropped, resting energy
//  counted twice inside the active figure, and a total that outlived the ride.
//  These pin the first two; the third is a lifecycle bug, not arithmetic.
//

import Testing
import Foundation
@testable import Andare

struct CalorieCalculationTests {

    private let weight = 70.0

    private func inputs(duration: TimeInterval, speed: Double?, cadence: Double = 80) -> CalorieCalculationInputs {
        CalorieCalculationInputs(
            duration: duration,
            speed: speed,
            cadence: cadence,
            workoutType: .cycling,
            weight: weight
        )
    }

    /// The regression: a segment with no GPS fix used to contribute nothing at
    /// all, but resting energy is burned whether or not the phone can see a
    /// satellite.
    @Test func restingEnergyAccruesWithoutASpeed() {
        let result = inputs(duration: 3600, speed: nil).calculate()

        #expect(result.active == 0)
        #expect(abs(result.basal - weight) < 0.0001)   // 1 kcal/kg/h for an hour
    }

    /// Standing at a light burns nothing extra, but still burns.
    @Test func aStationarySegmentHasNoActiveEnergy() {
        let result = inputs(duration: 3600, speed: 0.2).calculate()

        #expect(result.active == 0)
        #expect(result.basal > 0)
    }

    @Test func zeroCadenceHasNoActiveEnergy() {
        let result = inputs(duration: 3600, speed: 6.2, cadence: 0).calculate()

        #expect(result.active == 0)
        #expect(result.basal > 0)
    }

    /// Active is measured above rest, so the two parts sum to exactly
    /// `MET × weight × hours` with no double count.
    @Test func activeAndBasalSumToTheFullMetProduct() {
        // 6.2 m/s ≈ 13.9 mph → the 8.0 MET cycling band.
        let result = inputs(duration: 3600, speed: 6.2).calculate()

        #expect(abs(result.active - 7.0 * weight) < 0.0001)   // (8 − 1) × 70 × 1h
        #expect(abs(result.active + result.basal - 8.0 * weight) < 0.0001)
    }

    @Test func energyScalesLinearlyWithDuration() {
        let hour = inputs(duration: 3600, speed: 6.2).calculate()
        let tenMinutes = inputs(duration: 600, speed: 6.2).calculate()

        #expect(abs(hour.active / 6 - tenMinutes.active) < 0.0001)
        #expect(abs(hour.basal / 6 - tenMinutes.basal) < 0.0001)
    }

    @Test func aZeroWeightProfileYieldsNothing() {
        let result = CalorieCalculationInputs(
            duration: 3600, speed: 6.2, cadence: 80, workoutType: .cycling, weight: 0
        ).calculate()

        #expect(result.active == 0)
        #expect(result.basal == 0)
    }

    /// Walking's slowest band is 2.0 MET, so active must stay positive rather
    /// than going negative once the resting MET is subtracted.
    @Test func theSlowestBandNeverGoesNegative() {
        let result = CalorieCalculationInputs(
            duration: 3600, speed: 0.8, cadence: 60, workoutType: .walking, weight: weight
        ).calculate()

        #expect(result.active >= 0)
        #expect(abs(result.active - 1.0 * weight) < 0.0001)   // (2 − 1) × 70 × 1h
    }
}
