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

enum ResolvedUnitSystem {
    case metric, imperial
}

@MainActor
class StatsFormatter: ObservableObject {
    static let shared = StatsFormatter()
    
    @AppStorage("unitSystemPreference") private var unitSystem: UnitSystem = .systemDefault
    
    // Constants for conversion
    private let metersToMiles = 0.000621371
    private let metersToFeet = 3.28084
    private let kgToLbs = 2.20462
    
    private func resolveUnitSystem() -> ResolvedUnitSystem {
        switch unitSystem {
        case .systemDefault:
            // For US, use imperial. For UK and all others, use metric.
            // iOS `measurementSystem` handles this logic.
            return Locale.current.measurementSystem == .us ? .imperial : .metric
        case .metric:
            return .metric
        case .us:
            return .imperial
        }
    }
    
    func formatDuration(_ duration: TimeInterval) -> FormattedStats {
        let totalSeconds = Int(duration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        let formattedString = "\(hours):" + String(format: "%02d:%02d", minutes, seconds)
        return FormattedStats(value: formattedString, unit: "", colour: Color.durationColour)
    }

    func formatDistance(_ distanceInMeters: Double) -> FormattedStats {
        let system = resolveUnitSystem()
        
        if system == .metric {
            if distanceInMeters < 1000.0 {
                let value = NumberFormatter.integerFormatter.string(from: NSNumber(value: distanceInMeters)) ?? "0"
                return FormattedStats(value: value, unit: "M", colour: .distanceColour)
            } else {
                let distanceInKm = distanceInMeters / 1000.0
                let value = NumberFormatter.twoDecimalFormatter.string(from: NSNumber(value: distanceInKm)) ?? "0.00"
                return FormattedStats(value: value, unit: "KM", colour: .distanceColour)
            }
        } else { // Imperial
            let distanceInMiles = distanceInMeters * metersToMiles
            let value = NumberFormatter.twoDecimalFormatter.string(from: NSNumber(value: distanceInMiles)) ?? "0.00"
            return FormattedStats(value: value, unit: "MI", colour: .distanceColour)
        }
    }
    
    func formatSpeed(_ speedInMps: Double?) -> FormattedStats {
        guard let speed = speedInMps else {
            let unit = resolveUnitSystem() == .metric ? "KM/H" : "MPH"
            return FormattedStats(value: "--", unit: unit, colour: .speedColour)
        }
        
        let system = resolveUnitSystem()
        if system == .metric {
            let speedInKmh = speed * 3.6
            let value = NumberFormatter.decimalFormatter.string(from: NSNumber(value: speedInKmh)) ?? "0.0"
            return FormattedStats(value: value, unit: "KM/H", colour: .speedColour)
        } else { // Imperial
            let speedInMph = speed * 2.23694
            let value = NumberFormatter.decimalFormatter.string(from: NSNumber(value: speedInMph)) ?? "0.0"
            return FormattedStats(value: value, unit: "MPH", colour: .speedColour)
        }
    }

    func formatElevation(_ elevationInMeters: Double) -> FormattedStats {
        let system = resolveUnitSystem()
        if system == .metric {
            let value = NumberFormatter.integerFormatter.string(from: NSNumber(value: elevationInMeters)) ?? "0"
            return FormattedStats(value: value, unit: "M", colour: .elevationColour)
        } else { // Imperial
            let elevationInFeet = elevationInMeters * metersToFeet
            let value = NumberFormatter.integerFormatter.string(from: NSNumber(value: elevationInFeet)) ?? "0"
            return FormattedStats(value: value, unit: "FT", colour: .elevationColour)
        }
    }

    func formatEnergyBurned(_ energyBurned: Double) -> FormattedStats { // In kcals
        let value = NumberFormatter.integerFormatter.string(from: NSNumber(value: energyBurned)) ?? "0"
        return FormattedStats(value: value, unit: "KCAL", colour: Color.calorieColour)
    }

    // Formatter for optional cadence, used by StatsOverlayView
    func formatCadence(_ cadence: Double?, _ workoutType: WorkoutType) -> FormattedStats {
        guard let validCadence = cadence else {
            let unit = workoutType == .cycling ? "RPM" : "SPM"
            return FormattedStats(value: "--", unit: unit, colour: Color.cadenceColour)
        }
        
        let value = NumberFormatter.integerFormatter.string(from: NSNumber(value: validCadence)) ?? "0"
        let unit = workoutType == .cycling ? "RPM" : "SPM"
        return FormattedStats(value: value, unit: unit, colour: Color.cadenceColour)
    }
    
    // helper for formatting dates, can be used by any view
    func formatSummaryTitle(_ date: Date, _ type: WorkoutType) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E d MMM"
        let dateString = formatter.string(from: date)
        let typeString = type.rawValue
        return dateString + " " + typeString
    }
}
