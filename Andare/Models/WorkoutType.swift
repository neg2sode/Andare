//
//  WorkoutType.swift
//  Andare
//
//  Created by neg2sode on 2025/7/21.
//

import Foundation

// CaseIterable for creating a menu for all types, Identifiable for displaying type on UI
enum WorkoutType: String, CaseIterable, Identifiable, Codable {
    var id: String { self.rawValue }
    case cycling = "Cycling"
    case running = "Running"
    case walking = "Walking"

    var title: String {
        switch self {
            case .cycling: "Ride"
            case .running: "Run"
            case .walking: "Walk"
        }
    }

    var sfSymbol: String {
        switch self {
            case .cycling: "figure.outdoor.cycle"
            case .running: "figure.run"
            case .walking: "figure.walk"
        }
    }

    var cadenceInfo: WorkoutCadenceInfo {
        switch(self) {
        case .cycling:
            return WorkoutCadenceInfo(
                range: (min: 20, max: 150),
                cutoffs: (low: 60, high: 110),
                threshold: 2993.633414,
                unit: "RPM"
            )
        case .running:
            return WorkoutCadenceInfo(
                // Range bounds both the FFT peak-search band and chart scales.
                range: (min: 130, max: 210),
                cutoffs: (low: 160, high: 200),
                threshold: 1885.868061,
                unit: "SPM"
            )
        case .walking:
            return WorkoutCadenceInfo(
                range: (min: 60, max: 120),
                cutoffs: nil,
                threshold: 2842.008795,
                unit: "SPM"
            )
        }
    }
}

struct WorkoutCadenceInfo {
    let range: (min: Double, max: Double)
    let cutoffs: (low: Double, high: Double)?
    let threshold: Float
    let unit: String
}
