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

    /// Roughly how many gridlines to aim for before widening the spacing.
    private static let targetMarkCount = 6.0

    /// The narrowest spacing that keeps the mark count near `targetMarkCount`,
    /// from one segment (5.12s) doubling to at most one section (81.92s).
    static func stride(forDuration duration: TimeInterval) -> TimeInterval {
        var spacing = MotionManager.SEGMENT_DURATION
        while spacing < MotionManager.SECTION_DURATION && duration / spacing > targetMarkCount {
            spacing *= 2
        }
        return min(spacing, MotionManager.SECTION_DURATION)
    }

    static func gridValues(forDuration duration: TimeInterval) -> [TimeInterval] {
        let spacing = stride(forDuration: duration)
        // A workout shorter than one segment still deserves an axis.
        return Array(Swift.stride(from: 0, through: max(duration, spacing), by: spacing))
    }
}
