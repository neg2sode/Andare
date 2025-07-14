//
//  WorkoutDataModel.swift
//  Andare
//
//  Created by neg2sode on 2025/7/8.
//

import Foundation
import SwiftData
import CoreLocation

@Model
final class WorkoutDataModel {
    // All stored properties changed from 'let' to 'var'.
    @Attribute(.unique)
    var id: UUID
    
    var managementState: WorkoutManagementState.RawValue
    
    var mapDisplayContext: MapDisplayContext.RawValue
    
    var workoutType: WorkoutType
    var startTime: Date
    var endTime: Date
    
    var averageCadence: Double
    var totalDistance: Double
    var averageSpeed: Double
    var maxSpeed: Double
    var elevationGain: Double
    var activeCalories: Double
    var totalCalories: Double
    
    private var logMessagesData: Data
    
    @Relationship(deleteRule: .cascade, inverse: \CadenceSegmentModel.workout)
    var cadenceSegments: [CadenceSegmentModel]
    
    var logMessages: [String] {
        get {
            (try? JSONDecoder().decode([String].self, from: logMessagesData)) ?? []
        }
        set {
            logMessagesData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }
    
    // The designated initializer now sets 'var' properties. Its structure is unchanged.
    init(id: UUID, managementState: WorkoutManagementState, mapDisplayContext: MapDisplayContext, workoutType: WorkoutType, startTime: Date, endTime: Date, logMessages: [String], averageCadence: Double, totalDistance: Double, averageSpeed: Double, maxSpeed: Double, elevationGain: Double, activeCalories: Double, totalCalories: Double, cadenceSegments: [CadenceSegmentModel]) {
        self.id = id
        self.managementState = managementState.rawValue
        self.mapDisplayContext = mapDisplayContext.rawValue
        self.workoutType = workoutType
        self.startTime = startTime
        self.endTime = endTime
        self.logMessagesData = (try? JSONEncoder().encode(logMessages)) ?? Data()
        self.averageCadence = averageCadence
        self.totalDistance = totalDistance
        self.averageSpeed = averageSpeed
        self.maxSpeed = maxSpeed
        self.elevationGain = elevationGain
        self.activeCalories = activeCalories
        self.totalCalories = totalCalories
        self.cadenceSegments = cadenceSegments
    }
    
    // MARK: - Computed Properties (No changes needed here)
    
    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
    
    var locationAccuracy: CLAccuracyAuthorization {
        mapDisplayContext == MapDisplayContext.full.rawValue ? .fullAccuracy : .reducedAccuracy
    }
    
    // MARK: - Intent (No changes needed here)
    
    func updateManagementState(to newState: WorkoutManagementState) {
        self.managementState = newState.rawValue
    }
}

// MARK: - Convenience Initializer

extension WorkoutDataModel {
    convenience init(from data: WorkoutData) {
        // ... this implementation remains exactly the same as before.
        let segmentModels = data.cadenceSegments.map { segment -> CadenceSegmentModel in
            let locationPoints = segment.locations.map { location in
                LocationPoint(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude, altitude: location.altitude, horizontalAccuracy: location.horizontalAccuracy, timestamp: location.timestamp)
            }
            return CadenceSegmentModel(timestamp: segment.timestamp, cadence: segment.cadence, zone: segment.zone, locations: locationPoints, speed: segment.speed, baroAltitude: segment.baroAltitude, gpsAltitude: segment.gpsAltitude, distance: segment.distance)
        }
        
        self.init(
            id: data.id,
            managementState: .visible,
            mapDisplayContext: data.mapDisplayContext == .full ? .full : .hidden,
            workoutType: data.workoutType,
            startTime: data.startTime,
            endTime: data.endTime,
            logMessages: data.logMessages,
            averageCadence: data.averageCadence,
            totalDistance: data.totalDistance,
            averageSpeed: data.averageSpeed,
            maxSpeed: data.maxSpeed,
            elevationGain: data.elevationGain,
            activeCalories: data.activeCalories,
            totalCalories: data.totalCalories,
            cadenceSegments: segmentModels
        )
    }
}
