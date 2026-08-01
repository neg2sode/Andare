//
//  GuidePlacementView.swift
//  Andare
//
//  Screen 1 of the guide: phone placement for the chosen workout type.
//

import SwiftUI

struct WorkoutGuidance {
    let points: [String]

    static func forType(_ type: WorkoutType) -> WorkoutGuidance {
        switch type {
        case .cycling:
            return .init(
                points: [
                    "Tuck your phone tightly in a hip pocket or waistband.",
                    "Cadence is detected from your body's rotation — backpacks or mounts won't work."
                ]
            )
        case .running:
            return .init(
                points: [
                    "Place your phone in a hip pocket or waistband.",
                    "Alternatively, hold your phone firmly in your hand."
                ]
            )
        case .walking:
            return .init(
                points: [
                    "Any stable spot works well.",
                    "A pocket, waistband, or carrying it in your hand are all great options."
                ]
            )
        }
    }
}

struct GuidePlacementView: View {
    let workoutType: WorkoutType
    let continueAction: () -> Void
    let cancelAction: () -> Void

    @State private var hasAppeared = false
    @State private var bounceIcon = false
    @State private var rotatePhone = false

    let bounceTimer = Timer.publish(every: 1.28, on: .main, in: .common).autoconnect()
    let rotateTimer = Timer.publish(every: 2.4, on: .main, in: .common).autoconnect()

    private var guidance: WorkoutGuidance {
        .forType(workoutType)
    }

    var body: some View {
        GuideCardScaffold {
            VStack(alignment: .leading, spacing: 0) {
                Text("For \(workoutType.title)")
                    .font(.largeTitle).fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 24)
                    .opacity(hasAppeared ? 1 : 0)
                    .animation(.easeIn(duration: 0.3), value: hasAppeared)

                // Animation area - workout icon with iPhone
                animationSection
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .padding(.bottom, 48)

                placementSection

                if workoutType != .walking {
                    RiskWarningView()
                        .padding(.top, 48)
                        .opacity(hasAppeared ? 1 : 0)
                        .animation(.easeIn(duration: 0.4).delay(0.5), value: hasAppeared)
                }
            }
        } footer: {
            VStack(spacing: 24) {
                Button("Continue", action: continueAction)
                    .buttonStyle(PrimaryButtonStyle(radius: 30))

                Button("I'm Not Ready", action: cancelAction)
                    .font(.headline).fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .opacity(hasAppeared ? 1 : 0)
            .animation(.easeIn(duration: 0.4).delay(0.6), value: hasAppeared)
        }
        .onReceive(bounceTimer) { _ in
            guard hasAppeared else { return }
            bounceIcon.toggle()
        }
        .onReceive(rotateTimer) { _ in
            guard hasAppeared else { return }
            rotatePhone.toggle()
        }
        .onAppear {
            hasAppeared = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                bounceIcon = true
                rotatePhone = true
            }
        }
    }

    // MARK: - Animation Section

    private var animationSection: some View {
        ZStack {
            // Bouncing workout icon
            Image(systemName: workoutType.sfSymbol)
                .font(.system(size: 120))
                .foregroundStyle(Color.accentColor.opacity(0.3))
                .symbolEffect(.bounce, value: bounceIcon)

            // iPhone positioned at hip area with rotate animation
            Image(systemName: "iphone")
                .font(.system(size: 30))
                .foregroundStyle(Color.accentColor)
                .symbolEffect(.rotate, value: rotatePhone)
                .offset(phoneOffset)
        }
        .opacity(hasAppeared ? 1 : 0)
        .scaleEffect(hasAppeared ? 1 : 0.9)
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1), value: hasAppeared)
    }

    /// iPhone position relative to workout figure
    private var phoneOffset: CGSize {
        switch workoutType {
        case .cycling:
            return CGSize(width: -10, height: -13)
        case .running:
            return CGSize(width: 50, height: -18)
        case .walking:
            return CGSize(width: 7, height: 30)
        }
    }

    // MARK: - Placement Section

    private var placementSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "iphone")
                    .font(.headline)
                    .foregroundStyle(Color.accentColor)

                Text("Phone Placement")
                    .font(.headline)
            }
            .opacity(hasAppeared ? 1 : 0)
            .animation(.easeIn(duration: 0.3).delay(0.2), value: hasAppeared)

            ForEach(Array(guidance.points.enumerated()), id: \.offset) { index, point in
                Label(point, systemImage: "checkmark.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared ? 0 : 10)
                    .animation(
                        .easeOut(duration: 0.4).delay(0.3 + Double(index) * 0.1),
                        value: hasAppeared
                    )
            }
        }
    }
}

// MARK: - Risk Warning

struct RiskWarningView: View {
    @State private var hasAppeared = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("Secure Your Phone")
                    .font(.headline)
                    .fontWeight(.bold)

                Text("At high speeds, a loose phone can slip and get damaged. Please carry it firmly.")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .scaleEffect(hasAppeared ? 1.0 : 0.95)
        .onAppear {
            // A slight delay makes the pulse feel more intentional and separated
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.5)) {
                hasAppeared = true
            }
        }
    }
}

// MARK: - Previews

#Preview("Cycling") {
    GuidePlacementView(workoutType: .cycling, continueAction: {}, cancelAction: {})
}

#Preview("Running") {
    GuidePlacementView(workoutType: .running, continueAction: {}, cancelAction: {})
}

#Preview("Walking") {
    GuidePlacementView(workoutType: .walking, continueAction: {}, cancelAction: {})
}
