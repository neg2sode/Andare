//
//  SessionState.swift
//  Andare
//
//  Created by neg2sode on 2025/5/26.
//

import Foundation

/// The home screen's workout session flow state.
enum SessionState: Equatable {
    case idle
    case awaitingPermission
    case guidePlacement(workoutType: WorkoutType, requestAuth: Bool)
    case guidePermissions(workoutType: WorkoutType)
    case countingDown(Int)
    case starting
    case active
    case summary(data: WorkoutData)
    case transitioning
}
