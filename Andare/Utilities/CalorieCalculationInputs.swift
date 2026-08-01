//
//  CalorieCalculationInputs.swift
//  Andare
//
//  Created by neg2sode on 2025/5/26.
//

import Foundation

struct CalorieCalculationInputs {
    let duration: TimeInterval // seconds
    let distance: Double // meters
    let speed: Double // m/s
    let cadence: Double
    let workoutType: WorkoutType
    let weight: Double
    let height: Double
    
    func calculate() -> (active: Double, total: Double) {
        let durationHours = duration / 3600.0 // Convert seconds to hours
        let basalCalories = weight * durationHours
        
        guard self.isValid else { return (active: 0.0, total: basalCalories) }
        
        let activeCalories = metValue * weight * durationHours
        let totalCalories = activeCalories + basalCalories
        
        return (active: activeCalories, total: totalCalories)
    }
}

private extension CalorieCalculationInputs {
    var isValid: Bool {
        weight > 0 && duration > 0 && cadence > 0 && MovementActivity.zone(for: speed) != .stationary
    }
    
    var speedKph: Double {
        speed * 3.6
    }
    
    var speedMph: Double {
        speed * 2.23694
    }
    
    var metValue: Double {
        switch workoutType {
        case .cycling:
            if speedMph < 10 {
                return 4.0 // Leisurely pace
            } else if speedMph < 12 {
                return 6.8 // Moderate
            } else if speedMph < 14 {
                return 8.0 // Vigorous
            } else if speedMph < 16 {
                return 10.0 // Racing
            } else if speedMph < 20 {
                return 12.0
            } else {
                return 15.8 // Very fast
            }
            
        case .running:
            let speedMph = speed * 2.23694
            if speedMph < 5 {
                return 6.0 // Jogging
            } else if speedMph < 6 {
                return 8.3
            } else if speedMph < 7 {
                return 9.8
            } else if speedMph < 8 {
                return 11.0
            } else if speedMph < 9 {
                return 12.8
            } else {
                return 14.5 // Elite pace
            }

        case .walking:
            var baseMet: Double
            
            if speedMph < 2.0 {
                baseMet = 2.0 // Strolling
            } else if speedMph < 3.0 {
                baseMet = 3.0 // Walking, 3.0 mph
            } else if speedMph < 3.5 {
                baseMet = 3.8 // Walking, 3.5 mph
            } else if speedMph < 4.0 {
                baseMet = 5.0 // Walking, 4.0 mph
            } else {
                baseMet = 6.3 // Very brisk walk
            }
            
            if cadence > 120 {
                baseMet += 0.5
            }
            
            return baseMet
        }
    }
}
