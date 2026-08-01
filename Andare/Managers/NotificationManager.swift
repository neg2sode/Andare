//
//  NofiticationManager.swift
//  Andare
//
//  Created by neg2sode on 2025/5/14.
//

import Foundation
import UserNotifications // For local notifications

@MainActor
final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    func refreshStatus() {
        Task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            authorizationStatus = settings.authorizationStatus
        }
    }

    func requestAuthorisation() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            print("Notification permission granted: \(granted)")
            // After the user makes a choice, refresh the status to update the UI.
            refreshStatus()
        } catch {
            print("Failed to request notification authorization: \(error)")
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
