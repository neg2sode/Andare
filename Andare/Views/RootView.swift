//
//  SampleSummaryPresenter.swift
//  Andare
//
//  Created by neg2sode on 2026/8/8.
//

import SwiftUI

/// Root view chooser: shows the workout summary over a stand-in ride when
/// launched with `-showSampleSummary`, otherwise the normal home screen.
///
/// A workout recorded on a simulator has neither cadence nor GPS, so the chart
/// and the route map — the summary's two most visual sections — are otherwise
/// always empty states and impossible to review. Replacing the root rather than
/// presenting a sheet because `HomeView` already owns the drawer sheet, and a
/// second sheet cannot stack on top of it.
///
/// Outside debug builds this compiles down to `HomeView` alone.
struct RootView: View {
    var body: some View {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-showSampleSummary") {
            WorkoutSummaryView(data: .sample)
        } else {
            HomeView()
        }
        #else
        HomeView()
        #endif
    }
}
