//
//  DrawerTileGrid.swift
//  Andare
//
//  Created by neg2sode on 2026/8/7.
//

import SwiftUI
import SwiftData
import HealthKit

/// The drawer's unified grid of stat tiles, replacing the separate "Today" and
/// "Summary" sections. Every tile reads the same `scope`, so the grid can never
/// disagree with itself about which window it is describing.
struct DrawerTileGrid: View {
    let scope: DrawerScope

    @Query(
        filter: #Predicate<WorkoutDataModel> { workout in
            return workout.managementState == 0 // visible
        },
        sort: \.startTime, order: .reverse
    ) private var workouts: [WorkoutDataModel]

    @ObservedObject private var formatter = StatsFormatter.shared

    @State private var healthValues: [DrawerTile: Double] = [:]
    @State private var access: HealthKitManager.TodayDataAccess = .notRequested
    @State private var isLoading = true
    @State private var isShowingEditor = false

    @Environment(\.scenePhase) private var scenePhase

    @AppStorage(DrawerLayoutMigration.storageKey) private var layout = DrawerLayout.default

    private var tiles: [DrawerTile] { layout.entries.map(\.tile) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 12) {
                if tiles.isEmpty {
                    // Without this the drawer would be a dead end: no tile to
                    // long-press means no way back to the editor from here.
                    emptyState
                } else {
                    ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                        HStack(spacing: 12) {
                            ForEach(row) { tile in
                                view(for: tile)
                            }
                        }
                    }
                }
            }
            // Long press to customize, kept off the Health button below so it
            // cannot swallow that tap.
            .contentShape(Rectangle())
            .onLongPressGesture(minimumDuration: 0.5) {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                isShowingEditor = true
            }
            .accessibilityAction(named: "Customize tiles") { isShowingEditor = true }

            if access == .notRequested && tiles.contains(where: \.isHealthKitBacked) {
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
        .task(id: scope) { await refresh() }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active { Task { await refresh() } }
        }
        .sheet(isPresented: $isShowingEditor) {
            CustomizeDrawerView()
        }
    }

    private var emptyState: some View {
        Button {
            isShowingEditor = true
        } label: {
            Label("Add Tiles", systemImage: "plus.circle")
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity, minHeight: 60)
                .contentShape(Rectangle())
        }
        .cardStyle()
    }

    /// `LazyVGrid` cannot span columns, so pair up consecutive narrow tiles and
    /// let a wide one break the row. This keeps any ordering the user picks.
    private var rows: [[DrawerTile]] {
        var result: [[DrawerTile]] = []
        var pending: [DrawerTile] = []

        for tile in tiles {
            if tile.isWide {
                if !pending.isEmpty { result.append(pending); pending = [] }
                result.append([tile])
            } else {
                pending.append(tile)
                if pending.count == 2 { result.append(pending); pending = [] }
            }
        }
        if !pending.isEmpty { result.append(pending) }
        return result
    }

    @ViewBuilder
    private func view(for tile: DrawerTile) -> some View {
        if tile == .cadence {
            CadenceTile(scope: scope, workouts: workoutsInScope)
        } else {
            let reading = reading(for: tile)
            SummaryStatCard(
                label: reading.label,
                value: reading.value,
                unit: reading.unit,
                unitColour: reading.unitColour,
                icon: tile.icon,
                iconTint: tile.iconTint
            )
            .redacted(reason: isLoading && tile.isHealthKitBacked ? .placeholder : [])
            .accessibilityLabel(reading.spoken)
        }
    }

    // MARK: - Readings

    private struct Reading {
        var label: String
        var value: String
        var unit: String
        var unitColour: Color
        var spoken: String
    }

    private var workoutsInScope: [WorkoutDataModel] {
        let interval = scope.interval()
        return workouts.filter { interval.contains($0.startTime) }
    }

    /// A nil HealthKit sum means "nothing recorded" when reads demonstrably
    /// work, and "we can't see your data" otherwise — only the latter deserves
    /// a dash rather than a zero.
    private var healthPlaceholder: String { access == .readable ? "0" : "–" }

    private func aggregation(for tile: DrawerTile) -> Aggregation {
        layout.aggregation(for: tile)
    }

    private func reading(for tile: DrawerTile) -> Reading {
        let aggregation = aggregation(for: tile)
        let label = tile.label(scope: scope, aggregation: aggregation)
        let averaging = scope == .week && aggregation == .average

        if tile.isHealthKitBacked {
            guard var amount = healthValues[tile] else {
                return Reading(label: label, value: healthPlaceholder, unit: "",
                               unitColour: .clear, spoken: "\(label), no data")
            }
            if averaging { amount /= Double(scope.daysElapsed()) }
            return formatted(tile, amount: amount, label: label)
        }

        let scoped = workoutsInScope
        let total: Double
        switch tile {
        case .rideDistance: total = scoped.reduce(0) { $0 + $1.totalDistance }
        case .rideDuration: total = scoped.reduce(0) { $0 + $1.duration }
        default: total = 0
        }

        // Averaging ride metrics per workout, not per day — dividing by rest
        // days would understate what the workouts themselves looked like.
        let amount = averaging && !scoped.isEmpty ? total / Double(scoped.count) : total
        return formatted(tile, amount: amount, label: label)
    }

    private func formatted(_ tile: DrawerTile, amount: Double, label: String) -> Reading {
        switch tile {
        case .daylight:
            // A week of daylight in minutes runs to four digits; hours read better.
            if amount >= 120 {
                let hours = amount / 60
                let value = NumberFormatter.decimalFormatter.string(from: NSNumber(value: hours)) ?? "0"
                return Reading(label: label, value: value, unit: "HR", unitColour: .durationColour,
                               spoken: "\(label), \(value) hours")
            }
            let value = NumberFormatter.integerFormatter.string(from: NSNumber(value: amount)) ?? "0"
            return Reading(label: label, value: value, unit: "MIN", unitColour: .durationColour,
                           spoken: "\(label), \(value) minutes")

        case .steps:
            let value = NumberFormatter.groupedIntegerFormatter.string(from: NSNumber(value: amount)) ?? "0"
            return Reading(label: label, value: value, unit: "", unitColour: .clear,
                           spoken: "\(label), \(value)")

        case .walkingDistance, .rideDistance:
            let stats = formatter.formatDistance(amount)
            return Reading(label: label, value: stats.value, unit: stats.unit, unitColour: stats.colour,
                           spoken: "\(label), \(stats.value) \(stats.unit)")

        case .rideDuration:
            let stats = formatter.formatDuration(amount)
            return Reading(label: label, value: stats.value, unit: stats.unit, unitColour: stats.colour,
                           spoken: "\(label), \(stats.value)")

        case .cadence:
            return Reading(label: label, value: "", unit: "", unitColour: .clear, spoken: label)
        }
    }

    // MARK: - Loading

    private func refresh() async {
        let manager = HealthKitManager.shared
        let interval = scope.interval()

        access = await manager.todayDataAccess()

        async let daylight = manager.sum(.timeInDaylight, unit: .minute(), over: interval)
        async let steps = manager.sum(.stepCount, unit: .count(), over: interval)
        async let walking = manager.sum(.distanceWalkingRunning, unit: .meter(), over: interval)

        // Assigning nil removes the key, so an absent entry means "no data".
        var values: [DrawerTile: Double] = [:]
        values[.daylight] = await daylight
        values[.steps] = await steps
        values[.walkingDistance] = await walking

        healthValues = values
        isLoading = false
    }
}
