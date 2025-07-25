//
//  RecentWorkoutsView.swift
//  Andare
//
//  Created by neg2sode on 2025/7/9.
//

import SwiftUI
import SwiftData

struct RecentWorkoutsView: View {
    @Query(
        filter: #Predicate<WorkoutDataModel> { workout in
            return workout.managementState == 0 // visible
        },
        sort: \.startTime, order: .reverse
    ) private var workouts: [WorkoutDataModel]
    
    @Environment(\.modelContext) private var modelContext

    @State private var selectedWorkoutData: WorkoutData?
    @State private var workoutToDelete: WorkoutDataModel?
    @State private var isShowingDeleteConfirm = false
    
    @Binding var isExpanded: Bool
    private let rowHeight: CGFloat = 92
    
    private var workoutsInLastWeek: [WorkoutDataModel] {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: startOfToday)!

        return workouts.filter {
            $0.startTime >= sevenDaysAgo
        }
    }
    
    private var todaysWorkouts: [WorkoutDataModel] {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday)!

        return workouts.filter {
            $0.startTime >= startOfToday && $0.startTime < startOfTomorrow
        }
    }
    
    private var collapsedWorkouts: [WorkoutDataModel] {
        if todaysWorkouts.count >= 3 {
            return todaysWorkouts
        } else {
            return Array(workoutsInLastWeek.prefix(3))
        }
    }
    
    private var fullWorkouts: [WorkoutDataModel] {
        // always expand into the past‑week set
        workoutsInLastWeek
    }
    
    private var workoutsToShow: [WorkoutDataModel] {
        isExpanded ? fullWorkouts : collapsedWorkouts
    }
    
    private var shouldShowMoreButton: Bool {
        !isExpanded && collapsedWorkouts.count < fullWorkouts.count
    }
    
    private var workoutsHeaderTitle: String {
        if isExpanded {
            return "This Week's Workouts"
        } else {
            // collapsed
            if todaysWorkouts.count >= 3 {
                return "Today's Workouts"
            } else {
                return "Recent Workouts"
            }
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(workoutsHeaderTitle)
                    .font(.title)
                    .fontWeight(.bold)
                Spacer()
            }
            
            if workoutsInLastWeek.isEmpty {
                ContentUnavailableView("No Workouts Yet This Week", systemImage: "figure.run.circle")
                    .padding(.vertical)
                    .transition(.opacity)
            } else {
                VStack(spacing: 8) {
                    List {
                        ForEach(workoutsToShow) { workout in
                            WorkoutThumbnailCardView(workout: workout)
                                .onTapGesture {
                                    self.selectedWorkoutData = WorkoutData(from: workout)
                                }
                                .contextMenu {
                                    contextMenuButtons(for: workout)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        updateWorkout(workout, to: .hidden)
                                    } label: {
                                        Label("Hide", systemImage: "eye.slash.fill")
                                    }
                                    .tint(.blue) // Use a distinct color for Hide
                                }
                                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                    Button {
                                        self.workoutToDelete = workout
                                        self.isShowingDeleteConfirm = true
                                    } label: {
                                        Label("Delete", systemImage: "trash.fill")
                                    }
                                    .tint(.red)
                                }
                                .listRowInsets(EdgeInsets())
                                .listRowSeparator(.hidden)
                                .padding(.horizontal, 1)
                                .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.plain)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: workoutsToShow)
                    .frame(height: rowHeight * CGFloat(workoutsToShow.count))
                    .scrollDisabled(true)
                    
                    if shouldShowMoreButton {
                        Button("Show More") {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isExpanded = true
                            }
                        }
                        .fontWeight(.semibold)
                        .contentShape(Rectangle())
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }
                }
            }
        }
        .padding(.horizontal)
        .sheet(item: $selectedWorkoutData) { data in
            WorkoutSummaryView(data: data)
        }
        .alert(
            "Delete Workout Data",
            isPresented: $isShowingDeleteConfirm,
            presenting: workoutToDelete
        ) { workout in
            // This is the action for the "Delete" button inside the alert
            Button("Delete", role: .destructive) {
                updateWorkout(workout, to: .excluded)
            }
            // A "Cancel" button is added automatically, but we can be explicit
            Button("Cancel", role: .cancel) { }
        } message: { workout in
            Text("Do you want to delete this workout record? This will affect your summaries and cannot be undone.")
        }
    }
    
    @ViewBuilder
    private func contextMenuButtons(for workout: WorkoutDataModel) -> some View {
        Button {
            updateWorkout(workout, to: .hidden)
        } label: {
            Label("Hide", systemImage: "eye.slash")
        }
        
        Button(role: .destructive) {
            updateWorkout(workout, to: .excluded)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
    
    private func updateWorkout(_ workout: WorkoutDataModel, to newState: WorkoutManagementState) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            workout.updateManagementState(to: newState)
            try? modelContext.save()
        }
    }
}
