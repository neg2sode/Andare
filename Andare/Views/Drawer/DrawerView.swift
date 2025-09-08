//
//  DrawerView.swift
//  Andare
//
//  Created by neg2sode on 2025/7/2.
//

import SwiftUI

struct DrawerView: View {
    @State private var isShowingPreferences = false
    @State private var workoutsExpanded = false
    
    @StateObject var alertManager = AlertManager.shared
    
    @EnvironmentObject var drawerState: DrawerState
    @EnvironmentObject var pagingState: WorkoutPagingState

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Drawer Header
            HStack {
                Text("Andare Dev v1.8.0")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: { isShowingPreferences = true }) {
                    Image(systemName: "gearshape.fill")
                        .imageScale(.large)
                        .foregroundStyle(Color.accentColor)
                }
                .padding(.horizontal, 6)
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
            .padding(.top, 20)

            // MARK: - Scrollable Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    RecentWorkoutsView(isExpanded: $workoutsExpanded)
                    ArticlesView()
                    ContactMeView()
                }
            }
            .onChange(of: drawerState.selectedDetent) { _, newDetent in
                guard newDetent != .large else { return }
                withAnimation(.easeInOut(duration: 0.3)) {
                    workoutsExpanded = false
                }
            }
            
            // MARK: - Footnote
            if drawerState.selectedDetent == .large {
                Text("Made with ☕️ by neg2sode")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 8)
                    .transition(.opacity.animation(.easeInOut))
            } else {
                PageIndicatorView(
                    numberOfPages: pagingState.allWorkoutTypes.count,
                    currentPage: pagingState.allWorkoutTypes.firstIndex(of: pagingState.selectedWorkoutType) ?? 0
                )
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 8)
                .transition(.opacity.animation(.easeInOut))
            }
        }
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $isShowingPreferences) {
            PreferencesView()
                .presentationDetents([.fraction(0.7), .large])
                .presentationDragIndicator(.hidden)
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
