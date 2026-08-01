//
//  VibrationManager.swift
//  Andare
//
//  Created by neg2sode on 2025/5/13.
//

import Foundation
import CoreHaptics

final class VibrationManager {
    static let shared = VibrationManager()
    private var engine: CHHapticEngine?

    func prepareHapticEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        if engine == nil || engine?.playsHapticsOnly == false {
            do {
                engine = try CHHapticEngine()
                // Set up engine handlers (optional but good practice)
                engine?.stoppedHandler = { reason in
                    print("VibrationManager: Haptic engine stopped for reason: \(reason.rawValue)")
                    // Attempt to restart if needed, or handle appropriately
                }
                engine?.resetHandler = { [weak self] in
                    do {
                        try self?.engine?.start()
                    } catch {
                        print("VibrationManager: Failed to restart haptic engine after reset: \(error)")
                    }
                }
                try engine?.start()
            } catch {
                print("VibrationManager: Error creating or starting haptic engine: \(error.localizedDescription)")
                engine = nil
            }
        }
    }

    func stopHapticEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        engine?.stop(completionHandler: { error in
            if let error = error {
                print("VibrationManager: Error stopping haptic engine: \(error.localizedDescription)")
            } else {
                self.engine = nil
            }
        })
    }

    // MARK: - Haptic Patterns

    func playPatternA() {
        guard let engine = engine, CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            // A short, sharp tap
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8)
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
            let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("VibrationManager: Error playing haptics: \(error.localizedDescription)")
        }
    }

    func playPatternB() {
        guard let engine = engine, CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            // Two short taps
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.9)
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
            let event1 = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
            let event2 = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0.2)
            let pattern = try CHHapticPattern(events: [event1, event2], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("VibrationManager: Error playing haptics: \(error.localizedDescription)")
        }
    }
    
    func playPatternC() {
        guard let engine = engine, CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            // A short, sharp tap
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5)
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
            let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("VibrationManager: Error playing haptics: \(error.localizedDescription)")
        }
    }
}
