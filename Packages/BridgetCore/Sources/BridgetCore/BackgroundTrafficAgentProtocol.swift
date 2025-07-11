//
//  BackgroundTrafficAgentProtocol.swift
//  BridgetCore
//
//  Created by AI Assistant on 1/15/25.
//

import Foundation
import Combine

// MARK: - Platform-Agnostic Background Traffic Agent Protocol

/// Platform-agnostic protocol for background traffic monitoring
/// This allows different implementations for iOS (BackgroundTasks) and macOS (stub)
@preconcurrency
public protocol BackgroundTrafficAgentProtocol: ObservableObject {
    /// Whether background monitoring is currently active
    var isMonitoring: Bool { get }
    
    /// Last update time
    var lastUpdateTime: Date? { get }
    
    /// Background alerts
    var backgroundAlerts: [TrafficAlert] { get }
    
    /// Current monitoring status
    var monitoringStatus: MonitoringStatus { get }
    
    /// Start background monitoring
    func startBackgroundMonitoring()
    
    /// Stop background monitoring
    func stopBackgroundMonitoring()
    
    /// Clear all stored alerts
    func clearAlerts()
    
    /// Get active alerts from the last hour
    func getActiveAlerts() -> [TrafficAlert]
}

// MARK: - Monitoring Status Enum

public enum MonitoringStatus: String, CaseIterable {
    case inactive = "Inactive"
    case active = "Active"
    case enhanced = "Enhanced"
    case expired = "Expired"
}

// MARK: - Traffic Alert Types

public enum AlertType: String, CaseIterable, Codable {
    case trafficWorsening = "Traffic Worsening"
    case highRiskRoute = "High Risk Route"
    case bridgeOpening = "Bridge Opening"
    case routeChange = "Route Change"
}

public enum AlertSeverity: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
    
    public var systemImage: String {
        switch self {
        case .low: return "info.circle"
        case .medium: return "exclamationmark.triangle"
        case .high: return "exclamationmark.octagon"
        case .critical: return "xmark.octagon"
        }
    }
}

// MARK: - Traffic Alert

public struct TrafficAlert: Identifiable, Codable {
    public let id = UUID()
    public let type: AlertType
    public let message: String
    public let severity: AlertSeverity
    public let timestamp: Date
    
    public init(type: AlertType, message: String, severity: AlertSeverity) {
        self.type = type
        self.message = message
        self.severity = severity
        self.timestamp = Date()
    }
} 