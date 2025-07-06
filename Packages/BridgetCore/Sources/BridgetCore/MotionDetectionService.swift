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

public enum TrafficCondition: String, CaseIterable {
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
    
    // Vehicle detection thresholds
    private let vehicleAccelerationThreshold = 0.5 // m/s²
    private let vehicleSpeedThreshold = 5.0 // m/s (18 km/h)
    private let walkingAccelerationThreshold = 0.2 // m/s²
    
    // State tracking
    private var consecutiveVehicleReadings = 0
    private var consecutiveStationaryReadings = 0
    private let requiredReadingsForStateChange = 3
    
    public init() {
        print("🚗 [Motion] MotionDetectionService initialized")
    }
    
    public func startMonitoring() {
        guard motionManager.isAccelerometerAvailable else {
            print("❌ [Motion] Accelerometer not available")
            return
        }
        
        print("🚗 [Motion] Starting motion monitoring...")
        
        motionManager.accelerometerUpdateInterval = 1.0
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
            guard let data = data else { return }
            self?.processAccelerometerData(data)
        }
        
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 1.0
            motionManager.startDeviceMotionUpdates(to: .main) { [weak self] data, error in
                guard let data = data else { return }
                self?.processDeviceMotionData(data)
            }
        }
        
        isMonitoring = true
        print("🚗 [Motion] Motion monitoring started")
    }
    
    public func stopMonitoring() {
        print("🚗 [Motion] Stopping motion monitoring...")
        
        motionManager.stopAccelerometerUpdates()
        motionManager.stopDeviceMotionUpdates()
        
        isMonitoring = false
        vehicleState = .unknown
        currentSpeed = 0.0
        heading = 0.0
        acceleration = 0.0
        
        print("🚗 [Motion] Motion monitoring stopped")
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
                
                print("🚗 [Motion] State changed: \(oldState.rawValue) → \(newState.rawValue)")
                
                // Post notifications for state changes
                if newState == .inVehicle && oldState != .inVehicle {
                    NotificationCenter.default.post(name: .userEnteredVehicle, object: nil)
                } else if newState == .stationary && oldState == .inVehicle {
                    NotificationCenter.default.post(name: .userExitedVehicle, object: nil)
                }
            }
        }
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
            print("🚗 [Motion] Detected potential traffic slowdown - deceleration: \(String(format: "%.2f", groundAccelerationMagnitude)) m/s²")
        }
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