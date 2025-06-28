//
//  DTOs.swift
//  BridgetCore
//
//  Created by Peter Jemley on 6/19/25.
//

import Foundation

// MARK: - Sendable DTOs for Thread-Safe Concurrency

/// Thread-safe DTO for DrawbridgeEvent data transfer across concurrency boundaries
public struct EventDTO: Sendable, Codable {
    public let entityType: String
    public let entityName: String
    public let entityID: Int
    public let openDateTime: Date
    public let closeDateTime: Date?
    public let minutesOpen: Double
    public let latitude: Double
    public let longitude: Double
    
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
    
    public init(from event: DrawbridgeEvent) {
        self.entityType = event.entityType
        self.entityName = event.entityName
        self.entityID = event.entityID
        self.openDateTime = event.openDateTime
        self.closeDateTime = event.closeDateTime
        self.minutesOpen = event.minutesOpen
        self.latitude = event.latitude
        self.longitude = event.longitude
    }
}

/// Thread-safe DTO for CascadeEvent data transfer across concurrency boundaries
public struct CascadeEventDTO: Sendable, Codable {
    public let triggerBridgeID: Int
    public let triggerBridgeName: String
    public let targetBridgeID: Int
    public let targetBridgeName: String
    public let triggerTime: Date
    public let targetTime: Date
    public let delayMinutes: Double
    public let triggerDuration: Double
    public let targetDuration: Double
    public let cascadeStrength: Double
    public let cascadeType: String
    public let dayOfWeek: Int
    public let hour: Int
    public let month: Int
    public let isWeekend: Bool
    public let isSummer: Bool
    
    public init(
        triggerBridgeID: Int,
        triggerBridgeName: String,
        targetBridgeID: Int,
        targetBridgeName: String,
        triggerTime: Date,
        targetTime: Date,
        delayMinutes: Double,
        triggerDuration: Double,
        targetDuration: Double,
        cascadeStrength: Double,
        cascadeType: String,
        dayOfWeek: Int,
        hour: Int,
        month: Int,
        isWeekend: Bool,
        isSummer: Bool
    ) {
        self.triggerBridgeID = triggerBridgeID
        self.triggerBridgeName = triggerBridgeName
        self.targetBridgeID = targetBridgeID
        self.targetBridgeName = targetBridgeName
        self.triggerTime = triggerTime
        self.targetTime = targetTime
        self.delayMinutes = delayMinutes
        self.triggerDuration = triggerDuration
        self.targetDuration = targetDuration
        self.cascadeStrength = cascadeStrength
        self.cascadeType = cascadeType
        self.dayOfWeek = dayOfWeek
        self.hour = hour
        self.month = month
        self.isWeekend = isWeekend
        self.isSummer = isSummer
    }
    
    public init(from cascadeEvent: CascadeEvent) {
        self.triggerBridgeID = cascadeEvent.triggerBridgeID
        self.triggerBridgeName = cascadeEvent.triggerBridgeName
        self.targetBridgeID = cascadeEvent.targetBridgeID
        self.targetBridgeName = cascadeEvent.targetBridgeName
        self.triggerTime = cascadeEvent.triggerTime
        self.targetTime = cascadeEvent.targetTime
        self.delayMinutes = cascadeEvent.delayMinutes
        self.triggerDuration = cascadeEvent.triggerDuration
        self.targetDuration = cascadeEvent.targetDuration
        self.cascadeStrength = cascadeEvent.cascadeStrength
        self.cascadeType = cascadeEvent.cascadeType
        self.dayOfWeek = cascadeEvent.dayOfWeek
        self.hour = cascadeEvent.hour
        self.month = cascadeEvent.month
        self.isWeekend = cascadeEvent.isWeekend
        self.isSummer = cascadeEvent.isSummer
    }
}

/// Thread-safe DTO for BridgeAnalytics data transfer across concurrency boundaries
public struct BridgeAnalyticsDTO: Sendable, Codable {
    public let entityID: Int
    public let entityName: String
    public let year: Int
    public let month: Int
    public let dayOfWeek: Int
    public let hour: Int
    public let openingCount: Int
    public let totalMinutesOpen: Double
    public let averageMinutesPerOpening: Double
    public let longestOpeningMinutes: Double
    public let shortestOpeningMinutes: Double
    public let probabilityOfOpening: Double
    public let expectedDuration: Double
    public let confidence: Double
    
    public init(
        entityID: Int,
        entityName: String,
        year: Int,
        month: Int,
        dayOfWeek: Int,
        hour: Int,
        openingCount: Int,
        totalMinutesOpen: Double,
        averageMinutesPerOpening: Double,
        longestOpeningMinutes: Double,
        shortestOpeningMinutes: Double,
        probabilityOfOpening: Double,
        expectedDuration: Double,
        confidence: Double
    ) {
        self.entityID = entityID
        self.entityName = entityName
        self.year = year
        self.month = month
        self.dayOfWeek = dayOfWeek
        self.hour = hour
        self.openingCount = openingCount
        self.totalMinutesOpen = totalMinutesOpen
        self.averageMinutesPerOpening = averageMinutesPerOpening
        self.longestOpeningMinutes = longestOpeningMinutes
        self.shortestOpeningMinutes = shortestOpeningMinutes
        self.probabilityOfOpening = probabilityOfOpening
        self.expectedDuration = expectedDuration
        self.confidence = confidence
    }
    
    public init(from analytics: BridgeAnalytics) {
        self.entityID = analytics.entityID
        self.entityName = analytics.entityName
        self.year = analytics.year
        self.month = analytics.month
        self.dayOfWeek = analytics.dayOfWeek
        self.hour = analytics.hour
        self.openingCount = analytics.openingCount
        self.totalMinutesOpen = analytics.totalMinutesOpen
        self.averageMinutesPerOpening = analytics.averageMinutesPerOpening
        self.longestOpeningMinutes = analytics.longestOpeningMinutes
        self.shortestOpeningMinutes = analytics.shortestOpeningMinutes
        self.probabilityOfOpening = analytics.probabilityOfOpening
        self.expectedDuration = analytics.expectedDuration
        self.confidence = analytics.confidence
    }
}

/// Thread-safe DTO for DrawbridgeInfo data transfer across concurrency boundaries
public struct BridgeInfoDTO: Sendable, Codable {
    public let entityID: Int
    public let entityName: String
    public let entityType: String
    public let latitude: Double
    public let longitude: Double
    public let lastUpdated: Date
    public let totalOpenings: Int
    public let averageOpenTimeMinutes: Double
    public let longestOpenTimeMinutes: Double
    
    public init(
        entityID: Int,
        entityName: String,
        entityType: String,
        latitude: Double,
        longitude: Double,
        lastUpdated: Date,
        totalOpenings: Int,
        averageOpenTimeMinutes: Double,
        longestOpenTimeMinutes: Double
    ) {
        self.entityID = entityID
        self.entityName = entityName
        self.entityType = entityType
        self.latitude = latitude
        self.longitude = longitude
        self.lastUpdated = lastUpdated
        self.totalOpenings = totalOpenings
        self.averageOpenTimeMinutes = averageOpenTimeMinutes
        self.longestOpenTimeMinutes = longestOpenTimeMinutes
    }
    
    public init(from bridgeInfo: DrawbridgeInfo) {
        self.entityID = bridgeInfo.entityID
        self.entityName = bridgeInfo.entityName
        self.entityType = bridgeInfo.entityType
        self.latitude = bridgeInfo.latitude
        self.longitude = bridgeInfo.longitude
        self.lastUpdated = bridgeInfo.lastUpdated
        self.totalOpenings = bridgeInfo.totalOpenings
        self.averageOpenTimeMinutes = bridgeInfo.averageOpenTimeMinutes
        self.longestOpenTimeMinutes = bridgeInfo.longestOpenTimeMinutes
    }
}

// MARK: - Convenience Extensions

public extension Array where Element == DrawbridgeEvent {
    /// Convert to thread-safe DTOs for concurrency
    var toDTOs: [EventDTO] {
        map { EventDTO(from: $0) }
    }
}

public extension Array where Element == CascadeEvent {
    /// Convert to thread-safe DTOs for concurrency
    var toDTOs: [CascadeEventDTO] {
        map { CascadeEventDTO(from: $0) }
    }
}

public extension Array where Element == BridgeAnalytics {
    /// Convert to thread-safe DTOs for concurrency
    var toDTOs: [BridgeAnalyticsDTO] {
        map { BridgeAnalyticsDTO(from: $0) }
    }
}

public extension Array where Element == DrawbridgeInfo {
    /// Convert to thread-safe DTOs for concurrency
    var toDTOs: [BridgeInfoDTO] {
        map { BridgeInfoDTO(from: $0) }
    }
} 