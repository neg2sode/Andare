//
//  HomeView.swift
//  Andare
//
//  Created by neg2sode on 2025/5/26.
//

import SwiftUI
import HealthKit
import Combine
import SwiftData

struct HomeView: View {
    @StateObject private var rideSessionManager: RideSessionManager
    @StateObject private var drawerState = DrawerState()
    @StateObject private var pagingState: WorkoutPagingState
    @StateObject private var healthKitManager = HealthKitManager()
    @StateObject private var alertManager = AlertManager()
    
    @State private var isDrawerPresented = false
    @State private var isShowingLocationWarning = false
    @State private var rideState: RideFlowState = .idle
    
    private let timer = Timer.publish(every: 1.2, on: .main, in: .common).autoconnect()
    
    @Environment(\.modelContext) private var modelContext
    
    enum RideFlowState: Equatable {
        case idle
        case countingDown(Int)
        case starting
        case active
        case summary(data: WorkoutData)
        case transitioning
        
        static func == (lhs: RideFlowState, rhs: RideFlowState) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.starting, .starting), (.active, .active), (.transitioning, .transitioning):
                return true
            case (.countingDown(let l), .countingDown(let r)):
                return l == r
            case (.summary(let l), .summary(let r)):
                return l.id == r.id // Compare by ID
            default:
                return false
            }
        }
    }
    
    private var summaryBinding: Binding<WorkoutData?> {
        Binding<WorkoutData?>(
            get: {
                // The sheet should be presented if our state is .summary
                if case .summary(let data) = self.rideState {
                    return data
                }
                return nil
            },
            set: {
                // When the sheet is dismissed, its item is set to nil.
                // We transition our state to .transitioning.
                if $0 == nil {
                    self.rideState = .transitioning
                }
            }
        )
    }
    
    init() {
        let pagingState = WorkoutPagingState()
        let rideManager = RideSessionManager(workoutType: pagingState.selectedWorkoutType)
        
        self._pagingState = StateObject(wrappedValue: pagingState)
        self._rideSessionManager = StateObject(wrappedValue: rideManager)
    }
    
    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // The switch statement ensures only one view is shown at a time,
                // based on the explicit `rideState`.
                switch rideState {
                case .idle:
                    idleView
                        .transition(.opacity.animation(.easeInOut(duration: 0.5)))
                
                case .summary, .transitioning:
                    idleView.disabled(true)
                        .transition(.opacity.animation(.easeInOut(duration: 0.5)))
                    
                case .countingDown(let count):
                    countdownView(count: count)
                        .transition(.opacity)
                    
                case .starting, .active:
                    activeRideView
                        .transition(.opacity.animation(.easeInOut(duration: 0.5)))
                }
            }
            .drawerSheet(isPresented: $isDrawerPresented, drawerState: drawerState) {
                DrawerView()
                    .environmentObject(drawerState)
                    .environmentObject(pagingState)
                    .modelContainer(for: [WorkoutDataModel.self, CadenceSegmentModel.self])
            }
            .onAppear {
                Task { @MainActor in
                    isDrawerPresented = true
                }
            }
            .onReceive(timer) { _ in
                handleCountdown()
            }
            .sheet(isPresented: $isShowingLocationWarning) {
                LocationWarningDetailView()
            }
            .sheet(item: summaryBinding, onDismiss: {
                isDrawerPresented = true
                rideSessionManager.resetSessionState()
                // transition to the .idle state and unlock the UI
                rideState = .idle
            }) { summaryData in
                WorkoutSummaryView(data: summaryData)
            }
            .onChange(of: rideSessionManager.locationAuthStatus) { oldStatus, newStatus in
                // This handles starting the ride automatically after location permissions are granted.
                if oldStatus == .notDetermined {
                    switch newStatus {
                    case .authorizedWhenInUse, .authorizedAlways:
                        startRideSequence()
                    case .denied, .restricted:
                        isShowingLocationWarning = true
                    default:
                        break
                    }
                }
            }
            .onChange(of: pagingState.selectedWorkoutType) { _, newType in
                rideSessionManager.configure(for: newType)
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
    }
    
    // MARK: - Subviews for Clarity
    
    private var idleView: some View {
        PagingCarousel(selection: $pagingState.selectedWorkoutType, pages: pagingState.allWorkoutTypes) { workoutType in
            StartWorkoutButtonView(
                workoutType: workoutType,
                action: startRideSequence
            )
        }
    }
    
    private var activeRideView: some View {
        Group {
            StatsOverlayView(rideSessionManager: rideSessionManager)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                
            VStack {
                Spacer()
                Button(action: stopRide) {
                    Text("Stop Ride")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .background(Color.red)
                .cornerRadius(24)
                .shadow(radius: 5)
                .padding(.horizontal)
                .padding(.bottom, 0)
            }
        }
    }
    
    private func countdownView(count: Int) -> some View {
        ZStack {
            // The nudge view is always present during the countdown.
            LockScreenNudgeView()
                .padding(.trailing, 20)
                .offset(y: -160)
                .transition(.opacity.animation(.easeIn(duration: 0.5)))
            
            // The number is layered on top only for the final 3 seconds.
            if count <= 3 {
                Text(String(count))
                    .font(.system(size: 150, weight: .bold, design: .rounded))
                    .foregroundStyle(.accent)
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .onTapGesture {
            skipCountdownAndStartRide()
        }
    }
    
    // MARK: - State Transition Logic
    
    private func handleCountdown() {
        guard case .countingDown(let currentCount) = rideState else { return }
        
        if currentCount <= 4 {
            VibrationManager.shared.playPatternC()
        }

        if currentCount > 1 {
            rideState = .countingDown(currentCount - 1)
        } else {
            // Countdown finished, transition to the starting state and begin the async ride start.
            rideState = .starting
            startRide()
        }
    }
    
    private func skipCountdownAndStartRide() {
        // This guard prevents this function from running more than once,
        // for example, if the user taps at the exact same moment the timer fires.
        guard case .countingDown = rideState else { return }

        // Transition to the .starting state to show the stats view immediately.
        rideState = .starting
        startRide()
    }

    private func startRide() {
        Task {
            await rideSessionManager.startRide()
            // After the async start completes, transition to the fully active state.
            rideState = .active
        }
    }
    
    private func stopRide() {
        Task {
            if let summaryData = await rideSessionManager.stopRide(context: modelContext) {
                await MainActor.run {
                    rideState = .summary(data: summaryData)
                    VibrationManager.shared.playPatternB()
                }
            } else {
                await MainActor.run {
                    // If stopping fails, go back to idle.
                    rideState = .idle
                    VibrationManager.shared.playPatternA()
                    isDrawerPresented = true
                }
            }
        }
    }

    private func startRideSequence() {
        Task {
            do {
                try await healthKitManager.requestAuthorisation()
                
                await MainActor.run {
                    let workoutType = HKObjectType.workoutType()
                    guard healthKitManager.authorisationStatus(for: workoutType) == .sharingAuthorized else {
                        alertManager.showAlert(
                            title: "Workouts Permission Required",
                            message: "Andare needs permission to save Workouts in Health to track rides reliably. Please enable Workouts Sharing in Settings > Privacy & Security > Health > Andare."
                        )
                        return
                    }
                    
                    let locationStatus = rideSessionManager.locationAuthStatus
                    
                    switch locationStatus {
                    case .authorizedWhenInUse, .authorizedAlways, .denied, .restricted:
                        // Warm up sensors immediately, then start the UI countdown.
                        rideSessionManager.startRidePreparations()
                        withAnimation {
                            rideState = .countingDown(5)
                            isDrawerPresented = false
                        }
                    case .notDetermined:
                        rideSessionManager.locationManager.requestAuthorisation()
                    @unknown default:
                        alertManager.showAlert(
                            title: "Location Status Unknown",
                            message: "Could not determine location status. Attempting to start ride anyway."
                        )
                        startRide()
                        withAnimation {
                            isDrawerPresented = false
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    alertManager.showAlert(title: "HealthKit Error", message: "Could not request HealthKit permissions. \(error.localizedDescription)")
                }
            }
        }
    }
}

struct LockScreenNudgeView: View {
    @State private var isJumping = false
    
    var body: some View {
        ZStack {
            HStack {
                Spacer()
                VStack(alignment: .trailing, spacing: 16) {
                    Image(systemName: "arrow.right.to.line.compact")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundStyle(.primary)
                        .offset(x: isJumping ? 10 : 0)
                    
                    Text("Lock your screen\nPut iPhone in pocket")
                        .font(.title3)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                isJumping = true
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
