//
//  RideActivityAttributes.swift
//  Andare
//
//  Created by neg2sode on 2025/6/18.
//

import Foundation
import ActivityKit

struct RideActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var rideStartDate: Date?
        var preferredCadence: Double?
    }

    // This is static data that doesn't change during the activity.
    var workoutType: WorkoutType
}
