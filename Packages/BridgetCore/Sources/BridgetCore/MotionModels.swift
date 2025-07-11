//
//  MotionModels.swift
//  BridgetCore
//
//  Created by Peter Jemley on 6/19/25.
//

import Foundation
import CoreLocation

// MARK: - Motion Detection Models

/// Represents the user's current travel context
public struct UserContext: Codable {
    public let isInVehicle: Bool
    public let currentSpeed: Double
    public let heading: Double
    public let estimatedTravelTime: TimeInterval
    public let isRushHour: Bool
    public let timestamp: Date
    
    public init(
        isInVehicle: Bool,
        currentSpeed: Double,
        heading: Double,
        estimatedTravelTime: TimeInterval,
        isRushHour: Bool,
        timestamp: Date = Date()
    ) {
        self.isInVehicle = isInVehicle
        self.currentSpeed = currentSpeed
        self.heading = heading
        self.estimatedTravelTime = estimatedTravelTime
        self.isRushHour = isRushHour
        self.timestamp = timestamp
    }
}

/// Represents a prediction for a specific route to a bridge
public struct RoutePrediction: Identifiable {
    public let id = UUID()
    public let bridge: DrawbridgeInfo
    public let distance: CLLocationDistance
    public let estimatedTravelTime: TimeInterval
    public let bridgePrediction: MotionBridgePrediction
    public let riskLevel: RiskLevel
    public let timestamp: Date
    
    public init(
        bridge: DrawbridgeInfo,
        distance: CLLocationDistance,
        estimatedTravelTime: TimeInterval,
        bridgePrediction: MotionBridgePrediction,
        riskLevel: RiskLevel,
        timestamp: Date = Date()
    ) {
        self.bridge = bridge
        self.distance = distance
        self.estimatedTravelTime = estimatedTravelTime
        self.bridgePrediction = bridgePrediction
        self.riskLevel = riskLevel
        self.timestamp = timestamp
    }
}

/// Represents a bridge prediction with enhanced context
public struct MotionBridgePrediction {
    public let entityID: Int
    public let entityName: String
    public let probabilityOfOpening: Double
    public let predictedOpenTime: Date?
    public let predictedCloseTime: Date?
    public let riskLevel: RiskLevel
    public let timestamp: Date
    
    public init(
        entityID: Int,
        entityName: String,
        probabilityOfOpening: Double,
        predictedOpenTime: Date?,
        predictedCloseTime: Date?,
        riskLevel: RiskLevel,
        timestamp: Date = Date()
    ) {
        self.entityID = entityID
        self.entityName = entityName
        self.probabilityOfOpening = probabilityOfOpening
        self.predictedOpenTime = predictedOpenTime
        self.predictedCloseTime = predictedCloseTime
        self.riskLevel = riskLevel
        self.timestamp = timestamp
    }
}

/// Risk level for route predictions
public enum RiskLevel: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    
    public var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "orange"
        case .high: return "red"
        }
    }
    
    public var systemImage: String {
        switch self {
        case .low: return "checkmark.circle.fill"
        case .medium: return "exclamationmark.triangle.fill"
        case .high: return "xmark.octagon.fill"
        }
    }
}

// MARK: - Additional Notification Names
public extension Notification.Name {
    static let bridgePredictionUpdated = Notification.Name("bridgePredictionUpdated")
    static let routeRiskDetected = Notification.Name("routeRiskDetected")
} 