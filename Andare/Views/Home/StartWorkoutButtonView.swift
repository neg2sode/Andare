//
//  StartWorkoutButtonView.swift
//  Andare
//
//  Created by neg2sode on 2025/7/21.
//

import SwiftUI
import Combine

struct StartWorkoutButtonView: View {
    let workoutType: WorkoutType
    let action: (WorkoutType) -> Void

    @State private var isAnimating = false
    @State private var currentHint: HintState = .tapToStart
    @State private var timer: Timer?
    
    private enum HintState {
        case tapToStart, swipeHint
    }

    private var bannerTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .top).combined(with: .opacity)
        )
    }

    var body: some View {
        VStack(spacing: 40) {
            ZStack {
                if currentHint == .tapToStart {
                    Text("Tap to start a \(workoutType.title)")
                        .font(.system(size: 25))
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                        .transition(bannerTransition)
                }

                if currentHint == .swipeHint {
                    Text("Swipe for other workouts")
                        .font(.system(size: 25))
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                        .transition(bannerTransition)
                }
            }
            .frame(height: 50)

            Button(action: { self.action(self.workoutType) }) {
                ZStack {
                    Circle()
                        .fill(Color.accentColor)
                        .shadow(radius: 10)

                    Image(systemName: workoutType.sfSymbolName)
                        .font(.system(size: 70, weight: .light))
                        .foregroundStyle(.white)
                }
            }
            .frame(width: 200, height: 200)
            .scaleEffect(isAnimating ? 1.08 : 1.0)
            .animation(
                .easeInOut(duration: 1.28).repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
                startHintLoop()
            }
            .onDisappear {
                timer?.invalidate()
            }
            .onChange(of: workoutType) {
                startHintLoop()
            }
        }
    }

    private func startHintLoop() {
        timer?.invalidate()
        
        // first schedule for tapToStart delay
        let interval = (currentHint == .tapToStart) ? 7.68 : 2.56
        
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                currentHint = (currentHint == .tapToStart ? .swipeHint : .tapToStart)
            }
            // restart loop with new interval
            startHintLoop()
        }
    }
}

struct StartWorkoutButtonView_Previews: PreviewProvider {
    static var previews: some View {
        StartWorkoutButtonView(workoutType: .cycling) { _ in }
    }
}
