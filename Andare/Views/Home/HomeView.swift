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
    
    @StateObject var alertManager = AlertManager.shared
    @StateObject var locationManager = LocationManager.shared
    @StateObject var healthKitManager = HealthKitManager.shared
    
    @State private var isDrawerPresented = false
    @State private var isShowingLocationWarning = false
    @State private var sessionState: SessionState = .idle
    
    private let timer = Timer.publish(every: 1.28, on: .main, in: .common).autoconnect()
    
    @Environment(\.modelContext) private var modelContext
    
    @AppStorage("hasShownCyclingGuide") private var hasShownCyclingGuide: Bool = false
    @AppStorage("hasShownRunningGuide") private var hasShownRunningGuide: Bool = false
    @AppStorage("hasShownWalkingGuide") private var hasShownWalkingGuide: Bool = false
    
    private var isFirstGuideEver: Bool {
        return !hasShownCyclingGuide && !hasShownRunningGuide && !hasShownWalkingGuide
    }
    
    private func hasShownGuide(for workoutType: WorkoutType) -> Bool {
        switch workoutType {
            case .cycling: return hasShownCyclingGuide
            case .running: return hasShownRunningGuide
            case .walking: return hasShownWalkingGuide
        }
    }
    
    enum SessionState: Equatable {
        case idle
        case awaitingPermission
        case showingGuide(workoutType: WorkoutType, requestAuth: Bool)
        case countingDown(Int)
        case starting
        case active
        case summary(data: WorkoutData)
        case transitioning
        
        static func == (lhs: SessionState, rhs: SessionState) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.starting, .starting), (.active, .active), (.transitioning, .transitioning), (.awaitingPermission, .awaitingPermission):
                return true
            case (.showingGuide(let lType, let lAuth), .showingGuide(let rType, let rAuth)):
                return lType == rType && lAuth == rAuth
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
                if case .summary(let data) = self.sessionState {
                    return data
                }
                return nil
            },
            set: {
                // When the sheet is dismissed, its item is set to nil.
                // We transition our state to .transitioning.
                if $0 == nil {
                    self.sessionState = .transitioning
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
                switch sessionState {
                case .idle, .awaitingPermission:
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
                
                case .showingGuide(let workoutType, let requestAuth):
                    GuideView(
                        workoutType: workoutType,
                        requestAuth: requestAuth,
                        continueAction: {
                            handleGuideCompletion(for: workoutType)
                        },
                        cancelAction: {
                            withAnimation {
                                sessionState = .idle
                                isDrawerPresented = true
                            }
                        }
                    )
                    .transition(.opacity.animation(.easeInOut))
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
                sessionState = .idle
            }) { summaryData in
                WorkoutSummaryView(data: summaryData)
            }
            .onChange(of: rideSessionManager.locationAuthStatus) { oldStatus, newStatus in
                if oldStatus == .notDetermined {
                    switch newStatus {
                    case .authorizedWhenInUse, .authorizedAlways:
                        // This handles starting the ride automatically after location permissions are granted.
                        if sessionState == .awaitingPermission {
                            rideSessionManager.startRidePreparations()
                            proceedToCountdown()
                        }
                    case .denied, .restricted:
                        switch sessionState {
                        case .showingGuide(_, true):
                            isShowingLocationWarning = true
                        default:
                            break
                        }
                    default:
                        break
                    }
                }
            }
            .onChange(of: pagingState.selectedWorkoutType) { _, newType in
                rideSessionManager.configure(for: newType)
            }
        }
    }
    
    // MARK: - Subviews for Clarity
    
    private var idleView: some View {
        PagingCarousel(selection: $pagingState.selectedWorkoutType, pages: pagingState.allWorkoutTypes) { workoutType in
            StartWorkoutButtonView(
                workoutType: workoutType,
                action: startWorkoutSequence
            )
        }
    }
    
    private var activeRideView: some View {
        Group {
            StatsOverlayView(rideSessionManager: rideSessionManager)
                .frame(maxWidth: .infinity, alignment: .leading)
                .offset(y: -40)
          
            VStack {
                Spacer()
                Button(action: stopWorkout) {
                    Text("Stop Workout")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                }
                .background(Color.red)
                .cornerRadius(30)
                .shadow(radius: 5)
                .padding(.horizontal, 30)
                .padding(.bottom, 12)
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
            skipCountdownAndStartWorkout()
        }
    }
    
    // MARK: - State Transition Logic
    
    private func proceedToCountdown() {
        withAnimation {
            sessionState = .countingDown(5)
            isDrawerPresented = false
        }
    }
    
    private func handleGuideCompletion(for workoutType: WorkoutType) {
        switch workoutType {
            case .cycling: hasShownCyclingGuide = true
            case .running: hasShownRunningGuide = true
            case .walking: hasShownWalkingGuide = true
        }
        
        rideSessionManager.startRidePreparations()
        proceedToCountdown()
    }
    
    private func handleCountdown() {
        guard case .countingDown(let currentCount) = sessionState else { return }
        
        if currentCount <= 4 {
            VibrationManager.shared.playPatternC()
        }

        if currentCount > 1 {
            sessionState = .countingDown(currentCount - 1)
        } else {
            // Countdown finished, transition to the starting state and begin the async ride start.
            sessionState = .starting
            startWorkout()
        }
    }
    
    private func skipCountdownAndStartWorkout() {
        // This guard prevents this function from running more than once,
        // for example, if the user taps at the exact same moment the timer fires.
        guard case .countingDown = sessionState else { return }

        // Transition to the .starting state to show the stats view immediately.
        sessionState = .starting
        startWorkout()
    }

    private func startWorkout() {
        Task {
            await rideSessionManager.startRide()
            // After the async start completes, transition to the fully active state.
            sessionState = .active
        }
    }
    
    private func stopWorkout() {
        Task {
            if let summaryData = await rideSessionManager.stopRide(context: modelContext) {
                await MainActor.run {
                    sessionState = .summary(data: summaryData)
                    VibrationManager.shared.playPatternB()
                }
            } else {
                await MainActor.run {
                    // If stopping fails, go back to idle.
                    sessionState = .idle
                    VibrationManager.shared.playPatternA()
                    isDrawerPresented = true
                }
            }
        }
    }

    private func startWorkoutSequence(for workoutType: WorkoutType) {
        let hkWorkoutStatus = healthKitManager.authorisationStatus(for: HKObjectType.workoutType())
        
        guard hkWorkoutStatus != .sharingDenied else {
            alertManager.showAlert(
                title: "Workouts Permission Required",
                message: "Please enable Workouts Sharing in Settings → Privacy & Security → Health → Andare to start a workout."
            )
            return
        }
        
        let locationStatus = locationManager.authorisationStatus
        
        if !hasShownGuide(for: workoutType) {
            if isFirstGuideEver || locationStatus == .notDetermined {
                sessionState = .showingGuide(workoutType: workoutType, requestAuth: true)
            } else {
                sessionState = .showingGuide(workoutType: workoutType, requestAuth: false)
            }
            isDrawerPresented = false
            return
        }

        if locationStatus == .notDetermined {
            sessionState = .awaitingPermission
            locationManager.requestAuthorisation()
            return
        }
        
        rideSessionManager.startRidePreparations()
        proceedToCountdown()
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
                    
                    Text("Lock your screen safely\nStarting workout in no time")
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
