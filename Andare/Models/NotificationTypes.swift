//
//  NotificationTypes.swift
//  Andare
//
//  Created by neg2sode on 2025/7/21.
//

import Foundation

enum NotificationType: String, Codable {
    case lowCadenceAlert = "Low Cadence Alert"
    case highCadenceAlert = "High Cadence Alert"
    case pushingBike = "Consider Pushing Bike"
    case finishedWorkout = "Finished Workout?"
}

enum NotificationFrequency: String, Codable, CaseIterable {
    case normal = "Default"
    case high = "High"
}
