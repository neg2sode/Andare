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

    @State private var isAnimating = false

    // semantic state: which hint is logically current
    @State private var logicalHint: HintState = .tapToStart

    // visual states for each banner (we control these explicitly)
    @State private var tapOpacity: Double = 1.0
    @State private var tapOffset: CGFloat = 0.0
    @State private var tapZ: Double = 0

    @State private var swipeOpacity: Double = 0.0
    @State private var swipeOffset: CGFloat = 20.0
    @State private var swipeZ: Double = -1

    @State private var hintTask: Task<Void, Never>? = nil

    private enum HintState {
        case tapToStart, swipeHint
    }

    // ---- tune these ----
    private let tapInterval: Double = 7.68
    private let swipeInterval: Double = 2.56

    // outgoing/incoming durations (can differ)
    private let outDuration: Double = 0.2
    private let inDuration: Double = 0.25

    // distances
    private let outOffset: CGFloat = -28   // outgoing shifts up
    private let inStartOffset: CGFloat = 28 // incoming starts below

    var body: some View {
        VStack(spacing: 40) {
            ZStack {
                // TAP banner (we always render both but drive visual state)
                Text("Tap to start a \(workoutType.title)")
                    .font(.system(size: 25))
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                    .opacity(tapOpacity)
                    .offset(y: tapOffset)
                    .zIndex(tapZ)
                
                // SWIPE banner
                Text("Swipe for other workouts")
                    .font(.system(size: 25))
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                    .opacity(swipeOpacity)
                    .offset(y: swipeOffset)
                    .zIndex(swipeZ)
            }
            .frame(height: 56)
            .clipped()
            
            ZStack {
                if #available(iOS 26.0, *) {
                    Button(action: { self.action(self.workoutType) }) {
                        Image(systemName: workoutType.sfSymbolName)
                            .font(.system(size: 70, weight: .light))
                            .foregroundStyle(.white)
                            .frame(maxWidth: 170, maxHeight: 180)
                    }
                    .buttonStyle(.glassProminent)
                    .shadow(radius: 8)
                } else {
                    Button(action: { self.action(self.workoutType) }) {
                        ZStack {
                            Circle()
                                .fill(Color.accentColor)
                                .shadow(radius: 8)
                            
                            Image(systemName: workoutType.sfSymbolName)
                                .font(.system(size: 70, weight: .light))
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(width: 200, height: 200)
                }
            }
            .scaleEffect(isAnimating ? 1.08 : 1.0)
            .animation(.easeInOut(duration: 1.28).repeatForever(autoreverses: true), value: isAnimating)
            .onAppear {
                isAnimating = true
                startHintLoop()
            }
            .onDisappear {
                hintTask?.cancel()
                hintTask = nil
            }
            .onChange(of: workoutType) {
                startHintLoop()
            }
        }
        .onAppear {
            // ensure initial visual state is consistent for logicalHint == .tapToStart
            syncVisualsToLogical()
        }
    }

    // ensure visuals match logical starting state
    private func syncVisualsToLogical() {
        if logicalHint == .tapToStart {
            tapOpacity = 1.0; tapOffset = 0.0; tapZ = 1
            swipeOpacity = 0.0; swipeOffset = inStartOffset; swipeZ = 0
        } else {
            tapOpacity = 0.0; tapOffset = inStartOffset; tapZ = 0
            swipeOpacity = 1.0; swipeOffset = 0.0; swipeZ = 1
        }
    }

    private func startHintLoop() {
        hintTask?.cancel()

        // ensure visuals are consistent at start
        syncVisualsToLogical()

        hintTask = Task {
            while !Task.isCancelled {
                // wait the correct interval for the currently visible hint
                let interval = (logicalHint == .tapToStart) ? tapInterval : swipeInterval
                try? await Task.sleep(for: .seconds(interval))

                // Hard-coded cases: handle tap -> swipe and swipe -> tap explicitly
                if logicalHint == .tapToStart {
                    // CASE A: tapToStart -> swipeHint
                    // 1) animate tap exiting (slide up + fade)
                    withAnimation(.easeInOut(duration: outDuration)) {
                        tapOpacity = 0.0
                        tapOffset = outOffset
                        tapZ = 0
                    }
                    // prepare swipe initial state (below, invisible) BEFORE showing it
                    swipeOpacity = 0.0
                    swipeOffset = inStartOffset
                    swipeZ = 2 // bring incoming above outgoing while animating in
                    // wait for outgoing to finish
                    try? await Task.sleep(for: .seconds(outDuration))

                    // 2) set semantic state and animate swipe in from below (fade + move)
                    logicalHint = .swipeHint
                    withAnimation(.easeInOut(duration: inDuration)) {
                        swipeOpacity = 1.0
                        swipeOffset = 0.0
                        swipeZ = 1
                    }
                    // ensure tap is reset below for next time (optional)
                    try? await Task.sleep(for: .seconds(inDuration))
                    tapOffset = inStartOffset
                    tapZ = 0
                } else {
                    // CASE B: swipeHint -> tapToStart
                    // 1) animate swipe exiting (slide up + fade)
                    withAnimation(.easeInOut(duration: outDuration)) {
                        swipeOpacity = 0.0
                        swipeOffset = outOffset
                        swipeZ = 0
                    }
                    // prepare tap initial state (below, invisible)
                    tapOpacity = 0.0
                    tapOffset = inStartOffset
                    tapZ = 2
                    // wait for outgoing to finish
                    try? await Task.sleep(for: .seconds(outDuration))

                    // 2) semantic swap + animate tap in
                    logicalHint = .tapToStart
                    withAnimation(.easeInOut(duration: inDuration)) {
                        tapOpacity = 1.0
                        tapOffset = 0.0
                        tapZ = 1
                    }
                    try? await Task.sleep(for: .seconds(inDuration))
                    swipeOffset = inStartOffset
                    swipeZ = 0
                }
            }
        }
    }
}

struct StartWorkoutButtonView_Previews: PreviewProvider {
    static var previews: some View {
        StartWorkoutButtonView(workoutType: .cycling) { _ in }
    }
}
