//
//  DrawbridgeEvent.swift
//  Bridget
//
//  Created by Peter Jemley on 6/18/25.
//

import Foundation
import SwiftData
import CoreLocation

@Model
final class DrawbridgeEvent {
    var entityType: String
    var entityName: String
    var entityID: Int
    var openDateTime: Date
    var closeDateTime: Date?
    var minutesOpen: Double
    var latitude: Double
    var longitude: Double
    
    // Computed properties for convenience
    var isCurrentlyOpen: Bool {
        closeDateTime == nil
    }
    
    var duration: TimeInterval? {
        guard let closeDateTime = closeDateTime else { return nil }
        return closeDateTime.timeIntervalSince(openDateTime)
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
    
    init(
        entityType: String,
        entityName: String,
        entityID: Int,
        openDateTime: Date,
        closeDateTime: Date? = nil,
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

// MARK: - Extensions for grouping and filtering
extension DrawbridgeEvent {
    static func groupedByBridge(_ events: [DrawbridgeEvent]) -> [String: [DrawbridgeEvent]] {
        Dictionary(grouping: events, by: { $0.entityName })
    }
    
    static func eventsToday(_ events: [DrawbridgeEvent]) -> [DrawbridgeEvent] {
        let calendar = Calendar.current
        let today = Date()
        return events.filter { calendar.isDate($0.openDateTime, inSameDayAs: today) }
    }
    
    static func currentlyOpenBridges(_ events: [DrawbridgeEvent]) -> [DrawbridgeEvent] {
        events.filter { $0.isCurrentlyOpen }
    }
}