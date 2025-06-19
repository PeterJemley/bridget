//
//  BridgeAnalyticsTests.swift
//  BridgetCoreTests
//
//  Created by Peter Jemley on 6/19/25.
//

import XCTest
@testable import BridgetCore
import Foundation

final class BridgeAnalyticsTests: XCTestCase {
    
    func testBridgeAnalyticsCreation() {
        let analytics = BridgeAnalytics(
            entityID: 123,
            entityName: "Test Bridge",
            year: 2025,
            month: 6,
            dayOfWeek: 3, // Tuesday
            hour: 14 // 2 PM
        )
        
        XCTAssertEqual(analytics.id, "123-2025-6-3-14")
        XCTAssertEqual(analytics.entityID, 123)
        XCTAssertEqual(analytics.entityName, "Test Bridge")
        XCTAssertEqual(analytics.year, 2025)
        XCTAssertEqual(analytics.month, 6)
        XCTAssertEqual(analytics.dayOfWeek, 3)
        XCTAssertEqual(analytics.hour, 14)
        XCTAssertEqual(analytics.openingCount, 0)
        XCTAssertEqual(analytics.totalMinutesOpen, 0)
        XCTAssertEqual(analytics.probabilityOfOpening, 0)
    }
    
    func testAnalyticsCalculatorWithSingleEvent() {
        let calendar = Calendar.current
        let testDate = calendar.date(from: DateComponents(year: 2025, month: 6, day: 19, hour: 14))!
        
        let events = [
            DrawbridgeEvent(
                entityType: "Bridge",
                entityName: "Test Bridge",
                entityID: 123,
                openDateTime: testDate,
                closeDateTime: testDate.addingTimeInterval(900), // 15 minutes later
                minutesOpen: 15.0,
                latitude: 47.6,
                longitude: -122.3
            )
        ]
        
        let analyticsResults = BridgeAnalyticsCalculator.calculateAnalytics(from: events)
        
        XCTAssertEqual(analyticsResults.count, 1)
        
        let analytics = analyticsResults.first!
        XCTAssertEqual(analytics.entityID, 123)
        XCTAssertEqual(analytics.entityName, "Test Bridge")
        XCTAssertEqual(analytics.openingCount, 1)
        XCTAssertEqual(analytics.totalMinutesOpen, 15.0)
        XCTAssertEqual(analytics.averageMinutesPerOpening, 15.0)
        XCTAssertEqual(analytics.longestOpeningMinutes, 15.0)
        XCTAssertEqual(analytics.shortestOpeningMinutes, 15.0)
    }
    
    func testAnalyticsCalculatorWithMultipleEvents() {
        let calendar = Calendar.current
        let baseDate = calendar.date(from: DateComponents(year: 2025, month: 6, day: 19, hour: 14))!
        
        let events = [
            DrawbridgeEvent(
                entityType: "Bridge", entityName: "Test Bridge", entityID: 123,
                openDateTime: baseDate, closeDateTime: baseDate.addingTimeInterval(600),
                minutesOpen: 10.0, latitude: 47.6, longitude: -122.3
            ),
            DrawbridgeEvent(
                entityType: "Bridge", entityName: "Test Bridge", entityID: 123,
                openDateTime: baseDate, closeDateTime: baseDate.addingTimeInterval(1200),
                minutesOpen: 20.0, latitude: 47.6, longitude: -122.3
            ),
            DrawbridgeEvent(
                entityType: "Bridge", entityName: "Test Bridge", entityID: 123,
                openDateTime: baseDate, closeDateTime: baseDate.addingTimeInterval(900),
                minutesOpen: 15.0, latitude: 47.6, longitude: -122.3
            )
        ]
        
        let analyticsResults = BridgeAnalyticsCalculator.calculateAnalytics(from: events)
        
        XCTAssertEqual(analyticsResults.count, 1)
        
        let analytics = analyticsResults.first!
        XCTAssertEqual(analytics.openingCount, 3)
        XCTAssertEqual(analytics.totalMinutesOpen, 45.0)
        XCTAssertEqual(analytics.averageMinutesPerOpening, 15.0)
        XCTAssertEqual(analytics.longestOpeningMinutes, 20.0)
        XCTAssertEqual(analytics.shortestOpeningMinutes, 10.0)
    }
    
    func testAnalyticsCalculatorWithDifferentBridges() {
        let calendar = Calendar.current
        let testDate = calendar.date(from: DateComponents(year: 2025, month: 6, day: 19, hour: 14))!
        
        let events = [
            DrawbridgeEvent(
                entityType: "Bridge", entityName: "Bridge A", entityID: 1,
                openDateTime: testDate, closeDateTime: nil, minutesOpen: 10.0,
                latitude: 47.6, longitude: -122.3
            ),
            DrawbridgeEvent(
                entityType: "Bridge", entityName: "Bridge B", entityID: 2,
                openDateTime: testDate, closeDateTime: nil, minutesOpen: 20.0,
                latitude: 47.7, longitude: -122.4
            )
        ]
        
        let analyticsResults = BridgeAnalyticsCalculator.calculateAnalytics(from: events)
        
        XCTAssertEqual(analyticsResults.count, 2)
        
        let bridgeA = analyticsResults.first { $0.entityID == 1 }!
        let bridgeB = analyticsResults.first { $0.entityID == 2 }!
        
        XCTAssertEqual(bridgeA.entityName, "Bridge A")
        XCTAssertEqual(bridgeA.averageMinutesPerOpening, 10.0)
        
        XCTAssertEqual(bridgeB.entityName, "Bridge B")
        XCTAssertEqual(bridgeB.averageMinutesPerOpening, 20.0)
    }
    
    func testBridgePredictionCreation() {
        let bridgeInfo = DrawbridgeInfo(
            entityID: 123,
            entityName: "Test Bridge",
            entityType: "Drawbridge",
            latitude: 47.6,
            longitude: -122.3
        )
        
        let prediction = BridgePrediction(
            bridge: bridgeInfo,
            probability: 0.75,
            expectedDuration: 12.5,
            confidence: 0.8,
            timeFrame: "next hour",
            reasoning: "Test reasoning"
        )
        
        XCTAssertEqual(prediction.probability, 0.75)
        XCTAssertEqual(prediction.expectedDuration, 12.5)
        XCTAssertEqual(prediction.confidence, 0.8)
        XCTAssertEqual(prediction.timeFrame, "next hour")
        XCTAssertEqual(prediction.reasoning, "Test reasoning")
    }
    
    func testProbabilityTextFormatting() {
        let bridgeInfo = DrawbridgeInfo(entityID: 1, entityName: "Test", entityType: "Bridge", latitude: 0, longitude: 0)
        
        let veryLowPrediction = BridgePrediction(bridge: bridgeInfo, probability: 0.05, expectedDuration: 10, confidence: 0.5, timeFrame: "test", reasoning: "test")
        XCTAssertEqual(veryLowPrediction.probabilityText, "Very Low")
        
        let lowPrediction = BridgePrediction(bridge: bridgeInfo, probability: 0.2, expectedDuration: 10, confidence: 0.5, timeFrame: "test", reasoning: "test")
        XCTAssertEqual(lowPrediction.probabilityText, "Low")
        
        let moderatePrediction = BridgePrediction(bridge: bridgeInfo, probability: 0.5, expectedDuration: 10, confidence: 0.5, timeFrame: "test", reasoning: "test")
        XCTAssertEqual(moderatePrediction.probabilityText, "Moderate")
        
        let highPrediction = BridgePrediction(bridge: bridgeInfo, probability: 0.7, expectedDuration: 10, confidence: 0.5, timeFrame: "test", reasoning: "test")
        XCTAssertEqual(highPrediction.probabilityText, "High")
        
        let veryHighPrediction = BridgePrediction(bridge: bridgeInfo, probability: 0.9, expectedDuration: 10, confidence: 0.5, timeFrame: "test", reasoning: "test")
        XCTAssertEqual(veryHighPrediction.probabilityText, "Very High")
    }
    
    func testConfidenceTextFormatting() {
        let bridgeInfo = DrawbridgeInfo(entityID: 1, entityName: "Test", entityType: "Bridge", latitude: 0, longitude: 0)
        
        let lowConfidence = BridgePrediction(bridge: bridgeInfo, probability: 0.5, expectedDuration: 10, confidence: 0.2, timeFrame: "test", reasoning: "test")
        XCTAssertEqual(lowConfidence.confidenceText, "Low Confidence")
        
        let mediumConfidence = BridgePrediction(bridge: bridgeInfo, probability: 0.5, expectedDuration: 10, confidence: 0.5, timeFrame: "test", reasoning: "test")
        XCTAssertEqual(mediumConfidence.confidenceText, "Medium Confidence")
        
        let highConfidence = BridgePrediction(bridge: bridgeInfo, probability: 0.5, expectedDuration: 10, confidence: 0.8, timeFrame: "test", reasoning: "test")
        XCTAssertEqual(highConfidence.confidenceText, "High Confidence")
    }
    
    func testDurationTextFormatting() {
        let bridgeInfo = DrawbridgeInfo(entityID: 1, entityName: "Test", entityType: "Bridge", latitude: 0, longitude: 0)
        
        let shortDuration = BridgePrediction(bridge: bridgeInfo, probability: 0.5, expectedDuration: 0.5, confidence: 0.5, timeFrame: "test", reasoning: "test")
        XCTAssertEqual(shortDuration.durationText, "< 1 minute")
        
        let minutesDuration = BridgePrediction(bridge: bridgeInfo, probability: 0.5, expectedDuration: 45, confidence: 0.5, timeFrame: "test", reasoning: "test")
        XCTAssertEqual(minutesDuration.durationText, "45 minutes")
        
        let hoursDuration = BridgePrediction(bridge: bridgeInfo, probability: 0.5, expectedDuration: 75, confidence: 0.5, timeFrame: "test", reasoning: "test")
        XCTAssertEqual(hoursDuration.durationText, "1h 15m")
        
        let exactHour = BridgePrediction(bridge: bridgeInfo, probability: 0.5, expectedDuration: 60, confidence: 0.5, timeFrame: "test", reasoning: "test")
        XCTAssertEqual(exactHour.durationText, "1h 0m")
    }
}