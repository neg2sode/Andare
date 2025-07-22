//
//  StartWorkoutButtonView.swift
//  Andare
//
//  Created by neg2sode on 2025/7/21.
//

import SwiftUI

struct StartWorkoutButtonView: View {
    let workoutType: WorkoutType
    let action: () -> Void
    
    // State to drive the continuous animation
    @State private var isAnimating: Bool = false
    
    var body: some View {
        VStack(spacing: 70) {
            // 1. The "hovering" text above the button
            Text("Start a \(workoutType.title)")
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            
            // 2. The main breathing button
            Button(action: self.action) {
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
            }
        }
    }
}

struct StartWorkoutButtonView_Previews: PreviewProvider {
    static var previews: some View {
        StartWorkoutButtonView(workoutType: .cycling, action: {})
    }
}
