//
//  CadenceSegment.swift
//  Andare
//
//  Created by neg2sode on 2025/5/10.
//

import Foundation
import CoreLocation

struct CadenceSegment: Identifiable, Equatable {
    let id = UUID()
    let timestamp: Date // End timestamp of this segment

    let cadence: Double
    var zone: CadenceZone
    
    let locations: [CLLocation] // relevant locations of this segment
    let speed: Double?
    let baroAltitude: Double?
    let gpsAltitude: Double?
    let distance: Double?
}
