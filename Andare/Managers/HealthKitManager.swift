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
        HKQuantityType(.height)
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
