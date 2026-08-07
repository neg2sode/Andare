//
//  CadenceTile.swift
//  Andare
//
//  Created by neg2sode on 2026/8/7.
//

import SwiftUI

/// The full-width cadence tile: a sentence about how many workouts in the
/// current scope held a sound cadence.
///
/// This replaces the old share-above-60% verdict, which only made sense over a
/// week — scoped to a single day it had nothing to say. Counting workouts works
/// at either scale, and reads as an observation rather than a grade.
struct CadenceTile: View {
    let scope: DrawerScope
    let workouts: [WorkoutDataModel]

    /// The sentence the tile shows, derived purely from counts so the phrasing
    /// can be tested without standing up SwiftData or a view hierarchy.
    struct Verdict: Equatable {
        let title: String
        let detail: String
        let icon: String
        let colour: Color

        /// - Parameters:
        ///   - total: workouts in scope, whether or not cadence was recorded.
        ///   - measured: those that recorded a usable cadence.
        ///   - offCadence: of the measured ones, how many sat outside the
        ///     sustainable zone.
        static func make(total: Int, measured: Int, offCadence: Int, scope: DrawerScope) -> Verdict {
            // "today" / "this week", for use inside a sentence.
            let period = scope == .today ? "today" : "this week"

            guard total > 0 else {
                return Verdict(
                    title: scope == .today ? "No Workouts Today" : "No Workouts This Week",
                    detail: "Your cadence summary appears after a workout.",
                    icon: "circle.dashed",
                    colour: .gray
                )
            }

            guard measured > 0 else {
                return Verdict(
                    title: "No Cadence Data",
                    detail: total == 1
                        ? "Your workout \(period) didn't record a cadence."
                        : "Your workouts \(period) didn't record a cadence.",
                    icon: "circle.dashed",
                    colour: .gray
                )
            }

            let sound = measured - offCadence

            guard offCadence > 0 else {
                return Verdict(
                    title: "Cadence Looking Good",
                    detail: measured == 1
                        ? "Your workout \(period) held a sound cadence."
                        : "All \(measured) workouts \(period) held a sound cadence.",
                    icon: "checkmark.circle.fill",
                    colour: .cadenceColour
                )
            }

            let remainder: String
            switch sound {
            case 0: remainder = "Try to find your natural cadence by balancing speed and effort."
            case 1: remainder = "The other one held a sound cadence. Try balancing speed and effort."
            default: remainder = "The other \(sound) held a sound cadence. Try balancing speed and effort."
            }

            return Verdict(
                title: "\(offCadence) of \(measured) Off Cadence",
                detail: remainder,
                icon: "exclamationmark.circle.fill",
                colour: .lowCadenceColour
            )
        }
    }

    private var verdict: Verdict {
        // A zero zone means the workout recorded no usable cadence, which is
        // different from recording a poor one — it belongs in neither count.
        let zones = workouts.map {
            CadenceZone.zone(for: $0.averageCadence, workoutType: $0.workoutType)
        }
        let measured = zones.filter { $0 != .zero }

        return .make(
            total: workouts.count,
            measured: measured.count,
            offCadence: measured.filter { $0 != .normal }.count,
            scope: scope
        )
    }

    var body: some View {
        let verdict = self.verdict

        HStack(spacing: 12) {
            Image(systemName: verdict.icon)
                .font(.system(size: 36))
                .foregroundStyle(verdict.colour)

            VStack(alignment: .leading, spacing: 2) {
                Text(verdict.title)
                    .font(.headline)
                    .foregroundStyle(verdict.colour)

                Text(verdict.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(verdict.colour.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Cadence: \(verdict.title). \(verdict.detail)")
    }
}
