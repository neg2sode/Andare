//
//  WorkoutData.swift
//  Andare
//
//  Created by neg2sode on 2025/5/13.
//

import Foundation
import CoreLocation

struct WorkoutData: Identifiable, Equatable {
    let id = UUID()
    let workoutType: WorkoutType
    let startTime: Date
    let endTime: Date
    let cadenceSegments: [CadenceSegment]
    let notificationIntents: [NotificationIntent]
    let logMessages: [String]
    let averageCadence: Double
    let totalDistance: Double
    let averageSpeed: Double
    let maxSpeed: Double
    let elevationGain: Double
    let activeCalories: Double
    let totalCalories: Double
    
    let mapDisplayContext: MapDisplayContext

    // Calculated properties
    var duration: TimeInterval {
        return endTime.timeIntervalSince(startTime)
    }

    // Identity-based equality: `id` is unique per instance, and comparing the
    // full segment/log payload field-by-field is never what callers need.
    static func == (lhs: WorkoutData, rhs: WorkoutData) -> Bool {
        lhs.id == rhs.id
    }
}
