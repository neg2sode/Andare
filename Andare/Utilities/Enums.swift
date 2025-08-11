//
//  Enums.swift
//  Andare
//
//  Created by neg2sode on 2025/7/21.
//

import Foundation
import CoreLocation

enum CadenceZone: String, Codable {
    case low = "Low"
    case normal = "Normal"
    case high = "High"
    case zero = "Zero"

    // Helper to determine zone
    static func zone(for cadence: Double, workoutType: WorkoutType) -> CadenceZone {
        if cadence <= 0 {
            return .zero
        }
        if let threshold = workoutType.getInfo().threshold {
            if cadence < threshold.low {
                return .low
            } else if cadence > threshold.high {
                return .high
            } else {
                return .normal
            }
        } else {
            return .normal
        }
    }
}

enum MovementActivity: String, Codable {
    case stationary = "Stationary"
    case slow = "Slow Speed"
    case fast = "Normal Speed"
    case notDetermined = "Not Determined"
    
    static func zone(for speed: Double) -> MovementActivity {
        let stationaryThreshold = 0.7 // m/s
        let slowThreshold = 2.2 // m/s
        
        if speed < stationaryThreshold {
            return .stationary
        } else if speed < slowThreshold {
            return .slow
        } else {
            return .fast
        }
    }
}

enum SpeedTrend: String, Codable {
    case stable = "Stable"
    case accelerating = "Accelerating"
    case decelerating = "Decelerating"
    case notDetermined = "Not Determined"
    
    static func zone(for speedDelta: Double) -> SpeedTrend {
        let speedChangeThreshold = 1.2 // m/s
        
        if speedDelta > speedChangeThreshold {
            return .accelerating
        } else if speedDelta < -speedChangeThreshold {
            return .decelerating
        } else {
            return .stable
        }
    }
}

enum TerrainGradient: String, Codable {
    case level = "Level"
    case ascending = "Ascending!!!"
    case descending = "Descending!!!"
    case notDetermined = "Not Determined"
    
    static func zone(for slopePercent: Double) -> TerrainGradient {
        let levelSlopeThreshold = 3.0 // %
        
        if slopePercent > levelSlopeThreshold {
            return .ascending
        } else if slopePercent < -levelSlopeThreshold {
            return .descending
        } else {
            return .level
        }
    }
}

// CaseIterable for creating a menu for all typess, Identifiable for displaying type on UI
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
    
    var sfSymbolName: String {
        switch self {
            case .cycling: "figure.outdoor.cycle"
            case .running: "figure.run"
            case .walking: "figure.walk"
        }
    }
    
    func getInfo() -> WorkoutCadenceInfo {
        switch(self) {
        case .cycling:
            return WorkoutCadenceInfo(range: (min: 20, max: 150), threshold: (low: 60, high: 110)) // RPM
        case .running:
            return WorkoutCadenceInfo(range: (min: 100, max: 240), threshold: (low: 160, high: 200))
        case .walking:
            return WorkoutCadenceInfo(range: (min: 60, max: 160), threshold: nil)
        }
    }
}

enum NotificationType: String, Codable {
    case lowCadenceAlert = "Low Cadence Alert"
    case highCadenceAlert = "High Cadence Alert"
    case pushingBike = "Consider Pushing Bike"
    case finishedWorkout = "Finished Workout?"
}

enum NotificationFrequency: String, Codable, CaseIterable {
    case normal = "Default"
    case high = "High"
}

enum DominantAxis: String, CaseIterable {
    case x = "X"
    case y = "Y"
    case z = "Z"
    case none = "None"
}

struct WorkoutCadenceInfo {
    let range: (min: Double, max: Double)
    let threshold: (low: Double, high: Double)?
}
