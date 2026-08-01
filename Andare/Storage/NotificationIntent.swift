//
//  NotificationIntent.swift
//  Andare
//
//  Created by neg2sode on 2025/7/28.
//

import Foundation

struct NotificationIntent: Identifiable, Equatable {
    let id = UUID()
    let endDate: Date
    let type: NotificationType
    let duration: TimeInterval
    
    var startDate: Date {
        endDate.addingTimeInterval(-duration)
    }
}

extension NotificationIntent {
    init(from model: NotificationIntentModel) {
        self.init(
            endDate: model.endDate,
            type: model.type,
            duration: model.duration
        )
    }
}
