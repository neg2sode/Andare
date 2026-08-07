//
//  CadenceVerdictTests.swift
//  AndareTests
//
//  The cadence tile is a sentence, and a sentence can be ungrammatical in ways
//  a number cannot. These pin the singular/plural branches and the counts.
//

import Testing
@testable import Andare

struct CadenceVerdictTests {

    private func verdict(total: Int, measured: Int, off: Int, scope: DrawerScope = .today) -> CadenceTile.Verdict {
        CadenceTile.Verdict.make(total: total, measured: measured, offCadence: off, scope: scope)
    }

    @Test func noWorkoutsNamesTheScope() {
        #expect(verdict(total: 0, measured: 0, off: 0, scope: .today).title == "No Workouts Today")
        #expect(verdict(total: 0, measured: 0, off: 0, scope: .week).title == "No Workouts This Week")
    }

    /// A workout that recorded no cadence is not the same as one that recorded
    /// a poor cadence — it must not be counted as a problem.
    @Test func workoutsWithoutCadenceAreNotFailures() {
        let result = verdict(total: 2, measured: 0, off: 0)
        #expect(result.title == "No Cadence Data")
        #expect(result.colour == .gray)
    }

    @Test func singularAndPluralAgree() {
        #expect(verdict(total: 1, measured: 1, off: 0).detail
                == "Your workout today held a sound cadence.")
        #expect(verdict(total: 3, measured: 3, off: 0).detail
                == "All 3 workouts today held a sound cadence.")
        #expect(verdict(total: 1, measured: 1, off: 0, scope: .week).detail
                == "Your workout this week held a sound cadence.")
    }

    @Test func offCadenceCountsRead() {
        let result = verdict(total: 2, measured: 2, off: 1)
        #expect(result.title == "1 of 2 Off Cadence")
        #expect(result.detail.hasPrefix("The other one held a sound cadence."))

        #expect(verdict(total: 7, measured: 7, off: 3).title == "3 of 7 Off Cadence")
        #expect(verdict(total: 7, measured: 7, off: 3).detail.hasPrefix("The other 4 held"))
    }

    /// With nothing sound to point at, the copy must not say "the other 0".
    @Test func everyWorkoutOffCadenceAvoidsAnEmptyRemainder() {
        let result = verdict(total: 2, measured: 2, off: 2)
        #expect(result.title == "2 of 2 Off Cadence")
        #expect(!result.detail.contains("other"))
    }

    /// Unmeasured workouts are excluded from the denominator, so the tile never
    /// claims a larger sample than it actually judged.
    @Test func denominatorCountsOnlyMeasuredWorkouts() {
        #expect(verdict(total: 5, measured: 2, off: 1).title == "1 of 2 Off Cadence")
    }
}
