//
//  MotionDetectionService.iOS.swift
//  BridgetCore
//
//  Created by AI Assistant on 1/15/25.
//

#if os(iOS)

import Foundation
import CoreMotion
import SwiftUI
import UIKit

// MARK: - iOS-Specific Motion Detection Service

@MainActor
public class MotionDetectionService: MotionDetectionServiceProtocol {
    private let motionManager = CMMotionManager()
    
    @Published public var vehicleState: VehicleState = .unknown
    @Published public var currentSpeed: Double = 0.0
    @Published public var heading: Double = 0.0
    @Published public var acceleration: Double = 0.0
    @Published public var isMonitoring = false
    @Published public var isHighDetailMode = false
    @Published public var showMotionDebug: Bool = false
    
    // Configurable polling intervals
    @Published public var pollingInterval: TimeInterval = 1.0 // Default 1 Hz
    @Published public var highDetailInterval: TimeInterval = 0.1 // 10 Hz for high detail
    
    // Enhanced logging and export capabilities
    private var motionLogs: [MotionLogEntry] = []
    private let maxLogEntries = 10000 // Prevent memory issues
    private let logFileName = "motion_data.json"
    
    // Vehicle detection thresholds
    private let vehicleAccelerationThreshold = 0.5 // m/s²
    private let vehicleSpeedThreshold = 5.0 // m/s (18 km/h)
    private let walkingAccelerationThreshold = 0.2 // m/s²
    
    // State tracking
    private var consecutiveVehicleReadings = 0
    private var consecutiveStationaryReadings = 0
    private let requiredReadingsForStateChange = 3
    
    public init() {
        SecurityLogger.motion("MotionDetectionService initialized")
    }
    
    public static let shared = MotionDetectionService()
    
    // MARK: - Configuration Methods
    
    /// Sets the polling interval for motion detection
    /// - Parameter interval: Time interval in seconds (0.01 = 100 Hz, 1.0 = 1 Hz)
    public func setPollingInterval(_ interval: TimeInterval) {
        pollingInterval = max(0.01, min(interval, 10.0)) // Clamp between 0.01s (100 Hz) and 10s (0.1 Hz)
        
        if isMonitoring {
            // Restart monitoring with new interval
            stopMonitoring()
            startMonitoring()
        }
        
        SecurityLogger.motion("Polling interval set to \(String(format: "%.2f", pollingInterval))s (\(String(format: "%.1f", 1.0/pollingInterval)) Hz)")
    }
    
    /// Enables or disables high detail mode
    /// - Parameter enabled: Whether to enable high detail mode (10 Hz polling)
    public func setHighDetailMode(_ enabled: Bool) {
        isHighDetailMode = enabled
        
        if isMonitoring {
            // Restart monitoring with new mode
            stopMonitoring()
            startMonitoring()
        }
        
        let currentInterval = enabled ? highDetailInterval : pollingInterval
        let currentRate = 1.0 / currentInterval
        
        SecurityLogger.motion("High detail mode \(enabled ? "enabled" : "disabled") - \(String(format: "%.1f", currentRate)) Hz polling")
    }
    
    /// Gets the current effective polling interval
    public var currentPollingInterval: TimeInterval {
        return isHighDetailMode ? highDetailInterval : pollingInterval
    }
    
    /// Gets the current polling rate in Hz
    public var currentPollingRate: Double {
        return 1.0 / currentPollingInterval
    }
    
    public func startMonitoring() {
        guard motionManager.isAccelerometerAvailable else {
            SecurityLogger.error("Accelerometer not available")
            return
        }
        
        let interval = currentPollingInterval
        let rate = currentPollingRate
        
        SecurityLogger.motion("Starting motion monitoring at \(String(format: "%.1f", rate)) Hz...")
        
        motionManager.accelerometerUpdateInterval = interval
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
            guard let data = data else { return }
            self?.processAccelerometerData(data)
        }
        
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = interval
            motionManager.startDeviceMotionUpdates(to: .main) { [weak self] data, error in
                guard let data = data else { return }
                self?.processDeviceMotionData(data)
            }
        }
        
        isMonitoring = true
        SecurityLogger.motion("Motion monitoring started at \(String(format: "%.1f", rate)) Hz")
    }
    
    public func stopMonitoring() {
        SecurityLogger.motion("Stopping motion monitoring...")
        
        motionManager.stopAccelerometerUpdates()
        motionManager.stopDeviceMotionUpdates()
        
        isMonitoring = false
        vehicleState = .unknown
        currentSpeed = 0.0
        heading = 0.0
        acceleration = 0.0
        
        SecurityLogger.motion("Motion monitoring stopped")
    }
    
    private func processAccelerometerData(_ data: CMAccelerometerData) {
        let magnitude = sqrt(
            pow(data.acceleration.x, 2) + 
            pow(data.acceleration.y, 2) + 
            pow(data.acceleration.z, 2)
        )
        
        acceleration = magnitude
        
        // Detect movement patterns
        let newState: VehicleState
        
        if magnitude > vehicleAccelerationThreshold {
            newState = .inVehicle
            consecutiveVehicleReadings += 1
            consecutiveStationaryReadings = 0
        } else if magnitude > walkingAccelerationThreshold {
            newState = .walking
            consecutiveVehicleReadings = 0
            consecutiveStationaryReadings = 0
        } else {
            newState = .stationary
            consecutiveVehicleReadings = 0
            consecutiveStationaryReadings += 1
        }
        
        // Only change state after consistent readings
        if newState != vehicleState {
            if (newState == .inVehicle && consecutiveVehicleReadings >= requiredReadingsForStateChange) ||
               (newState == .stationary && consecutiveStationaryReadings >= requiredReadingsForStateChange) {
                
                let oldState = vehicleState
                vehicleState = newState
                
                // Post notifications for state changes
                if newState == .inVehicle && oldState != .inVehicle {
                    NotificationCenter.default.post(name: .userEnteredVehicle, object: nil)
                } else if oldState == .inVehicle && newState != .inVehicle {
                    NotificationCenter.default.post(name: .userExitedVehicle, object: nil)
                }
                
                SecurityLogger.motion("Vehicle state changed: \(oldState.rawValue) → \(newState.rawValue)")
            }
        }
        
        // Log motion data if debug is enabled
        if showMotionDebug {
            logMotionData(
                accelerationData: data,
                deviceMotionData: nil,
                trafficCondition: .unknown
            )
        }
    }
    
    private func processDeviceMotionData(_ data: CMDeviceMotion) {
        // Update heading from device motion
        heading = data.heading
        
        // Update speed estimation (simplified - in real app would use GPS)
        let userAcceleration = sqrt(
            pow(data.userAcceleration.x, 2) + 
            pow(data.userAcceleration.y, 2) + 
            pow(data.userAcceleration.z, 2)
        )
        
        // Simple speed estimation based on acceleration integration
        // This is a simplified approach - real apps would use GPS
        if userAcceleration > 0.1 {
            currentSpeed += userAcceleration * currentPollingInterval
        } else {
            currentSpeed *= 0.95 // Decay
        }
        
        currentSpeed = max(0, min(currentSpeed, 50)) // Clamp between 0 and 50 m/s
        
        // Log motion data if debug is enabled
        if showMotionDebug {
            logMotionData(
                accelerationData: nil,
                deviceMotionData: data,
                trafficCondition: .unknown
            )
        }
    }
    
    private func logMotionData(
        accelerationData: CMAccelerometerData?,
        deviceMotionData: CMDeviceMotion?,
        trafficCondition: TrafficCondition
    ) {
        let entry = MotionLogEntry(
            timestamp: Date(),
            speed: currentSpeed,
            acceleration: acceleration,
            vehicleState: vehicleState
        )
        
        motionLogs.append(entry)
        
        // Prevent memory issues by limiting log size
        if motionLogs.count > maxLogEntries {
            motionLogs.removeFirst(motionLogs.count - maxLogEntries)
        }
        
        // Log to console for real-time monitoring
        SecurityLogger.motion("Logged: \(entry.vehicleState.rawValue) | Speed: \(String(format: "%.1f", entry.speed)) m/s | Acceleration: \(String(format: "%.2f", entry.acceleration)) m/s²")
    }
    
    public func exportMotionLogs() -> MotionLogExport? {
        guard !motionLogs.isEmpty else {
            SecurityLogger.error("No motion data to export")
            return nil
        }
        
        let deviceInfo = "iPhone - iOS \(UIDevice.current.systemVersion)"
        let export = MotionLogExport(entries: motionLogs, deviceInfo: deviceInfo)
        
        SecurityLogger.motion("Exported \(motionLogs.count) motion entries")
        return export
    }
    
    public func exportMotionData() -> URL? {
        guard let export = exportMotionLogs() else { return nil }
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            
            let data = try encoder.encode(export)
            
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileName = "motion_data_\(Date().timeIntervalSince1970).json"
            let fileURL = documentsPath.appendingPathComponent(fileName)
            
            try data.write(to: fileURL)
            SecurityLogger.motion("Motion data exported to: \(fileURL.path)")
            return fileURL
        } catch {
            SecurityLogger.error("Failed to export motion data: \(error.localizedDescription)")
            return nil
        }
    }
    
    public func clearMotionLogs() {
        motionLogs.removeAll()
        SecurityLogger.motion("Motion logs cleared")
    }
    
    public func getMotionLogSummary() -> String {
        let totalEntries = motionLogs.count
        let vehicleEntries = motionLogs.filter { $0.vehicleState == .inVehicle }.count
        let walkingEntries = motionLogs.filter { $0.vehicleState == .walking }.count
        let stationaryEntries = motionLogs.filter { $0.vehicleState == .stationary }.count
        
        let avgSpeed = motionLogs.isEmpty ? 0 : motionLogs.map { $0.speed }.reduce(0, +) / Double(motionLogs.count)
        let avgAcceleration = motionLogs.isEmpty ? 0 : motionLogs.map { $0.acceleration }.reduce(0, +) / Double(motionLogs.count)
        
        return """
        Motion Log Summary:
        Total Entries: \(totalEntries)
        Vehicle: \(vehicleEntries) (\(totalEntries > 0 ? String(format: "%.1f", Double(vehicleEntries) / Double(totalEntries) * 100) : "0")%)
        Walking: \(walkingEntries) (\(totalEntries > 0 ? String(format: "%.1f", Double(walkingEntries) / Double(totalEntries) * 100) : "0")%)
        Stationary: \(stationaryEntries) (\(totalEntries > 0 ? String(format: "%.1f", Double(stationaryEntries) / Double(totalEntries) * 100) : "0")%)
        Average Speed: \(String(format: "%.2f", avgSpeed)) m/s
        Average Acceleration: \(String(format: "%.2f", avgAcceleration)) m/s²
        """
    }
    
    public var loggedEntriesCount: Int {
        motionLogs.count
    }
    
    // MARK: - SwiftUI Integration
    public var isInVehicle: Bool {
        vehicleState == .inVehicle
    }
    
    public var statusDescription: String {
        switch vehicleState {
        case .stationary:
            return "Stationary"
        case .walking:
            return "Walking"
        case .inVehicle:
            return "In Vehicle"
        case .unknown:
            return "Unknown"
        }
    }
}

#endif 