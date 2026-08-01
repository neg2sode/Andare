//
//  LongPressStopButton.swift
//  Andare
//
//  A stop button that requires a long press (~1.5s) to activate,
//  preventing accidental workout stops. Shows a filling progress
//  bar and scaling feedback while held. A quick tap nudges the bar
//  ~25% then animates it back, hinting that holding is the mechanic;
//  repeated taps yield diminishing nudges so the bar can't be "pumped".
//

import SwiftUI

struct LongPressStopButton: View {
    let onStop: () -> Void

    // MARK: - Configuration

    /// Duration (in seconds) the user must hold to trigger stop
    private let requiredHoldDuration: Double = 1.5

    /// How far the progress bar nudges on a quick tap (0…1)
    private let tapNudgeAmount: Double = 0.25

    /// How quickly repeated tap nudges shrink (multiplier per consecutive tap)
    private let nudgeDecay: Double = 0.5

    /// Minimum hold duration (seconds) to count as a "hold" vs a "tap"
    private let tapThreshold: Double = 0.2

    // MARK: - State

    @State private var holdProgress: Double = 0  // 0...1
    @State private var isHolding: Bool = false
    @State private var holdTask: Task<Void, Never>?
    @State private var hasTriggered: Bool = false
    @State private var buttonFrame: CGRect = .zero
    @State private var holdStartTime: Double = 0

    /// Tracks consecutive quick taps so the nudge shrinks over time
    @State private var consecutiveTaps: Int = 0
    @State private var tapDecayResetTask: Task<Void, Never>?

    /// Whether we're currently showing the tap-nudge hint
    @State private var isShowingTapHint: Bool = false

    /// Label text shown on the button
    @State private var labelText: String = "Hold to Stop"

    // MARK: - Derived

    private var buttonScale: Double {
        if isHolding {
            // Shrink slightly when pressed, then grow as it fills
            let pressedScale = 0.92
            let growAmount = 0.08 * holdProgress
            return pressedScale + growAmount
        }
        if isShowingTapHint {
            return 0.96  // Subtle press feedback on tap too
        }
        return 1.0
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background capsule (solid red when idle, lighter while filling)
            Capsule()
                .fill(Color.red.opacity(isHolding ? 0.7 : 1.0))
                .overlay {
                    // Progress fill from left to right
                    GeometryReader { geo in
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.red.opacity(0.9), Color(red: 0.85, green: 0.1, blue: 0.1)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * holdProgress)
                    }
                    .clipShape(Capsule())
                    .opacity(isHolding || isShowingTapHint ? 1 : 0)
                }

            // Label
            Text(labelText)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
                .animation(.easeInOut(duration: 0.15), value: labelText)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 58)
        .background {
            GeometryReader { geo in
                Color.clear.onAppear {
                    buttonFrame = geo.frame(in: .named("stopButton"))
                }
                .onChange(of: geo.size) { _, _ in
                    buttonFrame = geo.frame(in: .named("stopButton"))
                }
            }
        }
        .scaleEffect(buttonScale)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isHolding)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isShowingTapHint)
        .coordinateSpace(name: "stopButton")
        .gesture(holdGesture)
        .accessibilityLabel("Stop workout")
        .accessibilityHint("Double tap to stop the workout")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction {
            onStop()
        }
    }

    // MARK: - Gesture

    private var holdGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named("stopButton"))
            .onChanged { value in
                let padding: CGFloat = 40
                let hitArea = buttonFrame.insetBy(dx: -padding, dy: -padding)

                if !hitArea.contains(value.location) {
                    cancelHold()
                    return
                }

                if !isHolding && !hasTriggered && !isShowingTapHint {
                    startHold()
                }
            }
            .onEnded { _ in
                let elapsed = CACurrentMediaTime() - holdStartTime

                if elapsed < tapThreshold && !hasTriggered {
                    // Quick tap — show the nudge hint
                    cancelHold()
                    showTapHint()
                } else {
                    cancelHold()
                }
            }
    }

    // MARK: - Hold Logic

    private func startHold() {
        isHolding = true
        holdProgress = 0
        hasTriggered = false
        holdStartTime = CACurrentMediaTime()
        labelText = "Hold to Stop…"

        holdTask?.cancel()

        holdTask = Task { @MainActor in
            let start = CACurrentMediaTime()

            while !Task.isCancelled && isHolding && !hasTriggered {
                let elapsed = CACurrentMediaTime() - start
                holdProgress = min(1.0, elapsed / requiredHoldDuration)

                if holdProgress >= 1.0 {
                    triggerStop()
                    return
                }

                // ~60fps — cooperative yield, not a RunLoop timer
                try? await Task.sleep(nanoseconds: 16_000_000)
            }
        }
    }

    private func cancelHold() {
        guard !hasTriggered else { return }
        holdTask?.cancel()
        holdTask = nil
        isHolding = false
        labelText = "Hold to Stop"

        if !isShowingTapHint {
            withAnimation(.easeOut(duration: 0.3)) {
                holdProgress = 0
            }
        }
    }

    private func triggerStop() {
        hasTriggered = true
        holdTask?.cancel()
        holdTask = nil

        withAnimation(.easeInOut(duration: 0.15)) {
            holdProgress = 1.0
        }

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 200_000_000)
            onStop()
        }
    }

    // MARK: - Tap Hint

    /// Shows a quick progress nudge then shrinks it back, hinting "hold longer".
    private func showTapHint() {
        isShowingTapHint = true

        // Shrink the nudge for repeated taps
        let decayMultiplier = pow(nudgeDecay, Double(consecutiveTaps))
        let nudge = max(0.08, tapNudgeAmount * decayMultiplier)
        consecutiveTaps += 1

        // Reset consecutive-tap counter after 2s of inactivity
        tapDecayResetTask?.cancel()
        tapDecayResetTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            if !Task.isCancelled {
                consecutiveTaps = 0
            }
        }

        // Flash the label to coach the user
        labelText = "Keep holding!"

        // Animate progress up to the nudge amount
        withAnimation(.easeOut(duration: 0.15)) {
            holdProgress = nudge
        }

        // Then shrink it back after a brief pause
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 400_000_000) // 0.4s visible
            if !Task.isCancelled && !isHolding {
                withAnimation(.easeInOut(duration: 0.45)) {
                    holdProgress = 0
                }
                // Reset label after animation
                try? await Task.sleep(nanoseconds: 300_000_000)
                if !Task.isCancelled && !isHolding {
                    labelText = "Hold to Stop"
                    isShowingTapHint = false
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        Spacer()
        LongPressStopButton {}
            .padding(.horizontal, 30)
            .padding(.bottom, 40)
    }
}
