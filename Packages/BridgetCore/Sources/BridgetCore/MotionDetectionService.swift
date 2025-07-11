//
//  MotionDetectionService.swift
//  BridgetCore
//
//  Created by Peter Jemley on 6/19/25.
//

import Foundation
import SwiftUI
import BridgetCore

// MARK: - Traffic Analysis Types (Legacy - for backward compatibility)

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

// MARK: - Legacy Motion Logging Data Structures (for backward compatibility)

public struct LegacyMotionLogEntry: Codable {
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

public struct LegacyMotionLogExport: Codable {
    public let exportDate: Date
    public let deviceInfo: String
    public let totalEntries: Int
    public let timeRange: String
    public let entries: [LegacyMotionLogEntry]
    
    public init(entries: [LegacyMotionLogEntry], deviceInfo: String) {
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