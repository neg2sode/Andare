//
//  AggregateDurationTests.swift
//  AndareTests
//
//  A summed duration is not a stopwatch reading: nobody needs the seconds of a
//  three-hour week, and a clock string leaves most of a drawer tile empty.
//

import Testing
import Foundation
@testable import Andare

@MainActor
struct AggregateDurationTests {

    private var formatter: StatsFormatter { .shared }

    @Test func hoursDropTheSeconds() {
        #expect(formatter.formatAggregateDuration(2 * 3600 + 59 * 60 + 47).value == "2h 59m")
        #expect(formatter.formatAggregateDuration(3600).value == "1h 0m")
    }

    @Test func underAnHourKeepsSeconds() {
        #expect(formatter.formatAggregateDuration(47 * 60 + 12).value == "47m 12s")
        #expect(formatter.formatAggregateDuration(60).value == "1m 0s")
    }

    @Test func underAMinuteIsSecondsAlone() {
        #expect(formatter.formatAggregateDuration(38).value == "38s")
        #expect(formatter.formatAggregateDuration(0).value == "0s")
    }

    /// Only ever two units, whatever the length — that is the whole point.
    @Test func neverMoreThanTwoUnits() {
        for seconds in stride(from: 0.0, through: 200_000.0, by: 617.0) {
            let value = formatter.formatAggregateDuration(seconds).value
            let parts = value.split(separator: " ")
            #expect(parts.count <= 2, "\(seconds)s produced \(value)")
        }
    }

    /// A negative interval would otherwise render "-1h -30m".
    @Test func negativeDurationsClampToZero() {
        #expect(formatter.formatAggregateDuration(-500).value == "0s")
    }

    /// The single-ride summary and the live overlay keep the clock format,
    /// where seconds genuinely matter.
    @Test func theClockFormatIsUntouched() {
        #expect(formatter.formatDuration(3600).value == "1:00:00")
        #expect(formatter.formatDuration(6 * 60).value == "0:06:00")
    }
}
