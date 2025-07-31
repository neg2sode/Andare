//
//  StatsFormatter.swift
//  Andare
//
//  Created by neg2sode on 2025/6/2.
//

import Foundation
import SwiftUI

struct FormattedStats: Identifiable {
    let id = UUID()
    let value: String
    let unit: String
    let colour: Color
    
    var plain: String {
        return value + unit
    }
}

struct StatsFormatter {
    static func formatDuration(_ duration: TimeInterval) -> FormattedStats {
        let totalSeconds = Int(duration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        let formattedString = "\(hours):" + String(format: "%02d:%02d", minutes, seconds)
        return FormattedStats(value: formattedString, unit: "", colour: Color.durationColour)
    }

    static func formatDistance(_ distanceInMeters: Double) -> FormattedStats {
        if distanceInMeters < 1000.0 {
            let value = NumberFormatter.integerFormatter.string(from: NSNumber(value: distanceInMeters)) ?? "0"
            return FormattedStats(value: value, unit: "M", colour: Color.distanceColour)
        } else {
            let distanceInKm = distanceInMeters / 1000.0
            let value = NumberFormatter.twoDecimalFormatter.string(from: NSNumber(value: distanceInKm)) ?? "0.00"
            return FormattedStats(value: value, unit: "KM", colour: Color.distanceColour)
        }
    }
    
    // Formatter for optional speed, used by StatsOverlayView
    static func formatSpeed(_ speed: Double?) -> FormattedStats {
        guard let validSpeed = speed else {
            return FormattedStats(value: "--", unit: "KM/H", colour: Color.speedColour)
        }
        return formatSpeed(validSpeed) // Call non-optional version
    }

    // Formatter for non-optional speed, used by RideSummaryView
    static func formatSpeed(_ speed: Double) -> FormattedStats { // In m/s
        let speedInKmh = speed * 3.6
        let value = NumberFormatter.decimalFormatter.string(from: NSNumber(value: speedInKmh)) ?? "0.0"
        return FormattedStats(value: value, unit: "KM/H", colour: Color.speedColour)
    }

    static func formatElevation(_ elevation: Double) -> FormattedStats { // In meters
        let value = NumberFormatter.integerFormatter.string(from: NSNumber(value: elevation)) ?? "0"
        return FormattedStats(value: value, unit: "M", colour: Color.elevationColour)
    }

    static func formatEnergyBurned(_ energyBurned: Double) -> FormattedStats { // In kcals
        let value = NumberFormatter.integerFormatter.string(from: NSNumber(value: energyBurned)) ?? "0"
        return FormattedStats(value: value, unit: "KCAL", colour: Color.calorieColour)
    }

    // Formatter for optional cadence, used by StatsOverlayView
    static func formatCadence(_ cadence: Double?, _ workoutType: WorkoutType) -> FormattedStats {
        guard let validCadence = cadence else {
            let unit = workoutType == .cycling ? "RPM" : "SPM"
            return FormattedStats(value: "--", unit: unit, colour: Color.cadenceColour)
        }
        return formatCadence(validCadence, workoutType) // Call non-optional version
    }
    
    // Formatter for non-optional cadence, used by RideSummaryView
    static func formatCadence(_ cadence: Double, _ workoutType: WorkoutType) -> FormattedStats {
        let value = NumberFormatter.integerFormatter.string(from: NSNumber(value: cadence.rounded())) ?? "0"
        let unit = workoutType == .cycling ? "RPM" : "SPM"
        return FormattedStats(value: value, unit: unit, colour: Color.cadenceColour)
    }
    
    // helper for formatting dates, can be used by any view
    static func formatSummaryTitle(_ date: Date, _ type: WorkoutType) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E d MMM"
        let dateString = formatter.string(from: date)
        let typeString = type.rawValue
        return dateString + " " + typeString
    }
}
