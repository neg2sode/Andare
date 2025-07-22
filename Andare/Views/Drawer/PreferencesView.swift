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
        NavigationStack {
            Form {
                // ─────────────────────────────────────────────────────────────────
                // PERMISSIONS SECTION
                Section(header: Text("Permissions")) {
                    // 1) LOCATION ROW
                    Button {
                        handleLocationRowTap()
                    } label: {
                        HStack {
                            Text("Location")
                            Spacer()

                            // Icon logic:
                            // • Green checkmark if authorized
                            // • Orange warning if not authorized (denied/restricted/notDetermined)
                            Group {
                                switch locationManager.authorisationStatus {
                                case .authorizedAlways, .authorizedWhenInUse:
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                case .denied, .restricted:
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(.orange)
                                case .notDetermined:
                                    Image(systemName: "info.circle.fill")
                                        .foregroundStyle(.gray)
                                @unknown default:
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(.orange)
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    // Present LocationWarningDetailView if needed
                    .sheet(isPresented: $showingLocationWarningDetail) {
                        LocationWarningDetailView()
                    }

                    // 2) HEALTHKIT (WORKOUTS) ROW
                    Button {
                        let hkStatus = healthKitManager.authorisationStatus(
                            for: HKObjectType.workoutType()
                        )
                        if hkStatus != .sharingAuthorized {
                            alertManager.showAlert(
                                title: "How to Grant Workouts Permission",
                                message: """
                                    Andare needs permission to save Workouts in Health \
                                    to track rides reliably. Please enable Workouts Sharing \
                                    in Settings → Privacy & Security → Health → Andare.
                                    """
                            )
                        }
                        // If already authorized, tapping does nothing
                    } label: {
                        HStack {
                            Text("Workouts")
                            Spacer()
                            if healthKitManager.authorisationStatus(for: HKObjectType.workoutType())
                                == .sharingAuthorized {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            } else {
                                Image(systemName: "xmark.octagon.fill")
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
                // ─────────────────────────────────────────────────────────────────

                // ─────────────────────────────────────────────────────────────────
                // PROFILE / BODY WEIGHT SECTION
                Section {
                    HStack {
                        Text("Body Weight (kg)")
                        Spacer()
                        TextField("e.g. 70", value: $userWeightKg, formatter: NumberFormatter.decimalFormatter)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Height (cm)")
                        Spacer()
                        TextField("e.g. 170", value: $userHeightCm, formatter: NumberFormatter.decimalFormatter)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                } header: {
                    HStack {
                        Text("Profile")
                        Spacer()
                        // ✨ NEW: Conditional "Linked with HealthKit" indicator
                        if healthKitProfileLinked { // If ALL profile characteristics are authorized
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        } else { // If NOT ALL are authorized
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(.gray)
                        }
                        Text("HealthKit") // Generic text
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } // End Form
            .navigationTitle("Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(
                                Color.secondary,
                                Color(.tertiarySystemFill)
                            )
                            .imageScale(.large)
                    }
                }
            }
            // ─────────────────────────────────────────────────────────────────
            // SINGLE ALERT HANDLER (for HealthKit row)
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
            // ─────────────────────────────────────────────────────────────────
        } // End NavigationStack
        .onAppear {
            self.healthKitProfileLinked = healthKitManager.profileCharacteristicsAuthorised()
        }
    }

    // MARK: - Helper Methods

    /// Handle tapping the Location row:
    /// • If authorized OR user has chosen “Don't show again” (showLocationWarningPreference == false),
    ///   open system Settings.
    /// • Otherwise (status is denied/restricted/notDetermined AND showLocationWarningPreference == true),
    ///   show the LocationWarningDetailView sheet.
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
}

// MARK: - Preview

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
    }
}
