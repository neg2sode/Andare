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

    init() {
        // UI tests share one app install across test methods, so a test that
        // rearranges the drawer would otherwise leak its layout into the next
        // one — silently making them order-dependent.
        if ProcessInfo.processInfo.arguments.contains("-resetDrawerLayout") {
            UserDefaults.standard.removeObject(forKey: DrawerLayout.storageKey)
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
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
