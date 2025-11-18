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
    
    @StateObject private var formatter = StatsFormatter.shared

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(workout.workoutType.rawValue)")
                    .font(.headline)
                    .foregroundStyle(.primary)

                // Display distance, or duration if distance is negligible
                Text(primaryStat)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.accentColor)
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
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 1, y: 1)
        .shadow(color: .black.opacity(0.1), radius: 4, y: 0)
    }
    
    // MARK: - Computed Properties for Display Logic
    
    private var primaryStat: String {
        // Show distance if it's meaningful, otherwise show duration.
        if workout.averageCadence != 0 {
            let stats = formatter.formatCadence(workout.averageCadence, workout.workoutType)
            return stats.value + stats.unit.lowercased() + " avg."
        } else {
            let formatter = DateComponentsFormatter()
            formatter.allowedUnits = [.hour, .minute, .second]
            formatter.unitsStyle = .positional
            formatter.zeroFormattingBehavior = .pad
            return formatter.string(from: workout.duration) ?? "0:00"
        }
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
