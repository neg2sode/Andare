//
//  StatsOverlayView.swift
//  Andare
//
//  Created by neg2sode on 2025/5/26.
//

import SwiftUI
import Charts
import Combine

struct StatsOverlayView: View {
    @ObservedObject var rideSessionManager: RideSessionManager
    @StateObject private var formatter = StatsFormatter.shared
    
    @State private var isExpanded: Bool = false
    private let slideOffset: CGFloat = 420
    
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    init(rideSessionManager: RideSessionManager) {
        self.rideSessionManager = rideSessionManager
    }
    
    // MARK: - Gesture
    
    private var panelSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 5, coordinateSpace: .local)
            .onEnded { value in
                handleSwipe(translation: value.translation.height)
            }
    }
    
    private func handleSwipe(translation: CGFloat) {
        let threshold: CGFloat = 10
        
        // Swipe down (positive translation) when collapsed -> expand
        // Swipe up (negative translation) when expanded -> collapse
        let shouldToggle = (!isExpanded && translation > threshold) || 
                          (isExpanded && translation < -threshold)
        
        if shouldToggle {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
                isExpanded.toggle()
            }
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        if verticalSizeClass == .regular {
            ZStack(alignment: .top) {
                analysisPanel
                    .offset(y: isExpanded ? 0 : -slideOffset)
                
                portraitLayout
                    .offset(y: isExpanded ? slideOffset : 0)
            }
            .clipped()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .simultaneousGesture(panelSwipeGesture)
        } else {
            landscapeLayout
        }
    }
    
    var portraitLayout: some View {
        VStack(alignment: .leading, spacing: 24) {
            timerAndControlRow
                .padding(.bottom, 8)
            
            // Average Cadence
            OverlayStatsBlock(
                labelLine1: "AVERAGE",
                labelLine2: "CADENCE",
                stats: formatter.formatCadence(rideSessionManager.averageCadence, rideSessionManager.workoutType),
                valueToAnimate: rideSessionManager.averageCadence
            )
            
            // Average Speed
            OverlayStatsBlock(
                labelLine1: "AVERAGE",
                labelLine2: "SPEED",
                stats: formatter.formatSpeed(rideSessionManager.averageSpeed),
                valueToAnimate: rideSessionManager.averageSpeed
            )
            
            // Active Calories
            OverlayStatsBlock(
                labelLine1: "ACTIVE",
                labelLine2: "KILOCALORIES",
                stats: formatter.formatEnergyBurned(rideSessionManager.activeCalories),
                valueToAnimate: rideSessionManager.activeCalories
            )
            
            // Elevation Gained
            OverlayStatsBlock(
                labelLine1: "ELEVATION",
                labelLine2: "GAIN",
                stats: formatter.formatElevation(rideSessionManager.elevationGain),
                valueToAnimate: rideSessionManager.elevationGain
            )
            
            // Total Distance
            OverlayStatsBlock(
                labelLine1: "DISTANCE",
                labelLine2: "",
                stats: formatter.formatDistance(rideSessionManager.totalDistance),
                valueToAnimate: rideSessionManager.totalDistance
            )
        }
        .padding(.horizontal, 30)
    }
    
    private var timerAndControlRow: some View {
        HStack(alignment: .center) {
            Image(systemName: rideSessionManager.workoutType.sfSymbolName)
                .font(.system(size: 54))
                .symbolVariant(.circle.fill)
                .foregroundStyle(.accent)
                .symbolRenderingMode(.hierarchical)

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
            
            Button(action: {
                withAnimation(.spring()) {
                    isExpanded.toggle()
                }
            }) {
                Image(systemName: "chevron.down.circle.fill")
                    .font(.system(size: 54))
                    .foregroundStyle(.accent)
                    .symbolRenderingMode(.hierarchical)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }
        }
    }
    
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
                
                OverlayStatsBlock(labelLine1: "AVERAGE", labelLine2: "CADENCE", stats: formatter.formatCadence(rideSessionManager.averageCadence, rideSessionManager.workoutType), valueToAnimate: rideSessionManager.averageCadence)
                OverlayStatsBlock(labelLine1: "AVERAGE", labelLine2: "SPEED", stats: formatter.formatSpeed(rideSessionManager.averageSpeed), valueToAnimate: rideSessionManager.averageSpeed)
            }
            
            // Second Column
            VStack(alignment: .leading, spacing: 8) {
                OverlayStatsBlock(labelLine1: "ACTIVE", labelLine2: "KILOCALORIES", stats: formatter.formatEnergyBurned(rideSessionManager.activeCalories), valueToAnimate: rideSessionManager.activeCalories)
                OverlayStatsBlock(labelLine1: "ELEVATION", labelLine2: "GAIN", stats: formatter.formatElevation(rideSessionManager.elevationGain), valueToAnimate: rideSessionManager.elevationGain)
                OverlayStatsBlock(labelLine1: "DISTANCE", labelLine2: "", stats: formatter.formatDistance(rideSessionManager.totalDistance), valueToAnimate: rideSessionManager.totalDistance)
            }
        }
        .frame(maxWidth: .infinity) // Allow the HStack to center itself
    }
    
    private var analysisPanel: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Cadence Analysis")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                let axis = rideSessionManager.dominantAxis
                if axis != .none {
                    Text("Dominant Axis: \(axis.rawValue.uppercased())")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Not a Rotation")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            ZStack {
                if let startTime = rideSessionManager.sensorData.first?.timestamp {
                    VStack(alignment: .leading) {
                        Text("Power Spectrum")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        
                        powerSpectrumChart

                        Text("Sensor Time Series")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        
                        timeSeriesChart(startTime)
                    }
                } else {
                    VStack {
                        Spacer()
                        Text("No Analysis Yet")
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                }
            }
        }
        .padding(.horizontal, 30)
        .padding(.bottom, 30)
        .frame(height: slideOffset)
    }
    
    private var powerSpectrumChart: some View {
        let cadenceRange = rideSessionManager.workoutType.getInfo().range
        let peakFrequency = rideSessionManager.powerSpectrum.max(by: { $0.power < $1.power })?.frequency
        
        return Chart {
            ForEach(rideSessionManager.powerSpectrum) { point in
                BarMark(
                    x: .value("Frequency (Hz)", point.frequency),
                    y: .value("Power", point.power)
                )
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.blue]),
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .cornerRadius(3)
            }
            
            if rideSessionManager.dominantAxis != .none {
                if let peakFrequency {
                    RuleMark(x: .value("Peak", peakFrequency))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                        .foregroundStyle(Color.cadenceColour)
                        .annotation(position: .top, alignment: .center) {
                            Text("Peak")
                                .font(.caption2.bold())
                                .padding(6)
                                .background(Color(.systemBackground))
                                .cornerRadius(6)
                                .foregroundStyle(Color.accentColor)
                        }
                }
            } else {
                let threshold = rideSessionManager.workoutType.getInfo().threshold
                RuleMark(y: .value("Threshold", threshold))
                     .foregroundStyle(.gray)
                     .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                     .annotation(position: .top, alignment: .trailing) {
                         Text("Treshold")
                             .font(.caption2.bold())
                             .padding(3)
                             .foregroundStyle(.gray)
                     }
            }
        }
        .chartXScale(domain: 0...(cadenceRange.max / 60))
        .chartXAxisLabel("Frequency (Hz)")
        .chartYAxis(.hidden)
    }
    
    private func timeSeriesChart(_ startTime: TimeInterval) -> some View {
        return Chart {
            ForEach(rideSessionManager.sensorData) { point in
                LineMark(
                    x: .value("Time", point.timestamp - startTime),
                    y: .value("Sensor", point.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.green.opacity(0.7), Color.green]),
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .interpolationMethod(.cardinal)
            }
        }
        .chartXScale(domain: 0...MotionManager.SEGMENT_DURATION)
        .chartXAxisLabel("Time (s)")
        .chartYAxis(.hidden)
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
