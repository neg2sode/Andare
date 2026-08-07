//
//  CadenceChartAxisTests.swift
//  AndareTests
//
//  Chart gridline spacing is pure arithmetic over duration, so it can be
//  checked directly rather than eyeballed in a screenshot.
//

import Testing
import Foundation
@testable import Andare

struct CadenceChartAxisTests {

    private let segment = MotionManager.SEGMENT_DURATION   // 5.12s
    private let section = MotionManager.SECTION_DURATION   // 81.92s

    @Test func shortWorkoutsUseTheNarrowestSpacing() {
        #expect(CadenceChartAxis.stride(forDuration: 30) == segment)
        #expect(CadenceChartAxis.stride(forDuration: 0) == segment)
    }

    /// Every step is a power-of-two multiple of a segment, so marks always land
    /// on a real analysis boundary.
    @Test func everyStrideIsASegmentMultiple() {
        for duration in stride(from: 10.0, through: 7200.0, by: 37.0) {
            let step = CadenceChartAxis.stride(forDuration: duration)
            let multiple = step / segment
            #expect(multiple == multiple.rounded(), "stride \(step) is not a segment multiple")
            #expect(step >= segment)
            #expect(step <= section)
        }
    }

    /// The cap is what stops an hour-long ride from drawing a gridline per
    /// minute; it stays at one section however long the workout runs.
    @Test func longWorkoutsCapAtOneSection() {
        #expect(CadenceChartAxis.stride(forDuration: 3600) == section)
        #expect(CadenceChartAxis.stride(forDuration: 36000) == section)
    }

    @Test func spacingWidensAsTheWorkoutGrows() {
        let twoMinutes = CadenceChartAxis.stride(forDuration: 120)
        let tenMinutes = CadenceChartAxis.stride(forDuration: 600)

        #expect(twoMinutes > segment)
        #expect(tenMinutes > twoMinutes)
    }

    @Test func gridValuesStartAtZeroAndCoverTheWorkout() {
        let values = CadenceChartAxis.gridValues(forDuration: 300)

        #expect(values.first == 0)
        #expect(values.count > 1)
        #expect(values.last ?? 0 <= 300)
        // Evenly spaced by construction.
        let steps = zip(values.dropFirst(), values).map(-)
        #expect(steps.allSatisfy { abs($0 - CadenceChartAxis.stride(forDuration: 300)) < 0.0001 })
    }

    /// A workout shorter than one segment must still get an axis rather than a
    /// single point at zero.
    @Test func aVeryShortWorkoutStillGetsTwoMarks() {
        let values = CadenceChartAxis.gridValues(forDuration: 2)
        #expect(values == [0, segment])
    }
}
