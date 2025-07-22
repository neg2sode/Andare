//
//  StatsOverlayView.swift
//  Andare
//
//  Created by neg2sode on 2025/5/26.
//

import SwiftUI

// Reusable helper view for displaying a single stat block in the overlay
struct OverlayStatsBlock: View {
    let labelLine1: String
    let labelLine2: String // Can be empty if only one line is needed
    let stats: FormattedStats
    let valueToAnimate: Double? // Use optional Double for animation value

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 8) {
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(stats.value)
                    .font(.system(size: 70, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary) // Apply color from FormattedStats
                    .contentTransition(.numericText())
                    .animation(.snappy, value: valueToAnimate) // Apply animation
                Text(stats.unit)
                    .font(.system(size: 30, weight: .medium, design: .rounded))
                    .foregroundStyle(stats.colour) // Apply color from FormattedStats
            }
            
            VStack(alignment: .leading, spacing: -2) {
                Text(labelLine1)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                if !labelLine2.isEmpty { // Only show second line if not empty
                    Text(labelLine2)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 12) // Adjust vertical alignment of label block
        }
    }
}

struct ElapsedTimeBlock: View {
    let stats: FormattedStats
    
    var body: some View {
        Text(stats.value)
            .font(.system(size: 58, weight: .semibold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(stats.colour)
            .contentTransition(.numericText())
    }
}

struct StatsOverlayView: View {
    @ObservedObject var rideSessionManager: RideSessionManager
    @Environment(\.verticalSizeClass) var verticalSizeClass
    private var formatter = StatsFormatter()
    
    init(rideSessionManager: RideSessionManager) {
        self.rideSessionManager = rideSessionManager
    }
    
    var body: some View {
        if verticalSizeClass == .regular {
            portraitLayout
        } else {
            landscapeLayout
        }
    }
    
    var portraitLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Duration
            if let startDate = rideSessionManager.startDate {
                TimelineView(.periodic(from: startDate, by: 1.0)) { context in
                    let elapsedTime = context.date.timeIntervalSince(startDate)
                    ElapsedTimeBlock(stats: StatsFormatter.formatDuration(elapsedTime))
                }
            } else {
                ElapsedTimeBlock(stats: StatsFormatter.formatDuration(0))
            }
            
            // Average Cadence
            OverlayStatsBlock(
                labelLine1: "AVERAGE",
                labelLine2: "CADENCE",
                stats: StatsFormatter.formatCadence(rideSessionManager.averageCadence),
                valueToAnimate: rideSessionManager.averageCadence
            )
            
            // Average Speed
            OverlayStatsBlock(
                labelLine1: "AVERAGE",
                labelLine2: "SPEED",
                stats: StatsFormatter.formatSpeed(rideSessionManager.averageSpeed),
                valueToAnimate: rideSessionManager.averageSpeed
            )
            
            // Active Calories
            OverlayStatsBlock(
                labelLine1: "ACTIVE",
                labelLine2: "KILOCALORIES",
                stats: StatsFormatter.formatEnergyBurned(rideSessionManager.activeCalories),
                valueToAnimate: rideSessionManager.activeCalories
            )
            
            // Elevation Gained
            OverlayStatsBlock(
                labelLine1: "ELEVATION",
                labelLine2: "GAIN",
                stats: StatsFormatter.formatElevation(rideSessionManager.elevationGain),
                valueToAnimate: rideSessionManager.elevationGain
            )
            
            // Total Distance
            OverlayStatsBlock(
                labelLine1: "",
                labelLine2: "",
                stats: StatsFormatter.formatDistance(rideSessionManager.totalDistance),
                valueToAnimate: rideSessionManager.totalDistance
            )
        }
        .padding(.horizontal, 20)
    }
    
    private var landscapeLayout: some View {
        HStack(spacing: 40) {
            // First Column
            VStack(alignment: .leading, spacing: 8) {
                // Duration
                if let startDate = rideSessionManager.startDate {
                    TimelineView(.periodic(from: startDate, by: 1.0)) { context in
                        let elapsedTime = context.date.timeIntervalSince(startDate)
                        ElapsedTimeBlock(stats: StatsFormatter.formatDuration(elapsedTime))
                    }
                } else {
                    ElapsedTimeBlock(stats: StatsFormatter.formatDuration(0))
                }
                
                OverlayStatsBlock(labelLine1: "AVERAGE", labelLine2: "CADENCE", stats: StatsFormatter.formatCadence(rideSessionManager.averageCadence), valueToAnimate: rideSessionManager.averageCadence)
                OverlayStatsBlock(labelLine1: "AVERAGE", labelLine2: "SPEED", stats: StatsFormatter.formatSpeed(rideSessionManager.averageSpeed), valueToAnimate: rideSessionManager.averageSpeed)
            }
            
            // Second Column
            VStack(alignment: .leading, spacing: 8) {
                OverlayStatsBlock(labelLine1: "ACTIVE", labelLine2: "KILOCALORIES", stats: StatsFormatter.formatEnergyBurned(rideSessionManager.activeCalories), valueToAnimate: rideSessionManager.activeCalories)
                OverlayStatsBlock(labelLine1: "ELEVATION", labelLine2: "GAIN", stats: StatsFormatter.formatElevation(rideSessionManager.elevationGain), valueToAnimate: rideSessionManager.elevationGain)
                OverlayStatsBlock(labelLine1: "", labelLine2: "", stats: StatsFormatter.formatDistance(rideSessionManager.totalDistance), valueToAnimate: rideSessionManager.totalDistance)
            }
        }
        .frame(maxWidth: .infinity) // Allow the HStack to center itself
    }
}


struct StatsOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        let mock = RideSessionManager(workoutType: .cycling)
        mock.averageSpeed = 25.6
        mock.averageCadence = nil // Test nil case
        mock.elevationGain = 120.0
        mock.totalDistance = 2570.0
        mock.activeCalories = 200
        return StatsOverlayView(rideSessionManager: mock)
            .previewLayout(.sizeThatFits)
    }
}
