//
//  GuideView.swift
//  Andare
//
//  Created by neg2sode on 2025/7/25.
//

// File: GuideView.swift

import SwiftUI
import HealthKit

struct WorkoutGuidance {
    let title: String
    let points: [String]
    
    static func forType(_ type: WorkoutType) -> WorkoutGuidance {
        switch type {
        case .cycling:
            return .init(
                title: "For Cycling",
                points: [
                    "Place your iPhone in a hip pocket or waistband.",
                    "Cadence is detected from your body's rotation — backpacks or mounts won't work.",
                    "Ensure your phone is secure during high speeds."
                ]
            )
        case .running:
            return .init(
                title: "For Running",
                points: [
                    "Hold the phone firmly in your hand.",
                    "Alternatively, tuck it into a tight pocket or waistband.",
                    "A secure fit is key for accurate measurement."
                ]
            )
        case .walking:
            return .init(
                title: "For Walking",
                points: [
                    "Any stable spot works well.",
                    "A pocket, waistband, or carrying it in your hand are all great options.",
                    "Enjoy your walk!"
                ]
            )
        }
    }
}

struct GuideView: View {
    // MARK: - Properties
    let workoutType: WorkoutType
    let requestAuth: Bool
    let continueAction: () -> Void
    
    private var guidance: WorkoutGuidance {
        .forType(workoutType)
    }
    
    // This view manages its own permission state
    @StateObject private var locationManager = LocationManager()
    @StateObject private var healthKitManager = HealthKitManager()
    
    @Environment(\.scenePhase) private var scenePhase

    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Before You Start…")
                    .font(.largeTitle).fontWeight(.bold)
                    .padding(.top)

                // 2. The new workout-specific guidance section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: workoutType.sfSymbolName)
                            .font(.headline)
                            .foregroundStyle(Color.accentColor)
                        Text(guidance.title)
                            .font(.headline)
                    }
                    
                    ForEach(guidance.points, id: \.self) { point in
                        Label(point, systemImage: "checkmark.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                    }
                }

                // 3. The new, prominent risk warning view
                if workoutType != .walking {
                    RiskWarningView()
                }
                
                // The existing permission section
                if requestAuth {
                    permissionSection
                }
                
                Text("(You'll only see this guidance once for each type of workout.)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                Spacer()

                // Continue Button
                Button(action: continueAction) {
                    Text("Let's Go")
                        .font(.headline).fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .cornerRadius(16)
                }
                .disabled(requestAuth && !arePermissionsGranted)
                .opacity(requestAuth && !arePermissionsGranted ? 0.5 : 1.0)
                .animation(.easeInOut, value: arePermissionsGranted)
            }
            .padding(30)
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    healthKitManager.refreshStatus()
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var permissionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Required Permissions")
                .font(.headline)
            
            PermissionGuideRow(
                title: "Location",
                subtitle: "To track your route and distance.",
                iconName: "location.fill",
                status: locationManager.authorisationStatus.permissionStatus,
                action: { locationManager.requestAuthorisation() }
            )
            
            PermissionGuideRow(
                title: "Workouts",
                subtitle: "To save your session to Apple Health.",
                iconName: "heart.fill",
                status: healthKitManager.authorisationStatus.permissionStatus,
                action: { Task { try? await healthKitManager.requestAuthorisation() } }
            )
        }
    }
    
    // MARK: - Logic
    
    private var arePermissionsGranted: Bool {
        let locationOK = locationManager.authorisationStatus == .authorizedWhenInUse || locationManager.authorisationStatus == .authorizedAlways
        let healthOK = healthKitManager.authorisationStatus == .sharingAuthorized
        return locationOK && healthOK
    }
}


// MARK: - Helper Views

struct RiskWarningView: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundStyle(.orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Important: Secure Your Phone")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text("At high speeds, a loose phone can slip and get damaged. Please carry it firmly in a hip pocket or waistband.")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.15))
        .cornerRadius(12)
    }
}

struct FeatureHighlight: View {
    let iconName: String, iconColor: Color, title: String, subtitle: String
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: iconName).font(.title).foregroundStyle(iconColor).frame(width: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }
}

struct PermissionGuideRow: View {
    let title: String, subtitle: String, iconName: String
    let status: PermissionStatus
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: iconName)
                .font(.title2).foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(status.iconColor.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading) {
                Text(title).font(.headline)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if status == .granted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2).foregroundStyle(.green)
            } else {
                Button("Grant", action: action)
                    .buttonStyle(.bordered)
                    .tint(.accentColor)
            }
        }
    }
}


// MARK: - Previews

struct GuideView_Previews: PreviewProvider {
    static var previews: some View {
        GuideView(workoutType: .cycling, requestAuth: true, continueAction: {})
            .previewDisplayName("First Time Welcome")
        
        GuideView(workoutType: .walking, requestAuth: false, continueAction: {})
            .previewDisplayName("New Workout Type Welcome")
        
        GuideView(workoutType: .running, requestAuth: false, continueAction: {})
            .previewDisplayName("Running Welcome")
    }
}
