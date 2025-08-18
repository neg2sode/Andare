//
//  GuideView.swift
//  Andare
//
//  Created by neg2sode on 2025/7/25.
//

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
                    "Tuck your phone tightly in a hip pocket or waistband.",
                    "Cadence is detected from your body's rotation — backpacks or mounts won't work."
                ]
            )
        case .running:
            return .init(
                title: "For Running",
                points: [
                    "Place your phone in a hip pocket or waistband.",
                    "Alternatively, hold your phone firmly in your hand."
                ]
            )
        case .walking:
            return .init(
                title: "For Walking",
                points: [
                    "Any stable spot works well.",
                    "A pocket, waistband, or carrying it in your hand are all great options."
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
    let cancelAction: () -> Void
    
    private var guidance: WorkoutGuidance {
        .forType(workoutType)
    }

    @State private var hasAppeared = false
    
    @StateObject private var locationManager = LocationManager.shared
    @StateObject private var healthKitManager = HealthKitManager.shared
    
    @Environment(\.scenePhase) private var scenePhase

    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Before You Start…")
                .font(.largeTitle).fontWeight(.bold)
                .padding(.top, 50)
                .padding(.horizontal, 30)

            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    // 2. The new workout-specific guidance section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: workoutType.sfSymbolName)
                                .font(.headline)
                                .foregroundStyle(Color.accentColor)
                                .symbolEffect(.bounce, value: hasAppeared)
                            
                            Text(guidance.title)
                                .font(.headline)
                        }
                        .opacity(hasAppeared ? 1 : 0)
                        .animation(.easeIn(duration: 0.3), value: hasAppeared)
                        
                        ForEach(Array(guidance.points.enumerated()), id: \.offset) { index, point in
                            Label(point, systemImage: "checkmark.circle.fill")
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                                .opacity(hasAppeared ? 1 : 0)
                                .offset(y: hasAppeared ? 0 : 10)
                                // Each item animates in with a progressive delay
                                .animation(
                                    .easeOut(duration: 0.4).delay(0.3 + Double(index) * 0.15),
                                    value: hasAppeared
                                )
                        }
                    }
                    
                    if workoutType != .walking {
                        RiskWarningView()
                            // This will now fade in after the points
                            .opacity(hasAppeared ? 1 : 0)
                            .animation(.easeIn(duration: 0.4).delay(0.7), value: hasAppeared)
                    }
                    
                    if requestAuth {
                        permissionSection
                            // This fades in last
                            .opacity(hasAppeared ? 1 : 0)
                            .animation(.easeIn(duration: 0.4).delay(1.2), value: hasAppeared)
                    }
                }
                .padding(.horizontal, 30)
            }
            
            Spacer()

            // Buttons
            VStack(spacing: 24) {
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
                
                Button("I'm not Ready", action: cancelAction)
                    .font(.headline).fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 30)
            .padding(.bottom)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                healthKitManager.refreshStatus()
            }
        }
        .onAppear {
            hasAppeared = true
            healthKitManager.refreshStatus()
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
        let locationOK = locationManager.authorisationStatus != .notDetermined
        let healthOK = healthKitManager.authorisationStatus == .sharingAuthorized
        return locationOK && healthOK
    }
}


// MARK: - Helper Views

struct RiskWarningView: View {
    @State private var hasAppeared = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundStyle(.orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Important: Secure Your Phone")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text("At high speeds, a loose phone can slip and get damaged. Please carry it firmly.")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.15))
        .cornerRadius(12)
        .scaleEffect(hasAppeared ? 1.0 : 0.95)
        .onAppear {
            // A slight delay makes the pulse feel more intentional and separated
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.7)) {
                hasAppeared = true
            }
        }
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
                .background(.green.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading) {
                Text(title).font(.headline)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if status == .notDetermined {
                Button("Grant", action: action)
                    .buttonStyle(.bordered)
                    .tint(.accentColor)
            } else {
                Image(systemName: status.iconName)
                    .font(.title2).foregroundStyle(status.iconColour)
            }
        }
    }
}


// MARK: - Previews

struct GuideView_Previews: PreviewProvider {
    static var previews: some View {
        GuideView(workoutType: .cycling, requestAuth: true, continueAction: {}, cancelAction: {})
            .previewDisplayName("First Time Welcome")
        
        GuideView(workoutType: .walking, requestAuth: false, continueAction: {}, cancelAction: {})
            .previewDisplayName("New Workout Type Welcome")
        
        GuideView(workoutType: .running, requestAuth: false, continueAction: {}, cancelAction: {})
            .previewDisplayName("Running Welcome")
    }
}
