//
//  DrawbridgeEventTests.swift
//  BridgetCoreTests
//
//  Created by Peter Jemley on 6/19/25.
//

import XCTest
@testable import BridgetCore
import Foundation

final class DrawbridgeEventTests: XCTestCase {
    
    func testDrawbridgeEventCreation() {
        let openDate = Date()
        let event = DrawbridgeEvent(
            entityType: "Bridge",
            entityName: "Test Bridge",
            entityID: 123,
            openDateTime: openDate,
            closeDateTime: nil,
            minutesOpen: 15.5,
            latitude: 47.6062,
            longitude: -122.3321
        )
        
        XCTAssertEqual(event.entityType, "Bridge")
        XCTAssertEqual(event.entityName, "Test Bridge")
        XCTAssertEqual(event.entityID, 123)
        XCTAssertEqual(event.openDateTime, openDate)
        XCTAssertNil(event.closeDateTime)
        XCTAssertEqual(event.minutesOpen, 15.5)
        XCTAssertEqual(event.latitude, 47.6062)
        XCTAssertEqual(event.longitude, -122.3321)
    }
    
    func testIsCurrentlyOpenWhenNoCloseTime() {
        let event = DrawbridgeEvent(
            entityType: "Bridge",
            entityName: "Open Bridge",
            entityID: 1,
            openDateTime: Date(),
            closeDateTime: nil,
            minutesOpen: 10.0,
            latitude: 0, longitude: 0
        )
        
        XCTAssertTrue(event.isCurrentlyOpen)
    }
    
    func testIsCurrentlyOpenWhenClosed() {
        let event = DrawbridgeEvent(
            entityType: "Bridge",
            entityName: "Closed Bridge",
            entityID: 1,
            openDateTime: Date().addingTimeInterval(-3600), // 1 hour ago
            closeDateTime: Date().addingTimeInterval(-1800), // 30 min ago
            minutesOpen: 30.0,
            latitude: 0, longitude: 0
        )
        
        XCTAssertFalse(event.isCurrentlyOpen)
    }
    
    func testStatusText() {
        let openEvent = DrawbridgeEvent(
            entityType: "Bridge", entityName: "Open Bridge", entityID: 1,
            openDateTime: Date(), closeDateTime: nil, minutesOpen: 10.0,
            latitude: 0, longitude: 0
        )
        XCTAssertEqual(openEvent.statusText, "WAS OPEN")
        
        let closedEvent = DrawbridgeEvent(
            entityType: "Bridge", entityName: "Closed Bridge", entityID: 1,
            openDateTime: Date().addingTimeInterval(-3600),
            closeDateTime: Date().addingTimeInterval(-1800),
            minutesOpen: 30.0, latitude: 0, longitude: 0
        )
        XCTAssertEqual(closedEvent.statusText, "CLOSED")
    }
    
    func testRelativeTimeText() {
        let now = Date()
        let event = DrawbridgeEvent(
            entityType: "Bridge", entityName: "Test Bridge", entityID: 1,
            openDateTime: now.addingTimeInterval(-3600), // 1 hour ago
            closeDateTime: now.addingTimeInterval(-1800), // 30 min ago
            minutesOpen: 30.0, latitude: 0, longitude: 0
        )
        
        let relativeTime = event.relativeTimeText
        XCTAssertTrue(relativeTime.contains("ago"))
    }
    
    func testGetUniqueBridges() {
        let events = [
            DrawbridgeEvent(entityType: "Bridge", entityName: "Bridge A", entityID: 1,
                          openDateTime: Date(), closeDateTime: nil, minutesOpen: 10.0,
                          latitude: 47.6, longitude: -122.3),
            DrawbridgeEvent(entityType: "Bridge", entityName: "Bridge A", entityID: 1,
                          openDateTime: Date(), closeDateTime: nil, minutesOpen: 15.0,
                          latitude: 47.6, longitude: -122.3),
            DrawbridgeEvent(entityType: "Bridge", entityName: "Bridge B", entityID: 2,
                          openDateTime: Date(), closeDateTime: nil, minutesOpen: 20.0,
                          latitude: 47.7, longitude: -122.4)
        ]
        
        let uniqueBridges = DrawbridgeEvent.getUniqueBridges(events)
        XCTAssertEqual(uniqueBridges.count, 2)
        
        let bridgeNames = uniqueBridges.map(\.entityName).sorted()
        XCTAssertEqual(bridgeNames, ["Bridge A", "Bridge B"])
    }
    
    func testMinutesOpenFormatting() {
        let shortEvent = DrawbridgeEvent(
            entityType: "Bridge", entityName: "Short Bridge", entityID: 1,
            openDateTime: Date(), closeDateTime: nil, minutesOpen: 2.5,
            latitude: 0, longitude: 0
        )
        XCTAssertEqual(shortEvent.minutesOpen, 2.5)
        
        let longEvent = DrawbridgeEvent(
            entityType: "Bridge", entityName: "Long Bridge", entityID: 1,
            openDateTime: Date(), closeDateTime: nil, minutesOpen: 125.0,
            latitude: 0, longitude: 0
        )
        XCTAssertEqual(longEvent.minutesOpen, 125.0)
    }
    
    func testEventEquality() {
        let date = Date()
        let event1 = DrawbridgeEvent(
            entityType: "Bridge", entityName: "Test Bridge", entityID: 1,
            openDateTime: date, closeDateTime: nil, minutesOpen: 10.0,
            latitude: 47.6, longitude: -122.3
        )
        
        let event2 = DrawbridgeEvent(
            entityType: "Bridge", entityName: "Test Bridge", entityID: 1,
            openDateTime: date, closeDateTime: nil, minutesOpen: 10.0,
            latitude: 47.6, longitude: -122.3
        )
        
        // Events should be considered equal if they have same entityID, openDateTime, and minutesOpen
        XCTAssertEqual(event1.entityID, event2.entityID)
        XCTAssertEqual(event1.openDateTime, event2.openDateTime)
        XCTAssertEqual(event1.minutesOpen, event2.minutesOpen)
    }
}