//
//  CoordinateTransform.swift
//  Andare
//
//  Created by neg2sode on 2025/5/16.
//

import CoreLocation

private let a: Double = 6378245.0
private let ee: Double = 0.00669342162296594323

fileprivate func transformLatitude(x: Double, y: Double) -> Double {
    var result = -100.0 + 2.0 * x + 3.0 * y
    result += 0.2 * y * y + 0.1 * x * y + 0.2 * sqrt(abs(x))
    result += (20.0 * sin(6.0 * x * .pi) + 20.0 * sin(2.0 * x * .pi)) * 2.0 / 3.0
    result += (20.0 * sin(y * .pi) + 40.0 * sin(y / 3.0 * .pi)) * 2.0 / 3.0
    result += (160.0 * sin(y / 12.0 * .pi) + 320 * sin(y * .pi / 30.0)) * 2.0 / 3.0
    return result
}

fileprivate func transformLongitude(x: Double, y: Double) -> Double {
    var result = 300.0 + x + 2.0 * y
    result += 0.1 * x * x + 0.1 * x * y + 0.1 * sqrt(abs(x))
    result += (20.0 * sin(6.0 * x * .pi) + 20.0 * sin(2.0 * x * .pi)) * 2.0 / 3.0
    result += (20.0 * sin(x * .pi) + 40.0 * sin(x / 3.0 * .pi)) * 2.0 / 3.0
    result += (150.0 * sin(x / 12.0 * .pi) + 300.0 * sin(x / 30.0 * .pi)) * 2.0 / 3.0
    return result
}

// Returns true if coordinate is in mainland China’s GCJ-02 region
fileprivate func isInChina(_ coord: CLLocationCoordinate2D) -> Bool {
    let lon = coord.longitude
    let lat = coord.latitude
    return lon >= 72.004 && lon <= 137.8347 && lat >= 0.8293 && lat <= 55.8271
}

extension CLLocationCoordinate2D {
    // Convert a GCJ-02 point into WGS-84 if in China
    func adjustedForChina() -> CLLocationCoordinate2D {
        guard isInChina(self) else { return self }
        
        let dLat = transformLatitude(x: longitude - 105.0, y: latitude - 35.0)
        let dLon = transformLongitude(x: longitude - 105.0, y: latitude - 35.0)
        let radLat = latitude / 180.0 * .pi
        let magic = sin(radLat)
        let mm = 1 - ee * magic * magic
        let sqrtMagic = sqrt(mm)
        
        let latitudeOffset = (dLat * 180.0) / ((a * (1 - ee)) / (mm * sqrtMagic) * .pi)
        let longitudeOffset = (dLon * 180.0) / (a / sqrtMagic * cos(radLat) * .pi)
        
        return CLLocationCoordinate2D(
            latitude: latitude + latitudeOffset,
            longitude: longitude + longitudeOffset
        )
    }
}

