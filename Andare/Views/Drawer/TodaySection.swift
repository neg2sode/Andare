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
    @State private var access: HealthKitManager.TodayDataAccess = .notRequested

    @Environment(\.scenePhase) private var scenePhase

    private var canRequestAccess: Bool { access == .notRequested }

    /// A nil sum means "nothing recorded" when reads demonstrably work, and
    /// "we can't see your data" otherwise — only the latter deserves a dash.
    private var placeholder: String { access == .readable ? "0" : "–" }

    private var daylightValue: String {
        guard let daylightMinutes else { return placeholder }
        return NumberFormatter.integerFormatter.string(from: NSNumber(value: daylightMinutes)) ?? "0"
    }

    private var stepsValue: String {
        guard let steps else { return placeholder }
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
                    unit: daylightMinutes != nil || access == .readable ? "MIN" : "",
                    unitColour: .durationColour,
                    icon: "sun.max.fill",
                    iconTint: .orange
                )
                // The em-dash placeholder means nothing spoken aloud.
                .accessibilityLabel(daylightMinutes == nil && access != .readable
                                    ? "Time in Daylight, no data"
                                    : "Time in Daylight, \(daylightValue) minutes")

                SummaryStatCard(
                    label: "Steps",
                    value: stepsValue,
                    unit: "",
                    unitColour: .clear,
                    icon: "shoeprints.fill",
                    iconTint: .cadenceColour
                )
                .accessibilityLabel(steps == nil && access != .readable
                                    ? "Steps, no data"
                                    : "Steps, \(stepsValue)")
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
                        // Text alone is an 18pt-tall target; pad it to 44.
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
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
        access = await manager.todayDataAccess()
        daylightMinutes = await manager.fetchTodaysSum(.timeInDaylight, unit: .minute())
        steps = await manager.fetchTodaysSum(.stepCount, unit: .count())
        isLoading = false
    }
}
