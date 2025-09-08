//
//  PreferencesView.swift
//  Andare
//
//  Created by neg2sode on 2025/5/26.
//

import SwiftUI
import TipKit
import HealthKit
import CoreLocation
import UserNotifications

struct PreferencesView: View {
    @Environment(\.dismiss) var dismiss

    @AppStorage("showLocationWarningPreference") private var showLocationWarningPreference: Bool = true
    @AppStorage("realTimeAlertsEnabled") private var realTimeAlertsEnabled: Bool = false
    @AppStorage("finishWorkoutAlertEnabled") private var finishWorkoutAlertEnabled: Bool = false
    @AppStorage("notificationFrequencyRawValue") private var notificationFrequencyRawValue: String = NotificationFrequency.normal.rawValue
    @AppStorage("userWeightKg") private var userWeightKg: Double = 70.0
    @AppStorage("userHeightCm") private var userHeightCm: Double = 170.0

    @State private var showingLocationWarningDetail = false
    @State private var healthKitProfileLinked = false
    
    @StateObject var alertManager = AlertManager()
    @StateObject private var locationManager = LocationManager.shared
    @StateObject private var healthKitManager = HealthKitManager.shared
    @StateObject private var notificationManager = NotificationManager.shared
    
    private let frequencyTip = NotificationFrequencyTip()
    
    private var frequencyBinding: Binding<NotificationFrequency> {
        Binding(
            get: { NotificationFrequency(rawValue: notificationFrequencyRawValue) ?? .normal },
            set: { notificationFrequencyRawValue = $0.rawValue }
        )
    }

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
                    Text("Done")
                        .foregroundStyle(Color.accent)
                }
                .padding(.horizontal, 6)
            }
            .padding(.top, 20)
            .padding(.bottom, 8)
            .padding(.horizontal)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    permissionsSection
                    profileSection
                    notificationSection
                }
                .padding(.vertical)
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .onAppear {
            self.healthKitProfileLinked = healthKitManager.profileCharacteristicsAuthorised()
            notificationManager.refreshStatus()
        }
        .alert(alertManager.title, isPresented: $alertManager.isPresenting) {
            if alertManager.showSettingsButton {
                 Button("Open Settings") { UIApplication.openAppSettings() }
                 Button("Cancel", role: .cancel) { }
             } else {
                 Button("OK", role: .cancel) { }
             }
        } message: {
            Text(alertManager.message)
        }
    }
    
    private var permissionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Permissions")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
                .textCase(nil)
            
            VStack(spacing: 0) {
                // location row
                Button(action: handleLocationRowTap) {
                    PermissionRow(title: "Location", status: locationManager.authorisationStatus.permissionStatus)
                }
                .sheet(isPresented: $showingLocationWarningDetail) { LocationWarningDetailView() }
                
                Divider().padding(.leading)
                
                // Workouts Row
                Button(action: handleWorkoutsRowTap) {
                    PermissionRow(title: "Workouts", status: healthKitManager.authorisationStatus(for: HKObjectType.workoutType()).permissionStatus)
                }
                
                Divider().padding(.leading)
                
                // notification row
                Button(action: handleNotificationsRowTap) {
                    PermissionRow(title: "Notifications", status: notificationManager.authorizationStatus.permissionStatus)
                }
            }
            .buttonStyle(.plain) // Apply to all buttons within
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
    
    private var profileSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Profile")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .textCase(nil)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text("Apple Health")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if healthKitProfileLinked {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(.gray)
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
    
    private var notificationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notifications")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .textCase(nil)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                Toggle("Finish Workout Alert", isOn: $finishWorkoutAlertEnabled)
                    .padding(.horizontal)
                    .padding(.vertical, 13)
                
                Divider().padding(.leading)
                
                Toggle("Real-Time Alerts", isOn: $realTimeAlertsEnabled)
                    .padding(.horizontal)
                    .padding(.vertical, 13)
                
                if realTimeAlertsEnabled {
                    Divider().padding(.leading)
                    HStack {
                        HStack(spacing: 8) {
                            Text("Frequency")
                                .popoverTip(frequencyTip)
                        }
                        Spacer()
                        // 5. USE THE CUSTOM BINDING for the Picker.
                        Picker("Frequency", selection: frequencyBinding) {
                            Text("High").tag(NotificationFrequency.high)
                            Text("Default").tag(NotificationFrequency.normal)
                        }
                        .pickerStyle(.segmented).frame(maxWidth: 160)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 13)
                }
            }
            .background(Color(.secondarySystemGroupedBackground)).cornerRadius(12).padding(.horizontal)
            .animation(.easeInOut(duration: 0.2), value: realTimeAlertsEnabled)
        }
    }

    // MARK: - Helper Methods

    private func handleLocationRowTap() {
        let status = locationManager.authorisationStatus

        if (status == .restricted || status == .denied) && showLocationWarningPreference {
            showingLocationWarningDetail = true
        } else if status == .notDetermined {
            locationManager.requestAuthorisation()
        } else {
            UIApplication.openAppSettings()
        }
    }
    
    private func handleWorkoutsRowTap() {
        let status = healthKitManager.authorisationStatus(
            for: HKObjectType.workoutType()
        )
        
        if status == .notDetermined {
            Task { try? await healthKitManager.requestAuthorisation() }
        } else if status == .sharingDenied {
            alertManager.showAlert(
                title: "How to Grant Workouts Permission",
                message: "Please enable Workouts Sharing in Settings → Privacy & Security → Health → Andare to start a workout."
            )
        }
    }
    
    private func handleNotificationsRowTap() {
        switch notificationManager.authorizationStatus {
        case .notDetermined:
            // If permissions haven't been asked for, request them.
            Task {
                await notificationManager.requestAuthorisation()
            }
        default:
            // If permissions are already granted or denied, go to the Settings app.
            UIApplication.openNotificationSettings()
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
                .foregroundStyle(status.iconColour)
        }
        .padding(.horizontal)
        .padding(.vertical, 13)
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
        .padding(.horizontal)
        .padding(.vertical, 13)
        .contentShape(Rectangle())
    }
}

// MARK: - Helper Enums and Extensions

// An enum to decouple the view from CoreLocation/HealthKit types
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

// MARK: - Preview

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
    }
}
