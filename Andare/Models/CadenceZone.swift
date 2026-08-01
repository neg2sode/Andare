//
//  CadenceZone.swift
//  Andare
//
//  Created by neg2sode on 2025/7/21.
//

import SwiftUI

enum CadenceZone: String, Codable {
    case low = "Low"
    case normal = "Normal"
    case high = "High"
    case zero = "Zero"

    /// User-facing name. The raw value is persisted (SwiftData) and must stay stable,
    /// so display copy lives here instead.
    var displayName: String {
        switch self {
        case .normal: return "Sound"
        default: return rawValue
        }
    }

    var color: Color {
        switch self {
        case .low: return .lowCadenceColour
        case .normal: return .cadenceColour
        case .high: return .highCadenceColour
        case .zero: return .gray
        }
    }

    // Helper to determine zone
    static func zone(for cadence: Double, workoutType: WorkoutType) -> CadenceZone {
        if cadence <= 0 {
            return .zero
        }
        if let cutoffs = workoutType.cadenceInfo.cutoffs {
            if cadence < cutoffs.low {
                return .low
            } else if cadence > cutoffs.high {
                return .high
            } else {
                return .normal
            }
        } else {
            return .normal
        }
    }
}
