//
//  MotionPermissionManager.swift
//  Andare
//
//  Created by neg2sode on 2026/8/1.
//

import Foundation
import CoreMotion

/// Exposes the Motion & Fitness authorization state (barometer/CMAltimeter,
/// used for elevation tracking). CoreMotion has no explicit request API, so
/// "Grant" briefly starts altitude updates to trigger the system prompt.
@MainActor
final class MotionPermissionManager: ObservableObject {
    static let shared = MotionPermissionManager()

    @Published var authorisationStatus: CMAuthorizationStatus

    /// Whether the device has a barometer at all; the permission row is
    /// hidden when it doesn't (e.g. simulator, older devices).
    let isAvailable = CMAltimeter.isRelativeAltitudeAvailable()

    private let altimeter = CMAltimeter()

    init() {
        self.authorisationStatus = CMAltimeter.authorizationStatus()
    }

    func refreshStatus() {
        authorisationStatus = CMAltimeter.authorizationStatus()
    }

    func requestAuthorisation() {
        guard isAvailable else {
            refreshStatus()
            return
        }

        altimeter.startRelativeAltitudeUpdates(to: .main) { [weak self] _, _ in
            // First callback or error means the user has responded to the prompt.
            Task { @MainActor in
                guard let self else { return }
                self.altimeter.stopRelativeAltitudeUpdates()
                self.refreshStatus()
            }
        }

        // A denial may never fire the handler; re-check shortly after.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.refreshStatus()
        }
    }
}
