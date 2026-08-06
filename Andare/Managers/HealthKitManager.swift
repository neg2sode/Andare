//
//  HealthKitManager.swift
//  Andare
//
//  Created by neg2sode on 2025/4/29.
//

import Foundation
import HealthKit

final class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    
    @Published var authorisationStatus: HKAuthorizationStatus
    
    private let healthStore = HKHealthStore()

    // Define the types we want to read and share
    private let typesToShare: Set<HKSampleType> = [
        HKObjectType.workoutType(),
        HKSeriesType.workoutRoute(),
        HKQuantityType(.cyclingCadence),
        HKQuantityType(.cyclingSpeed),
        HKQuantityType(.distanceCycling),
        HKQuantityType(.activeEnergyBurned),
        HKQuantityType(.basalEnergyBurned),
        HKQuantityType(.bodyMass),
        HKQuantityType(.height)
    ]


    private let typesToRead: Set<HKSampleType> = [
        HKObjectType.workoutType(),
        HKQuantityType(.cyclingCadence),
        HKQuantityType(.bodyMass),
        HKQuantityType(.height),
        HKQuantityType(.timeInDaylight),
        HKQuantityType(.stepCount)
    ]

    // Read-only types backing the drawer's Today cards.
    private let todayReadTypes: Set<HKObjectType> = [
        HKQuantityType(.timeInDaylight),
        HKQuantityType(.stepCount)
    ]
    
    init() {
        self.authorisationStatus = healthStore.authorizationStatus(for: HKObjectType.workoutType())
    }
    
    func refreshStatus() {
        authorisationStatus = healthStore.authorizationStatus(for: HKObjectType.workoutType())
    }

    // Function to request authorization from the user
    func requestAuthorisation() async throws {
        // Check if HealthKit is available on this device
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.healthDataNotAvailable
        }

        do {
            try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
        } catch {
            throw error
        }
        
        refreshStatus()
    }

    // Check authorization status for a specific type
    func authorisationStatus(for type: HKObjectType) -> HKAuthorizationStatus {
        return healthStore.authorizationStatus(for: type)
    }
    
    /// Whether requesting authorization would show the HealthKit sheet for
    /// the Today card read types (i.e. the user hasn't been asked yet).
    func shouldRequestTodayAuthorisation() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else { return false }
        let status = try? await healthStore.statusForAuthorizationRequest(toShare: [], read: todayReadTypes)
        return status == .shouldRequest
    }

    func requestTodayAuthorisation() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        try? await healthStore.requestAuthorization(toShare: [], read: todayReadTypes)
    }

    /// Today's cumulative sum for a quantity type, in the given unit.
    /// Returns nil when there is no readable data — HealthKit does not
    /// distinguish "read denied" from "no data", so nil covers both.
    func fetchTodaysSum(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double? {
        guard HKHealthStore.isHealthDataAvailable() else { return nil }
        let quantityType = HKQuantityType(identifier)
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, statistics, _ in
                guard let sum = statistics?.sumQuantity() else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: sum.doubleValue(for: unit))
            }
            healthStore.execute(query)
        }
    }

    func fetchBodyMass() async -> Double? {
        let bodyMassType = HKQuantityType(.bodyMass)
        let authStatus = healthStore.authorizationStatus(for: bodyMassType)
        guard authStatus == .sharingAuthorized else { return nil } // Only fetch if authorized

        let queryPredicate = HKQuery.predicateForSamples(withStart: Date.distantPast, end: Date(), options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: bodyMassType, predicate: queryPredicate, limit: 1, sortDescriptors: [sortDescriptor]) { (query, samples, error) in
                guard error == nil, let quantitySample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                let bodyMass = quantitySample.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
                continuation.resume(returning: bodyMass)
            }
            healthStore.execute(query)
        }
    }
    
    /// Most recent height sample in centimetres, or nil when unreadable.
    func fetchHeight() async -> Double? {
        let heightType = HKQuantityType(.height)
        guard healthStore.authorizationStatus(for: heightType) == .sharingAuthorized else { return nil }

        let queryPredicate = HKQuery.predicateForSamples(withStart: Date.distantPast, end: Date(), options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: heightType, predicate: queryPredicate, limit: 1, sortDescriptors: [sortDescriptor]) { (_, samples, error) in
                guard error == nil, let quantitySample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: quantitySample.quantity.doubleValue(for: .meterUnit(with: .centi)))
            }
            healthStore.execute(query)
        }
    }

    /// Writes a body mass sample in kilograms. Returns false when sharing is
    /// not authorised or the save fails.
    func saveBodyMass(_ kilograms: Double) async -> Bool {
        let quantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: kilograms)
        return await saveProfileSample(type: HKQuantityType(.bodyMass), quantity: quantity)
    }

    /// Writes a height sample in centimetres. Returns false when sharing is
    /// not authorised or the save fails.
    func saveHeight(_ centimetres: Double) async -> Bool {
        let quantity = HKQuantity(unit: .meterUnit(with: .centi), doubleValue: centimetres)
        return await saveProfileSample(type: HKQuantityType(.height), quantity: quantity)
    }

    private func saveProfileSample(type: HKQuantityType, quantity: HKQuantity) async -> Bool {
        guard HKHealthStore.isHealthDataAvailable(),
              healthStore.authorizationStatus(for: type) == .sharingAuthorized else { return false }

        let now = Date()
        let sample = HKQuantitySample(type: type, quantity: quantity, start: now, end: now)

        do {
            try await healthStore.save(sample)
            return true
        } catch {
            return false
        }
    }

    func profileCharacteristicsAuthorised() -> Bool {
        let requiredTypes: Set = [
            HKQuantityType(.bodyMass),
            HKQuantityType(.height)
        ]

        for type in requiredTypes {
            if healthStore.authorizationStatus(for: type) != .sharingAuthorized {
                return false
            }
        }
        return true
    }
}

// Custom error enum for HealthKit related issues
enum HealthKitError: Error, LocalizedError {
    case healthDataNotAvailable
    case authorizationFailed(String?)
    case configurationError(String?) // Added for issues like missing types

    var errorDescription: String? {
        switch self {
        case .healthDataNotAvailable:
            return "Health data is not available on this device."
        case .authorizationFailed(let reason):
            return "HealthKit authorization failed. \(reason ?? "")"
        case .configurationError(let reason):
            return "HealthKit configuration error. \(reason ?? "")"
        }
    }
}
