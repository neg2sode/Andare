//
//  AndareApp.swift
//  Andare
//
//  Created by neg2sode on 2025/1/4.
//

import SwiftUI
import SwiftData
import TipKit

@main
struct AndareApp: App {
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        // This configures the TipKit system.
        // You can add different options here later if needed.
        // For example, to reset all tips for testing:
        // try? Tips.resetDatastore()
        try? Tips.configure([
            // This option is great for development, as it makes tips
            // appear instantly instead of waiting for the system's logic.
            // You might want to remove this for your App Store build.
            .displayFrequency(.immediate),

            // This option tells TipKit to store its data in a location
            // that is NOT backed up to iCloud, which is often desired.
            .datastoreLocation(.applicationDefault)
        ])
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(for: [WorkoutDataModel.self, CadenceSegmentModel.self])
        .onChange(of: scenePhase) {
            switch scenePhase {
            case .active:
                VibrationManager.shared.prepareHapticEngine()
            case.background:
                VibrationManager.shared.stopHapticEngine()
            default:
                break
            }
        }
    }
}
