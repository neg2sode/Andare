//
//  PreferenceView.swift
//  Andare
//
//  Created by neg2sode on 2025/5/26.
//

import SwiftUI
import HealthKit
import CoreLocation

struct PreferencesView: View {
    @Environment(\.dismiss) var dismiss

    @StateObject private var locationManager = LocationManager()
    @StateObject private var healthKitManager = HealthKitManager()
    @StateObject private var alertManager = AlertManager()

    // Re-introduce AppStorage to track "Don't show again" from LocationWarningDetailView
    @AppStorage("showLocationWarningPreference") private var showLocationWarningPreference: Bool = true
    @AppStorage("userWeightKg") private var userWeightKg: Double = 70.0
    @AppStorage("userHeightCm") private var userHeightCm: Double = 170.0

    @State private var showingLocationWarningDetail = false
    @State private var healthKitProfileLinked = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Preferences")
                    .font(.title)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(
                            Color.secondary,
                            Color(.tertiarySystemFill)
                        )
                        .font(.title)
                }
            }
            .padding()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Permissions")
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                            .textCase(nil)
                        
                        VStack(spacing: 0) {
                            Button(action: handleLocationRowTap) {
                                PermissionRow(title: "Location", status: locationManager.authorisationStatus.permissionStatus)
                            }
                            .sheet(isPresented: $showingLocationWarningDetail) { LocationWarningDetailView() }
                            
                            Divider().padding(.leading)
                            
                            // Workouts Row
                            Button(action: handleWorkoutsRowTap) {
                                PermissionRow(title: "Workouts", status: healthKitManager.authorisationStatus(for: HKObjectType.workoutType()).permissionStatus)
                            }
                        }
                        .buttonStyle(.plain) // Apply to all buttons within
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Profile")
                                .font(.headline)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                                .textCase(nil)
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Text("HealthKit")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                if healthKitProfileLinked {
                                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                                } else {
                                    Image(systemName: "info.circle.fill").foregroundStyle(.gray)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.horizontal)
                        
                        VStack(spacing: 0) {
                            ProfileRow(title: "Body Weight (kg)", value: $userWeightKg, formatter: .decimalFormatter)
                            Divider().padding(.leading)
                            ProfileRow(title: "Height (cm)", value: $userHeightCm, formatter: .decimalFormatter)
                        }
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
        }
        .alert(alertManager.title, isPresented: $alertManager.isPresenting) {
            if alertManager.showSettingsButton {
                Button("Open Settings") {
                    UIApplication.openAppSettings()
                }
                Button("Cancel", role: .cancel) { }
            } else {
                Button("OK", role: .cancel) { }
            }
        } message: {
            Text(alertManager.message)
        }
        .onAppear {
            self.healthKitProfileLinked = healthKitManager.profileCharacteristicsAuthorised()
        }
    }

    // MARK: - Helper Methods

    private func handleLocationRowTap() {
        let status = locationManager.authorisationStatus

        // If user already opted out of warnings OR Location is authorized, open Settings
        if !showLocationWarningPreference || status == .notDetermined {
            UIApplication.openAppSettings()
        } else if status == .restricted || status == .denied {
            // Location not authorized AND user still wants to see the warning → show detail sheet
            showingLocationWarningDetail = true
        }
    }
    
    private func handleWorkoutsRowTap() {
        let status = healthKitManager.authorisationStatus(
            for: HKObjectType.workoutType()
        )
        if status != .sharingAuthorized {
            alertManager.showAlert(
                title: "How to Grant Workouts Permission",
                message: """
                    Andare needs permission to save Workouts in Health \
                    to track rides reliably. Please enable Workouts Sharing \
                    in Settings → Privacy & Security → Health → Andare.
                    """
            )
        }
    }
}

// A helper for the simple "Title" + "Status Icon" rows
struct PermissionRow: View {
    let title: String
    let status: PermissionStatus
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Image(systemName: status.iconName)
                .foregroundStyle(status.iconColor)
        }
        .padding()
        .contentShape(Rectangle())
    }
}

// A helper for the "Title" + "TextField" rows
struct ProfileRow: View {
    let title: String
    @Binding var value: Double
    let formatter: NumberFormatter
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            TextField("Value", value: $value, formatter: formatter)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
        }
        .padding()
    }
}

// MARK: - Helper Enums and Extensions

// An enum to decouple the view from CoreLocation/HealthKit types
enum PermissionStatus {
    case granted, denied, warning, undetermined
    
    var iconName: String {
        switch self {
            case .granted: "checkmark.circle.fill"
            case .denied: "xmark.octagon.fill"
            case .warning: "exclamationmark.triangle.fill"
            case .undetermined: "info.circle.fill"
        }
    }
    
    var iconColor: Color {
        switch self {
            case .granted: .green
            case .denied: .red
            case .warning: .orange
            case .undetermined: .gray
        }
    }
}

// Extend the system types to map to our view-specific enum
extension CLAuthorizationStatus {
    var permissionStatus: PermissionStatus {
        switch self {
            case .authorizedAlways, .authorizedWhenInUse: .granted
            case .denied, .restricted: .warning
            case .notDetermined: .undetermined
            @unknown default: .warning
        }
    }
}

extension HKAuthorizationStatus {
    var permissionStatus: PermissionStatus {
        switch self {
            case .sharingAuthorized: .granted
            case .sharingDenied: .denied
            case .notDetermined: .undetermined
            @unknown default: .denied
        }
    }
}

// MARK: - Preview

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
    }
}
