//
//  RideActivityWidget.swift
//  Andare
//
//  Created by neg2sode on 2025/6/18.
//

import SwiftUI
import WidgetKit
import ActivityKit

struct RideActivityWidget: Widget {
    @ViewBuilder
    private func workoutIcon(for workoutType: WorkoutType) -> some View {
        Image(systemName: workoutType.sfSymbolName)
            .foregroundStyle(.accent)
    }
    
    @ViewBuilder
    private func workoutTitle(for workoutType: WorkoutType) -> some View {
        Text("Andare \(workoutType.rawValue)")
            .foregroundStyle(.primary)
    }
    
    @ViewBuilder
    private func timerView(for rideStartDate: Date?) -> some View {
        if let startDate = rideStartDate {
            Text(timerInterval: startDate...Date.distantFuture, countsDown: false)
                .foregroundStyle(.durationColour)
        } else {
            Text("--:--")
                .foregroundStyle(.durationColour)
        }
    }
    
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RideActivityAttributes.self) { context in
            // MARK: Lock Screen UI
            VStack {
                // Top Row: Ride Info and Duration
                HStack {
                    workoutIcon(for: context.attributes.workoutType)
                        .symbolVariant(.circle.fill)
                        .font(.title)
                    
                    workoutTitle(for: context.attributes.workoutType)
                        .font(.headline)
                    
                    Spacer()
                    
                    timerView(for: context.state.rideStartDate)
                        .font(.title3.monospacedDigit())
                        .frame(width: 80)
                }
                
                // Center: Current Cadence
                if let cadence = context.state.preferredCadence {
                    VStack {
                        Text(String(Int(cadence.rounded())))
                            .foregroundStyle(Color.primary)
                            .font(.system(size: 56, weight: .semibold, design: .rounded))
                        Text("RPM")
                            .font(.headline)
                            .foregroundStyle(Color.secondary)
                    }
                    .padding(.top, 4)
                }
            }
            .padding()
            .activityBackgroundTint(Color(.systemGray6))
            .activitySystemActionForegroundColor(.primary)
            
        } dynamicIsland: { context in
            // MARK: Dynamic Island UI
            DynamicIsland {
                // MARK: Expanded UI (when user long-presses the island)
                DynamicIslandExpandedRegion(.leading) {
                    workoutIcon(for: context.attributes.workoutType)
                        .symbolVariant(.circle.fill)
                        .font(.title)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    timerView(for: context.state.rideStartDate)
                        .font(.title3.monospacedDigit())
                        .frame(width: 80)
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        if let cadence = context.state.preferredCadence {
                            HStack(alignment: .lastTextBaseline, spacing: 2) {
                                Text(String(Int(cadence.rounded())))
                                    .font(.title2.weight(.semibold))
                                Text("RPM")
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            HStack(alignment: .lastTextBaseline, spacing: 2) {
                                Text("--")
                                    .font(.title2.weight(.semibold))
                                Text("RPM")
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        workoutTitle(for: context.attributes.workoutType)
                            .font(.caption)
                    }
                }

            } compactLeading: {
                workoutIcon(for: context.attributes.workoutType)
                    
            } compactTrailing: {
                // MARK: Compact UI (trailing/right side)
                if let cadence = context.state.preferredCadence {
                    HStack(alignment: .lastTextBaseline, spacing: 1) {
                        Text(String(Int(cadence.rounded())))
                            .font(.body.weight(.semibold).monospacedDigit())
                        Text("RPM")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.leading, -2)
                    }
                    .frame(width: 60)
                } else {
                    timerView(for: context.state.rideStartDate)
                        .font(.caption.monospacedDigit())
                        .frame(width: 45)
                }
                
            } minimal: {
                // MARK: Minimal UI (when multiple activities are active)
                workoutIcon(for: context.attributes.workoutType)
            }
        }
    }
}
