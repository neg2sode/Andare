//
//  WorkoutStatus.swift
//  Andare
//
//  Created by neg2sode on 2025/7/21.
//

import Foundation

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
