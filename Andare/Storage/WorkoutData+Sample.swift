//
//  WorkoutData+Sample.swift
//  Andare
//
//  Created by neg2sode on 2026/8/8.
//

#if DEBUG
import Foundation
import CoreLocation

extension WorkoutData {
    /// A finished ride with a route and a full set of cadence segments.
    ///
    /// The simulator cannot produce gyroscope data, so a real workout there
    /// always ends with an empty chart and no map — which makes the summary
    /// screen's two most visual sections impossible to check. This stands in
    /// for one. Debug builds only; reachable via the `-showSampleSummary`
    /// launch argument.
    static func sample(minutes: Double = 6) -> WorkoutData {
        let seconds = minutes * 60
        let start = Date().addingTimeInterval(-seconds)
        var segments: [CadenceSegment] = []

        // One segment each, wandering across the cadence zones so every legend
        // entry has something to colour.
        let count = Int(seconds / MotionManager.SEGMENT_DURATION)
        for index in 0..<count {
            let progress = Double(index) / Double(count)
            let cadence: Double
            switch progress {
            case ..<0.15: cadence = 0                       // stopped at a light
            case ..<0.35: cadence = 58 + progress * 40      // warming up, low
            case ..<0.75: cadence = 78 + sin(progress * 18) * 6
            default: cadence = 104 + sin(progress * 24) * 8 // pushing, high
            }

            // Scaled by progress, not by index, so the route covers the same
            // ground whether the sample is six minutes or an hour.
            let latitude = 31.2304 + progress * 0.03
            let longitude = 121.4737 + sin(progress * 6) * 0.004

            segments.append(
                CadenceSegment(
                    timestamp: start.addingTimeInterval(Double(index) * MotionManager.SEGMENT_DURATION),
                    cadence: cadence,
                    zone: CadenceZone.zone(for: cadence, workoutType: .cycling),
                    locations: [CLLocation(latitude: latitude, longitude: longitude)],
                    speed: cadence > 0 ? 6.2 : 0,
                    baroAltitude: 12 + progress * 30,
                    gpsAltitude: 12 + progress * 30,
                    distance: cadence > 0 ? 31.7 : 0
                )
            )
        }

        let measured = segments.filter { $0.cadence > 0 }
        let average = measured.reduce(0) { $0 + $1.cadence } / Double(max(measured.count, 1))

        // Roughly consistent with 6.2 m/s over the moving portion, and with the
        // MET 8 cycling band at 70kg.
        let movingHours = Double(measured.count) * MotionManager.SEGMENT_DURATION / 3600
        let active = 7.0 * 70 * movingHours
        let basal = seconds / 3600 * 70

        return WorkoutData(
            workoutType: .cycling,
            startTime: start,
            endTime: Date(),
            cadenceSegments: segments,
            notificationIntents: [],
            logMessages: ["Sample workout for layout review."],
            averageCadence: average,
            totalDistance: Double(measured.count) * 31.7,
            averageSpeed: 6.2,
            maxSpeed: 9.4,
            elevationGain: 38,
            activeCalories: active,
            totalCalories: active + basal,
            mapDisplayContext: .full
        )
    }
}
#endif
