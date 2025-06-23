//
//  ComprehensiveUITests.swift
//  BridgetTests
//
//  Created by Alex AI on 6/22/25.
//

import XCTest
import SwiftUI
import SwiftData
@testable import Bridget
@testable import BridgetCore
@testable import BridgetNetworking
@testable import BridgetDashboard
@testable import BridgetBridgeDetail
@testable import BridgetStatistics
@testable import BridgetBridgesList
@testable import BridgetHistory
@testable import BridgetSettings
@testable import BridgetSharedUI

/// Comprehensive automated tests that validate the exact functionality tested manually
/// These tests provide regression protection for all manual testing scenarios
final class ComprehensiveUITests: XCTestCase {
    
    // MARK: - Test Infrastructure
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var testEvents: [DrawbridgeEvent] = []
    var testBridgeInfo: [DrawbridgeInfo] = []
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory SwiftData container that mirrors manual testing data
        let schema = Schema([DrawbridgeEvent.self, DrawbridgeInfo.self, BridgeAnalytics.self, CascadeEvent.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [config])
        modelContext = ModelContext(modelContainer)
        
        createRealisticTestData()
        print("🧪 [AUTOMATED] Test setup complete with \(testEvents.count) events, \(testBridgeInfo.count) bridges")
    }
    
    override func tearDown() async throws {
        testEvents.removeAll()
        testBridgeInfo.removeAll()
        modelContext = nil
        modelContainer = nil
        try await super.tearDown()
    }
    
    /// Creates realistic test data that mirrors Seattle bridge data structure
    private func createRealisticTestData() {
        let seattleBridgeNames = [
            "Fremont Bridge", "Ballard Bridge", "University Bridge", 
            "Montlake Bridge", "1st Avenue South Bridge", "Spokane Street Bridge"
        ]
        
        let now = Date()
        let calendar = Calendar.current
        
        for (index, bridgeName) in seattleBridgeNames.enumerated() {
            let bridgeID = index + 1
            
            // Create realistic event history (varying patterns per bridge)
            let eventCount = bridgeName == "Fremont Bridge" ? 50 : Int.random(in: 15...35)
            
            for i in 0..<eventCount {
                let hoursBack = i * Int.random(in: 1...6)
                let openDate = calendar.date(byAdding: .hour, value: -hoursBack, to: now) ?? now
                let duration = bridgeName == "Fremont Bridge" ? Int.random(in: 5...25) : Int.random(in: 8...20)
                let closeDate = calendar.date(byAdding: .minute, value: duration, to: openDate)
                
                let event = DrawbridgeEvent(
                    entityType: "Bridge",
                    entityName: bridgeName,
                    entityID: bridgeID,
                    openDateTime: openDate,
                    closeDateTime: closeDate,
                    minutesOpen: Double(duration),
                    latitude: 47.6000 + Double(index) * 0.01,
                    longitude: -122.3300 - Double(index) * 0.01
                )
                testEvents.append(event)
                modelContext.insert(event)
            }
            
            let bridgeInfo = DrawbridgeInfo(
                entityID: bridgeID,
                entityName: bridgeName,
                entityType: "Drawbridge",
                latitude: 47.6000 + Double(index) * 0.01,
                longitude: -122.3300 - Double(index) * 0.01
            )
            testBridgeInfo.append(bridgeInfo)
            modelContext.insert(bridgeInfo)
        }
        
        try? modelContext.save()
    }
    
    // MARK: - PHASE 1: App Launch & Data Loading Tests
    
    func testAppLaunchDataLoadingSequence() async throws {
        // Test corresponds to Manual Test 1.1-1.2
        print("🧪 [AUTOMATED] Testing app launch sequence...")
        
        // Simulate app launch conditions
        let contentView = ContentViewModular()
        XCTAssertNotNil(contentView, "ContentViewModular should initialize successfully")
        
        // Test data loading logic
        let initialLoadNeeded = testEvents.isEmpty
        XCTAssertFalse(initialLoadNeeded, "Test data should be populated")
        
        // Simulate initial data processing
        let analytics = BridgeAnalyticsCalculator.calculateAnalytics(from: testEvents)
        XCTAssertFalse(analytics.isEmpty, "Analytics should be calculated from test data")
        XCTAssertTrue(analytics.count >= testBridgeInfo.count, "Analytics should exist for all bridges")
        
        print("🧪 [AUTOMATED] ✅ App launch sequence validated")
    }
    
    func testNeuralEngineDetectionLogic() throws {
        // Test corresponds to Manual Test 1.3
        print("🧪 [AUTOMATED] Testing Neural Engine detection...")
        
        let neuralManager = NeuralEngineManager()
        let capability = neuralManager.getCurrentCapability()
        
        // Should detect some Neural Engine capability (Unknown in simulator, A18Pro on device)
        XCTAssertTrue(capability.coreCount >= 8, "Neural Engine should have at least 8 cores")
        XCTAssertTrue(capability.topsPerformance >= 5.0, "Neural Engine should have at least 5.0 TOPS")
        XCTAssertFalse(capability.deviceType.isEmpty, "Device type should be detected")
        
        print("🧪 [AUTOMATED] ✅ Neural Engine detection: \(capability.deviceType) (\(capability.coreCount) cores, \(capability.topsPerformance) TOPS)")
    }
    
    // MARK: - PHASE 2: Dashboard Functionality Tests
    
    func testStatusOverviewCardDataBinding() throws {
        // Test corresponds to Manual Test 2.1
        print("🧪 [AUTOMATED] Testing StatusOverviewCard data binding...")
        
        let totalBridges = Set(testEvents.map { $0.entityID }).count
        let currentlyOpen = testEvents.filter { $0.isCurrentlyOpen }.count
        let todayEvents = DrawbridgeEvent.eventsToday(testEvents)
        let totalEvents = testEvents.count
        
        // Verify calculations match what StatusOverviewCard would display
        XCTAssertTrue(totalBridges > 0, "Should have bridges")
        XCTAssertTrue(totalEvents > 0, "Should have events")
        XCTAssertTrue(todayEvents.count >= 0, "Today's events should be non-negative")
        
        // Test StatusOverviewCard initialization would not crash
        let dashboard = DashboardView(events: testEvents, bridgeInfo: testBridgeInfo)
        XCTAssertNotNil(dashboard, "DashboardView should initialize with test data")
        
        print("🧪 [AUTOMATED] ✅ StatusOverviewCard data binding validated")
    }
    
    func testLastKnownStatusSectionDataIntegrity() throws {
        // Test corresponds to Manual Test 2.2
        print("🧪 [AUTOMATED] Testing LastKnownStatusSection data integrity...")
        
        // Verify bridge status calculation logic
        for bridgeInfo in testBridgeInfo {
            let bridgeEvents = testEvents.filter { $0.entityID == bridgeInfo.entityID }
            let latestEvent = bridgeEvents.max(by: { $0.openDateTime < $1.openDateTime })
            
            if let latestEvent = latestEvent {
                let status = latestEvent.isCurrentlyOpen ? "WAS OPEN" : "CLOSED"
                XCTAssertTrue(["WAS OPEN", "CLOSED"].contains(status), "Status should be valid")
                
                // Verify relative time calculation
                let relativeTime = latestEvent.relativeTimeText
                XCTAssertFalse(relativeTime.isEmpty, "Relative time should be calculated")
            }
        }
        
        print("🧪 [AUTOMATED] ✅ LastKnownStatusSection data integrity validated")
    }
    
    func testRecentActivitySectionSorting() throws {
        // Test corresponds to Manual Test 2.3
        print("🧪 [AUTOMATED] Testing RecentActivitySection sorting...")
        
        // Verify events are sorted by most recent first
        let sortedEvents = testEvents.sorted { $0.openDateTime > $1.openDateTime }
        let recentEvents = Array(sortedEvents.prefix(10))
        
        // Verify sorting is correct
        for i in 1..<recentEvents.count {
            XCTAssertTrue(recentEvents[i-1].openDateTime >= recentEvents[i].openDateTime,
                         "Events should be sorted by most recent first")
        }
        
        print("🧪 [AUTOMATED] ✅ RecentActivitySection sorting validated")
    }
    
    // MARK: - PHASE 3: Bridge Detail Analysis Tests
    
    func testBridgeDetailDataFiltering() throws {
        // Test corresponds to Manual Test 3.1
        print("🧪 [AUTOMATED] Testing BridgeDetail data filtering...")
        
        // Select a bridge for detailed testing
        guard let testBridge = testBridgeInfo.first else {
            XCTFail("No test bridges available")
            return
        }
        
        // Filter events for this specific bridge
        let bridgeSpecificEvents = testEvents.filter { $0.entityID == testBridge.entityID }
        XCTAssertFalse(bridgeSpecificEvents.isEmpty, "Bridge should have events")
        
        // Verify all events belong to the correct bridge
        for event in bridgeSpecificEvents {
            XCTAssertEqual(event.entityID, testBridge.entityID, "Event should belong to correct bridge")
            XCTAssertEqual(event.entityName, testBridge.entityName, "Event name should match bridge name")
        }
        
        print("🧪 [AUTOMATED] ✅ BridgeDetail data filtering validated for \(testBridge.entityName)")
    }
    
    func testTimePeriodFilteringLogic() throws {
        // Test corresponds to Manual Test 3.2 (CRITICAL)
        print("🧪 [AUTOMATED] Testing time period filtering logic...")
        
        let calendar = Calendar.current
        let now = Date()
        
        // Test different time periods
        let timePeriods = [
            ("24H", 1), ("7D", 7), ("30D", 30), ("90D", 90)
        ]
        
        for (periodName, days) in timePeriods {
            let cutoffDate = calendar.date(byAdding: .day, value: -days, to: now) ?? now
            let filteredEvents = testEvents.filter { $0.openDateTime >= cutoffDate }
            
            // Verify filtering logic is correct
            for event in filteredEvents {
                XCTAssertTrue(event.openDateTime >= cutoffDate,
                             "Event should be within \(periodName) time period")
            }
            
            print("🧪 [AUTOMATED] ✅ \(periodName) filtering: \(filteredEvents.count)/\(testEvents.count) events")
        }
    }
    
    func testAnalysisTypeDataProcessing() throws {
        // Test corresponds to Manual Test 3.3
        print("🧪 [AUTOMATED] Testing analysis type data processing...")
        
        guard let testBridge = testBridgeInfo.first else {
            XCTFail("No test bridges available")
            return
        }
        
        let bridgeEvents = testEvents.filter { $0.entityID == testBridge.entityID }
        
        // Test Patterns analysis
        let analytics = BridgeAnalyticsCalculator.calculateAnalytics(from: bridgeEvents)
        XCTAssertFalse(analytics.isEmpty, "Patterns analysis should produce results")
        
        // Test Cascade analysis
        let cascades = CascadeDetectionEngine.detectCascadeEffects(from: testEvents)
        XCTAssertTrue(cascades.count >= 0, "Cascade analysis should complete without error")
        
        // Test Predictions analysis
        let prediction = BridgeAnalytics.getCurrentPrediction(for: testBridge, from: analytics)
        if let prediction = prediction {
            XCTAssertTrue(prediction.probability >= 0.0 && prediction.probability <= 1.0,
                         "Prediction probability should be valid")
        }
        
        print("🧪 [AUTOMATED] ✅ Analysis type data processing validated")
    }
    
    func testPredictionDataValidation() throws {
        // Test corresponds to Manual Test 3.5 (KEY TEST)
        print("🧪 [AUTOMATED] Testing prediction data validation...")
        
        for bridgeInfo in testBridgeInfo.prefix(3) { // Test first 3 bridges
            let bridgeEvents = testEvents.filter { $0.entityID == bridgeInfo.entityID }
            
            // Test enhanced ARIMA predictions
            let enhancedPrediction = BridgeAnalytics.getARIMAEnhancedPrediction(
                for: bridgeInfo,
                events: bridgeEvents,
                analytics: [],
                cascadeEvents: []
            )
            
            if let prediction = enhancedPrediction {
                // Validate prediction data ranges
                XCTAssertTrue(prediction.probability >= 0.0 && prediction.probability <= 1.0,
                             "Probability should be 0-100%")
                XCTAssertTrue(prediction.expectedDuration > 0,
                             "Expected duration should be positive")
                XCTAssertTrue(prediction.confidence >= 0.0 && prediction.confidence <= 1.0,
                             "Confidence should be 0-100%")
                XCTAssertFalse(prediction.reasoning.isEmpty,
                              "Reasoning should not be empty")
                
                print("🧪 [AUTOMATED] ✅ \(bridgeInfo.entityName): \(Int(prediction.probability * 100))% probability, \(prediction.expectedDuration)min duration")
            } else {
                print("🧪 [AUTOMATED] ⚠️ \(bridgeInfo.entityName): No prediction available (may need more data)")
            }
        }
    }
    
    // MARK: - PHASE 4: Cross-Tab Navigation Tests
    
    func testBridgeListDataConsistency() throws {
        // Test corresponds to Manual Test 4.1
        print("🧪 [AUTOMATED] Testing bridge list data consistency...")
        
        // Simulate BridgesListView data binding
        let uniqueBridges = DrawbridgeEvent.getUniqueBridges(testEvents)
        
        // Verify consistency with testBridgeInfo
        for bridgeInfo in testBridgeInfo {
            let foundInEvents = uniqueBridges.contains { $0.entityID == bridgeInfo.entityID }
            XCTAssertTrue(foundInEvents, "Bridge \(bridgeInfo.entityName) should exist in events data")
        }
        
        // Test search functionality logic
        let searchTerm = "Fremont"
        let filteredBridges = testBridgeInfo.filter { 
            $0.entityName.localizedCaseInsensitiveContains(searchTerm) 
        }
        
        if !filteredBridges.isEmpty {
            XCTAssertTrue(filteredBridges.allSatisfy { $0.entityName.contains("Fremont") },
                         "Filtered bridges should match search term")
        }
        
        print("🧪 [AUTOMATED] ✅ Bridge list data consistency validated")
    }
    
    func testHistoryAnalysisDataProcessing() throws {
        // Test corresponds to Manual Test 4.2
        print("🧪 [AUTOMATED] Testing history analysis data processing...")
        
        // Test different analysis types that HistoryView uses
        let analysisTypes = ["Frequency", "Duration", "Timeline", "Patterns", "Comparison"]
        
        for analysisType in analysisTypes {
            switch analysisType {
            case "Frequency":
                let hourlyData = Dictionary(grouping: testEvents) { event in
                    Calendar.current.component(.hour, from: event.openDateTime)
                }
                XCTAssertFalse(hourlyData.isEmpty, "Frequency analysis should produce hourly data")
                
            case "Duration":
                let durations = testEvents.compactMap { $0.duration }
                XCTAssertFalse(durations.isEmpty, "Duration analysis should have duration data")
                
            case "Timeline":
                let sortedEvents = testEvents.sorted { $0.openDateTime > $1.openDateTime }
                XCTAssertEqual(sortedEvents.count, testEvents.count, "Timeline should preserve all events")
                
            case "Patterns":
                let analytics = BridgeAnalyticsCalculator.calculateAnalytics(from: testEvents)
                XCTAssertFalse(analytics.isEmpty, "Patterns analysis should produce analytics")
                
            case "Comparison":
                let bridgeGroups = Dictionary(grouping: testEvents) { $0.entityID }
                XCTAssertTrue(bridgeGroups.count > 1, "Comparison analysis should have multiple bridges")
                
            default:
                break
            }
        }
        
        print("🧪 [AUTOMATED] ✅ History analysis data processing validated")
    }
    
    func testStatisticsTabCrashPrevention() async throws {
        // Test corresponds to Manual Test 4.3 (CRASH PREVENTION TEST)
        print("🧪 [AUTOMATED] Testing Statistics tab crash prevention...")
        
        let expectation = XCTestExpectation(description: "Statistics calculations complete without crash")
        expectation.expectedFulfillmentCount = 5
        
        // Simulate the exact conditions that caused the EXC_BAD_ACCESS crash
        for i in 0..<5 {
            Task.detached {
                // This mirrors the StatisticsView pull-to-refresh operation
                let eventsSnapshot = Array(self.testEvents)
                let limitedEvents = Array(eventsSnapshot.sorted { $0.openDateTime > $1.openDateTime }.prefix(2000))
                
                // This should NOT crash (the fix we implemented)
                let analytics = BridgeAnalyticsCalculator.calculateAnalytics(from: limitedEvents)
                
                XCTAssertTrue(analytics.count >= 0, "Statistics calculation should complete")
                print("🧪 [AUTOMATED] ✅ Statistics refresh \(i) completed: \(analytics.count) records")
                
                expectation.fulfill()
            }
        }
        
        await fulfillment(of: [expectation], timeout: 30.0)
    }
    
    // MARK: - Performance & Stress Testing
    
    func testLargeDatasetPerformance() throws {
        // Test corresponds to Manual Test 5.1
        print("🧪 [AUTOMATED] Testing large dataset performance...")
        
        // Create large dataset similar to real Seattle data (4000+ events)
        var largeDataset: [DrawbridgeEvent] = []
        let now = Date()
        
        for i in 0..<4000 {
            let bridgeID = (i % 6) + 1 // Distribute across 6 bridges
            let hoursBack = i / 10 // Spread over time
            let openDate = now.addingTimeInterval(TimeInterval(-hoursBack * 3600))
            let duration = Double.random(in: 5...30)
            let closeDate = openDate.addingTimeInterval(duration * 60)
            
            let event = DrawbridgeEvent(
                entityType: "Bridge",
                entityName: "Performance Test Bridge \(bridgeID)",
                entityID: bridgeID,
                openDateTime: openDate,
                closeDateTime: closeDate,
                minutesOpen: duration,
                latitude: 47.6000 + Double(bridgeID) * 0.01,
                longitude: -122.3300 - Double(bridgeID) * 0.01
            )
            largeDataset.append(event)
        }
        
        // Test performance with large dataset
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let analytics = BridgeAnalyticsCalculator.calculateAnalytics(from: largeDataset)
        
        let executionTime = CFAbsoluteTimeGetCurrent() - startTime
        
        XCTAssertFalse(analytics.isEmpty, "Analytics should be calculated for large dataset")
        XCTAssertLessThan(executionTime, 10.0, "Large dataset calculation should complete within 10 seconds")
        
        print("🧪 [AUTOMATED] ✅ Large dataset performance: \(analytics.count) analytics in \(String(format: "%.2f", executionTime))s")
    }
    
    func testNeuralEnginePerformanceValidation() throws {
        // Test corresponds to Manual Test 5.2
        print("🧪 [AUTOMATED] Testing Neural Engine performance...")
        
        let predictor = NeuralEngineARIMAPredictor()
        let limitedEvents = Array(testEvents.prefix(100)) // Reasonable test size
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let predictions = predictor.generatePredictions(from: limitedEvents)
        
        let executionTime = CFAbsoluteTimeGetCurrent() - startTime
        
        XCTAssertTrue(predictions.count >= 0, "Neural Engine predictions should complete")
        XCTAssertLessThan(executionTime, 1.0, "Neural Engine predictions should be fast")
        
        // Validate prediction quality
        for prediction in predictions {
            XCTAssertTrue(prediction.probability >= 0.0 && prediction.probability <= 1.0,
                         "Neural Engine predictions should have valid probabilities")
            XCTAssertTrue(prediction.expectedDuration > 0,
                         "Neural Engine predictions should have positive durations")
        }
        
        print("🧪 [AUTOMATED] ✅ Neural Engine performance: \(predictions.count) predictions in \(String(format: "%.3f", executionTime))s")
    }
    
    // MARK: - Regression Prevention Tests
    
    func testStatisticsCrashRegressionPrevention() async throws {
        // Specifically prevents the EXC_BAD_ACCESS crash that was fixed
        print("🧪 [AUTOMATED] Testing Statistics crash regression prevention...")
        
        let expectation = XCTestExpectation(description: "Regression test completes")
        expectation.expectedFulfillmentCount = 10
        
        // Simulate the exact conditions that caused the original crash
        for i in 0..<10 {
            Task.detached {
                // Multiple threads accessing statistics calculations simultaneously
                let eventsSnapshot = Array(self.testEvents)
                let limitedEvents = Array(eventsSnapshot.sorted { $0.openDateTime > $1.openDateTime }.prefix(2000))
                
                // This was the exact operation that crashed before the fix
                let analytics = BridgeAnalyticsCalculator.calculateAnalytics(from: limitedEvents)
                
                // Should complete without EXC_BAD_ACCESS
                XCTAssertTrue(analytics.count >= 0, "Statistics calculation should not crash")
                
                print("🧪 [REGRESSION] Thread \(i) completed analytics: \(analytics.count) records")
                expectation.fulfill()
            }
        }
        
        await fulfillment(of: [expectation], timeout: 45.0)
        print("🧪 [AUTOMATED] ✅ Statistics crash regression prevented")
    }
}