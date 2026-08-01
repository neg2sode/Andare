//
//  StartWorkoutButtonView.swift
//  Andare
//
//  Created by neg2sode on 2025/7/21.
//

import SwiftUI

struct StartWorkoutButtonView: View {
    let workoutType: WorkoutType
    let action: (WorkoutType) -> Void

    @State private var visibleHintIndex: Int = 0

    private let displayDuration: Double = 4.0
    private let fadeDuration: Double = 0.3
    private let hintCount: Int = 2

    var body: some View {
        VStack(spacing: 40) {
            // Hints stacked, only one visible at a time
            ZStack {
                Text("Tap to start a \(workoutType.title)")
                    .font(.title3.weight(.semibold))
                    .opacity(visibleHintIndex == 0 ? 1 : 0)

                Text("Swipe for other workouts")
                    .font(.title3.weight(.semibold))
                    .opacity(visibleHintIndex == 1 ? 1 : 0)
            }
            .frame(height: 32)
            .animation(.easeInOut(duration: fadeDuration), value: visibleHintIndex)

            startButton
                .onChange(of: workoutType) { _, _ in
                    visibleHintIndex = 0
                }
        }
        .task(id: workoutType) {
            await runHintCycle()
        }
    }

    private func runHintCycle() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(displayDuration))

            guard !Task.isCancelled else { break }

            visibleHintIndex = (visibleHintIndex + 1) % hintCount
        }
    }

    // MARK: - Start Button

    // Uses TimelineView for reliable perpetual breathing animation.
    // PhaseAnimator (and repeatForever state animations) can misbehave when
    // views are removed from the hierarchy (e.g. TabView page recycling),
    // so we derive the scale from the clock instead.
    private var startButton: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            // Sine wave: oscillates between 1.0 and 1.08 with 1.2s period
            let scale = 1.0 + 0.08 * ((sin(time * .pi / 1.2) + 1.0) / 2.0)

            Button(action: { self.action(self.workoutType) }) {
                ZStack {
                    buttonShape
                        .fill(Color.accentColor.gradient)
                        .shadow(color: Color.accentColor.opacity(0.4), radius: 20, y: 10)

                    Image(systemName: workoutType.sfSymbol)
                        .font(.system(size: 70, weight: .light))
                        .foregroundStyle(.white)
                }
            }
            .frame(width: 200, height: 200)
            .scaleEffect(scale)
            .accessibilityLabel("Start \(workoutType.title)")
        }
    }

    private var buttonShape: AnyShape {
        switch workoutType {
        case .cycling: AnyShape(CyclingButtonShape())
        case .running: AnyShape(RunningButtonShape())
        case .walking: AnyShape(WalkingButtonShape())
        }
    }
}

#Preview {
    StartWorkoutButtonView(workoutType: .cycling) { _ in }
}
