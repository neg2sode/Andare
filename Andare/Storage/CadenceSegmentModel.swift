//
//  CadenceSegmentModel.swift
//  Andare
//
//  Created by neg2sode on 2025/7/8.
//

import Foundation
import SwiftData

@Model
final class CadenceSegmentModel {
    // All stored properties are now 'var' to satisfy the @Model macro.
    var timestamp: Date
    var cadence: Double
    var zone: CadenceZone
    var locations: [LocationPoint]
    var speed: Double?
    var baroAltitude: Double?
    var gpsAltitude: Double?
    var distance: Double?
    
    var workout: WorkoutDataModel?

    init(timestamp: Date, cadence: Double, zone: CadenceZone, locations: [LocationPoint], speed: Double?, baroAltitude: Double?, gpsAltitude: Double?, distance: Double?) {
        self.timestamp = timestamp
        self.cadence = cadence
        self.zone = zone
        self.locations = locations
        self.speed = speed
        self.baroAltitude = baroAltitude
        self.gpsAltitude = gpsAltitude
        self.distance = distance
    }
}
