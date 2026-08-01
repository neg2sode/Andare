//
//  NotificationIntentModel.swift
//  Andare
//
//  Created by neg2sode on 2025/7/28.
//

import Foundation
import SwiftData

@Model
final class NotificationIntentModel {
    var endDate: Date
    var type: NotificationType // Assumes NotificationType is Codable
    var duration: TimeInterval
    
    // The inverse relationship back to the parent workout
    var workout: WorkoutDataModel?
    
    init(endDate: Date, type: NotificationType, duration: TimeInterval) {
        self.endDate = endDate
        self.type = type
        self.duration = duration
    }
}
