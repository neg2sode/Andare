//
//  MotionManager.swift
//  Andare
//
//  Created by neg2sode on 2025/2/3.
//

import CoreMotion
import Combine
import Accelerate

struct SensorData {
    let timestamp: Double
    let x: Double
    let y: Double
    let z: Double
}

struct CadenceData {
    let timestamp: Date
    let cadence: Double
    let preferredCadence: Double?
}

struct AltitudeData {
    let timestamp: Date
    let altitude: Double // relative altitude, in meters
}

final class MotionManager {
    static let UPDATE_INTERVAL: TimeInterval = 0.01 // 100 Hz
    static let SAMPLE_RATE: Double = 1.0 / UPDATE_INTERVAL // Hz
    static let SEGMENT_BUFFER_SIZE: Int = 512 // ensuring 2^n for fft
    static let SECTION_BUFFER_SIZE: Int = 8192 // ensuring integer multiple of segment buffer size
    static let SEGMENT_DURATION: TimeInterval = UPDATE_INTERVAL * Double(SEGMENT_BUFFER_SIZE) // 5.12s
    static let SECTION_DURATION: TimeInterval = UPDATE_INTERVAL * Double(SECTION_BUFFER_SIZE) // 81.92s
    
    private let motionManager = CMMotionManager()
    private let altimeter = CMAltimeter()
    private let operationQueue = OperationQueue()

    private var segmentBuffer: [SensorData] = []
    private var sectionBuffer: [SensorData] = []
    private var timeIntervalSince1970AtStart: TimeInterval = 0
    private var systemUptimeAtStart: TimeInterval = 0
    private var minCadenceFreq: Double
    private var maxCadenceFreq: Double

    let cadencePublisher = PassthroughSubject<CadenceData, Never>()
    let altitudePublisher = PassthroughSubject<AltitudeData, Never>()
    
    // Public accessor for gyro state
    var isDeviceMotionActive: Bool {
        return motionManager.isGyroActive
    }

    init(workoutType: WorkoutType) {
        let cadenceRange = workoutType.getInfo().range
        self.minCadenceFreq = cadenceRange.min / 60.0 // converting to frequency (Hz) from RPM
        self.maxCadenceFreq = cadenceRange.max / 60.0
        operationQueue.maxConcurrentOperationCount = 1
        motionManager.gyroUpdateInterval = MotionManager.UPDATE_INTERVAL
    }
    
    func configure(for newType: WorkoutType) {
        let cadenceRange = newType.getInfo().range
        self.minCadenceFreq = cadenceRange.min / 60.0
        self.maxCadenceFreq = cadenceRange.max / 60.0
    }

    func startUpdates() {
        guard motionManager.isGyroAvailable else { return }
        guard !motionManager.isGyroActive else { return }

        // Clear buffer on start
        segmentBuffer.removeAll()
        sectionBuffer.removeAll()
        
        self.timeIntervalSince1970AtStart = Date().timeIntervalSince1970
        self.systemUptimeAtStart = ProcessInfo.processInfo.systemUptime

        motionManager.startGyroUpdates(to: operationQueue) { [weak self] (data, error) in
            guard let self = self else { return }
            guard let data = data else { return }
            if let error = error { fatalError("*** Gyroscope fatal update error: \(error.localizedDescription) ***") }

            let eventWallTime = self.timeIntervalSince1970AtStart + (data.timestamp - self.systemUptimeAtStart)
            let gyroData = SensorData(
                timestamp: eventWallTime,
                x: data.rotationRate.x,
                y: data.rotationRate.y,
                z: data.rotationRate.z
            )
            self.segmentBuffer.append(gyroData)

            // Process buffer when full
            if self.segmentBuffer.count >= Self.SEGMENT_BUFFER_SIZE {
                self.sectionBuffer.append(contentsOf: self.segmentBuffer)
                var bufferToProcess = Array(self.segmentBuffer.prefix(Self.SEGMENT_BUFFER_SIZE))
                let newCadence = self.processBuffer(bufferToProcess)
                var processingEndTime = Date()
                // Remove the processed part efficiently (sliding window)
                self.segmentBuffer.removeFirst(Self.SEGMENT_BUFFER_SIZE)
                
                if self.sectionBuffer.count >= Self.SECTION_BUFFER_SIZE {
                    bufferToProcess = Array(self.sectionBuffer.prefix(Self.SECTION_BUFFER_SIZE))
                    let newPreferredCadence = self.processBuffer(bufferToProcess)
                    processingEndTime = Date()
                    self.sectionBuffer.removeFirst(Self.SECTION_BUFFER_SIZE)
                    
                    let cadenceRecord = CadenceData(
                        timestamp: processingEndTime,
                        cadence: newCadence,
                        preferredCadence: newPreferredCadence
                    )
                    self.cadencePublisher.send(cadenceRecord)
                } else {
                    let cadenceRecord = CadenceData(
                        timestamp: processingEndTime,
                        cadence: newCadence,
                        preferredCadence: nil
                    )
                    self.cadencePublisher.send(cadenceRecord)
                }
            }
        }
        
        if CMAltimeter.isRelativeAltitudeAvailable() {
            altimeter.startRelativeAltitudeUpdates(to: operationQueue) { [weak self] (data, error) in
                guard let self = self else { return }
                guard let data = data else { return }
                if let error = error {
                    print("Altimeter update error: \(error.localizedDescription)")
                    // Optionally send error via a publisher if UI needs to react
                    return
                }

                let eventWallTime = self.timeIntervalSince1970AtStart + (data.timestamp - self.systemUptimeAtStart)
                
                let altitudeRecord = AltitudeData(
                    timestamp: Date(timeIntervalSince1970: eventWallTime),
                    altitude: data.relativeAltitude.doubleValue
                )
                self.altitudePublisher.send(altitudeRecord)
            }
        }
    }

    func stopUpdates() {
        if motionManager.isGyroActive {
            motionManager.stopGyroUpdates()
        }
        if CMAltimeter.isRelativeAltitudeAvailable() {
            altimeter.stopRelativeAltitudeUpdates()
        }
        segmentBuffer.removeAll() // Clear buffer on stop
        sectionBuffer.removeAll()
    }
    
    func processBuffer(_ buffer: [SensorData]) -> Double {
        guard !buffer.isEmpty else { return 0 }
        
        // 1. Extract raw data for all axes
        let x = buffer.map { Float($0.x) }
        let y = buffer.map { Float($0.y) }
        let z = buffer.map { Float($0.z) }
        
        // 2. Shared parameters
        let n = buffer.count
        let log2n = vDSP_Length(log2(Double(n)))
        guard let fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(FFT_RADIX2)) else { return 0 }
        defer { vDSP_destroy_fftsetup(fftSetup) }

        // reused variables
        var peaks: [(frequency: Double, magnitude: Double)] = []
        var signal = [Float](repeating: 0, count: n)
        var real = [Float](repeating: 0, count: n/2)
        var imag = [Float](repeating: 0, count: n/2)
        var output = real.withUnsafeMutableBufferPointer { realBP in
            imag.withUnsafeMutableBufferPointer { imagBP in
                DSPSplitComplex(realp: realBP.baseAddress!, imagp: imagBP.baseAddress!)
            }
        }

        // 3. Process each axis
        for axisData in [x, y, z] {
            // Apply Hann window
            signal.replaceSubrange(0..<n, with: axisData)
            var window = [Float](repeating: 0, count: n)
            vDSP_hann_window(&window, vDSP_Length(n), 0)
            vDSP_vmul(signal, 1, window, 1, &signal, 1, vDSP_Length(n))

            // FFT
            signal.withUnsafeMutableBytes { ptr in
                let input = ptr.bindMemory(to: DSPComplex.self).baseAddress!
                vDSP_ctoz(input, 2, &output, 1, vDSP_Length(n/2))
            }
            vDSP_fft_zrip(fftSetup, &output, 1, log2n, FFTDirection(FFT_FORWARD))
               
            // Magnitudes
            var magnitudes = [Float](repeating: 0, count: n/2)
            vDSP_zvmags(&output, 1, &magnitudes, 1, vDSP_Length(n/2))

            let sampleRate = Double(n) / (buffer.last!.timestamp - buffer.first!.timestamp)
            var maxMag: Float = magnitudes[0] // 0 is always considered for stillness detection
            var peakIndex = 0 // index starting from 0
               
            for k in 1..<n/2 {
                let freq = Double(k) * sampleRate / Double(n)
                if freq < self.minCadenceFreq { continue }
                if freq > self.maxCadenceFreq { break }

                if magnitudes[k] > maxMag {
                    maxMag = magnitudes[k]
                    peakIndex = k
                }
            }
               
            let peakFreq = Double(peakIndex) * sampleRate / Double(n)
            peaks.append((peakFreq, Double(maxMag)))
        }
        
        guard let dominantPeak = peaks.max(by: { $0.magnitude < $1.magnitude }) else { return 0 }
        let rpm = dominantPeak.frequency * 60
        return rpm
    }
    
    deinit {
        stopUpdates()
    }
}
