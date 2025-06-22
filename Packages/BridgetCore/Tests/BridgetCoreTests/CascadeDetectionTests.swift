//
//  CascadeDetectionTests.swift
//  BridgetCoreTests
//
//  Created by Peter Jemley on 6/19/25.
//

import XCTest
@testable import BridgetCore
import Foundation

final class CascadeDetectionTests: XCTestCase {
    
    func testCascadeEventCreation() {
        let triggerTime = Date()
        let targetTime = triggerTime.addingTimeInterval(15 * 60) // 15 minutes later
        
        let cascade = CascadeEvent(
            triggerBridgeID: 1,
            triggerBridgeName: "Ballard Bridge",
            targetBridgeID: 2,
            targetBridgeName: "Fremont Bridge",
            triggerTime: triggerTime,
            targetTime: targetTime,
            triggerDuration: 12.0,
            targetDuration: 8.0,
            cascadeStrength: 0.75,
            cascadeType: "short-term"
        )
        
        XCTAssertEqual(cascade.triggerBridgeID, 1)
        XCTAssertEqual(cascade.targetBridgeID, 2)
        XCTAssertEqual(cascade.delayMinutes, 15.0)
        XCTAssertEqual(cascade.cascadeStrength, 0.75)
        XCTAssertEqual(cascade.cascadeType, "short-term")
    }
    
    func testCascadeDetectionWithSimpleSequence() {
        let baseTime = Date()
        
        // Create a simple cascade sequence: Bridge 1 opens, then Bridge 2 opens 10 minutes later
        let events = [
            DrawbridgeEvent(
                entityType: "Bridge", entityName: "Bridge A", entityID: 1,
                openDateTime: baseTime, closeDateTime: baseTime.addingTimeInterval(600),
                minutesOpen: 10.0, latitude: 47.6, longitude: -122.3
            ),
            DrawbridgeEvent(
                entityType: "Bridge", entityName: "Bridge B", entityID: 2,
                openDateTime: baseTime.addingTimeInterval(600), // 10 minutes later
                closeDateTime: baseTime.addingTimeInterval(1200),
                minutesOpen: 10.0, latitude: 47.7, longitude: -122.4
            )
        ]
        
        let cascades = CascadeDetectionEngine.detectCascadeEffects(from: events)
        
        XCTAssertFalse(cascades.isEmpty, "Should detect at least one cascade")
        
        if let firstCascade = cascades.first {
            XCTAssertEqual(firstCascade.triggerBridgeID, 1)
            XCTAssertEqual(firstCascade.targetBridgeID, 2)
            XCTAssertEqual(firstCascade.delayMinutes, 10.0)
            XCTAssertGreaterThan(firstCascade.cascadeStrength, 0.3, "Should have significant cascade strength")
        }
    }
    
    func testCascadeDetectionWithMultipleBridges() {
        let baseTime = Date()
        
        // Create a multi-bridge cascade sequence
        let events = [
            // Bridge 1 triggers cascade
            DrawbridgeEvent(
                entityType: "Bridge", entityName: "Bridge A", entityID: 1,
                openDateTime: baseTime, closeDateTime: baseTime.addingTimeInterval(900),
                minutesOpen: 15.0, latitude: 47.6, longitude: -122.3
            ),
            // Bridge 2 responds after 5 minutes
            DrawbridgeEvent(
                entityType: "Bridge", entityName: "Bridge B", entityID: 2,
                openDateTime: baseTime.addingTimeInterval(300), closeDateTime: baseTime.addingTimeInterval(1200),
                minutesOpen: 15.0, latitude: 47.7, longitude: -122.4
            ),
            // Bridge 3 responds after 20 minutes
            DrawbridgeEvent(
                entityType: "Bridge", entityName: "Bridge C", entityID: 3,
                openDateTime: baseTime.addingTimeInterval(1200), closeDateTime: baseTime.addingTimeInterval(2100),
                minutesOpen: 15.0, latitude: 47.8, longitude: -122.5
            )
        ]
        
        let cascades = CascadeDetectionEngine.detectCascadeEffects(from: events)
        
        // Should detect two cascades: 1->2 and 1->3
        XCTAssertGreaterThanOrEqual(cascades.count, 2)
        
        // Check that we have cascades from Bridge 1
        let bridge1Cascades = cascades.filter { $0.triggerBridgeID == 1 }
        XCTAssertGreaterThanOrEqual(bridge1Cascades.count, 2)
        
        // Check timing
        let shortCascade = bridge1Cascades.first { $0.targetBridgeID == 2 }
        let longCascade = bridge1Cascades.first { $0.targetBridgeID == 3 }
        
        XCTAssertNotNil(shortCascade)
        XCTAssertNotNil(longCascade)
        
        if let short = shortCascade, let long = longCascade {
            XCTAssertEqual(short.delayMinutes, 5.0)
            XCTAssertEqual(long.delayMinutes, 20.0)
            XCTAssertGreaterThan(short.cascadeStrength, long.cascadeStrength, "Shorter delay should have stronger correlation")
        }
    }
    
    func testCascadeDetectionIgnoresLongDelays() {
        let baseTime = Date()
        
        // Create events with 45-minute delay (outside 30-minute window)
        let events = [
            DrawbridgeEvent(
                entityType: "Bridge", entityName: "Bridge A", entityID: 1,
                openDateTime: baseTime, closeDateTime: baseTime.addingTimeInterval(600),
                minutesOpen: 10.0, latitude: 47.6, longitude: -122.3
            ),
            DrawbridgeEvent(
                entityType: "Bridge", entityName: "Bridge B", entityID: 2,
                openDateTime: baseTime.addingTimeInterval(2700), // 45 minutes later
                closeDateTime: baseTime.addingTimeInterval(3300),
                minutesOpen: 10.0, latitude: 47.7, longitude: -122.4
            )
        ]
        
        let cascades = CascadeDetectionEngine.detectCascadeEffects(from: events)
        
        // Should not detect cascades outside the 30-minute window
        let longDelayCascades = cascades.filter { $0.delayMinutes > 30 }
        XCTAssertEqual(longDelayCascades.count, 0, "Should not detect cascades with delays > 30 minutes")
    }
    
    func testCascadeStrengthCalculation() {
        let baseTime = Date()
        
        // Test immediate cascade (high strength)
        let immediateEvents = [
            DrawbridgeEvent(
                entityType: "Bridge", entityName: "Bridge A", entityID: 1,
                openDateTime: baseTime, closeDateTime: baseTime.addingTimeInterval(600),
                minutesOpen: 10.0, latitude: 47.6, longitude: -122.3
            ),
            DrawbridgeEvent(
                entityType: "Bridge", entityName: "Bridge B", entityID: 2,
                openDateTime: baseTime.addingTimeInterval(120), // 2 minutes later
                closeDateTime: baseTime.addingTimeInterval(720),
                minutesOpen: 10.0, latitude: 47.7, longitude: -122.4
            )
        ]
        
        // Test delayed cascade (lower strength)
        let delayedEvents = [
            DrawbridgeEvent(
                entityType: "Bridge", entityName: "Bridge C", entityID: 3,
                openDateTime: baseTime, closeDateTime: baseTime.addingTimeInterval(600),
                minutesOpen: 10.0, latitude: 47.8, longitude: -122.5
            ),
            DrawbridgeEvent(
                entityType: "Bridge", entityName: "Bridge D", entityID: 4,
                openDateTime: baseTime.addingTimeInterval(1500), // 25 minutes later
                closeDateTime: baseTime.addingTimeInterval(2100),
                minutesOpen: 10.0, latitude: 47.9, longitude: -122.6
            )
        ]
        
        let immediateCascades = CascadeDetectionEngine.detectCascadeEffects(from: immediateEvents)
        let delayedCascades = CascadeDetectionEngine.detectCascadeEffects(from: delayedEvents)
        
        if let immediate = immediateCascades.first, let delayed = delayedCascades.first {
            XCTAssertGreaterThan(immediate.cascadeStrength, delayed.cascadeStrength,
                               "Immediate cascade should have higher strength than delayed cascade")
        }
    }
    
    func testCascadeAnalyticsIntegration() {
        let baseTime = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .weekday, .hour], from: baseTime)
        
        // Create cascade sequence
        let events = [
            DrawbridgeEvent(
                entityType: "Bridge", entityName: "Trigger Bridge", entityID: 1,
                openDateTime: baseTime, closeDateTime: baseTime.addingTimeInterval(600),
                minutesOpen: 10.0, latitude: 47.6, longitude: -122.3
            ),
            DrawbridgeEvent(
                entityType: "Bridge", entityName: "Target Bridge", entityID: 2,
                openDateTime: baseTime.addingTimeInterval(300), closeDateTime: baseTime.addingTimeInterval(900),
                minutesOpen: 10.0, latitude: 47.7, longitude: -122.4
            )
        ]
        
        // Calculate analytics with cascade detection
        let analytics = BridgeAnalyticsCalculator.calculateAnalytics(from: events)
        
        XCTAssertFalse(analytics.isEmpty)
        
        // Check that cascade metrics are populated
        let triggerAnalytics = analytics.filter { $0.entityID == 1 && $0.year == components.year && $0.month == components.month }
        let targetAnalytics = analytics.filter { $0.entityID == 2 && $0.year == components.year && $0.month == components.month }
        
        XCTAssertFalse(triggerAnalytics.isEmpty)
        XCTAssertFalse(targetAnalytics.isEmpty)
        
        // Trigger bridge should have cascade influence
        if let trigger = triggerAnalytics.first {
            XCTAssertGreaterThan(trigger.cascadeInfluence, 0, "Trigger bridge should have cascade influence")
            XCTAssertGreaterThan(trigger.cascadeProbability, 0, "Trigger bridge should have cascade probability")
        }
        
        // Target bridge should have cascade susceptibility
        if let target = targetAnalytics.first {
            XCTAssertGreaterThan(target.cascadeSusceptibility, 0, "Target bridge should have cascade susceptibility")
        }
    }
    
    func testCascadeTypeClassification() {
        let baseTime = Date()
        
        let testCases = [
            (delay: 2.0, expectedType: "immediate"),    // < 5 minutes
            (delay: 8.0, expectedType: "short-term"),   // 5-15 minutes
            (delay: 20.0, expectedType: "medium-term"), // 15-30 minutes
        ]
        
        for testCase in testCases {
            let events = [
                DrawbridgeEvent(
                    entityType: "Bridge", entityName: "Bridge A", entityID: 1,
                    openDateTime: baseTime, closeDateTime: baseTime.addingTimeInterval(600),
                    minutesOpen: 10.0, latitude: 47.6, longitude: -122.3
                ),
                DrawbridgeEvent(
                    entityType: "Bridge", entityName: "Bridge B", entityID: 2,
                    openDateTime: baseTime.addingTimeInterval(testCase.delay * 60),
                    closeDateTime: baseTime.addingTimeInterval(testCase.delay * 60 + 600),
                    minutesOpen: 10.0, latitude: 47.7, longitude: -122.4
                )
            ]
            
            let cascades = CascadeDetectionEngine.detectCascadeEffects(from: events)
            
            if let cascade = cascades.first {
                XCTAssertEqual(cascade.cascadeType, testCase.expectedType,
                             "Cascade with \(testCase.delay) minute delay should be classified as \(testCase.expectedType)")
            }
        }
    }
    
    func testCascadeInsightsGeneration() {
        let cascadeEvents = [
            CascadeEvent(
                triggerBridgeID: 1, triggerBridgeName: "Ballard Bridge",
                targetBridgeID: 2, targetBridgeName: "Fremont Bridge",
                triggerTime: Date(), targetTime: Date().addingTimeInterval(300),
                triggerDuration: 10.0, targetDuration: 8.0,
                cascadeStrength: 0.8, cascadeType: "short-term"
            ),
            CascadeEvent(
                triggerBridgeID: 1, triggerBridgeName: "Ballard Bridge",
                targetBridgeID: 3, targetBridgeName: "Aurora Bridge",
                triggerTime: Date(), targetTime: Date().addingTimeInterval(600),
                triggerDuration: 10.0, targetDuration: 12.0,
                cascadeStrength: 0.6, cascadeType: "medium-term"
            )
        ]
        
        let analytics = [
            BridgeAnalytics(entityID: 1, entityName: "Ballard Bridge", year: 2025, month: 6, dayOfWeek: 4, hour: 14)
        ]
        
        let insights = CascadeInsights.generateCascadeInsights(
            for: 1,
            from: cascadeEvents,
            analytics: analytics
        )
        
        XCTAssertFalse(insights.isEmpty, "Should generate cascade insights")
        XCTAssertTrue(insights.contains { $0.contains("High cascade influence") },
                     "Should identify high cascade influence")
        XCTAssertTrue(insights.contains { $0.contains("Fremont Bridge") },
                     "Should identify primary cascade target")
    }
    
    func testCascadeAlertsGeneration() {
        let now = Date()
        let recentTrigger = DrawbridgeEvent(
            entityType: "Bridge", entityName: "Ballard Bridge", entityID: 1,
            openDateTime: now.addingTimeInterval(-300), // 5 minutes ago
            closeDateTime: now.addingTimeInterval(-60),  // 1 minute ago
            minutesOpen: 4.0, latitude: 47.6, longitude: -122.3
        )
        
        let cascadeEvents = [
            CascadeEvent(
                triggerBridgeID: 1, triggerBridgeName: "Ballard Bridge",
                targetBridgeID: 2, targetBridgeName: "Fremont Bridge",
                triggerTime: now.addingTimeInterval(-300),
                targetTime: now.addingTimeInterval(600), // Expected in 10 minutes
                triggerDuration: 4.0, targetDuration: 8.0,
                cascadeStrength: 0.7, cascadeType: "short-term"
            )
        ]
        
        let bridgeInfo = [
            DrawbridgeInfo(entityID: 2, entityName: "Fremont Bridge", entityType: "Bridge", latitude: 47.7, longitude: -122.4)
        ]
        
        let alerts = CascadeInsights.getCascadeAlerts(
            recentEvents: [recentTrigger],
            cascadeEvents: cascadeEvents,
            bridgeInfo: bridgeInfo
        )
        
        XCTAssertFalse(alerts.isEmpty, "Should generate cascade alerts")
        
        if let alert = alerts.first {
            XCTAssertEqual(alert.targetBridge, "Fremont Bridge")
            XCTAssertEqual(alert.triggerBridge, "Ballard Bridge")
            XCTAssertEqual(alert.probability, 0.7)
        }
    }
}