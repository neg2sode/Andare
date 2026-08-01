//
//  GyroHistoryPoint.swift
//  Andare
//
//  Created by neg2sode on 2026/8/1.
//

import Foundation

/// One sample in the sliding window that drives the live gyro charts.
struct GyroHistoryPoint: Identifiable {
    let id = UUID()
    let value: Double
}
