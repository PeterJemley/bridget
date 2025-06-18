//
//  DrawbridgeInfo.swift
//  Bridget
//
//  Created by Peter Jemley on 6/18/25.
//

import Foundation
import SwiftData
import CoreLocation

@Model
final class DrawbridgeInfo {
    @Attribute(.unique) var entityID: Int
    var entityName: String
    var entityType: String
    var latitude: Double
    var longitude: Double
    var lastUpdated: Date
    
    // Statistics computed from events
    var totalOpenings: Int = 0
    var averageOpenTimeMinutes: Double = 0
    var longestOpenTimeMinutes: Double = 0
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
    
    init(
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