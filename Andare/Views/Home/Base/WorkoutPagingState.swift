//
//  WorkoutPagingState.swift
//  Andare
//
//  Created by neg2sode on 2025/7/20.
//

import Foundation
import SwiftUI

final class WorkoutPagingState: ObservableObject {
    @Published var selectedWorkoutType: WorkoutType = .cycling
    
    let allWorkoutTypes: [WorkoutType] = WorkoutType.allCases
    
    init() {
        let savedPreference = UserDefaults.standard.string(forKey: "preferredWorkoutType")
        self.selectedWorkoutType = WorkoutType(rawValue: savedPreference ?? "") ?? .cycling
    }
}
