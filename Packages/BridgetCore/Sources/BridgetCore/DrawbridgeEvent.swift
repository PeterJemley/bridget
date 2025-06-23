//
//  DrawbridgeEvent.swift
//  BridgetCore
//
//  Created by Peter Jemley on 6/19/25.
//

import Foundation
import SwiftData
import CoreLocation
import SwiftUI

@Model
public final class DrawbridgeEvent {
    @Attribute(.unique) public var id: String
    
    public var entityType: String
    public var entityName: String
    public var entityID: Int
    public var openDateTime: Date
    public var closeDateTime: Date?
    public var minutesOpen: Double
    public var latitude: Double
    public var longitude: Double
    
    // Computed properties for convenience
    public var isCurrentlyOpen: Bool {
        closeDateTime == nil
    }
    
    public var duration: TimeInterval? {
        guard let closeDateTime = closeDateTime else { return nil }
        return closeDateTime.timeIntervalSince(openDateTime)
    }
    
    public var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    public var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
    
    public var relativeTimeText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: openDateTime, relativeTo: Date())
    }
    
    // Smart traffic impact classification (replaces "Moderate" everywhere)
    public var trafficImpact: TrafficImpact {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: openDateTime)
        let weekday = calendar.component(.weekday, from: openDateTime)
        let isWeekend = weekday == 1 || weekday == 7
        let isRushHour = !isWeekend && ((hour >= 7 && hour <= 9) || (hour >= 16 && hour <= 18))
        
        // Smart impact calculation based on duration, time, and bridge type
        switch minutesOpen {
        case 0..<5:
            return isRushHour ? .low : .minimal
        case 5..<15:
            if isRushHour {
                return entityName.lowercased().contains("fremont") ? .high : .moderate
            } else {
                return .low
            }
        case 15..<30:
            if isRushHour {
                return .high
            } else {
                return entityName.lowercased().contains("fremont") ? .moderate : .low
            }
        case 30..<60:
            return isRushHour ? .severe : .high
        default:
            return .severe
        }
    }

    // Impact severity for UI display with variety
    public var impactSeverity: ImpactSeverity {
        switch trafficImpact {
        case .minimal: return ImpactSeverity(level: "Minimal", color: .green, systemImage: "checkmark.circle")
        case .low: return ImpactSeverity(level: "Low", color: .blue, systemImage: "info.circle")
        case .moderate: return ImpactSeverity(level: "Moderate", color: .orange, systemImage: "exclamationmark.triangle")
        case .high: return ImpactSeverity(level: "High", color: .red, systemImage: "exclamationmark.triangle.fill")
        case .severe: return ImpactSeverity(level: "Severe", color: .purple, systemImage: "xmark.octagon.fill")
        }
    }
    
    public init(
        entityType: String,
        entityName: String,
        entityID: Int,
        openDateTime: Date,
        closeDateTime: Date? = nil,
        minutesOpen: Double,
        latitude: Double,
        longitude: Double
    ) {
        self.id = "\(entityID)-\(Int(openDateTime.timeIntervalSince1970))"
        self.entityType = entityType
        self.entityName = entityName
        self.entityID = entityID
        self.openDateTime = openDateTime
        self.closeDateTime = closeDateTime
        self.minutesOpen = minutesOpen
        self.latitude = latitude
        self.longitude = longitude
    }
}

// Traffic impact enums and supporting types
public enum TrafficImpact: String, CaseIterable {
    case minimal = "Minimal"
    case low = "Low"
    case moderate = "Moderate"
    case high = "High"
    case severe = "Severe"
}

public struct ImpactSeverity {
    public let level: String
    public let color: Color
    public let systemImage: String
    
    public init(level: String, color: Color, systemImage: String) {
        self.level = level
        self.color = color
        self.systemImage = systemImage
    }
}

// MARK: - Extensions for grouping and filtering
extension DrawbridgeEvent {
    public static func groupedByBridge(_ events: [DrawbridgeEvent]) -> [String: [DrawbridgeEvent]] {
        Dictionary(grouping: events, by: { $0.entityName })
    }
    
    public static func getUniqueBridges(_ events: [DrawbridgeEvent]) -> [(entityID: Int, entityName: String, entityType: String, latitude: Double, longitude: Double)] {
        var uniqueBridges: [Int: (entityID: Int, entityName: String, entityType: String, latitude: Double, longitude: Double)] = [:]
        
        for event in events {
            if uniqueBridges[event.entityID] == nil {
                uniqueBridges[event.entityID] = (
                    entityID: event.entityID,
                    entityName: event.entityName,
                    entityType: event.entityType,
                    latitude: event.latitude,
                    longitude: event.longitude
                )
            }
        }
        
        return Array(uniqueBridges.values)
    }
    
    public static func eventsToday(_ events: [DrawbridgeEvent]) -> [DrawbridgeEvent] {
        let calendar = Calendar.current
        let today = Date()
        return events.filter { calendar.isDate($0.openDateTime, inSameDayAs: today) }
    }
    
    public static func currentlyOpenBridges(_ events: [DrawbridgeEvent]) -> [DrawbridgeEvent] {
        events.filter { $0.isCurrentlyOpen }
    }
}
