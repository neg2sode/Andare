//
//  WorkoutDataModel+Support.swift
//  Andare
//
//  Created by neg2sode on 2025/7/8.
//

import Foundation
import CoreLocation

enum WorkoutManagementState: Int, Codable {
    case visible = 0
    case hidden = 1
    case excluded = 2
}

enum MapDisplayContext: Int, Codable {
    case full = 0
    case prompt = 1
    case hidden = 2
}

struct LocationPoint: Codable, Hashable {
    let latitude: CLLocationDegrees
    let longitude: CLLocationDegrees
    let altitude: CLLocationDistance
    let horizontalAccuracy: CLLocationAccuracy
    let timestamp: Date
}
