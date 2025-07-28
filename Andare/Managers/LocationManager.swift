//
//  LocationManager.swift
//  Andare
//
//  Created by neg2sode on 2025/5/4.
//

import Foundation
import CoreLocation
import Combine // For PassthroughSubject

// Needs to inherit from NSObject to be CLLocationManagerDelegate
final class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()
    
    private let locationManager = CLLocationManager()

    // --- Published State ---
    // Publish authorization status for observers
    @Published var authorisationStatus: CLAuthorizationStatus

    // --- Combine Subjects for Updates/Errors ---
    // Subject to publish new locations
    let locationUpdateSubject = PassthroughSubject<CLLocation, Never>()
    // Subject to publish errors
    let locationErrorSubject = PassthroughSubject<Error, Never>()
    
    var accuracyAuthorization: CLAccuracyAuthorization {
        return locationManager.accuracyAuthorization
    }

    override init() {
        // Initialize status before calling super.init()
        authorisationStatus = locationManager.authorizationStatus
        super.init()

        locationManager.delegate = self

        // Configure Location Manager settings for workout tracking
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone // Get all updates initially
        locationManager.activityType = .fitness // Optimize for fitness tracking
        locationManager.allowsBackgroundLocationUpdates = true // ** CRUCIAL FOR BACKGROUND **
        locationManager.pausesLocationUpdatesAutomatically = false // We control start/stop
        locationManager.showsBackgroundLocationIndicator = true // Show blue indicator bar/pill
    }
    
    // MARK: - Permission Handling
    func requestAuthorisation() {
        locationManager.requestWhenInUseAuthorization()
    }

    // MARK: - Update Control

    func startUpdates() {
        let currentStatus = locationManager.authorizationStatus

        // Check authorization before starting
        if currentStatus == .authorizedWhenInUse || currentStatus == .authorizedAlways {
            locationManager.startUpdatingLocation()
        } else if currentStatus == .notDetermined {
            requestAuthorisation()
        }
    }
    
    func stopUpdates() {
        locationManager.stopUpdatingLocation()
    }
}

// MARK: - CLLocationManagerDelegate Implementation
extension LocationManager: CLLocationManagerDelegate {
    // Called when authorization status changes
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let newStatus = manager.authorizationStatus

        // Update the published property on the main thread
        Task { @MainActor in
            self.authorisationStatus = newStatus
            
            if newStatus == .denied || newStatus == .restricted {
                // Handle case where user revokes permission while app is running
                stopUpdates() // Ensure updates stop if permission revoked
            }
        }
    }

    // Called when new location data is available
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // The last location in the array is typically the most recent
        guard let latestLocation = locations.last else { return }

        // Publish the latest location
        Task {
            locationUpdateSubject.send(latestLocation)
        }
    }

    // Called when location updates fail
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Don't stop updates for temporary errors, but publish the error
        Task {
            locationErrorSubject.send(error)
        }

        // Handle specific errors if needed (e.g., CLCLError.denied)
        if let clError = error as? CLError, clError.code == .denied {
            Task { @MainActor in
                stopUpdates()
                // Update status if necessary (delegate might handle this anyway)
                self.authorisationStatus = .denied
            }
        }
    }
}
