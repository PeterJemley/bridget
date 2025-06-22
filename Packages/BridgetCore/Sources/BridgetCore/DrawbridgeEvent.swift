//
//  DrawbridgeEvent.swift
//  BridgetCore
//
//  Created by Peter Jemley on 6/19/25.
//

import Foundation
import SwiftData
import CoreLocation

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