//
//  RootView.swift
//  Andare
//
//  Created by neg2sode on 2026/8/8.
//

import SwiftUI
import SwiftData

/// The app's root, and the first place with a `ModelContext` — which is why the
/// stored-workout repair runs here rather than in `AndareApp.init()`.
///
/// In debug builds it can also stand in a sample ride via `-showSampleSummary`.
/// A workout recorded on a simulator has neither cadence nor GPS, so the chart
/// and the route map are otherwise always empty states and impossible to review.
/// It replaces the root rather than presenting a sheet, because `HomeView`
/// already owns the drawer sheet and a second sheet cannot stack on top of it.
struct RootView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        content
            .task {
                WorkoutCalorieRepair.runIfNeeded(context: modelContext)
            }
    }

    @ViewBuilder
    private var content: some View {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-showSampleSummary") {
            WorkoutSummaryView(data: .sample(minutes: 60))
        } else if ProcessInfo.processInfo.arguments.contains("-showSampleSummaryShort") {
            WorkoutSummaryView(data: .sample(minutes: 6))
        } else {
            HomeView()
        }
        #else
        HomeView()
        #endif
    }
}
