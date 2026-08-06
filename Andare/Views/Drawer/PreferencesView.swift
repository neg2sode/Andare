//
//  PreferencesView.swift
//  Andare
//
//  Created by neg2sode on 2025/5/26.
//

import SwiftUI
import HealthKit
import CoreLocation
import UserNotifications

/// Which profile field the keyboard is attached to.
enum ProfileField: Hashable {
    case weight, height
}

struct PreferencesView: View {
    @Environment(\.dismiss) var dismiss

    @AppStorage("showLocationWarningPreference") private var showLocationWarningPreference: Bool = true
    @AppStorage("realTimeAlertsEnabled") private var realTimeAlertsEnabled: Bool = false
    @AppStorage("finishWorkoutAlertEnabled") private var finishWorkoutAlertEnabled: Bool = false
    @AppStorage("notificationFrequencyRawValue") private var notificationFrequencyRawValue: String = NotificationFrequency.normal.rawValue
    @AppStorage("unitSystemPreference") private var unitSystem: UnitSystem = .systemDefault
    @AppStorage("userWeightKg") private var userWeightKg: Double = 70.0
    @AppStorage("userHeightCm") private var userHeightCm: Double = 170.0

    @State private var showingLocationWarningDetail = false
    @State private var profileSync: ProfileSyncState = .checking
    @State private var syncSpin = false
    @State private var syncTask: Task<Void, Never>?
    @FocusState private var focusedField: ProfileField?

    @StateObject private var alertManager = AlertManager()
    @ObservedObject private var locationManager = LocationManager.shared
    @ObservedObject private var healthKitManager = HealthKitManager.shared
    @ObservedObject private var notificationManager = NotificationManager.shared

    /// Whether the profile values are backed by Apple Health right now.
    private enum ProfileSyncState {
        case checking   // a read or write is in flight
        case linked     // Health holds these values
        case unlinked   // no Health access; values stay on device
    }

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
            }
            .padding(.top, 20)
            .padding(.bottom, 8)
            .padding(.horizontal, 22)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    permissionsSection
                    profileSection
                    unitsSection
                    notificationSection
                }
                .padding(.vertical)
            }
        }
        .sheet(isPresented: $showingLocationWarningDetail) { LocationWarningDetailView() }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .toolbar {
            // decimalPad has no return key, so give the fields a way to resign
            // first responder — that is what commits the value to Health.
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = nil }
            }
        }
        .task {
            notificationManager.refreshStatus()
            await loadProfileFromHealth()
        }
        .onChange(of: focusedField) { previous, current in
            // Leaving a field commits it.
            if let previous, previous != current {
                syncProfileToHealth(previous)
            }
        }
        .onDisappear { syncTask?.cancel() }
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
            SectionHeader(title: "Permissions")
            
            VStack(spacing: 0) {
                // location row
                Button(action: handleLocationRowTap) {
                    PermissionRow(title: "Location", status: locationManager.authorisationStatus.permissionStatus)
                        .padding(.horizontal)
                        .padding(.vertical, 13)
                }

                Divider().padding(.leading)

                // Workouts Row
                Button(action: handleWorkoutsRowTap) {
                    PermissionRow(title: "Workouts", status: healthKitManager.authorisationStatus(for: HKObjectType.workoutType()).permissionStatus)
                        .padding(.horizontal)
                        .padding(.vertical, 13)
                }

                Divider().padding(.leading)

                // notification row
                Button(action: handleNotificationsRowTap) {
                    PermissionRow(title: "Notifications", status: notificationManager.authorizationStatus.permissionStatus)
                        .padding(.horizontal)
                        .padding(.vertical, 13)
                }
            }
            .buttonStyle(.plain) // Apply to all buttons within
            .cardStyle(radius: 12)
            .padding(.horizontal)
        }
    }
    
    private var profileSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                SectionHeader(title: "Profile")

                Spacer()

                healthSyncIndicator
                    .padding(.horizontal, 32)
            }

            VStack(spacing: 0) {
                ProfileRow(
                    title: "Body Weight",
                    value: $userWeightKg,
                    unit: "kg",
                    field: .weight,
                    focusedField: $focusedField
                )
                Divider().padding(.leading)
                ProfileRow(
                    title: "Height",
                    value: $userHeightCm,
                    unit: "cm",
                    field: .height,
                    focusedField: $focusedField
                )
            }
            .cardStyle(radius: 12)
            .padding(.horizontal)
        }
    }

    private var healthSyncIndicator: some View {
        HStack(spacing: 4) {
            Text("Apple Health")
                .font(.caption)
                .foregroundStyle(.secondary)

            Group {
                switch profileSync {
                case .checking:
                    Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                        .foregroundStyle(.secondary)
                        .symbolEffect(.rotate, value: syncSpin)
                case .linked:
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                case .unlinked:
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.gray)
                }
            }
            .contentTransition(.symbolEffect(.replace))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(profileSyncAccessibilityLabel)
    }

    private var profileSyncAccessibilityLabel: String {
        switch profileSync {
        case .checking: "Apple Health, syncing"
        case .linked: "Apple Health, synced"
        case .unlinked: "Apple Health, not connected. Values are stored on this device only."
        }
    }
    
    private var unitsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Units")
            
            // The rounded group container
            VStack(spacing: 0) {
                // 1. REPLACE the Picker with a Menu
                Menu {
                    // 2. This is the content of the pop-up menu
                    ForEach(UnitSystem.allCases, id: \.self) { system in
                        Button {
                            // Action: Update the AppStorage variable
                            self.unitSystem = system
                        } label: {
                            HStack {
                                Text(system.rawValue)
                                if unitSystem == system {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    // 3. This is the label for the menu, which is our full-width row
                    HStack {
                        Text("Measurement")
                        
                        Spacer()
                        
                        HStack {
                            Text(unitSystem.rawValue)
                            
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 13)
                }
                .tint(.primary)
            }
            .cardStyle(radius: 12)
            .padding(.horizontal)
        }
    }
    
    private var notificationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Notifications")
            
            VStack(spacing: 0) {
                Toggle(isOn: $finishWorkoutAlertEnabled) {
                    rowLabel("Finish Workout Alert", info: .finishWorkoutAlert)
                }
                .padding(.horizontal)
                .padding(.vertical, 13)

                Divider().padding(.leading)

                Toggle(isOn: $realTimeAlertsEnabled) {
                    rowLabel("Real-Time Alerts", info: .realTimeAlerts)
                }
                .padding(.horizontal)
                .padding(.vertical, 13)

                if realTimeAlertsEnabled {
                    Divider().padding(.leading)
                    HStack {
                        rowLabel("Frequency", info: .frequency)
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
            .cardStyle(radius: 12).padding(.horizontal)
            .animation(.easeInOut(duration: 0.2), value: realTimeAlertsEnabled)
        }
    }

    // MARK: - Notification Explanations

    /// The copy behind each `info.circle` button in the Notifications section.
    private enum NotificationInfo {
        case finishWorkoutAlert, realTimeAlerts, frequency

        var title: String {
            switch self {
            case .finishWorkoutAlert: "Finish Workout Alert"
            case .realTimeAlerts: "Real-Time Alerts"
            case .frequency: "Notification Frequency"
            }
        }

        var message: String {
            switch self {
            case .finishWorkoutAlert:
                "If you've barely moved for the last few minutes, Andare asks whether your workout is over, so a session you forgot to end doesn't keep recording. Needs location access."
            case .realTimeAlerts:
                "During a ride, Andare reviews your recent cadence and terrain. If you spent most of the last few minutes below or above your sound cadence range, it sends a nudge — and on a climb you're struggling with, it suggests pushing the bike instead. Rides only."
            case .frequency:
                "How often those checks run.\n\nDefault: about every 4 minutes\nHigh: about every 80 seconds\n\nHigh reacts sooner but interrupts more."
            }
        }
    }

    private func rowLabel(_ title: String, info: NotificationInfo) -> some View {
        HStack(spacing: 6) {
            Text(title)

            Button {
                alertManager.showAlert(title: info.title, message: info.message)
            } label: {
                Image(systemName: "info.circle")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("About \(info.title)")
        }
    }

    // MARK: - Apple Health Profile Sync

    /// The spinner is driven by real work, but a HealthKit round trip can
    /// finish in a few milliseconds — hold it long enough to be legible.
    private static let minimumSyncDisplay: Duration = .milliseconds(700)

    /// Pulls weight and height from Health so the rows show what Health holds.
    private func loadProfileFromHealth() async {
        guard healthKitManager.profileCharacteristicsAuthorised() else {
            profileSync = .unlinked
            return
        }

        beginSyncing()
        async let mass = healthKitManager.fetchBodyMass()
        async let height = healthKitManager.fetchHeight()
        async let delay: Void? = try? await Task.sleep(for: Self.minimumSyncDisplay)
        let (fetchedMass, fetchedHeight, _) = await (mass, height, delay)

        if let fetchedMass { userWeightKg = fetchedMass }
        if let fetchedHeight { userHeightCm = fetchedHeight }

        withAnimation { profileSync = .linked }
    }

    /// Commits an edited field: keeps the value physically plausible, then
    /// writes it back to Health. Debounced so quickly moving between fields
    /// doesn't stack overlapping saves.
    private func syncProfileToHealth(_ field: ProfileField) {
        // A mistyped value would otherwise skew calorie estimates and end up
        // in the user's Health record.
        switch field {
        case .weight: userWeightKg = min(max(userWeightKg, 20), 300)
        case .height: userHeightCm = min(max(userHeightCm, 50), 250)
        }

        guard healthKitManager.profileCharacteristicsAuthorised() else {
            profileSync = .unlinked
            return
        }

        syncTask?.cancel()
        beginSyncing()

        syncTask = Task {
            let saved: Bool
            switch field {
            case .weight: saved = await healthKitManager.saveBodyMass(userWeightKg)
            case .height: saved = await healthKitManager.saveHeight(userHeightCm)
            }
            try? await Task.sleep(for: Self.minimumSyncDisplay)
            guard !Task.isCancelled else { return }

            withAnimation { profileSync = saved ? .linked : .unlinked }
        }
    }

    private func beginSyncing() {
        withAnimation { profileSync = .checking }
        syncSpin.toggle()
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

// A helper for the "Title" + "TextField" + unit rows
struct ProfileRow: View {
    let title: String
    @Binding var value: Double
    let unit: String
    let field: ProfileField
    var focusedField: FocusState<ProfileField?>.Binding

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            TextField("Value", value: $value, formatter: NumberFormatter.decimalFormatter)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 60)
                .focused(focusedField, equals: field)
            Text(unit)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 13)
        .contentShape(Rectangle())
        .onTapGesture { focusedField.wrappedValue = field }
    }
}

// MARK: - Preview

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
    }
}
