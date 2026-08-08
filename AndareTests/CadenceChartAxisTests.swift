//
//  CadenceChartAxisTests.swift
//  AndareTests
//
//  Chart gridline spacing is pure arithmetic over duration, so it can be
//  checked directly rather than eyeballed in a screenshot. The rule that
//  matters: one FFT section is the *minimum* spacing, and however long the
//  ride, no more than four lines land between the ends.
//

import Testing
import Foundation
@testable import Andare

struct CadenceChartAxisTests {

    private let section = MotionManager.SECTION_DURATION   // 81.92s

    /// Gridlines strictly inside the workout, excluding the 0:00 axis.
    private func intermediateCount(_ duration: TimeInterval) -> Int {
        CadenceChartAxis.gridValues(forDuration: duration).filter { $0 > 0 }.count
    }

    /// The regression that prompted this: an hour used to draw ~44 lines.
    @Test func neverMoreThanFourIntermediateLines() {
        for duration in stride(from: 10.0, through: 21_600.0, by: 53.0) {
            #expect(intermediateCount(duration) <= 4,
                    "\(duration)s produced \(intermediateCount(duration)) lines")
        }
    }

    /// Below one section there is nothing worth subdividing.
    @Test func aWorkoutShorterThanOneSectionHasNoIntermediateLines() {
        #expect(CadenceChartAxis.gridValues(forDuration: 60) == [0])
        #expect(CadenceChartAxis.gridValues(forDuration: section - 1) == [0])
        #expect(CadenceChartAxis.gridValues(forDuration: 0) == [0])
    }

    /// One section is the floor — nothing narrower is ever chosen.
    @Test func strideNeverGoesBelowOneSection() {
        for duration in stride(from: 1.0, through: 3600.0, by: 17.0) {
            #expect(CadenceChartAxis.stride(forDuration: duration) >= section)
        }
    }

    @Test func shortRidesStayOnTheSectionStride() {
        #expect(CadenceChartAxis.stride(forDuration: 300) == section)
        #expect(intermediateCount(300) == 3)
        // 6 minutes still fits four lines at one section apart.
        #expect(CadenceChartAxis.stride(forDuration: 360) == section)
        #expect(intermediateCount(360) == 4)
    }

    /// Above the section floor the stride snaps to readable clock intervals.
    @Test func anHourUsesFifteenMinutes() {
        #expect(CadenceChartAxis.stride(forDuration: 3600) == 900)
        #expect(CadenceChartAxis.gridValues(forDuration: 3600) == [0, 900, 1800, 2700])
    }

    @Test func twoHoursUsesHalfHours() {
        #expect(CadenceChartAxis.stride(forDuration: 7200) == 1800)
        #expect(intermediateCount(7200) == 3)
    }

    /// A longer ride must never get a *tighter* grid than a shorter one.
    @Test func strideIsMonotonicInDuration() {
        var previous: TimeInterval = 0
        for duration in stride(from: 60.0, through: 21_600.0, by: 60.0) {
            let current = CadenceChartAxis.stride(forDuration: duration)
            #expect(current >= previous, "stride shrank at \(duration)s")
            previous = current
        }
    }

    /// Beyond the fixed ladder the fallback still has to hold the line.
    @Test func absurdlyLongRidesStillCapAtFour() {
        for duration in [30_000.0, 86_400.0, 200_000.0] {
            #expect(intermediateCount(duration) <= 4)
            #expect(CadenceChartAxis.stride(forDuration: duration) > 0)
        }
    }

    /// A ride lasting almost exactly a whole number of strides used to draw an
    /// unlabelled line flush against the right edge — 3600.001s produced a mark
    /// at 3600.
    @Test func noLineLandsAgainstTheRightEdge() {
        for duration in [300.0, 3600.0, 3600.001, 7200.0, 7200.5, 900.0] {
            let spacing = CadenceChartAxis.stride(forDuration: duration)
            for value in CadenceChartAxis.gridValues(forDuration: duration) {
                #expect(duration - value > spacing * 0.1,
                        "\(value) sits on the edge of a \(duration)s chart")
            }
        }
    }

    @Test func exactMultiplesDoNotGainAnExtraLine() {
        // 3600 / 900 = 4 exactly: three lines inside, not four.
        #expect(CadenceChartAxis.gridValues(forDuration: 3600) == [0, 900, 1800, 2700])
        #expect(CadenceChartAxis.gridValues(forDuration: 3600.001) == [0, 900, 1800, 2700])
    }

    @Test func zeroCadenceMarkersStopAfterTenMinutes() {
        #expect(CadenceChartAxis.showsZeroMarkers(forDuration: 300))
        #expect(CadenceChartAxis.showsZeroMarkers(forDuration: 600))
        #expect(!CadenceChartAxis.showsZeroMarkers(forDuration: 601))
        #expect(!CadenceChartAxis.showsZeroMarkers(forDuration: 3600))
    }
}
