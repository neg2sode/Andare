//
//  RideSessionManager.swift
//  Andare
//
//  Created by neg2sode on 2025/4/29.
//

import Foundation
import HealthKit
import CoreLocation
import Combine
import SwiftUI
import ActivityKit
import SwiftData

struct CadenceSegmentComputationResult {
    let segment: CadenceSegment
    let movementActivity: MovementActivity
    let speedTrend: SpeedTrend
    let terrainGradient: TerrainGradient
    let distance: CLLocationDistance?
    let speed: Double?
    let elevationGain: Double
    let cadence: Double
    let validLocations: [CLLocation]
    let calories: (active: Double, total: Double)?
}

@MainActor
final class RideSessionManager: ObservableObject {
    @AppStorage("userWeightKg") private var userWeightKg: Double = 70.0
    @AppStorage("userHeightCm") private var userHeightCm: Double = 170.0

    // --- Dependencies ---
    var motionManager: MotionManager
    let healthStore = HKHealthStore()
    let locationManager = LocationManager()
    private(set) var workoutType: WorkoutType
    
    // --- Published State for UI ---
    @Published var totalDistance: Double = 0.0
    @Published var elevationGain: Double = 0.0
    @Published var averageCadence: Double?
    @Published var averageSpeed: Double?
    @Published var maxSpeed: Double?
    @Published var activeCalories: Double = 0.0
    @Published var totalCalories: Double = 0.0
    @Published var logEntries: [LogEntry] = []
    @Published var locationAuthStatus: CLAuthorizationStatus = .notDetermined
    
    // --- Constants ---
    private let halfMaxLogEntries = 500
    private let halfMaxBufferSize = 5
    private let maxSplitCount = 3
    private let minDistanceForSlope = 7.5

    // --- Internal State ---
    private var workoutBuilder: HKWorkoutBuilder? // Use the Builder
    private var routeBuilder: HKWorkoutRouteBuilder?
    private var activity: Activity<RideActivityAttributes>? = nil
    private var cadenceSamples: [HKQuantitySample] = []
    private var cadenceSegments: [CadenceSegment] = [] // for storing cadence and relevant information in the update interval
    private var altitudeBuffer: [AltitudeData] = []
    private var locationBuffer: [CLLocation] = []
    private var counter = Counter()
    
    private var cadenceUpdateTask: Task<Void, Never>?
    private var altitudeUpdateTask: Task<Void, Never>?
    private var locationStatusTask: Task<Void, Never>?
    private var locationUpdateTask: Task<Void, Never>?
    private var locationErrorTask: Task<Void, Never>?
    
    var startDate: Date? { workoutBuilder?.startDate }

    // Pre-define workout configuration
    private let workoutConfiguration: HKWorkoutConfiguration = {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .cycling
        configuration.locationType = .outdoor
        return configuration
    }()

    init(workoutType: WorkoutType) {
        self.workoutType = workoutType
        self.motionManager = MotionManager(workoutType: workoutType)
        self.subscribeToLocationManagerUpdates()
        self.locationAuthStatus = locationManager.authorisationStatus
    }
    
    func configure(for newType: WorkoutType) {
        guard self.workoutType != newType else { return }
        
        self.workoutType = newType
        self.motionManager.configure(for: newType)
        self.resetSessionState()
    }
    
    // Helper function to add logs safely
    private func logDebug(_ message: String) {
        let entry = LogEntry(timestamp: Date(), message: message)
        self.logEntries.append(entry)
        // Limit log size
        if self.logEntries.count >= 2 * halfMaxLogEntries {
            self.logEntries.removeFirst(self.logEntries.count - halfMaxLogEntries)
        }
    }

    // MARK: - Session Control Methods

    func startRide() async {
        guard workoutBuilder == nil else { return }

        // Use .local() for the current device (iPhone)
        workoutBuilder = HKWorkoutBuilder(healthStore: healthStore, configuration: workoutConfiguration, device: .local())
        routeBuilder = workoutBuilder?.seriesBuilder(for: .workoutRoute()) as? HKWorkoutRouteBuilder
        guard let builder = workoutBuilder else { return }
        
        let startDate = Date()
        do {
            try await builder.beginCollection(at: startDate)
        } catch {
            logDebug("Failed to begin collection: \(error.localizedDescription)")
            workoutBuilder = nil
            routeBuilder = nil
            return
            // TODO: Show error alert to user
        }
        
        await startLiveActivityTimer(at: startDate)
        self.motionManager.startUpdates()
        self.locationManager.startUpdates()
        self.subscribeToMotionManagerUpdates()
        self.subscribeToLocationManagerUpdates()
    }
    
    func startRidePreparations() {
        self.startLiveActivity()
        self.locationManager.startUpdates()
    }

    func stopRide(context: ModelContext) async -> WorkoutData? {
        // Stop sensors and processing immediately
        cadenceUpdateTask?.cancel()
        cadenceUpdateTask = nil
        altitudeUpdateTask?.cancel()
        altitudeUpdateTask = nil
        locationUpdateTask?.cancel()
        locationUpdateTask = nil
        motionManager.stopUpdates()
        locationManager.stopUpdates()
        
        guard let finalData = self.finaliseLocalData(context: context) else {
            logDebug("Workout was too short or invalid to create a summary. Discarding.")
            workoutBuilder?.discardWorkout()
            self.workoutBuilder = nil
            self.routeBuilder = nil
            return nil
        }

        if let builder = self.workoutBuilder {
            let endDate = Date()
            do {
                await self.saveSummaryStats(to: builder)
                await self.stopLiveActivity()
                
                try await builder.endCollection(at: endDate)
                try await builder.finishWorkout()
                
                if !self.cadenceSamples.isEmpty {
                    try await healthStore.save(self.cadenceSamples)
                }
            } catch {
                logDebug("A failure occurred during HealthKit finalization: \(error.localizedDescription)")
                builder.discardWorkout() // We still continue, because we want to show the summary to the user.
            }
        }
        
        // clean up state and return
        self.workoutBuilder = nil
        self.routeBuilder = nil
        return finalData
    }

    // MARK: - Location Subscription
    
    private func subscribeToLocationManagerUpdates() {
        locationStatusTask?.cancel()
            // Observe Authorization Status changes
            locationStatusTask = Task {
                for await status in locationManager.$authorisationStatus.values {
                    guard !Task.isCancelled else { break }
                    self.locationAuthStatus = status
                }
            }
        
        locationUpdateTask?.cancel()
        locationUpdateTask = Task {
            for await location in locationManager.locationUpdateSubject.values {
                guard !Task.isCancelled else { break }

                self.locationBuffer.append(location)
                if self.locationBuffer.count >= 2 * halfMaxBufferSize {
                    self.locationBuffer.removeFirst(halfMaxBufferSize)
                }
            }
        }

        locationErrorTask?.cancel()
        locationErrorTask = Task {
            for await error in locationManager.locationErrorSubject.values {
                guard !Task.isCancelled else { break }
                logDebug("LM ERROR: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Motion Subscription

    private func subscribeToMotionManagerUpdates() {
        cadenceUpdateTask?.cancel()
        cadenceUpdateTask = Task {
            for await rawCadenceData in motionManager.cadencePublisher.values {
                guard !Task.isCancelled else { break }
                
                let timestamp = rawCadenceData.timestamp
                let rawCadence = rawCadenceData.cadence
                let result = await self.computeCadenceSegment(timestamp: timestamp, rawCadence: rawCadence)
                
                self.cadenceSegments.append(result.segment)
                
                self.counter.update(
                    zone: result.segment.zone,
                    activity: result.movementActivity,
                    trend: result.speedTrend,
                    gradient: result.terrainGradient
                )
                
                if let speed = result.speed {
                    self.maxSpeed = max(self.maxSpeed ?? speed, speed)
                }
                
                if let dist = result.distance {
                    self.totalDistance += dist
                    if let startDate = workoutBuilder?.startDate, self.totalDistance >= 0.5 {
                        let duration = timestamp.timeIntervalSince(startDate)
                        self.averageSpeed = self.totalDistance / duration
                    }
                }
                
                if result.cadence != 0 {
                    let prevAvg = self.averageCadence ?? 0
                    let count = Double(self.cadenceSegments.count - 1)
                    self.averageCadence = (prevAvg * count + result.cadence) / (count + 1)
                }
                
                self.elevationGain += result.elevationGain
                
                if let calories = result.calories {
                    self.activeCalories += calories.active
                    self.totalCalories += calories.total
                }
                
                if !result.validLocations.isEmpty {
                    do {
                        try await routeBuilder?.insertRouteData(result.validLocations)
                    } catch {
                        logDebug("Failed to insert route data: \(error.localizedDescription)")
                    }
                }
                
                logDebug("\(rawCadenceData.cadence.rounded()), \(result.movementActivity.rawValue), \(result.speedTrend.rawValue), \(result.terrainGradient.rawValue)")
                
                if let preferredCadence = rawCadenceData.preferredCadence {
                    if preferredCadence > 0 {
                        await updateLiveActivity(with: preferredCadence)
                        let endDate = timestamp
                        let startDate = self.cadenceSamples.last?.endDate ?? endDate.addingTimeInterval(-MotionManager.SECTION_DURATION)
                        let quantity = HKQuantity(unit: .count().unitDivided(by: .minute()), doubleValue: preferredCadence)
                        let cadenceSample = HKQuantitySample(type: HKQuantityType(.cyclingCadence), quantity: quantity, start: startDate, end: endDate)
                        self.cadenceSamples.append(cadenceSample)
                    }
                    
                    counter.split += 1
                    if counter.split >= maxSplitCount {
                        if workoutType == .cycling {
                            await counter.judgeNotificationA()
                        }
                        
                        if locationAuthStatus == .authorizedAlways || locationAuthStatus == .authorizedWhenInUse {
                            if workoutType == .cycling {
                                await counter.judgeNotificationC()
                            } else if workoutType == .walking || workoutType == .running {
                                await counter.judgeNotificationB()
                            }
                        }
                        
                        counter = Counter() // reset the counter
                    }
                }
            }
        }
        
        altitudeUpdateTask?.cancel()
        altitudeUpdateTask = Task {
            for await altitudeDataPoint in motionManager.altitudePublisher.values {
                guard !Task.isCancelled else { break }

                self.altitudeBuffer.append(altitudeDataPoint)
                if self.altitudeBuffer.count >= 2 * halfMaxBufferSize {
                    self.altitudeBuffer.removeFirst(halfMaxBufferSize)
                }
            }
        }
    }
    
    // MARK: - Live Activities
    
    private func startLiveActivity() {
        // Ensure activities are enabled by the user in Settings
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            logDebug("Live Activities are not enabled.")
            return
        }

        // Create the static and initial dynamic data for the activity
        let attributes = RideActivityAttributes(workoutType: self.workoutType)
        let initialState = RideActivityAttributes.ContentState(rideStartDate: nil, preferredCadence: nil)
        let content = ActivityContent(state: initialState, staleDate: nil)

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            self.activity = activity
        } catch {
            logDebug("Failed to request Live Activity: \(error.localizedDescription)")
        }
    }
    
    private func startLiveActivityTimer(at startDate: Date) async {
        guard let rideActivity = self.activity else { return }

        // Create a new state, providing the start date but preserving any other existing state.
        let updatedState = RideActivityAttributes.ContentState(
            rideStartDate: startDate,
            preferredCadence: rideActivity.content.state.preferredCadence
        )
        let content = ActivityContent(state: updatedState, staleDate: nil)

        await rideActivity.update(content)
    }
    
    private func updateLiveActivity(with preferredCadence: Double) async {
        guard let rideActivity = self.activity else { return }

        // Use the most recent start date and the new cadence.
        let updatedState = RideActivityAttributes.ContentState(
            rideStartDate: rideActivity.content.state.rideStartDate,
            preferredCadence: preferredCadence
        )
        let content = ActivityContent(state: updatedState, staleDate: nil)

        await rideActivity.update(content)
    }

    private func stopLiveActivity() async {
        let finalState = RideActivityAttributes.ContentState(rideStartDate: self.startDate ?? Date())
        let content = ActivityContent(state: finalState, staleDate: nil)
        
        await activity?.end(content, dismissalPolicy: .immediate)
        self.activity = nil
    }
    
    // MARK: - Helper Functions
    
    private func computeCadenceSegment(timestamp: Date, rawCadence: Double) async -> CadenceSegmentComputationResult {
        let prevSegment = self.cadenceSegments.last
        let startTime = prevSegment?.timestamp ?? workoutBuilder?.startDate ?? (timestamp - MotionManager.SEGMENT_DURATION)
        let duration = timestamp.timeIntervalSince(startTime)
        let relevantLocs = self.locationBuffer.filter { $0.timestamp > startTime && $0.timestamp <= timestamp }
        let relevantAlts = self.altitudeBuffer.filter { $0.timestamp > startTime && $0.timestamp <= timestamp }

        var segmentSpeed: Double?
        var segmentDistance: CLLocationDistance?
        var gpsAltitude: Double?
        var baroAltitude: Double?
        var movementActivity: MovementActivity = .notDetermined
        var speedTrend: SpeedTrend = .notDetermined
        var terrainGradient: TerrainGradient = .notDetermined
        var segmentCadence = rawCadence
        var elevationGain: Double = 0
        var calorieResult: (active: Double, total: Double)? = nil

        var validLocs = relevantLocs.filter {
            $0.horizontalAccuracy >= 0 && $0.horizontalAccuracy <= 30
        }

        if !relevantLocs.isEmpty {
            let validSpeeds = relevantLocs.compactMap { $0.speed >= 0 ? $0.speed : nil }

            if !validSpeeds.isEmpty {
                let avgSpeed = validSpeeds.reduce(0, +) / Double(validSpeeds.count)
                segmentSpeed = avgSpeed

                movementActivity = MovementActivity.zone(for: avgSpeed)
                if let prevAvgSpeed = prevSegment?.speed {
                    let delta = avgSpeed - prevAvgSpeed
                    speedTrend = SpeedTrend.zone(for: delta)
                }
            }

            let validAltitudes = relevantLocs.compactMap {
                $0.verticalAccuracy >= 0 && $0.verticalAccuracy <= 10 ? $0.altitude : nil
            }
            if !validAltitudes.isEmpty {
                gpsAltitude = validAltitudes.reduce(0, +) / Double(validAltitudes.count)
            }

            if !validLocs.isEmpty {
                var distance: CLLocationDistance = 0
                if let prevLoc = prevSegment?.locations.last, let firstLoc = validLocs.first {
                    distance += firstLoc.distance(from: prevLoc)
                }
                for i in 0..<(validLocs.count - 1) {
                    distance += validLocs[i+1].distance(from: validLocs[i])
                }
                segmentDistance = distance
            }
        }

        if !relevantAlts.isEmpty {
            baroAltitude = relevantAlts.reduce(0) { $0 + $1.altitude } / Double(relevantAlts.count)

            if let rltAlt = baroAltitude, let prevAlt = prevSegment?.baroAltitude,
               let dist = segmentDistance, let prevDist = prevSegment?.distance {
                let rltElevation = rltAlt - prevAlt
                let avgDistance = (dist + prevDist) / 2

                var errorFlag = false
                if let absAlt = gpsAltitude, let prevAbsAlt = prevSegment?.gpsAltitude {
                    let absElevation = absAlt - prevAbsAlt
                    let error = abs(rltElevation - absElevation)
                    if error > 0.30 { errorFlag = true }
                }

                if avgDistance > minDistanceForSlope && movementActivity != .stationary && !errorFlag {
                    let slope = (rltElevation / avgDistance) * 100.0
                    terrainGradient = TerrainGradient.zone(for: slope)
                    if rltElevation > 0 {
                        elevationGain += rltElevation
                    }
                }
            }
        }

        if movementActivity == .stationary {
            segmentCadence = 0 // nullify the plot
            validLocs = [] // don't show stationary segment on route map
        }
        
        let cadenceZone = CadenceZone.zone(for: segmentCadence, workoutType: self.workoutType)

        if let dist = segmentDistance, let spd = segmentSpeed {
            let inputs = CalorieCalculationInputs(
                duration: duration,
                distance: dist,
                speed: spd,
                workoutType: self.workoutType,
                weight: userWeightKg,
                height: userHeightCm
            )
            let active = inputs.calculate().active
            let total = inputs.calculate().total
            calorieResult = (active, total)
        }

        let segment = CadenceSegment(
            timestamp: timestamp,
            cadence: segmentCadence,
            zone: cadenceZone,
            locations: validLocs,
            speed: segmentSpeed,
            baroAltitude: baroAltitude,
            gpsAltitude: gpsAltitude,
            distance: segmentDistance
        )

        return CadenceSegmentComputationResult(
            segment: segment,
            movementActivity: movementActivity,
            speedTrend: speedTrend,
            terrainGradient: terrainGradient,
            distance: segmentDistance,
            speed: segmentSpeed,
            elevationGain: elevationGain,
            cadence: segmentCadence,
            validLocations: validLocs,
            calories: calorieResult
        )
    }
    
    private func saveSummaryStats(to builder: HKWorkoutBuilder) async {
        var samples: [HKQuantitySample] = []
        let endDate = Date()
        let startDate = builder.startDate ?? endDate
        
        if self.totalDistance > 0 {
            let quantity = HKQuantity(unit: .meter(), doubleValue: self.totalDistance)
            let sample = HKQuantitySample(type: HKQuantityType(.distanceCycling), quantity: quantity, start: startDate, end: endDate)
            samples.append(sample)
        }
        
        if self.activeCalories > 0 {
            let quantity = HKQuantity(unit: .kilocalorie(), doubleValue: self.activeCalories)
            let sample = HKQuantitySample(type: HKQuantityType(.activeEnergyBurned), quantity: quantity, start: startDate, end: endDate)
            samples.append(sample)
        }
        
        let basalCalories = self.totalCalories - self.activeCalories
        if basalCalories > 0 {
            let quantity = HKQuantity(unit: .kilocalorie(), doubleValue: basalCalories)
            let sample = HKQuantitySample(type: HKQuantityType(.basalEnergyBurned), quantity: quantity, start: startDate, end: endDate)
            samples.append(sample)
        }
        
        if !samples.isEmpty {
            do {
                try await builder.addSamples(samples)
            } catch {
                logDebug("Failed to add summary stats to workout: \(error.localizedDescription)")
            }
        }
        
        var metadata: [String: Any] = [:]
        
        metadata[HKMetadataKeyWorkoutBrandName] = "Andare \(self.workoutType.rawValue)"
        
        if self.elevationGain > 0 {
            let quantity = HKQuantity(unit: .meter(), doubleValue: self.elevationGain)
            metadata[HKMetadataKeyElevationAscended] = quantity
        }
        
        if let averageSpeed = self.averageSpeed {
            let quantity = HKQuantity(unit: .meter().unitDivided(by: .second()), doubleValue: averageSpeed)
            metadata[HKMetadataKeyAverageSpeed] = quantity
        }
        
        if !metadata.isEmpty {
            do {
                try await builder.addMetadata(metadata)
            } catch {
                logDebug("Failed to add metadata to workout: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Internal State Management

    private func finaliseLocalData(context: ModelContext) -> WorkoutData? {
        guard let startDate = workoutBuilder?.startDate else { return nil }
        let endDate = cadenceSegments.last?.timestamp ?? workoutBuilder?.endDate ?? Date()
        let logMessages = self.logEntries.map { "[\($0.formattedTimestamp)] \($0.message)" }

        let finalData = WorkoutData(
            workoutType: self.workoutType,
            startTime: startDate,
            endTime: endDate,
            cadenceSegments: self.cadenceSegments,
            logMessages: logMessages,
            averageCadence: self.averageCadence ?? 0.0,
            totalDistance: self.totalDistance,
            averageSpeed: self.averageSpeed ?? 0.0,
            maxSpeed: self.maxSpeed ?? 0.0,
            elevationGain: self.elevationGain,
            activeCalories: self.activeCalories,
            totalCalories: self.totalCalories,
            mapDisplayContext: locationManager.accuracyAuthorization == .fullAccuracy ? .full : .prompt
        )
        
        // --- Save to SwiftData ---
        let workoutToSave = WorkoutDataModel(from: finalData)
        context.insert(workoutToSave)
        do {
            try context.save()
        } catch {
            print("❌ Failed to save workout: \(error.localizedDescription)")
        }
        
        return finalData
    }

    public func resetSessionState() {
        self.cadenceSamples.removeAll()
        self.cadenceSegments.removeAll()
        self.altitudeBuffer.removeAll()
        self.locationBuffer.removeAll()
        self.logEntries.removeAll()
        self.counter = Counter()
        self.totalDistance = 0.0
        self.elevationGain = 0.0
        self.activeCalories = 0.0
        self.averageCadence = nil
        self.averageSpeed = nil
    }
    
    deinit {
        self.cadenceUpdateTask?.cancel()
        self.altitudeUpdateTask?.cancel()
        self.locationUpdateTask?.cancel()
        self.locationErrorTask?.cancel()
        self.workoutBuilder?.discardWorkout()
    }
}
