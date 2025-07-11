//
//  MotionDetectionService.macOS.swift
//  BridgetCore
//
//  Created by AI Assistant on 1/15/25.
//

#if os(macOS)

import Foundation
import Combine

// MARK: - macOS Stub Motion Detection Service

@MainActor
public class MotionDetectionService: MotionDetectionServiceProtocol {
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
    
    // Simulated motion data for testing
    private var simulationTimer: Timer?
    private var simulationStep: Int = 0
    
    public init() {
        SecurityLogger.motion("MotionDetectionService (macOS stub) initialized")
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
        SecurityLogger.motion("Starting motion monitoring (macOS stub) at \(String(format: "%.1f", currentPollingRate)) Hz...")
        
        // Start simulation timer
        simulationTimer = Timer.scheduledTimer(withTimeInterval: currentPollingInterval, repeats: true) { [weak self] _ in
            self?.simulateMotionData()
        }
        
        isMonitoring = true
        SecurityLogger.motion("Motion monitoring started (macOS stub)")
    }
    
    public func stopMonitoring() {
        SecurityLogger.motion("Stopping motion monitoring (macOS stub)...")
        
        simulationTimer?.invalidate()
        simulationTimer = nil
        
        isMonitoring = false
        vehicleState = .unknown
        currentSpeed = 0.0
        heading = 0.0
        acceleration = 0.0
        
        SecurityLogger.motion("Motion monitoring stopped (macOS stub)")
    }
    
    private func simulateMotionData() {
        simulationStep += 1
        
        // Simulate different motion patterns
        let pattern = simulationStep % 60 // 60-second cycle
        
        if pattern < 20 {
            // Stationary for 20 seconds
            vehicleState = .stationary
            currentSpeed = 0.0
            acceleration = 0.0
            heading = 0.0
        } else if pattern < 35 {
            // Walking for 15 seconds
            vehicleState = .walking
            currentSpeed = 1.4 // ~5 km/h walking speed
            acceleration = 0.1 + Double.random(in: 0...0.1)
            heading = Double(pattern) * 0.1
        } else {
            // In vehicle for 25 seconds
            vehicleState = .inVehicle
            currentSpeed = 13.9 + Double.random(in: -2...2) // ~50 km/h
            acceleration = 0.3 + Double.random(in: -0.2...0.2)
            heading = Double(pattern) * 0.2
        }
        
        // Log motion data if debug is enabled
        if showMotionDebug {
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
            
            SecurityLogger.motion("Simulated: \(entry.vehicleState.rawValue) | Speed: \(String(format: "%.1f", entry.speed)) m/s | Acceleration: \(String(format: "%.2f", entry.acceleration)) m/s²")
        }
    }
    
    public func exportMotionLogs() -> MotionLogExport? {
        guard !motionLogs.isEmpty else {
            SecurityLogger.error("No motion data to export")
            return nil
        }
        
        let deviceInfo = "macOS - Simulated Motion Data"
        let export = MotionLogExport(entries: motionLogs, deviceInfo: deviceInfo)
        
        SecurityLogger.motion("Exported \(motionLogs.count) motion entries (macOS stub)")
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
            let fileName = "motion_data_macos_\(Date().timeIntervalSince1970).json"
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
        SecurityLogger.motion("Motion logs cleared (macOS stub)")
    }
    
    public func getMotionLogSummary() -> String {
        let totalEntries = motionLogs.count
        let vehicleEntries = motionLogs.filter { $0.vehicleState == .inVehicle }.count
        let walkingEntries = motionLogs.filter { $0.vehicleState == .walking }.count
        let stationaryEntries = motionLogs.filter { $0.vehicleState == .stationary }.count
        
        let avgSpeed = motionLogs.isEmpty ? 0 : motionLogs.map { $0.speed }.reduce(0, +) / Double(motionLogs.count)
        let avgAcceleration = motionLogs.isEmpty ? 0 : motionLogs.map { $0.acceleration }.reduce(0, +) / Double(motionLogs.count)
        
        return """
        Motion Log Summary (macOS Simulated):
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
            return "Stationary (Simulated)"
        case .walking:
            return "Walking (Simulated)"
        case .inVehicle:
            return "In Vehicle (Simulated)"
        case .unknown:
            return "Unknown (Simulated)"
        }
    }
}

#endif 