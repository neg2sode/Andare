//
//  WeekStartTests.swift
//  AndareTests
//
//  A weekly scope resets at midnight on its first day, taking six days of
//  workouts out of view with it. Which day that is has to be the user's call.
//

import Testing
import Foundation
@testable import Andare

struct WeekStartTests {

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    /// `Calendar.firstWeekday` numbering, which is 1-based from Sunday.
    @Test func firstWeekdayNumbersMatchFoundation() {
        #expect(WeekStart.sunday.firstWeekday == 1)
        #expect(WeekStart.monday.firstWeekday == 2)
        #expect(WeekStart.saturday.firstWeekday == 7)
        #expect(WeekStart.system.firstWeekday == nil)
    }

    @Test func systemDefersToTheLocale() {
        #expect(WeekStart.system.calendar.firstWeekday == Calendar.current.firstWeekday)
    }

    @Test func anExplicitChoiceOverridesTheLocale() {
        #expect(WeekStart.monday.calendar.firstWeekday == 2)
        #expect(WeekStart.saturday.calendar.firstWeekday == 7)
    }

    /// The reported case: Sunday 9 August 2026. On a Sunday-start week the
    /// scope had just reset to a single day, hiding six days of workouts;
    /// starting weeks on Monday keeps them in view.
    @Test func aSundayStartWeekResetsOnSundayMorning() {
        let sunday = date(2026, 8, 9)

        var sundayStart = WeekStart.sunday.calendar
        sundayStart.timeZone = TimeZone(identifier: "UTC")!
        var mondayStart = WeekStart.monday.calendar
        mondayStart.timeZone = TimeZone(identifier: "UTC")!

        #expect(DrawerScope.week.daysElapsed(containing: sunday, calendar: sundayStart) == 1)
        #expect(DrawerScope.week.daysElapsed(containing: sunday, calendar: mondayStart) == 7)

        // Saturday the 8th is outside a Sunday-start week but inside a
        // Monday-start one.
        let saturday = date(2026, 8, 8)
        #expect(!DrawerScope.week.interval(containing: sunday, calendar: sundayStart).contains(saturday))
        #expect(DrawerScope.week.interval(containing: sunday, calendar: mondayStart).contains(saturday))
    }

    /// Whatever the setting, a week never covers more than seven days.
    @Test func aWeekIsNeverLongerThanSevenDays() {
        for start in WeekStart.allCases {
            var calendar = start.calendar
            calendar.timeZone = TimeZone(identifier: "UTC")!
            for day in 1...28 {
                let elapsed = DrawerScope.week.daysElapsed(containing: date(2026, 8, day), calendar: calendar)
                #expect((1...7).contains(elapsed), "\(start) day \(day) gave \(elapsed)")
            }
        }
    }

    /// The row says what "System" actually resolved to, so the choice is not a
    /// mystery until you change it.
    @Test func theSystemRowNamesItsResolvedDay() {
        #expect(WeekStart.system.displayLabel.hasPrefix("System"))
        #expect(WeekStart.monday.displayLabel == "Monday")
    }

    /// Raw values are persisted in UserDefaults, so they are frozen.
    @Test func rawValuesAreStable() {
        #expect(WeekStart.allCases.map(\.rawValue) == ["system", "sunday", "monday", "saturday"])
    }
}
