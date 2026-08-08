//
//  DaylightReadingTests.swift
//  AndareTests
//
//  The estimate stands in for a Health reading, so the rule deciding when it
//  applies has to be exact — showing a guess where a measurement exists would
//  be worse than showing nothing.
//

import Testing
import Foundation
@testable import Andare

struct DaylightReadingTests {

    @Test func aRealReadingIsUsedAsIs() {
        let reading = DaylightReading.resolve(healthMinutes: 195, workoutMinutes: 180)

        #expect(reading == .measured(minutes: 195))
        #expect(reading.minutes == 195)
        #expect(!reading.isEstimated)
    }

    /// The reported case: no daylight from Health, but three hours of outdoor
    /// riding the app recorded itself.
    @Test func workoutTimeStandsInWhenHealthGivesNothing() {
        let reading = DaylightReading.resolve(healthMinutes: nil, workoutMinutes: 179.8)

        #expect(reading == .estimated(minutes: 179.8))
        #expect(reading.isEstimated)
    }

    /// A zero is as uninformative as a nil — both mean nothing was recorded.
    @Test func aZeroReadingAlsoFallsBack() {
        #expect(DaylightReading.resolve(healthMinutes: 0, workoutMinutes: 60)
                == .estimated(minutes: 60))
    }

    /// Nothing to read and nothing to infer from: say so rather than show 0.
    @Test func nothingToInferFromIsUnavailable() {
        #expect(DaylightReading.resolve(healthMinutes: nil, workoutMinutes: 0) == .unavailable)
        #expect(DaylightReading.resolve(healthMinutes: 0, workoutMinutes: 0) == .unavailable)
        #expect(DaylightReading.resolve(healthMinutes: nil, workoutMinutes: 0).minutes == nil)
    }

    /// A measurement always wins, even a small one against a long ride.
    @Test func aSmallMeasurementStillBeatsAnEstimate() {
        let reading = DaylightReading.resolve(healthMinutes: 3, workoutMinutes: 240)

        #expect(reading == .measured(minutes: 3))
        #expect(!reading.isEstimated)
    }

    /// Health cannot report negative minutes, but a corrupt read must not turn
    /// into a confident negative number on the tile.
    @Test func anImpossibleReadingFallsBack() {
        #expect(DaylightReading.resolve(healthMinutes: -5, workoutMinutes: 30)
                == .estimated(minutes: 30))
    }
}
