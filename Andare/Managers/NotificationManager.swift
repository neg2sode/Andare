//
//  NofiticationManager.swift
//  Andare
//
//  Created by neg2sode on 2025/5/14.
//

import Foundation
import UserNotifications // For local notifications

enum NotificationType: String {
    case lowCadenceAlert = "Low Cadence Alert"
    case highCadenceAlert = "High Cadence Alert"
    case pushingBike = "Consider Pushing Bike"
    case finishedWorkout = "Finished Workout?"
}

final class NotificationManager {
    static let shared = NotificationManager()

    // Request permission on init -> needs to be changed in the future
    init() {
        Task {
            await requestAuthorisation()
        }
    }

    func requestAuthorisation() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            return false
        }
    }

    // Main function to process workout status and decide on feedback
    func notifyRideStatus(type: NotificationType) async {
        switch type {
        case .lowCadenceAlert:
            await scheduleNotification(title: "Cadence Alert", body: "Your cadence is a bit low!", identifier: "lowCadenceAlert")
        case .highCadenceAlert:
            await scheduleNotification(title: "Cadence Alert", body: "Your cadence is a bit high!", identifier: "highCadenceAlert")
        case .pushingBike:
            await scheduleNotification(title: "Cadence Alert", body: "Consider walking with your bike when uphill.", identifier: "pushingBikeAlert")
        case .finishedWorkout:
            await scheduleNotification(title: "Finished Workout?", body: "We noticed that you haven't moved for a while.", identifier: "finishedWorkoutAlert")
        }
    }


    private func scheduleNotification(title: String, body: String, sound: UNNotificationSound = .default, identifier: String = UUID().uuidString) async {
        do {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            guard settings.authorizationStatus == .authorized else { return }

            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = sound

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("NotificationManager: Error scheduling notification \(identifier): \(error.localizedDescription)")
        }
    }
}
