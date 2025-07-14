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
    let workoutType: WorkoutType
    let weight: Double
    let height: Double
    
    func calculate() -> (active: Double, total: Double) {
        guard self.isValid else { return (active: 0.0, total: 0.0) }

        let durationHours = self.duration / 3600.0 // Convert seconds to hours
        let met = self.metValue
        
        let activeCalories = met * self.weight * durationHours
        let basalCalories = self.weight * durationHours
        let totalCalories = activeCalories + basalCalories
        
        return (active: activeCalories, total: totalCalories)
    }
}

private extension CalorieCalculationInputs {
    var isValid: Bool {
        weight > 0 && duration > 0
    }
    
    var speedKph: Double {
        speed * 3.6
    }
    
    var metValue: Double {
        switch workoutType {
        case .cycling:
            switch speedKph {
            case ..<16.0: return 3.0
            case ..<24.0: return 7.0
            default: return 9.0
            }
        case .running:
            return 9.0
        case .walking:
            return 2.0
        }
    }
}
