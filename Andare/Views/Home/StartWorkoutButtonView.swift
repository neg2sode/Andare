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
    
    // State to drive the continuous animation
    @State private var isAnimating: Bool = false
    @State private var currentHint: HintState = .tapToStart
    @State private var previousHint: HintState = .tapToStart
    @State private var timerTask: Task<Void, Never>?
    
    private enum HintState: CaseIterable {
        case tapToStart, swipeHint
    }
    
    var body: some View {
        VStack(spacing: 70) {
            // 1. The "hovering" text above the button
            bannerText
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
                .id(currentHint)
                .transition(transition(from: previousHint, to: currentHint))
            
            // 2. The main breathing button
            Button(action: {self.action(self.workoutType)}) {
                ZStack {
                    // The circular background
                    Circle()
                        .fill(Color.accentColor)
                        .shadow(radius: 10)
                    
                    // 3. The glyph, determined by the workout type
                    Image(systemName: workoutType.sfSymbolName)
                        .font(.system(size: 70, weight: .light))
                        .foregroundStyle(.white)
                }
            }
            .frame(width: 180, height: 180)
            // 4. The animation modifiers
            .scaleEffect(isAnimating ? 1.08 : 1.0) // A subtle 8% size increase
            .animation(
                .easeInOut(duration: 1.28).repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                // Start the animation when the view appears
                self.isAnimating = true
                startHintLoop()
            }
            .onChange(of: workoutType) {
                startHintLoop()
            }
        }
    }
    
    @ViewBuilder
    private var bannerText: some View {
        switch currentHint {
        case .tapToStart:
            Text("Tap to start a \(workoutType.title)")
        case .swipeHint:
            Text("Swipe for other workouts")
        }
    }
    
    private func transition(from: HintState, to: HintState) -> AnyTransition {
        // All other transitions are a push
        return .asymmetric(
            insertion: .push(from: .top),
            removal: .push(from: .bottom)
        ).animation(.easeInOut(duration: 0.3))
    }
    
    private func startHintLoop() {
        timerTask?.cancel() // Cancel any existing loop
        
        timerTask = Task {
            // Determine the starting state and loop order
            let hintSequence: [HintState] = [.tapToStart, .swipeHint]
            
            var currentIndex = 0
            
            // Set the initial state without animation
            self.currentHint = hintSequence[currentIndex]
            self.previousHint = hintSequence[currentIndex]
            
            while !Task.isCancelled {
                // Determine the duration for the current state
                let duration: TimeInterval = (currentHint == .tapToStart) ? 7.68 : 2.56
                
                do {
                    try await Task.sleep(for: .seconds(duration))
                } catch {
                    // The task was cancelled, so exit the loop
                    return
                }
                
                // Advance to the next state
                currentIndex = (currentIndex + 1) % hintSequence.count
                let nextHint = hintSequence[currentIndex]
                
                // Update state for the animation
                self.previousHint = self.currentHint
                withAnimation {
                    self.currentHint = nextHint
                }
            }
        }
    }
}


struct StartWorkoutButtonView_Previews: PreviewProvider {
    static var previews: some View {
        StartWorkoutButtonView(workoutType: .cycling, action: {_ in })
    }
}
