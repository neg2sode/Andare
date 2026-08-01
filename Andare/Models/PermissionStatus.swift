//
//  PermissionStatus.swift
//  Andare
//
//  Created by neg2sode on 2025/5/26.
//

import SwiftUI
import CoreLocation
import HealthKit
import UserNotifications

// An enum to decouple views from CoreLocation/HealthKit/UserNotifications types
enum PermissionStatus {
    case granted, denied, warning, notDetermined

    var iconName: String {
        switch self {
            case .granted: "checkmark.circle.fill"
            case .denied: "xmark.octagon.fill"
            case .warning: "exclamationmark.triangle.fill"
            case .notDetermined: "info.circle.fill"
        }
    }

    var iconColour: Color {
        switch self {
            case .granted: .green
            case .denied: .red
            case .warning: .orange
            case .notDetermined: .gray
        }
    }
}

// Extend the system types to map to our view-specific enum
extension CLAuthorizationStatus {
    var permissionStatus: PermissionStatus {
        switch self {
            case .authorizedAlways, .authorizedWhenInUse: .granted
            case .denied, .restricted: .warning
            case .notDetermined: .notDetermined
            @unknown default: .warning
        }
    }
}

extension HKAuthorizationStatus {
    var permissionStatus: PermissionStatus {
        switch self {
            case .sharingAuthorized: .granted
            case .sharingDenied: .denied
            case .notDetermined: .notDetermined
            @unknown default: .denied
        }
    }
}

extension UNAuthorizationStatus {
    var permissionStatus: PermissionStatus {
        switch self {
        case .authorized, .provisional, .ephemeral:
            return .granted
        case .denied:
            return .denied
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .denied
        }
    }
}
