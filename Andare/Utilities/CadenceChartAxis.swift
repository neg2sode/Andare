//
//  CadenceChartAxis.swift
//  Andare
//
//  Created by neg2sode on 2026/8/8.
//

import Foundation

/// Where the cadence chart draws its vertical gridlines.
///
/// Spacing is expressed in the app's own unit of measurement rather than round
/// clock time: one FFT segment, doubling up to one section. The 81.92s window
/// is what narrows bin width enough to resolve under 1 RPM — which is why a
/// second FFT runs over it at all — so a mark landing there is an analysis
/// boundary rather than an arbitrary tick.
enum CadenceChartAxis {

    /// Gridlines strictly between the start and the end of the workout.
    private static let maxIntermediateMarks = 4

    /// One FFT section is the narrowest spacing allowed — a workout shorter
    /// than that gets no intermediate line at all. Above it, readable clock
    /// intervals, since a section multiple like 12:17 is a boundary that means
    /// something to the analysis but nothing to the reader.
    private static let candidates: [TimeInterval] = [
        MotionManager.SECTION_DURATION,   // 81.92s
        120, 300, 600, 900, 1200, 1800, 2700, 3600, 5400, 7200
    ]

    /// Below ten minutes the zero-cadence markers read as individual stops;
    /// beyond it they merge into a solid band along the axis and say nothing.
    static let zeroMarkerMaxDuration: TimeInterval = 600

    static func stride(forDuration duration: TimeInterval) -> TimeInterval {
        if let fit = candidates.first(where: { intermediateMarkCount(stride: $0, duration: duration) <= maxIntermediateMarks }) {
            return fit
        }
        // Longer than the ladder covers: divide instead, rounded up to a whole
        // minute so the labels stay tidy.
        return (duration / Double(maxIntermediateMarks + 1) / 60).rounded(.up) * 60
    }

    /// How close to the end a mark may sit, as a fraction of the stride. A ride
    /// lasting almost exactly a whole number of strides would otherwise draw an
    /// unlabelled line flush against the right edge.
    private static let endMargin = 0.15

    static func gridValues(forDuration duration: TimeInterval) -> [TimeInterval] {
        guard duration > 0 else { return [0] }
        let spacing = stride(forDuration: duration)
        return Array(Swift.stride(from: 0, to: duration - spacing * endMargin, by: spacing))
    }

    static func showsZeroMarkers(forDuration duration: TimeInterval) -> Bool {
        duration <= zeroMarkerMaxDuration
    }

    private static func intermediateMarkCount(stride: TimeInterval, duration: TimeInterval) -> Int {
        max(Int((duration / stride).rounded(.up)) - 1, 0)
    }
}
