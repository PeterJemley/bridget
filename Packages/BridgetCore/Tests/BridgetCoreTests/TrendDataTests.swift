//
//  TrendDataTests.swift
//  BridgetCoreTests
//
//  Created by AI Assistant on 1/15/25.
//

import XCTest
import BridgetCore
@testable import BridgetCore

final class TrendDataTests: XCTestCase {
    
    // MARK: - Test Data Setup
    
    private func createSampleEvents() -> [DrawbridgeEvent] {
        let calendar = Calendar.current
        let today = Date()
        
        return [
            // Today's events
            DrawbridgeEvent(
                entityType: "Bridge",
                entityName: "Fremont Bridge",
                entityID: 1,
                openDateTime: calendar.date(byAdding: .hour, value: -2, to: today) ?? today,
                closeDateTime: calendar.date(byAdding: .hour, value: -1, to: today),
                minutesOpen: 15.0,
                latitude: 47.6519,
                longitude: -122.3531
            ),
            DrawbridgeEvent(
                entityType: "Bridge",
                entityName: "Ballard Bridge",
                entityID: 2,
                openDateTime: calendar.date(byAdding: .hour, value: -4, to: today) ?? today,
                closeDateTime: calendar.date(byAdding: .hour, value: -3, to: today),
                minutesOpen: 12.0,
                latitude: 47.6613,
                longitude: -122.3750
            ),
            
            // Yesterday's events
            DrawbridgeEvent(
                entityType: "Bridge",
                entityName: "Fremont Bridge",
                entityID: 1,
                openDateTime: calendar.date(byAdding: .day, value: -1, to: today) ?? today,
                closeDateTime: calendar.date(byAdding: .day, value: -1, to: calendar.date(byAdding: .hour, value: -1, to: today) ?? today),
                minutesOpen: 18.0,
                latitude: 47.6519,
                longitude: -122.3531
            ),
            
            // Last week's events
            DrawbridgeEvent(
                entityType: "Bridge",
                entityName: "University Bridge",
                entityID: 3,
                openDateTime: calendar.date(byAdding: .day, value: -8, to: today) ?? today,
                closeDateTime: calendar.date(byAdding: .day, value: -8, to: calendar.date(byAdding: .hour, value: -1, to: today) ?? today),
                minutesOpen: 20.0,
                latitude: 47.6519,
                longitude: -122.3531
            ),
            
            // Two weeks ago events
            DrawbridgeEvent(
                entityType: "Bridge",
                entityName: "Fremont Bridge",
                entityID: 1,
                openDateTime: calendar.date(byAdding: .day, value: -15, to: today) ?? today,
                closeDateTime: calendar.date(byAdding: .day, value: -15, to: calendar.date(byAdding: .hour, value: -1, to: today) ?? today),
                minutesOpen: 16.0,
                latitude: 47.6519,
                longitude: -122.3531
            )
        ]
    }
    
    // MARK: - Daily Trend Tests
    
    func testCalculateDailyTrend() {
        let events = createSampleEvents()
        let dailyTrend = TrendCalculator.calculateDailyTrend(from: events, days: 7)
        
        XCTAssertFalse(dailyTrend.isEmpty, "Daily trend should not be empty")
        XCTAssertEqual(dailyTrend.count, 7, "Should have 7 days of data")
        
        // Check that today has 2 events
        let today = Calendar.current.startOfDay(for: Date())
        let todaysData = dailyTrend.first { Calendar.current.isDate($0.date, inSameDayAs: today) }
        XCTAssertNotNil(todaysData, "Should have today's data")
        XCTAssertEqual(todaysData?.count, 2, "Today should have 2 events")
    }
    
    func testCalculateDailyTrendWithEmptyData() {
        let dailyTrend = TrendCalculator.calculateDailyTrend(from: [], days: 7)
        
        XCTAssertFalse(dailyTrend.isEmpty, "Should still return 7 days of zero data")
        XCTAssertEqual(dailyTrend.count, 7, "Should have 7 days of data")
        
        // All counts should be zero
        for point in dailyTrend {
            XCTAssertEqual(point.count, 0, "All counts should be zero for empty data")
        }
    }
    
    // MARK: - Weekly Trend Tests
    
    func testCalculateWeeklyTrend() {
        let events = createSampleEvents()
        let weeklyTrend = TrendCalculator.calculateWeeklyTrend(from: events, weeks: 4)
        
        XCTAssertFalse(weeklyTrend.isEmpty, "Weekly trend should not be empty")
        XCTAssertLessThanOrEqual(weeklyTrend.count, 4, "Should have at most 4 weeks of data")
        
        // Check that this week has events
        let thisWeek = weeklyTrend.first { point in
            let calendar = Calendar.current
            let weekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
            return calendar.isDate(point.weekStart, inSameDayAs: weekStart)
        }
        XCTAssertNotNil(thisWeek, "Should have this week's data")
    }
    
    // MARK: - Trend Summary Tests
    
    func testCalculateTrendSummary() {
        let events = createSampleEvents()
        let currentEvents = TrendCalculator.eventsForToday(events)
        let previousEvents = TrendCalculator.eventsForPeriod(events, days: 2).filter { event in
            !currentEvents.contains { $0.id == event.id }
        }
        let dataPoints = TrendCalculator.calculateDailyTrend(from: events, days: 7)
        
        let summary = TrendCalculator.calculateTrendSummary(
            currentEvents: currentEvents,
            previousEvents: previousEvents,
            dataPoints: dataPoints
        )
        
        XCTAssertEqual(summary.currentValue, 2, "Current value should be 2")
        XCTAssertEqual(summary.previousValue, 1, "Previous value should be 1")
        XCTAssertEqual(summary.change, 1, "Change should be 1")
        XCTAssertEqual(summary.trendDirection, .up, "Trend should be up")
    }
    
    func testCalculateTrendSummaryWithNoChange() {
        let events = createSampleEvents()
        let currentEvents = TrendCalculator.eventsForToday(events)
        let dataPoints = TrendCalculator.calculateDailyTrend(from: events, days: 7)
        
        let summary = TrendCalculator.calculateTrendSummary(
            currentEvents: currentEvents,
            previousEvents: currentEvents, // Same as current
            dataPoints: dataPoints
        )
        
        XCTAssertEqual(summary.change, 0, "Change should be 0")
        XCTAssertEqual(summary.trendDirection, .stable, "Trend should be stable")
    }
    
    // MARK: - Period Filter Tests
    
    func testEventsForToday() {
        let events = createSampleEvents()
        let todaysEvents = TrendCalculator.eventsForToday(events)
        
        XCTAssertEqual(todaysEvents.count, 2, "Should have 2 events today")
        
        let calendar = Calendar.current
        for event in todaysEvents {
            XCTAssertTrue(calendar.isDate(event.openDateTime, inSameDayAs: Date()), "All events should be from today")
        }
    }
    
    func testEventsForThisWeek() {
        let events = createSampleEvents()
        let thisWeeksEvents = TrendCalculator.eventsForThisWeek(events)
        
        XCTAssertEqual(thisWeeksEvents.count, 3, "Should have 3 events this week")
        
        let calendar = Calendar.current
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        for event in thisWeeksEvents {
            XCTAssertGreaterThanOrEqual(event.openDateTime, weekStart, "All events should be from this week")
        }
    }
    
    func testEventsForLastWeek() {
        let events = createSampleEvents()
        let lastWeeksEvents = TrendCalculator.eventsForLastWeek(events)
        
        XCTAssertEqual(lastWeeksEvents.count, 1, "Should have 1 event from last week")
        
        let calendar = Calendar.current
        let lastWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date()
        let lastWeekInterval = calendar.dateInterval(of: .weekOfYear, for: lastWeekStart)
        let lastWeekEnd = lastWeekInterval?.end ?? Date()
        
        for event in lastWeeksEvents {
            XCTAssertGreaterThanOrEqual(event.openDateTime, lastWeekStart, "All events should be from last week")
            XCTAssertLessThan(event.openDateTime, lastWeekEnd, "All events should be before this week")
        }
    }
    
    // MARK: - Bridge Count Trend Tests
    
    func testCalculateBridgeCountTrend() {
        let events = createSampleEvents()
        let bridgeTrend = TrendCalculator.calculateBridgeCountTrend(from: events, days: 7)
        
        XCTAssertNotNil(bridgeTrend, "Should return a trend summary")
        XCTAssertEqual(bridgeTrend.currentValue, 2, "Should have 2 unique bridges in current period")
        XCTAssertEqual(bridgeTrend.previousValue, 1, "Should have 1 unique bridge in previous period")
        XCTAssertEqual(bridgeTrend.change, 1, "Change should be 1")
        XCTAssertEqual(bridgeTrend.trendDirection, .up, "Trend should be up")
    }
    
    // MARK: - Data Range Trend Tests
    
    func testCalculateDataRangeTrend() {
        let events = createSampleEvents()
        let dataRangeTrend = TrendCalculator.calculateDataRangeTrend(from: events)
        
        XCTAssertFalse(dataRangeTrend.isEmpty, "Data range trend should not be empty")
        XCTAssertLessThanOrEqual(dataRangeTrend.count, 29, "Should have at most 29 days of data")
    }
    
    // MARK: - Trend Direction Tests
    
    func testTrendDirectionProperties() {
        XCTAssertEqual(TrendDirection.up.symbol, "↗", "Up trend should have correct symbol")
        XCTAssertEqual(TrendDirection.down.symbol, "↘", "Down trend should have correct symbol")
        XCTAssertEqual(TrendDirection.stable.symbol, "→", "Stable trend should have correct symbol")
        
        XCTAssertEqual(TrendDirection.up.color, .red, "Up trend should be red")
        XCTAssertEqual(TrendDirection.down.color, .green, "Down trend should be green")
        XCTAssertEqual(TrendDirection.stable.color, .gray, "Stable trend should be gray")
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceWithLargeDataset() {
        let largeEvents = (0..<1000).map { index in
            DrawbridgeEvent(
                entityType: "Bridge",
                entityName: "Bridge \(index % 5)",
                entityID: index % 5,
                openDateTime: Date().addingTimeInterval(-Double(index * 3600)),
                closeDateTime: Date().addingTimeInterval(-Double(index * 3600) + 900),
                minutesOpen: Double.random(in: 5...30),
                latitude: 47.6519,
                longitude: -122.3531
            )
        }
        
        measure {
            let _ = TrendCalculator.calculateDailyTrend(from: largeEvents, days: 30)
        }
    }
} 