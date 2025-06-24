//
//  DrawbridgeEvent.swift
//  BridgetCore
//
//  Created by Peter Jemley on 6/19/25.
//

import Foundation
import SwiftData

@Model
public final class DrawbridgeEvent {
    public var entityType: String
    public var entityName: String
    public var entityID: Int
    public var openDateTime: Date
    public var closeDateTime: Date?
    public var minutesOpen: Double
    public var latitude: Double
    public var longitude: Double
    
    public init(
        entityType: String,
        entityName: String,
        entityID: Int,
        openDateTime: Date,
        closeDateTime: Date?,
        minutesOpen: Double,
        latitude: Double,
        longitude: Double
    ) {
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

// MARK: - Computed Properties
public extension DrawbridgeEvent {
    var isCurrentlyOpen: Bool {
        return closeDateTime == nil
    }
    
    // Basic relative time formatting
    var relativeTimeText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: openDateTime, relativeTo: Date())
    }
    
    var formattedOpenTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a" // Default to 12-hour format
        return formatter.string(from: openDateTime)
    }
    
    var formattedOpenDateTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a" // Default to 12-hour format
        return formatter.string(from: openDateTime)
    }
    
    // UPDATED: Smart traffic impact classification
    var impactSeverity: ImpactSeverity {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: openDateTime)
        let weekday = calendar.component(.weekday, from: openDateTime)
        
        // Base severity from duration
        var severity: TrafficImpact = .minimal
        
        switch minutesOpen {
        case 0..<5: severity = .minimal
        case 5..<15: severity = .low
        case 15..<30: severity = .moderate
        case 30..<60: severity = .high
        default: severity = .severe
        }
        
        // Adjust for time of day (rush hour impact)
        let isRushHour = (hour >= 7 && hour <= 9) || (hour >= 17 && hour <= 19)
        if isRushHour {
            severity = TrafficImpact(rawValue: min(severity.rawValue + 1, TrafficImpact.severe.rawValue)) ?? severity
        }
        
        // Adjust for weekday vs weekend
        let isWeekend = weekday == 1 || weekday == 7
        if isWeekend && severity.rawValue > 0 {
            severity = TrafficImpact(rawValue: severity.rawValue - 1) ?? severity
        }
        
        // Bridge-specific adjustments
        if entityName.lowercased().contains("fremont") && severity.rawValue < TrafficImpact.severe.rawValue {
            severity = TrafficImpact(rawValue: severity.rawValue + 1) ?? severity
        }
        
        return ImpactSeverity(severity)
    }
}

// MARK: - Static Helper Methods
public extension DrawbridgeEvent {
    static func eventsToday(_ events: [DrawbridgeEvent]) -> [DrawbridgeEvent] {
        let calendar = Calendar.current
        let today = Date()
        
        return events.filter { event in
            calendar.isDate(event.openDateTime, inSameDayAs: today)
        }
    }
    
    static func getUniqueBridges(_ events: [DrawbridgeEvent]) -> [(entityID: Int, entityName: String, entityType: String, latitude: Double, longitude: Double)] {
        let uniqueData = Dictionary(grouping: events, by: \.entityID)
            .compactMapValues { $0.first }
        
        return uniqueData.values.map { event in
            (
                entityID: event.entityID,
                entityName: event.entityName,
                entityType: event.entityType,
                latitude: event.latitude,
                longitude: event.longitude
            )
        }
        .sorted { $0.entityName < $1.entityName }
    }
    
    static func filterByRetentionDate(_ events: [DrawbridgeEvent], retentionDate: Date?) -> [DrawbridgeEvent] {
        guard let retentionDate = retentionDate else { return events }
        return events.filter { $0.openDateTime >= retentionDate }
    }
}

// MARK: - Impact Classification System

public enum TrafficImpact: Int, CaseIterable {
    case minimal = 0
    case low = 1 
    case moderate = 2
    case high = 3
    case severe = 4
}

public struct ImpactSeverity {
    public let impact: TrafficImpact
    
    public init(_ impact: TrafficImpact) {
        self.impact = impact
    }
    
    public var level: String {
        switch impact {
        case .minimal: return "Minimal"
        case .low: return "Low"
        case .moderate: return "Moderate" 
        case .high: return "High"
        case .severe: return "Severe"
        }
    }
    
    public var color: Color {
        switch impact {
        case .minimal: return .green
        case .low: return .mint
        case .moderate: return .orange
        case .high: return .red
        case .severe: return .purple
        }
    }
    
    public var systemImage: String {
        switch impact {
        case .minimal: return "checkmark.circle.fill"
        case .low: return "info.circle.fill"
        case .moderate: return "exclamationmark.triangle.fill"
        case .high: return "exclamationmark.octagon.fill"
        case .severe: return "xmark.octagon.fill"
        }
    }
}

// MARK: - Color Extension
import SwiftUI

extension Color {
    public static let mint = Color(red: 0.0, green: 0.8, blue: 0.7)
}