//
//  WorkoutData+Mapping.swift
//  Andare
//
//  Created by neg2sode on 2025/7/9.
//

import Foundation
import CoreLocation

// This extension provides the logic to convert our persistent database models
// back into the transient structs that our Views use.

extension WorkoutData {
    /// Creates a transient WorkoutData struct from a persistent WorkoutDataModel object.
    init(from model: WorkoutDataModel) {
        // Map the CadenceSegmentModels back to CadenceSegments
        let segments = model.cadenceSegments.map { CadenceSegment(from: $0) }
        
        self.init(
            workoutType: model.workoutType,
            startTime: model.startTime,
            endTime: model.endTime,
            cadenceSegments: segments,
            logMessages: model.logMessages,
            averageCadence: model.averageCadence,
            totalDistance: model.totalDistance,
            averageSpeed: model.averageSpeed,
            maxSpeed: model.maxSpeed,
            elevationGain: model.elevationGain,
            activeCalories: model.activeCalories,
            totalCalories: model.totalCalories,
            mapDisplayContext: MapDisplayContext(rawValue: model.mapDisplayContext) ?? .hidden
        )
    }
}

extension CadenceSegment {
    /// Creates a transient CadenceSegment from a persistent CadenceSegmentModel.
    init(from model: CadenceSegmentModel) {
        // Map the LocationPoints back to CLLocations
        let locations = model.locations.map { CLLocation(from: $0) }
        
        self.init(
            timestamp: model.timestamp,
            cadence: model.cadence,
            zone: model.zone,
            locations: locations,
            speed: model.speed,
            baroAltitude: model.baroAltitude,
            gpsAltitude: model.gpsAltitude,
            distance: model.distance
        )
    }
}

extension CLLocation {
    /// Creates a CLLocation from a storable LocationPoint struct.
    convenience init(from point: LocationPoint) {
        self.init(
            coordinate: CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude),
            altitude: point.altitude,
            horizontalAccuracy: point.horizontalAccuracy,
            verticalAccuracy: -1, // Not stored, use default
            course: -1,          // Not stored, use default
            speed: -1,           // Not stored, use default
            timestamp: point.timestamp
        )
    }
}
