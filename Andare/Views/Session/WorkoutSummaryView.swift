//
//  WorkoutSummaryView.swift
//  Andare
//
//  Created by neg2sode on 2025/5/1.
//

import SwiftUI
import Charts
import MapKit
import UniformTypeIdentifiers // for pasteboard copying

// Helper View for Legend Items
struct LegendItem: View {
    let colour: Color
    let text: String
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(colour)
                .frame(width: 8, height: 8)
            Text(text)
                .font(.caption)
                .foregroundStyle(.gray)
        }
    }
}

struct WorkoutSummaryView: View {
    private let data: WorkoutData
    private let coordinates: [CLLocationCoordinate2D]
    private let routePolyline: MKPolyline?
    
    private var debugLogString: String {
        data.logMessages.joined(separator: "\n")
    }

    @State private var isDoneButtonVisible = false
    @State private var isShowingFullMap = false
    @State private var mapCameraPosition: MapCameraPosition
    
    @Environment(\.dismiss) var dismiss
    
    init(data: WorkoutData) {
        self.data = data
        
        let validCoordinates = data.cadenceSegments
            .filter { MovementActivity.zone(for: $0.speed ?? 0.0) != .stationary }
            .flatMap { $0.locations.map { $0.coordinate.adjustedForChina() } }
        self.coordinates = validCoordinates

        if !validCoordinates.isEmpty {
            let polyline = MKPolyline(coordinates: validCoordinates, count: validCoordinates.count)
            self.routePolyline = polyline

            // Calculate a bounding box and set camera position
            let mapRect = polyline.boundingMapRect
            // Add some padding to the mapRect
            let paddedRect = mapRect.insetBy(dx: -mapRect.size.width * 0.1, dy: -mapRect.size.height * 0.1)
            // Initialize @State with .rect
            self._mapCameraPosition = State(initialValue: .rect(paddedRect))
        } else {
            self.routePolyline = nil
            // Default camera position if no route data
            self._mapCameraPosition = State(initialValue: .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 31.2304, longitude: 121.4737), // Default: Shanghai
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            )))
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                scrollableContent
                floatingDoneButton
            }
            .navigationTitle(StatsFormatter.formatSummaryTitle(data.startTime, data.workoutType))
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $isShowingFullMap) {
            if let polyline = routePolyline,
               let start = coordinates.first,
               let end = coordinates.last {
                FullMapView(
                    initialMapCameraPosition: mapCameraPosition,
                    routePolyline: polyline,
                    start: start,
                    end: end,
                    formattedTitle: StatsFormatter.formatSummaryTitle(data.startTime, data.workoutType)
                )
            }
        }
    }
    
    private var scrollableContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                summaryStatsSectionGrid
                chartSection
                mapSection
                debugLogSection
            }
            .padding()
            .padding(.bottom, 80)
        }
        // detect upward drag to show Done button
        .simultaneousGesture(
          DragGesture(minimumDistance: 5, coordinateSpace: .local)
            .onChanged { value in
              // negative y-translation = drag *up*
              if value.translation.height < -10 {
                withAnimation(.easeInOut) {
                  isDoneButtonVisible = true
                }
              }
            }
        )
    }
    
    private var floatingDoneButton: some View {
        VStack {
            Spacer()
            if isDoneButtonVisible {
                Button(action: { dismiss() }) {
                    Text("Done")
                        .font(.headline).fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 30)
                .padding(.bottom)
                .shadow(radius: 5)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
    
    // MARK: - Extracted View Sections
    
    // Updated Summary Stats using a Grid for better layout
    private var summaryStatsSectionGrid: some View {
        VStack(alignment: .leading, spacing: 15) { // Overall container for title + grid
            Text("Workout Summary") // Title for the section as seen in the image
                .font(.title2)
                .fontWeight(.bold)

            Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 12) { // Spacing for grid cells
                GridRow {
                    statsView(label: "Duration", stats: StatsFormatter.formatDuration(data.duration))
                    statsView(label: "Avg. Cadence", stats: StatsFormatter.formatCadence(data.averageCadence))
                }
                Divider()
                GridRow {
                    statsView(label: "Distance", stats: StatsFormatter.formatDistance(data.totalDistance))
                    statsView(label: "Elevation Gain", stats: StatsFormatter.formatElevation(data.elevationGain))
                }
                Divider()
                GridRow {
                    statsView(label: "Avg. Speed", stats: StatsFormatter.formatSpeed(data.averageSpeed))
                    statsView(label: "Max Speed", stats: StatsFormatter.formatSpeed(data.maxSpeed))
                }
                Divider()
                GridRow {
                    statsView(label: "Active Kilocalories", stats: StatsFormatter.formatEnergyBurned(data.activeCalories))
                    statsView(label: "Total Kilocalories", stats: StatsFormatter.formatEnergyBurned(data.totalCalories))
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            )
        }
        .padding(.bottom) // Original padding for the whole section
    }
    
    // Helper for individual stat display
    private func statsView(label: String, stats: FormattedStats) -> some View {
        VStack(alignment: .leading) {
            Text(label)
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(.primary)
            HStack(alignment: .lastTextBaseline, spacing: 0) {
                Text(stats.value)
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(stats.colour) // Apply specific color to the value
                    .lineLimit(1) // Ensure the value stays on one line
                    .minimumScaleFactor(0.7) // Allow text to shrink if it's too long to fit
                Text(stats.unit)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(stats.colour)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading) // Ensure each statView takes up available column width
    }
    
    // 2. Chart Section
    private var chartSection: some View {
        VStack(alignment: .leading) {
            Text("Cadence Over Time")
                .font(.title2)
                .fontWeight(.bold)

            if data.cadenceSegments.isEmpty {
                Text("No cadence data recorded.")
                    .foregroundStyle(.secondary)
                    .padding(.top, 5)
            } else {
                Chart {
                    ForEach(data.cadenceSegments) { segment in
                        chartMark(for: segment)
                    }
                    averageCadenceRuleMark
                }
                // Apply modifiers directly here:
                .chartForegroundStyleScale([
                    CadenceZone.low.rawValue: Color.lowCadenceColour,
                    CadenceZone.normal.rawValue: Color.cadenceColour,
                    CadenceZone.high.rawValue: Color.highCadenceColour
                ])
                .chartLegend(position: .bottom, alignment: .center) {
                    HStack {
                        LegendItem(colour: Color.lowCadenceColour, text: CadenceZone.low.rawValue)
                        LegendItem(colour: Color.cadenceColour, text: CadenceZone.normal.rawValue)
                        LegendItem(colour: Color.highCadenceColour, text: CadenceZone.high.rawValue)
                        LegendItem(colour: Color.gray, text: CadenceZone.zero.rawValue)
                    }
                    .padding(.top, 5)
                 }
                .chartYScale(domain: 0...max(120, (data.cadenceSegments.map{$0.cadence}.max() ?? 0) + 20))
                .chartXAxis {
                    AxisMarks(preset: .automatic, values: .automatic(desiredCount: 5)) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel {
                            if let time = value.as(TimeInterval.self) {
                                let minutes = Int(time) / 60
                                let seconds = Int(time) % 60
                                Text("\(minutes):\(String(format: "%02d", seconds))")
                                    .font(.caption)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(preset: .automatic, values: .automatic(desiredCount: 5)) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel()
                    }
                }
                .frame(height: 250)
                .padding(.top, 5)
            }
        }
    }
    
    private var mapSection: some View {
        VStack(alignment: .leading) {
            switch data.mapDisplayContext {
            case .full:
                HStack {
                    Text("Route Map")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                if let polyline = self.routePolyline,
                   let startCoord = self.coordinates.first,
                   let endCoord = self.coordinates.last {
                    Map(initialPosition: mapCameraPosition, interactionModes: []) {
                        Self.routeMapContent(polyline: polyline, start: startCoord, end: endCoord)
                    }
                    .mapControlVisibility(.hidden) // Keep inline map clean
                    .frame(height: 200)
                    .cornerRadius(10)
                    .padding(.top, 5)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isShowingFullMap = true
                    }
                } else {
                    Text("No route data recorded.")
                        .foregroundStyle(.secondary)
                        .padding(.top, 5)
                }
            
            case .prompt:
                HStack {
                    Text("Route Map")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                // Message for reduced accuracy (existing code)
                Text("Route map is not available because Precise Location is turned off for Andare. You can enable it in Settings > Privacy & Security > Location Services > Andare.")
                    .font(.footnote)
                    .foregroundStyle(.orange)
                    .padding(.vertical, 10)
                    .padding(.horizontal)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.top, 5)
            
            case .hidden:
                EmptyView()
            }
        }
    }
    
    private var debugLogSection: some View {
        DisclosureGroup("Debug Logs (\(data.logMessages.count))") {
            ScrollView(.vertical, showsIndicators: true) {
               VStack(alignment: .leading, spacing: 2) {
                   ForEach(data.logMessages, id: \.self) { message in
                       Text(message)
                           .font(.system(size: 10, design: .monospaced))
                           .padding(.leading, 5)
                   }
               }
               .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 200)
            .background(Color(.systemGray6))
            .cornerRadius(5)
            .padding(.top, 5)
        }
        .contextMenu {
            if data.logMessages.isEmpty {
                // If there are no logs, show a disabled item as feedback.
                Label("No Logs Available", systemImage: "xmark.circle")
                    .disabled(true)
            } else {
                Button(action: copyDebugLogs) {
                    Label("Copy Logs", systemImage: "document.on.clipboard")
                }
                
                Button(action: sendDebugMail) {
                    Label("Send Logs", systemImage: "paperplane.fill")
                }
            }
        }
    }
    
    private func sendDebugMail() {
        let subject = "Andare Workout Debug Log - \(data.startTime.formatted())"
        let body = diagnosticMetadataHeader + "\n" + debugLogString
        
        MailUtilities.send(subject: subject, body: body)
    }
    
    private func copyDebugLogs() {
        UIPasteboard.general.string = debugLogString
        VibrationManager.shared.playPatternA()
    }
    
    private var diagnosticMetadataHeader: String {
        // --- App Info ---
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "N/A"
        let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "N/A"
        
        // --- Device Info ---
        let device = UIDevice.current
        let osVersion = "\(device.systemName) \(device.systemVersion)"
        
        // Get device model identifier (e.g., "iPhone17,3")
        var systemInfo = utsname()
        uname(&systemInfo)
        let model = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                ptr in String(cString: ptr)
            }
        }
        
        // --- Locale Info ---
        let languageCode = Locale.current.language.languageCode?.identifier ?? "N/A"
        let regionCode = Locale.current.region?.identifier ?? "N/A"
        
        // --- Workout Info ---
        let workoutID = data.id.uuidString
        
        // Assemble the report
        let report = """
        --- Device Report ---
        Workout ID: \(workoutID)
        
        App Version: \(appVersion)
        Build Number: \(buildNumber)
        
        Device Model: \(model)
        OS Version: \(osVersion)
        
        Language: \(languageCode)
        Region: \(regionCode)
        ---------------------
        """
        
        return report
    }
    
    @MapContentBuilder
    static func routeMapContent(polyline: MKPolyline, start: CLLocationCoordinate2D, end: CLLocationCoordinate2D) -> some MapContent {
        MapPolyline(polyline)
            .stroke(Color.pathColour, lineWidth: 5)
        
        Annotation("Start", coordinate: start, anchor: .center) {
            Circle()
                .fill(Color.green)
                .frame(width: 12, height: 16)
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
        }
        Annotation("End", coordinate: end, anchor: .center) {
            Circle()
                .fill(Color.red)
                .frame(width: 12, height: 16)
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
        }
    }
    
    // --- Helper for Chart Marks ---
    // Use @ViewBuilder to allow returning different Mark types
    @ChartContentBuilder
    private func chartMark(for segment: CadenceSegment) -> some ChartContent {
        let timeOffset = segment.timestamp.timeIntervalSince(data.startTime)
        // Use the pre-calculated timeOffset from the wrapper
        let xValue: PlottableValue = .value("Time", timeOffset)

        if segment.zone != .zero {
            BarMark(
                x: xValue,
                yStart: .value("Cadence Min", 0),
                yEnd: .value("Cadence Max", segment.cadence),
                width: .fixed(3)
            )
            .foregroundStyle(by: .value("Zone", segment.zone.rawValue))
            .cornerRadius(2)
        } else {
            PointMark(
                x: xValue,
                y: .value("Cadence", 1)
            )
            .foregroundStyle(Color.gray)
            .symbolSize(20)
        }
    }
    
    // --- Helper for Average RuleMark ---
    private var averageCadenceRuleMark: some ChartContent {
        RuleMark(y: .value("Average", data.averageCadence))
             .foregroundStyle(.gray)
             .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
             .annotation(position: .top, alignment: .trailing) {
                 Text("Avg.: \(Int(data.averageCadence))")
                     .font(.caption)
                     .foregroundStyle(.gray)
                     .padding(.trailing, 4)
             }
    }
}
