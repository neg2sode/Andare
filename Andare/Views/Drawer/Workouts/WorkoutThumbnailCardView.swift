//
//  WorkoutThumbnailCardView.swift
//  Andare
//
//  Created by neg2sode on 2025/7/9.
//

import SwiftUI
import SwiftData

struct WorkoutThumbnailCardView: View {
    let workout: WorkoutDataModel
    let onTap: () -> Void

    @ObservedObject private var formatter = StatsFormatter.shared

    private var cadenceZone: CadenceZone {
        CadenceZone.zone(for: workout.averageCadence, workoutType: workout.workoutType)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(workout.workoutType.rawValue)")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    primaryStatView
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    Text(formattedDate)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(formattedTimeRange)
                        .font(.subheadline) // Smaller font for secondary info
                        .foregroundStyle(.secondary) // Muted color
                }
            }
            .padding()
            .cardStyle(radius: 12)
            .shadow(color: .black.opacity(0.08), radius: 1, y: 1)
            .shadow(color: .black.opacity(0.1), radius: 4, y: 0)
        }
        .buttonStyle(CardPressStyle())
    }

    // MARK: - Computed Properties for Display Logic

    /// Average cadence with a zone-coloured unit and an up/down hint for
    /// high/low zones; falls back to duration when no cadence was detected.
    @ViewBuilder
    private var primaryStatView: some View {
        if workout.averageCadence != 0 {
            let stats = formatter.formatCadence(workout.averageCadence, workout.workoutType)

            HStack(spacing: 4) {
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(stats.value)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(stats.unit)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(cadenceZone.color)
                }

                if cadenceZone == .low || cadenceZone == .high {
                    Image(systemName: cadenceZone == .low ? "arrow.down" : "arrow.up")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(cadenceZone.color)
                }
            }
        } else {
            Text(formattedDuration)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.primary)
        }
    }

    private var formattedDuration: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: workout.duration) ?? "0:00"
    }
    
    private var formattedDate: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(workout.startTime) {
            return "Today"
        } else if calendar.isDateInYesterday(workout.startTime) {
            return "Yesterday"
        } else {
            // e.g., "Tuesday", "Monday"
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE" // Format for the full day name
            return formatter.string(from: workout.startTime)
        }
    }
    
    private var formattedTimeRange: String {
        // Create a single formatter for efficiency.
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm" // 24-hour format like "23:55"
        
        // Format both start and end times.
        let startTimeString = formatter.string(from: workout.startTime)
        let endTimeString = formatter.string(from: workout.endTime)
        
        // Combine them using an en-dash (–) for correct typography.
        return "\(startTimeString)–\(endTimeString)"
    }
}
