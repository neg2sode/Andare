//
//  CadenceSummarySection.swift
//  Andare
//
//  Created by neg2sode on 2026/8/3.
//

import SwiftUI
import SwiftData

/// Drawer section giving a verdict on the past week's cadence quality.
/// Computed from the same visible-workouts window Recent Workouts shows,
/// independent of that section's expanded/collapsed state.
struct CadenceSummarySection: View {
    @Query(
        filter: #Predicate<WorkoutDataModel> { workout in
            return workout.managementState == 0 // visible
        },
        sort: \.startTime, order: .reverse
    ) private var workouts: [WorkoutDataModel]

    private var workoutsInLastWeek: [WorkoutDataModel] {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: startOfToday)!

        return workouts.filter { $0.startTime >= sevenDaysAgo }
    }

    private struct Verdict {
        let title: String
        let detail: String
        let icon: String
        let colour: Color
    }

    private var verdict: Verdict {
        let week = workoutsInLastWeek

        guard !week.isEmpty else {
            return Verdict(
                title: "No Data",
                detail: "Complete a workout to see your weekly cadence summary.",
                icon: "circle.dashed",
                colour: .gray
            )
        }

        let soundCount = week.filter { workout in
            CadenceZone.zone(for: workout.averageCadence, workoutType: workout.workoutType) == .normal
        }.count

        let share = Double(soundCount) / Double(week.count)

        if share > 0.6 {
            return Verdict(
                title: "Sound Cadence",
                detail: "Your workouts this week show sustainable cadence patterns. Keep going!",
                icon: "checkmark.circle.fill",
                colour: .cadenceColour
            )
        } else {
            return Verdict(
                title: "Know Your Cadence",
                detail: "Recent cadence patterns aren't ideal — that's OK! Try to find your natural cadence by balancing speed and effort.",
                icon: "exclamationmark.circle.fill",
                colour: .lowCadenceColour
            )
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Summary")
                .font(.title2)
                .fontWeight(.bold)

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
            .background(verdict.colour.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Weekly cadence summary: \(verdict.title). \(verdict.detail)")
        }
        .padding(.horizontal)
    }
}
