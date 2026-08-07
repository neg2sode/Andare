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
    
    /// The window to show, chosen from the drawer title. This used to be decided
    /// here — the header rewrote itself between "Today's", "Recent" and "This
    /// Week's" depending on how many workouts existed, so the section silently
    /// disagreed with the rest of the drawer about what period it covered.
    let scope: DrawerScope

    private let rowHeight: CGFloat = 92

    private var workoutsToShow: [WorkoutDataModel] {
        let interval = scope.interval()
        return workouts.filter { interval.contains($0.startTime) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Workouts")
                .font(.title2)
                .fontWeight(.bold)

            if workoutsToShow.isEmpty {
                emptyStateView
            } else {
                workoutListView
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
    
    private var emptyStateView: some View {
        // Same dashed circle the cadence tile uses for its no-data state, so
        // the two empty sections read as one absence rather than two.
        ContentUnavailableView(
            scope == .today ? "No Workouts Yet Today" : "No Workouts Yet This Week",
            systemImage: "circle.dashed"
        )
        .padding(.vertical)
        .transition(.opacity)
    }
    
    private var workoutListView: some View {
        VStack(spacing: 8) {
            List {
                ForEach(workoutsToShow) { workout in
                    WorkoutThumbnailCardView(workout: workout) {
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
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .padding(.horizontal, 0)
                        .padding(.vertical, 5)
                }
            }
            .listStyle(.plain)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: workoutsToShow)
            .frame(height: rowHeight * CGFloat(workoutsToShow.count))
            .scrollDisabled(true)
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
