//
//  GuidePermissionsView.swift
//  Andare
//
//  Screen 2 of the guide (first workout only): what to expect and the
//  permissions Andare needs, with an info toggle for the full details.
//

import SwiftUI
import HealthKit

struct GuidePermissionsView: View {
    let workoutType: WorkoutType
    let continueAction: () -> Void
    let backAction: () -> Void

    @State private var hasAppeared = false
    @State private var showPermissionDetails = false

    @ObservedObject private var locationManager = LocationManager.shared
    @ObservedObject private var healthKitManager = HealthKitManager.shared
    @ObservedObject private var motionPermissionManager = MotionPermissionManager.shared

    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        GuideCardScaffold {
            VStack(alignment: .leading, spacing: 24) {
                Text("Before You Go…")
                    .font(.largeTitle).fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .opacity(hasAppeared ? 1 : 0)
                    .animation(.easeIn(duration: 0.3), value: hasAppeared)

                // Switchable content area
                VStack(alignment: .leading, spacing: 16) {
                    if showPermissionDetails {
                        permissionDetailsView
                            .transition(.opacity)
                    } else {
                        userGuideView
                            .transition(.opacity)
                    }
                }
                .opacity(hasAppeared ? 1 : 0)
                .animation(.easeIn(duration: 0.4).delay(0.1), value: hasAppeared)

                Divider()
                    .opacity(hasAppeared ? 1 : 0)
                    .animation(.easeIn(duration: 0.3).delay(0.2), value: hasAppeared)

                permissionSection
            }
        } footer: {
            VStack(spacing: 16) {
                nextHint

                VStack(spacing: 24) {
                    Button("Let's Go", action: continueAction)
                        .buttonStyle(PrimaryButtonStyle(radius: 30))
                        .disabled(!allPermissionsGranted)
                        .opacity(allPermissionsGranted ? 1.0 : 0.5)
                        .animation(.easeInOut(duration: 0.2), value: allPermissionsGranted)

                    Button("Back to Guide for \(workoutType.title)", action: backAction)
                        .font(.headline).fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
            }
            .opacity(hasAppeared ? 1 : 0)
            .animation(.easeIn(duration: 0.4).delay(0.5), value: hasAppeared)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                refreshStatuses()
            }
        }
        .onAppear {
            hasAppeared = true
            refreshStatuses()
        }
    }

    private func refreshStatuses() {
        healthKitManager.refreshStatus()
        motionPermissionManager.refreshStatus()
    }

    // MARK: - User Guide (Default View)

    private var userGuideView: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Andare works in the background.")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text("You can safely turn off your screen any time during the workout. Location permission is required for that.")
                    .font(.subheadline)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("There will be a countdown.")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text("Andare enters background there. Feel free to put your phone in the right position and set out for your \(workoutType.title.lowercased())!")
                    .font(.subheadline)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Andare runs local.")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text("It does not collect or share any personal data or information with third parties.")
                    .font(.subheadline)
            }
        }
    }

    // MARK: - Permission Details (Info View)

    private var permissionDetailsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(Color.calorieColour)
                    Text("Workouts")
                        .font(.subheadline).fontWeight(.semibold)
                }
                Text("Workout sharing is required for starting workouts. Andare also requests permission for sharing workout data like cycling cadence, as well as reading body measurements like body mass.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: "location.fill")
                        .foregroundStyle(Color.distanceColour)
                    Text("Location")
                        .font(.subheadline).fontWeight(.semibold)
                }
                Text("Location is required for background updates. Andare uses location data to create route maps, calculate distance and speed, and detect the terrain in real time.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: "figure.walk.motion")
                        .foregroundStyle(Color.elevationColour)
                    Text("Motion & Fitness")
                        .font(.subheadline).fontWeight(.semibold)
                }
                Text("This is an optional permission that grants access to the barometer for elevation tracking. Cadence detection uses CoreMotion, which doesn't require explicit permission.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Permission Section

    private var permissionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with info button
            HStack {
                Text("Permissions")
                    .font(.headline)

                Button {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showPermissionDetails.toggle()
                    }
                } label: {
                    Image(systemName: showPermissionDetails ? "info.circle.fill" : "info.circle")
                        .foregroundStyle(showPermissionDetails ? Color.accentColor : .secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(showPermissionDetails ? "Hide permission details" : "Show permission details")
            }
            .opacity(hasAppeared ? 1 : 0)
            .animation(.easeIn(duration: 0.3).delay(0.2), value: hasAppeared)

            // Permission rows
            VStack(spacing: 12) {
                PermissionRow(
                    title: "Workouts",
                    subtitle: "For saving sessions.",
                    icon: "heart.fill",
                    iconTint: .calorieColour,
                    status: healthKitManager.authorisationStatus.permissionStatus,
                    grantAction: { Task { try? await healthKitManager.requestAuthorisation() } }
                )

                PermissionRow(
                    title: "Location",
                    subtitle: "For background functionality.",
                    icon: "location.fill",
                    iconTint: .distanceColour,
                    status: locationManager.authorisationStatus.permissionStatus,
                    grantAction: { locationManager.requestAuthorisation() }
                )

                if motionPermissionManager.isAvailable {
                    PermissionRow(
                        title: "Motion & Fitness",
                        subtitle: "For elevation via barometer.",
                        icon: "figure.walk.motion",
                        iconTint: .elevationColour,
                        status: motionPermissionManager.authorisationStatus.permissionStatus,
                        grantAction: { motionPermissionManager.requestAuthorisation() }
                    )
                }
            }
            .opacity(hasAppeared ? 1 : 0)
            .animation(.easeIn(duration: 0.4).delay(0.3), value: hasAppeared)
        }
    }

    // MARK: - Next Hint

    private var nextHint: some View {
        VStack(spacing: 4) {
            Text("Next, you'll see the countdown.")
            Text("You can turn off the screen any time after it starts.")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
    }

    // MARK: - Logic

    private var allPermissionsGranted: Bool {
        let locationOK = locationManager.authorisationStatus != .notDetermined
        let healthOK = healthKitManager.authorisationStatus == .sharingAuthorized
        // Motion is optional: any response (or no barometer) is fine.
        let motionOK = !motionPermissionManager.isAvailable ||
                       motionPermissionManager.authorisationStatus != .notDetermined
        return locationOK && healthOK && motionOK
    }
}

// MARK: - Preview

#Preview {
    GuidePermissionsView(workoutType: .cycling, continueAction: {}, backAction: {})
}
