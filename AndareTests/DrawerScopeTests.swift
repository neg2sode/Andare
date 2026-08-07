//
//  DrawerScopeTests.swift
//  AndareTests
//
//  Calendar-week boundary maths for the drawer's scope selector. Averages
//  divide by days elapsed rather than by seven, which is easy to get subtly
//  wrong and invisible in the UI — a Tuesday would just look like a bad week.
//

import Testing
import Foundation
@testable import Andare

struct DrawerScopeTests {

    /// Fixed timezone and first weekday, so these assertions don't depend on
    /// where the test machine happens to be.
    private func calendar(firstWeekday: Int) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.firstWeekday = firstWeekday
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, in calendar: Calendar) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    // 7 Aug 2026 is a Friday; the Monday of its week is 3 Aug.
    private var mondayFirst: Calendar { calendar(firstWeekday: 2) }
    private var sundayFirst: Calendar { calendar(firstWeekday: 1) }

    @Test func todayCoversExactlyOneDay() {
        let calendar = mondayFirst
        let friday = date(2026, 8, 7, in: calendar)
        let interval = DrawerScope.today.interval(containing: friday, calendar: calendar)

        #expect(interval.start == calendar.startOfDay(for: friday))
        #expect(interval.end == calendar.startOfDay(for: date(2026, 8, 8, in: calendar)))
        #expect(DrawerScope.today.daysElapsed(containing: friday, calendar: calendar) == 1)
    }

    @Test func weekStartsOnTheLocaleFirstWeekday() {
        let calendar = mondayFirst
        let friday = date(2026, 8, 7, in: calendar)
        let interval = DrawerScope.week.interval(containing: friday, calendar: calendar)

        #expect(interval.start == calendar.startOfDay(for: date(2026, 8, 3, in: calendar)))
        // Mon 3rd through Fri 7th inclusive.
        #expect(DrawerScope.week.daysElapsed(containing: friday, calendar: calendar) == 5)
    }

    @Test func weekRespectsASundayStartingLocale() {
        let calendar = sundayFirst
        let friday = date(2026, 8, 7, in: calendar)
        let interval = DrawerScope.week.interval(containing: friday, calendar: calendar)

        #expect(interval.start == calendar.startOfDay(for: date(2026, 8, 2, in: calendar)))
        #expect(DrawerScope.week.daysElapsed(containing: friday, calendar: calendar) == 6)
    }

    /// The regression that matters: on the first day of the week, a week scope
    /// must be one day, not seven. Dividing by seven here would show every
    /// reading at a seventh of its real value.
    @Test func weekOnItsFirstDayIsASingleDay() {
        let calendar = mondayFirst
        let monday = date(2026, 8, 3, in: calendar)

        #expect(DrawerScope.week.daysElapsed(containing: monday, calendar: calendar) == 1)
        #expect(DrawerScope.week.interval(containing: monday, calendar: calendar)
                == DrawerScope.today.interval(containing: monday, calendar: calendar))
    }

    @Test func sundayIsTheLastDayOfAMondayStartingWeek() {
        let calendar = mondayFirst
        let sunday = date(2026, 8, 9, in: calendar)

        #expect(DrawerScope.week.daysElapsed(containing: sunday, calendar: calendar) == 7)
        #expect(DrawerScope.week.interval(containing: sunday, calendar: calendar).start
                == calendar.startOfDay(for: date(2026, 8, 3, in: calendar)))
    }

    /// A week that straddles a month boundary still starts in the prior month.
    @Test func weekStraddlingAMonthBoundary() {
        let calendar = mondayFirst
        let tuesday = date(2026, 9, 1, in: calendar)

        #expect(DrawerScope.week.interval(containing: tuesday, calendar: calendar).start
                == calendar.startOfDay(for: date(2026, 8, 31, in: calendar)))
        #expect(DrawerScope.week.daysElapsed(containing: tuesday, calendar: calendar) == 2)
    }

    /// Only the structure this type controls is asserted — the date portions go
    /// through `FormatStyle` and so depend on the machine's locale.
    @Test func titlesNameTheirPeriod() {
        let calendar = mondayFirst
        let friday = date(2026, 8, 7, in: calendar)
        let monday = date(2026, 8, 3, in: calendar)

        #expect(DrawerScope.week.title(for: friday, calendar: calendar).hasPrefix("This Week · "))
        #expect(DrawerScope.week.title(for: monday, calendar: calendar).hasPrefix("This Week · "))

        // Mid-week shows a range, the first day of the week a single date.
        #expect(DrawerScope.week.title(for: friday, calendar: calendar)
                != DrawerScope.week.title(for: monday, calendar: calendar))

        // Both scopes separate their label from the date the same way.
        #expect(DrawerScope.today.title(for: friday, calendar: calendar).contains(" · "))
        #expect(!DrawerScope.today.title(for: friday, calendar: calendar).contains("This Week"))
    }
}
