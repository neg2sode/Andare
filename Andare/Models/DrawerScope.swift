//
//  DrawerScope.swift
//  Andare
//
//  Created by neg2sode on 2026/8/7.
//

import Foundation

/// The window of time the whole drawer describes, chosen from the drawer title.
///
/// Before this existed the drawer held three disagreeing windows at once — a
/// "Today" section, a rolling-seven-day cadence summary, and a workout list that
/// rewrote its own header depending on how many workouts had happened. One scope
/// applied to every section is what keeps them honest with each other.
enum DrawerScope: String, CaseIterable, Identifiable {
    case today
    case week

    var id: String { rawValue }

    /// Menu entry text, independent of any date.
    var menuLabel: String {
        switch self {
        case .today: "Today"
        case .week: "This Week"
        }
    }

    /// The span of time to aggregate over, as a half-open `[start, end)` range.
    ///
    /// Both scopes end at the start of tomorrow rather than "now", so a workout
    /// finishing during the read cannot fall outside the window. The week runs
    /// from the locale's first weekday up to today — not the full seven days —
    /// which is why a Monday legitimately shows a single day of data.
    func interval(containing date: Date = Date(), calendar: Calendar = .current) -> DateInterval {
        let startOfToday = calendar.startOfDay(for: date)
        let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? date

        switch self {
        case .today:
            return DateInterval(start: startOfToday, end: startOfTomorrow)
        case .week:
            // A locale where the week starts on Sunday puts a Sunday's own
            // start-of-week at itself, so this is one day, not eight.
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? startOfToday
            return DateInterval(start: startOfWeek, end: startOfTomorrow)
        }
    }

    /// Whole days covered by the interval, never less than one.
    ///
    /// Averages divide by this rather than by seven — on a Tuesday, dividing a
    /// two-day week by seven would understate every reading by 70%.
    func daysElapsed(containing date: Date = Date(), calendar: Calendar = .current) -> Int {
        let interval = self.interval(containing: date, calendar: calendar)
        let days = calendar.dateComponents([.day], from: interval.start, to: interval.end).day ?? 1
        return max(days, 1)
    }

    /// The drawer's large title: "Friday, Aug 7" or "This Week · Aug 3–7".
    func title(for date: Date = Date(), calendar: Calendar = .current) -> String {
        switch self {
        case .today:
            // Composed rather than one format string so the "·" matches the
            // week title. Both halves stay locale-ordered.
            let weekday = date.formatted(.dateTime.weekday(.wide))
            let day = date.formatted(.dateTime.month(.abbreviated).day())
            return "\(weekday) · \(day)"

        case .week:
            let start = interval(containing: date, calendar: calendar).start
            let dayOnly = Date.FormatStyle.dateTime.month(.abbreviated).day()

            // On the first day of the week there is no range to show yet.
            guard !calendar.isDate(start, inSameDayAs: date) else {
                return "This Week · \(date.formatted(dayOnly))"
            }

            // An interval style collapses "Aug 3 – Aug 7" to "Aug 3 – 7" on its
            // own, and keeps both months when the week straddles one.
            let span = (start..<date).formatted(.interval.month(.abbreviated).day())
            return "This Week · \(span)"
        }
    }
}
