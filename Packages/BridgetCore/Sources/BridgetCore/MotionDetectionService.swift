//
//  MotionDetectionService.swift
//  BridgetCore
//
//  Created by Peter Jemley on 6/19/25.
//

import Foundation
import CoreMotion
import SwiftUI

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
        
        // Estimate speed from acceleration patterns
        // This is a simplified calculation - could be enhanced with GPS
        let speedChange = sqrt(
            pow(data.userAcceleration.x, 2) +
            pow(data.userAcceleration.y, 2) +
            pow(data.userAcceleration.z, 2)
        )
        currentSpeed = max(0, currentSpeed + speedChange)
        
        // Decay speed over time to simulate realistic behavior
        currentSpeed *= 0.95
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