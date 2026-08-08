//
//  DrawerView.swift
//  Andare
//
//  Created by neg2sode on 2025/7/2.
//

import SwiftUI

struct DrawerView: View {
    @State private var isShowingPreferences = false
    @State private var gearIsRotating = false

    /// The window every section below describes. Deliberately not persisted —
    /// the drawer is a "what's happening now" surface, and coming back to a
    /// week view days later would be a confusing thing to land on.
    @State private var scope: DrawerScope = .today

    @ObservedObject private var alertManager = AlertManager.shared

    @AppStorage(WeekStart.storageKey) private var weekStart: WeekStart = .system

    @Binding var drawerDetent: PresentationDetent
    @EnvironmentObject var pagingState: WorkoutPagingState

    private var isExpanded: Bool { drawerDetent == .large }

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Drawer Header
            HStack {
                scopeTitle

                Spacer()
                
                Button(action: { isShowingPreferences = true }) {
                    Image(systemName: "gearshape.fill")
                        .imageScale(.large)
                        .foregroundStyle(Color.accentColor)
                        .rotationEffect(.degrees(gearIsRotating ? 360 : 0))
                        .animation(
                            Animation.linear(duration: 10.24)
                                .repeatForever(autoreverses: false),
                            value: gearIsRotating
                        )
                }
                .padding(.horizontal, 6)
                .accessibilityLabel("Preferences")
                .onAppear {
                    gearIsRotating = true
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 10)
            .padding(.top, 36)

            // MARK: - Scrollable Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    DrawerTileGrid(scope: scope)
                    RecentWorkoutsView(scope: scope)
                    ArticlesView()
                    ContactMeView()
                }
            }
            .onChange(of: drawerDetent) { _, newDetent in
                // The drawer already forgets its state when it closes; scope
                // follows the same rule, so the collapsed bar over the home
                // screen always reads as today's date.
                guard newDetent != .large else { return }
                withAnimation(.easeInOut(duration: 0.3)) {
                    scope = .today
                }
            }

            // MARK: - Footnote
            if drawerDetent == .large {
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

    /// The drawer title doubles as the scope control — but only once the drawer
    /// is open. Collapsed, this bar is 100pt tall and is what the user taps and
    /// drags to expand; a `Menu` there would swallow that tap, and nothing it
    /// changed would be on screen to see.
    @ViewBuilder
    private var scopeTitle: some View {
        if isExpanded {
            Menu {
                ForEach(DrawerScope.allCases) { option in
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) { scope = option }
                    } label: {
                        HStack {
                            Text(option.menuLabel)
                            if scope == option {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    titleText

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .layoutPriority(1)
                }
            }
            .tint(.primary)
            .accessibilityLabel("Time period")
            .accessibilityValue(scope.menuLabel)
            .accessibilityHint("Changes the period the drawer describes")
        } else {
            titleText
        }
    }

    /// A week title carries a date range, which is long enough to wrap onto a
    /// second line and drag the chevron out of alignment. Scaling down beats
    /// wrapping for a header that has to share its row with two controls.
    private var titleText: some View {
        Text(scope.title(calendar: weekStart.calendar))
            .font(.largeTitle)
            .fontWeight(.bold)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
    }
}
