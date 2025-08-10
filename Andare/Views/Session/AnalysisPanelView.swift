//
//  AnalysisPanelView.swift
//  Andare
//
//  Created by neg2sode on 2025/8/10.
//

import SwiftUI
import Charts

struct AnalysisPanelView: View {
    let workoutType: WorkoutType

    var body: some View {
        VStack {
            Text("Analysis Panel")
            Text("Cadence: - RPM")
            Text("Spectrum Points: -")
        }
        .frame(height: 200) // Placeholder height
        .frame(maxWidth: .infinity)
        .cornerRadius(12)
    }
}

struct AnalysisPanelView_Previews: PreviewProvider {
    static var previews: some View {
        return AnalysisPanelView(workoutType: .cycling)
    }
}
