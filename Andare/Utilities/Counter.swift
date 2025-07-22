//
//  Counter.swift
//  Andare
//
//  Created by neg2sode on 2025/7/4.
//

import Foundation
import CoreLocation

struct Counter {
    var lowCadence = 0
    var highCadence = 0
    var uphill = 0
    var uphillBad = 0
    var inactive = 0
    var inactiveOrSlow = 0
    var total = 0
    var split = 0
    
    mutating func update(zone: CadenceZone, activity: MovementActivity, trend: SpeedTrend, gradient: TerrainGradient) {
        total += 1
        
        if activity != .fast {
            inactiveOrSlow += 1
            if activity != .slow {
                inactive += 1
            }
        }
        
        if gradient == .ascending {
            uphill += 1
            if zone == .low {
                lowCadence += 1
                uphillBad += 1
            } else if zone == .high {
                highCadence += 1
                if activity == .slow {
                    uphillBad += 1
                }
            }
        } else if gradient != .descending {
            if zone == .low {
                if activity == .fast && trend != .decelerating {
                    lowCadence += 1
                }
            } else if zone == .high {
                highCadence += 1
            }
        }
    }
    
    func judgeNotificationB() async {
        guard total > 0 else { return }

        let inactiveRatio = Double(inactive) / Double(total)
        
        if inactiveRatio > 0.75 {
            await NotificationManager.shared.notifyRideStatus(type: .finishedWorkout)
        }
    }
    
    func judgeNotificationC() async {
        guard total > 0 else { return }
        
        let inactiveOrSlowRatio = Double(inactiveOrSlow) / Double(total)
        
        if inactiveOrSlowRatio > 0.75 {
            await NotificationManager.shared.notifyRideStatus(type: .finishedWorkout)
        }
    }
    
    func judgeNotificationA() async {
        guard total > 0 else { return }
        
        let lowRatio = Double(lowCadence) / Double(total)
        let highRatio = Double(highCadence) / Double(total)
        let uphillRatio = Double(uphill) / Double(total)
        
        if lowRatio > 0.5 {
            await NotificationManager.shared.notifyRideStatus(type: .lowCadenceAlert)
        } else if highRatio > 0.5 {
            await NotificationManager.shared.notifyRideStatus(type: .highCadenceAlert)
        } else if uphillRatio > 0.1 {
            let uphillBadRatio = Double(uphillBad) / Double(uphill)
            if uphillBadRatio > 0.5 {
                await NotificationManager.shared.notifyRideStatus(type: .pushingBike)
            }
        }
    }
}
