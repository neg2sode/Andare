//
//  StatsOverlayView.swift
//  Andare
//
//  Created by neg2sode on 2025/5/26.
//

import SwiftUI
import Charts
import Combine

extension Color {
    static let gyroXColour: Color = .elevationColour
    static let gyroYColour: Color = .calorieColour
    static let gyroZColour: Color = .distanceColour
}

struct StatsOverlayView: View {
    @ObservedObject var rideSessionManager: RideSessionManager
    @ObservedObject private var formatter = StatsFormatter.shared

    @State private var isExpanded: Bool = false
    @AppStorage("hasDiscoveredStatsPanel") private var hasDiscoveredStats: Bool = false
    private let slideOffset: CGFloat = 420

    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.scenePhase) private var scenePhase

    init(rideSessionManager: RideSessionManager) {
        self.rideSessionManager = rideSessionManager
    }

    var body: some View {
        Group {
            if verticalSizeClass == .regular {
                ZStack(alignment: .top) {
                    gyroPanel
                        .offset(y: isExpanded ? 0 : -slideOffset)

                    portraitLayout
                        .offset(y: isExpanded ? slideOffset : 0)
                }
                .clipped() // hides content that slides outside the frame
                .animation(.spring(response: 0.4, dampingFraction: 0.9), value: isExpanded)
                .contentShape(Rectangle())
                .simultaneousGesture(panelSwipeGesture)
            } else {
                landscapeLayout
            }
        }
        .onChange(of: isExpanded) { updateGyroStreaming() }
        .onChange(of: scenePhase) { updateGyroStreaming() }
        .onChange(of: verticalSizeClass) { updateGyroStreaming() }
        .onDisappear {
            rideSessionManager.stopGyroStreaming()
        }
    }

    // MARK: - Gyro Streaming Lifecycle

    /// The panel's charts are the only consumer of per-sample gyro data on the
    /// main thread — stream only while they are actually visible.
    private func updateGyroStreaming() {
        let panelVisible = isExpanded && scenePhase == .active && verticalSizeClass == .regular
        if panelVisible {
            rideSessionManager.startGyroStreaming()
        } else {
            rideSessionManager.stopGyroStreaming()
        }
    }

    // MARK: - Expand/Collapse Gesture

    private var panelSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 5, coordinateSpace: .local)
            .onEnded { value in
                let threshold: CGFloat = 10
                let shouldToggle = (!isExpanded && value.translation.height > threshold) ||
                                   (isExpanded && value.translation.height < -threshold)
                if shouldToggle {
                    isExpanded.toggle()
                    markPanelDiscovered()
                }
            }
    }

    private func markPanelDiscovered() {
        guard !hasDiscoveredStats else { return }
        withAnimation(.easeOut(duration: 0.4)) {
            hasDiscoveredStats = true
        }
    }

    // MARK: - Stat Blocks (shared by both layouts)

    private var statBlocks: [(label1: String, label2: String, stats: FormattedStats, animationValue: Double?)] {
        let speedLabel = rideSessionManager.workoutType == .cycling ? "SPEED" : "PACE"
        return [
            ("AVERAGE", "CADENCE",
             formatter.formatCadence(rideSessionManager.averageCadence, rideSessionManager.workoutType),
             rideSessionManager.averageCadence),
            ("AVERAGE", speedLabel,
             formatter.formatSpeedOrPace(rideSessionManager.averageSpeed, workoutType: rideSessionManager.workoutType),
             rideSessionManager.averageSpeed),
            ("ACTIVE", "KILOCALORIES",
             formatter.formatEnergyBurned(rideSessionManager.activeCalories),
             rideSessionManager.activeCalories),
            ("ELEVATION", "GAIN",
             formatter.formatElevation(rideSessionManager.elevationGain),
             rideSessionManager.elevationGain),
            ("DISTANCE", "",
             formatter.formatDistance(rideSessionManager.totalDistance),
             rideSessionManager.totalDistance),
        ]
    }

    @ViewBuilder
    private func statBlockViews(_ indices: [Int]) -> some View {
        ForEach(indices, id: \.self) { index in
            let block = statBlocks[index]
            OverlayStatsBlock(
                labelLine1: block.label1,
                labelLine2: block.label2,
                stats: block.stats,
                valueToAnimate: block.animationValue
            )
        }
    }

    // MARK: - Portrait

    var portraitLayout: some View {
        VStack(alignment: .leading, spacing: 24) {
            timerAndControlRow
                .padding(.bottom, 8)

            statBlockViews(Array(statBlocks.indices))
        }
        .padding(.horizontal, 30)
    }

    private var timerAndControlRow: some View {
        HStack(alignment: .center) {
            Image(systemName: rideSessionManager.workoutType.sfSymbol)
                .font(.system(size: 54))
                .symbolVariant(.circle.fill)
                .foregroundStyle(.accent)
                .symbolRenderingMode(.hierarchical)
                .symbolEffect(.pulse, options: .repeating)

            Spacer()

            // Duration
            if let startDate = rideSessionManager.startDate {
                TimelineView(.periodic(from: startDate, by: 1.0)) { context in
                    let elapsedTime = context.date.timeIntervalSince(startDate)
                    ElapsedTimeBlock(stats: formatter.formatDuration(elapsedTime))
                }
            } else {
                ElapsedTimeBlock(stats: formatter.formatDuration(0))
            }

            Spacer()

            // Expand/collapse chevron with one-time discovery hint
            Button {
                isExpanded.toggle()
                markPanelDiscovered()
            } label: {
                Image(systemName: "chevron.down.circle.fill")
                    .font(.system(size: 54))
                    .foregroundStyle(.accent)
                    .symbolRenderingMode(.hierarchical)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }
            // Overlaid so the hint never widens the row (the timer would wrap)
            .overlay(alignment: .bottom) {
                if !hasDiscoveredStats {
                    Text("Swipe down for more")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .fixedSize()
                        .offset(y: 16)
                        .transition(.opacity)
                }
            }
        }
    }

    // MARK: - Landscape

    private var landscapeLayout: some View {
        HStack(spacing: 40) {
            // First Column
            VStack(alignment: .leading, spacing: 8) {
                // Duration
                if let startDate = rideSessionManager.startDate {
                    TimelineView(.periodic(from: startDate, by: 1.0)) { context in
                        let elapsedTime = context.date.timeIntervalSince(startDate)
                        ElapsedTimeBlock(stats: formatter.formatDuration(elapsedTime))
                    }
                } else {
                    ElapsedTimeBlock(stats: formatter.formatDuration(0))
                }

                statBlockViews([0, 1])
            }

            // Second Column
            VStack(alignment: .leading, spacing: 8) {
                statBlockViews([2, 3, 4])
            }
        }
        .frame(maxWidth: .infinity) // Allow the HStack to center itself
    }

    // MARK: - Gyro Panel (the hidden "vibe" surface)

    private var gyroPanel: some View {
        VStack(spacing: 14) {
            FlowingGyroChart(
                history: rideSessionManager.gyroXHistory,
                color: .gyroXColour,
                label: "X",
                workoutType: rideSessionManager.workoutType
            )

            FlowingGyroChart(
                history: rideSessionManager.gyroYHistory,
                color: .gyroYColour,
                label: "Y",
                workoutType: rideSessionManager.workoutType
            )

            FlowingGyroChart(
                history: rideSessionManager.gyroZHistory,
                color: .gyroZColour,
                label: "Z",
                workoutType: rideSessionManager.workoutType
            )
        }
        .padding(.horizontal, 30)
        .padding(.bottom, 30)
        .frame(height: slideOffset)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Live rotation signal across three axes")
    }
}

// MARK: - Flowing Gyro Chart

struct FlowingGyroChart: View {
    let history: [GyroHistoryPoint]
    let color: Color
    let label: String
    let workoutType: WorkoutType

    /// Dynamic Y scale based on typical rotation intensity per workout type
    private var chartYScale: ClosedRange<Double> {
        switch workoutType {
        case .cycling: return -8...8
        case .running: return -15...15
        case .walking: return -10...10
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            // Axis label
            Text(label)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .frame(width: 24)

            // Chart
            Chart {
                ForEach(Array(history.enumerated()), id: \.element.id) { position, point in
                    LineMark(
                        x: .value("Position", position),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(color.gradient)
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartXScale(domain: 0...512)
            .chartYScale(domain: chartYScale)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .frame(height: 110)
    }
}

// Reusable helper view for displaying a single stat block in the overlay
struct OverlayStatsBlock: View {
    let labelLine1: String
    let labelLine2: String // Can be empty if only one line is needed
    let stats: FormattedStats
    let valueToAnimate: Double? // Use optional Double for animation value

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 8) {
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(stats.value)
                    .font(.system(size: 70, weight: .medium, design: .rounded))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
                    .animation(.snappy(duration: 0.1), value: valueToAnimate)
                Text(stats.unit)
                    .font(.system(size: 30, weight: .medium, design: .rounded))
                    .foregroundStyle(stats.colour)
            }

            VStack(alignment: .leading, spacing: -2) {
                Text(labelLine1)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                if !labelLine2.isEmpty {
                    Text(labelLine2)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 12)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(labelLine1) \(labelLine2): \(stats.value) \(stats.unit)")
    }
}

struct ElapsedTimeBlock: View {
    let stats: FormattedStats

    var body: some View {
        Text(stats.value)
            .font(.system(size: 48, weight: .medium, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(.primary)
            .contentTransition(.numericText())
    }
}

struct StatsOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        let mock = RideSessionManager(workoutType: .cycling)
        mock.averageSpeed = 25.6
        mock.averageCadence = nil // Test nil case
        mock.elevationGain = 120.0
        mock.totalDistance = 2570.0
        mock.activeCalories = 200
        return StatsOverlayView(rideSessionManager: mock)
            .previewLayout(.sizeThatFits)
    }
}
