//
//  AndareApp.swift
//  Andare
//
//  Created by neg2sode on 2025/1/4.
//

import SwiftUI
import SwiftData

@main
struct AndareApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            // We'll replace the old ContentView with our new TabView structure
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
