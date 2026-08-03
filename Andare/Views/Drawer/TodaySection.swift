//
//  TodaySection.swift
//  Andare
//
//  Created by neg2sode on 2026/8/3.
//

import SwiftUI
import HealthKit

/// Drawer section showing today's Time in Daylight and Steps from HealthKit.
/// Values are real queries — when data is unreadable (denied or none yet)
/// the cards show an em-dash rather than fake numbers.
struct TodaySection: View {
    @State private var daylightMinutes: Double?
    @State private var steps: Double?
    @State private var isLoading = true
    @State private var canRequestAccess = false

    @Environment(\.scenePhase) private var scenePhase

    private var daylightValue: String {
        guard let daylightMinutes else { return "–" }
        return NumberFormatter.integerFormatter.string(from: NSNumber(value: daylightMinutes)) ?? "0"
    }

    private var stepsValue: String {
        guard let steps else { return "–" }
        return NumberFormatter.groupedIntegerFormatter.string(from: NSNumber(value: steps)) ?? "0"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today")
                .font(.title2)
                .fontWeight(.bold)

            HStack(spacing: 12) {
                SummaryStatCard(
                    label: "Time in Daylight",
                    value: daylightValue,
                    unit: daylightMinutes != nil ? "MIN" : "",
                    unitColour: .durationColour,
                    icon: "sun.max.fill",
                    iconTint: .orange
                )

                SummaryStatCard(
                    label: "Steps",
                    value: stepsValue,
                    unit: "",
                    unitColour: .clear,
                    icon: "shoeprints.fill",
                    iconTint: .cadenceColour
                )
            }
            .redacted(reason: isLoading ? .placeholder : [])

            if canRequestAccess {
                Button {
                    Task {
                        await HealthKitManager.shared.requestTodayAuthorisation()
                        await refresh()
                    }
                } label: {
                    Label("Allow Health Access", systemImage: "heart.text.square")
                        .font(.subheadline.weight(.medium))
                }
                .padding(.top, 2)
            }
        }
        .padding(.horizontal)
        .task {
            await refresh()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task { await refresh() }
            }
        }
    }

    private func refresh() async {
        let manager = HealthKitManager.shared
        canRequestAccess = await manager.shouldRequestTodayAuthorisation()
        daylightMinutes = await manager.fetchTodaysSum(.timeInDaylight, unit: .minute())
        steps = await manager.fetchTodaysSum(.stepCount, unit: .count())
        isLoading = false
    }
}
