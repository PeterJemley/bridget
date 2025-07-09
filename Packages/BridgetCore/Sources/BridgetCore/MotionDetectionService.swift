//
//  MotionDetectionService.swift
//  BridgetCore
//
//  Created by Peter Jemley on 6/19/25.
//

import Foundation
import CoreMotion
import SwiftUI

// MARK: - Traffic Analysis Types

public enum TrafficCondition: String, CaseIterable, Codable {
    case unknown = "Unknown"
    case freeFlow = "Free Flow"
    case normalTraffic = "Normal Traffic"
    case moderateTraffic = "Moderate Traffic"
    case heavyTraffic = "Heavy Traffic"
    
    var description: String {
        switch self {
        case .unknown:
            return "Unable to determine traffic conditions"
        case .freeFlow:
            return "Traffic flowing freely at normal speeds"
        case .normalTraffic:
            return "Typical traffic conditions"
        case .moderateTraffic:
            return "Some congestion, reduced speeds"
        case .heavyTraffic:
            return "Heavy congestion, frequent stops"
        }
    }
    
    var color: Color {
        switch self {
        case .unknown: return .gray
        case .freeFlow: return .green
        case .normalTraffic: return .blue
        case .moderateTraffic: return .orange
        case .heavyTraffic: return .red
        }
    }
}

@MainActor
public class MotionDetectionService: ObservableObject {
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
                
                SecurityLogger.motion("State changed: \(oldState.rawValue) → \(newState.rawValue)")
                
                // Post notifications for state changes
                if newState == .inVehicle && oldState != .inVehicle {
                    NotificationCenter.default.post(name: .userEnteredVehicle, object: nil)
                } else if newState == .stationary && oldState == .inVehicle {
                    NotificationCenter.default.post(name: .userExitedVehicle, object: nil)
                }
            }
        }
        
        // Log motion data for analysis
        let trafficCondition = analyzeTrafficConditions()
        logMotionData(accelerationData: data, deviceMotionData: nil, trafficCondition: trafficCondition)
    }
    
    private func processDeviceMotionData(_ data: CMDeviceMotion) {
        // Calculate heading from device orientation
        heading = atan2(data.attitude.rotationMatrix.m12, data.attitude.rotationMatrix.m11)
        
        // Use gravity-corrected acceleration for better traffic analysis
        // This represents the device's acceleration relative to the ground
        let groundAccelerationMagnitude = sqrt(
            pow(data.userAcceleration.x, 2) +
            pow(data.userAcceleration.y, 2) +
            pow(data.userAcceleration.z, 2)
        )
        
        // Detect traffic patterns based on acceleration patterns
        // Sudden deceleration often indicates traffic slowdowns
        let isDecelerating = groundAccelerationMagnitude > 0.3 && 
                            data.userAcceleration.z < -0.2 // Forward deceleration
        
        // Update speed based on acceleration patterns
        // Positive acceleration increases speed, negative decreases it
        let speedChange = data.userAcceleration.z * 0.5 // Scale factor for realistic speed changes
        currentSpeed = max(0, currentSpeed + speedChange)
        
        // Decay speed over time to simulate realistic behavior
        currentSpeed *= 0.98
        
        // Log traffic-related events
        if isDecelerating && vehicleState == .inVehicle {
            SecurityLogger.motion("Detected potential traffic slowdown - deceleration: \(String(format: "%.2f", groundAccelerationMagnitude)) m/s²")
        }
        
        // Log motion data for analysis (with device motion data)
        let trafficCondition = analyzeTrafficConditions()
        logMotionData(accelerationData: nil, deviceMotionData: data, trafficCondition: trafficCondition)
    }
    
    public func getCurrentUserContext(estimatedTravelTime: TimeInterval = 0) -> UserContext {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        let isRushHour = (hour >= 7 && hour <= 9) || (hour >= 17 && hour <= 19)
        
        return UserContext(
            isInVehicle: vehicleState == .inVehicle,
            currentSpeed: currentSpeed,
            heading: heading,
            estimatedTravelTime: estimatedTravelTime,
            isRushHour: isRushHour
        )
    }
    
    /// Analyzes current motion patterns to detect traffic conditions
    public func analyzeTrafficConditions() -> TrafficCondition {
        guard vehicleState == .inVehicle else {
            return .unknown
        }
        
        // Analyze speed and acceleration patterns
        if currentSpeed < 2.0 && acceleration > 0.1 {
            return .heavyTraffic // Low speed with frequent acceleration/deceleration
        } else if currentSpeed < 5.0 {
            return .moderateTraffic // Moderate speed
        } else if currentSpeed > 10.0 {
            return .freeFlow // High speed, likely free-flowing traffic
        } else {
            return .normalTraffic
        }
    }
    
    // MARK: - Enhanced Logging and Export Methods
    
    /// Logs current motion data for analysis
    private func logMotionData(
        accelerationData: CMAccelerometerData?,
        deviceMotionData: CMDeviceMotion?,
        trafficCondition: TrafficCondition
    ) {
        let entry = MotionLogEntry(
            vehicleState: vehicleState,
            speed: currentSpeed,
            heading: heading,
            acceleration: acceleration,
            accelerationX: accelerationData?.acceleration.x ?? 0.0,
            accelerationY: accelerationData?.acceleration.y ?? 0.0,
            accelerationZ: accelerationData?.acceleration.z ?? 0.0,
            userAccelerationX: deviceMotionData?.userAcceleration.x ?? 0.0,
            userAccelerationY: deviceMotionData?.userAcceleration.y ?? 0.0,
            userAccelerationZ: deviceMotionData?.userAcceleration.z ?? 0.0,
            trafficCondition: trafficCondition
        )
        
        motionLogs.append(entry)
        
        // Prevent memory issues by limiting log size
        if motionLogs.count > maxLogEntries {
            motionLogs.removeFirst(motionLogs.count - maxLogEntries)
        }
        
        // Log to console for real-time monitoring
        SecurityLogger.motion("Logged: \(entry.vehicleState.rawValue) | Speed: \(String(format: "%.1f", entry.speed)) m/s | Acceleration: \(String(format: "%.2f", entry.acceleration)) m/s² | Traffic: \(entry.trafficCondition.rawValue)")
    }
    
    /// Exports motion data to a JSON file
    public func exportMotionData() -> URL? {
        guard !motionLogs.isEmpty else {
            SecurityLogger.error("No motion data to export")
            return nil
        }
        
        let deviceInfo = "iPhone 16 Pro - iOS \(UIDevice.current.systemVersion)"
        let export = MotionLogExport(entries: motionLogs, deviceInfo: deviceInfo)
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            
            let data = try encoder.encode(export)
            
            // Save to Documents directory
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsPath.appendingPathComponent(logFileName)
            
            try data.write(to: fileURL)
            
            SecurityLogger.motion("Exported \(motionLogs.count) motion entries")
            return fileURL
            
        } catch {
            SecurityLogger.error("Failed to export motion data", error: error)
            return nil
        }
    }
    
    /// Clears all logged motion data
    public func clearMotionLogs() {
        motionLogs.removeAll()
        SecurityLogger.motion("Cleared all motion logs")
    }
    
    /// Returns summary statistics of logged motion data
    public func getMotionLogSummary() -> String {
        guard !motionLogs.isEmpty else {
            return "No motion data logged"
        }
        
        let totalEntries = motionLogs.count
        let vehicleEntries = motionLogs.filter { $0.vehicleState == .inVehicle }.count
        let walkingEntries = motionLogs.filter { $0.vehicleState == .walking }.count
        let stationaryEntries = motionLogs.filter { $0.vehicleState == .stationary }.count
        
        let avgSpeed = motionLogs.map { $0.speed }.reduce(0, +) / Double(totalEntries)
        let maxSpeed = motionLogs.map { $0.speed }.max() ?? 0.0
        
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        
        let timeRange = if let first = motionLogs.first?.timestamp,
                          let last = motionLogs.last?.timestamp {
            "\(formatter.string(from: first)) - \(formatter.string(from: last))"
        } else {
            "Unknown"
        }
        
        return """
        📊 Motion Log Summary:
        • Total Entries: \(totalEntries)
        • Time Range: \(timeRange)
        • Vehicle Time: \(vehicleEntries) entries (\(String(format: "%.1f", Double(vehicleEntries) / Double(totalEntries) * 100))%)
        • Walking Time: \(walkingEntries) entries (\(String(format: "%.1f", Double(walkingEntries) / Double(totalEntries) * 100))%)
        • Stationary Time: \(stationaryEntries) entries (\(String(format: "%.1f", Double(stationaryEntries) / Double(totalEntries) * 100))%)
        • Average Speed: \(String(format: "%.1f", avgSpeed)) m/s
        • Max Speed: \(String(format: "%.1f", maxSpeed)) m/s
        """
    }
    
    /// Returns the number of logged entries
    public var loggedEntriesCount: Int {
        return motionLogs.count
    }
}

// MARK: - Motion Logging Data Structures

public struct MotionLogEntry: Codable {
    public let timestamp: Date
    public let vehicleState: VehicleState
    public let speed: Double
    public let heading: Double
    public let acceleration: Double
    public let accelerationX: Double
    public let accelerationY: Double
    public let accelerationZ: Double
    public let userAccelerationX: Double
    public let userAccelerationY: Double
    public let userAccelerationZ: Double
    public let trafficCondition: TrafficCondition
    public let location: String? // Optional location context
    
    public init(
        vehicleState: VehicleState,
        speed: Double,
        heading: Double,
        acceleration: Double,
        accelerationX: Double,
        accelerationY: Double,
        accelerationZ: Double,
        userAccelerationX: Double,
        userAccelerationY: Double,
        userAccelerationZ: Double,
        trafficCondition: TrafficCondition,
        location: String? = nil
    ) {
        self.timestamp = Date()
        self.vehicleState = vehicleState
        self.speed = speed
        self.heading = heading
        self.acceleration = acceleration
        self.accelerationX = accelerationX
        self.accelerationY = accelerationY
        self.accelerationZ = accelerationZ
        self.userAccelerationX = userAccelerationX
        self.userAccelerationY = userAccelerationY
        self.userAccelerationZ = userAccelerationZ
        self.trafficCondition = trafficCondition
        self.location = location
    }
}

public struct MotionLogExport: Codable {
    public let exportDate: Date
    public let deviceInfo: String
    public let totalEntries: Int
    public let timeRange: String
    public let entries: [MotionLogEntry]
    
    public init(entries: [MotionLogEntry], deviceInfo: String) {
        self.exportDate = Date()
        self.deviceInfo = deviceInfo
        self.totalEntries = entries.count
        self.entries = entries
        
        if let firstEntry = entries.first,
           let lastEntry = entries.last {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            self.timeRange = "\(formatter.string(from: firstEntry.timestamp)) - \(formatter.string(from: lastEntry.timestamp))"
        } else {
            self.timeRange = "No data"
        }
    }
}

// MARK: - SwiftUI Integration
public extension MotionDetectionService {
    var isInVehicle: Bool {
        vehicleState == .inVehicle
    }
    
    var statusDescription: String {
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