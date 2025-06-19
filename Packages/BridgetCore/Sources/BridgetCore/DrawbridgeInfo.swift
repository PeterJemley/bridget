//
//  DrawbridgeInfo.swift
//  BridgetCore
//
//  Created by Peter Jemley on 6/19/25.
//

import Foundation
import SwiftData
import CoreLocation

@Model
public final class DrawbridgeInfo {
    @Attribute(.unique) public var entityID: Int
    public var entityName: String
    public var entityType: String
    public var latitude: Double
    public var longitude: Double
    public var lastUpdated: Date
    
    // Statistics computed from events
    public var totalOpenings: Int = 0
    public var averageOpenTimeMinutes: Double = 0
    public var longestOpenTimeMinutes: Double = 0
    
    public var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    public var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
    
    public init(
        entityID: Int,
        entityName: String,
        entityType: String,
        latitude: Double,
        longitude: Double,
        lastUpdated: Date = Date()
    ) {
        self.entityID = entityID
        self.entityName = entityName
        self.entityType = entityType
        self.latitude = latitude
        self.longitude = longitude
        self.lastUpdated = lastUpdated
    }
}