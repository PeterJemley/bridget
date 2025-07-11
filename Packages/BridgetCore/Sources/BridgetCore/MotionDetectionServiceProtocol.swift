//
//  MotionDetectionServiceProtocol.swift
//  BridgetCore
//
//  Created by AI Assistant on 1/15/25.
//

import Foundation
import Combine

// MARK: - Platform-Agnostic Motion Detection Protocol

/// Platform-agnostic protocol for motion detection services
/// This allows different implementations for iOS (CoreMotion) and macOS (CoreLocation)
@preconcurrency
public protocol MotionDetectionServiceProtocol: ObservableObject {
    /// Current vehicle state
    var vehicleState: VehicleState { get }
    
    /// Whether motion monitoring is currently active
    var isMonitoring: Bool { get }
    
    /// Current speed in meters per second
    var currentSpeed: Double { get }
    
    /// Current acceleration in meters per second squared
    var acceleration: Double { get }
    
    /// Whether to show motion debug information
    var showMotionDebug: Bool { get set }
    
    /// Status description for UI display
    var statusDescription: String { get }
    
    /// Whether the user is currently in a vehicle
    var isInVehicle: Bool { get }
    
    /// Number of logged motion entries
    var loggedEntriesCount: Int { get }
    
    /// Start motion monitoring
    func startMonitoring()
    
    /// Stop motion monitoring
    func stopMonitoring()
    
    /// Export motion logs
    func exportMotionLogs() -> MotionLogExport?
    
    /// Export motion data (alias for exportMotionLogs)
    func exportMotionData() -> URL?
    
    /// Clear motion logs
    func clearMotionLogs()
    
    /// Get motion log summary
    func getMotionLogSummary() -> String
}

// MARK: - Vehicle State Enum

public enum VehicleState: String, CaseIterable, Codable {
    case unknown = "Unknown"
    case stationary = "Stationary"
    case walking = "Walking"
    case inVehicle = "In Vehicle"
    
    public var systemImage: String {
        switch self {
        case .unknown: return "questionmark.circle"
        case .stationary: return "figure.stand"
        case .walking: return "figure.walk"
        case .inVehicle: return "car.fill"
        }
    }
}

// MARK: - Motion Log Export

public struct MotionLogExport: Codable {
    public let entries: [MotionLogEntry]
    public let deviceInfo: String
    public let exportDate: Date
    
    public init(entries: [MotionLogEntry], deviceInfo: String) {
        self.entries = entries
        self.deviceInfo = deviceInfo
        self.exportDate = Date()
    }
}

public struct MotionLogEntry: Codable, Identifiable {
    public let id = UUID()
    public let timestamp: Date
    public let speed: Double
    public let acceleration: Double
    public let vehicleState: VehicleState
    
    public init(timestamp: Date, speed: Double, acceleration: Double, vehicleState: VehicleState) {
        self.timestamp = timestamp
        self.speed = speed
        self.acceleration = acceleration
        self.vehicleState = vehicleState
    }
}

// MARK: - Notification Names

public extension Notification.Name {
    static let userEnteredVehicle = Notification.Name("userEnteredVehicle")
    static let userExitedVehicle = Notification.Name("userExitedVehicle")
} 