//
//  WorkoutPagingState.swift
//  Andare
//
//  Created by neg2sode on 2025/7/20.
//

import Foundation
import SwiftUI

final class WorkoutPagingState: ObservableObject {
    @AppStorage("preferredWorkoutType") var selectedWorkoutType: WorkoutType = .cycling
    
    let allWorkoutTypes: [WorkoutType] = WorkoutType.allCases
}
