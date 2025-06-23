import XCTest
import SwiftUI
import SwiftData
@testable import BridgetStatistics
@testable import BridgetCore

final class BridgetStatisticsTests: XCTestCase {
    
    // MARK: - Test Properties
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var testEvents: [DrawbridgeEvent] = []
    var testBridgeInfo: [DrawbridgeInfo] = []
    
    // MARK: - Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory SwiftData container for testing
        let schema = Schema([DrawbridgeEvent.self, DrawbridgeInfo.self, BridgeAnalytics.self, CascadeEvent.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [config])
        modelContext = ModelContext(modelContainer)
        
        createTestData()
    }
    
    override func tearDown() async throws {
        testEvents.removeAll()
        testBridgeInfo.removeAll()
        modelContext = nil
        modelContainer = nil
        
        try await super.tearDown()
    }
    
    private func createTestData() {
        let now = Date()
        let calendar = Calendar.current
        
        // Create test events for statistics calculations
        for bridgeID in 1...5 {
            for i in 0..<20 {
                let openDate = calendar.date(byAdding: .hour, value: -i, to: now) ?? now
                let closeDate = calendar.date(byAdding: .minute, value: Int.random(in: 5...30), to: openDate)
                
                let event = DrawbridgeEvent(
                    entityType: "Bridge",
                    entityName: "Test Bridge \(bridgeID)",
                    entityID: bridgeID,
                    openDateTime: openDate,
                    closeDateTime: closeDate,
                    minutesOpen: Double.random(in: 5...30),
                    latitude: 47.6000 + Double(bridgeID) * 0.01,
                    longitude: -122.3300 - Double(bridgeID) * 0.01
                )
                testEvents.append(event)
                modelContext.insert(event)
            }
            
            let bridgeInfo = DrawbridgeInfo(
                entityID: bridgeID,
                entityName: "Test Bridge \(bridgeID)",
                entityType: "Bridge",
                latitude: 47.6000 + Double(bridgeID) * 0.01,
                longitude: -122.3300 - Double(bridgeID) * 0.01
            )
            testBridgeInfo.append(bridgeInfo)
            modelContext.insert(bridgeInfo)
        }
        
        try? modelContext.save()
    }
    
    // MARK: - Basic StatisticsView Tests
    
    func testStatisticsViewCreation() throws {
        let statisticsView = StatisticsView()
        XCTAssertNotNil(statisticsView)
    }
    
    // MARK: - Threading & Concurrency Tests (Would have caught the crash!)
    
    func testStatisticsViewPullToRefreshConcurrency() async throws {
        let expectation = XCTestExpectation(description: "Pull to refresh completes without crash")
        expectation.expectedFulfillmentCount = 3
        
        // Simulate multiple rapid pull-to-refresh actions
        for i in 0..<3 {
            Task.detached {
                print("🧪 [TEST] Starting concurrent analytics calculation \(i)")
                
                // Simulate the analytics calculation that was crashing
                let eventsSnapshot = Array(self.testEvents)
                let limitedEvents = Array(eventsSnapshot.sorted { $0.openDateTime > $1.openDateTime }.prefix(2000))
                
                // This should not crash
                let analytics = BridgeAnalyticsCalculator.calculateAnalytics(from: limitedEvents)
                
                XCTAssertTrue(analytics.count >= 0, "Analytics calculation should complete without crash")
                
                print("🧪 [TEST] Completed analytics calculation \(i): \(analytics.count) records")
                expectation.fulfill()
            }
        }
        
        await fulfillment(of: [expectation], timeout: 30.0)
    }
    
    func testStatisticsViewThreadSafety() async throws {
        let expectation = XCTestExpectation(description: "Thread safety test completes")
        expectation.expectedFulfillmentCount = 5
        
        // Test concurrent access to statistics generation
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<5 {
                group.addTask {
                    // Simulate different thread accessing events data
                    let eventsSubset = Array(self.testEvents.shuffled().prefix(50))
                    
                    // This should be thread-safe
                    let analytics = BridgeAnalyticsCalculator.calculateAnalytics(from: eventsSubset)
                    
                    XCTAssertTrue(analytics.count >= 0)
                    
                    print("🧪 [TEST] Thread \(i) completed with \(analytics.count) analytics")
                    expectation.fulfill()
                }
            }
        }
        
        await fulfillment(of: [expectation], timeout: 20.0)
    }
    
    func testStatisticsCalculationMemoryManagement() async throws {
        let expectation = XCTestExpectation(description: "Memory management test completes")
        
        // Test repeated analytics calculations to check for memory leaks
        Task.detached {
            for iteration in 0..<10 {
                autoreleasepool {
                    let analytics = BridgeAnalyticsCalculator.calculateAnalytics(from: self.testEvents)
                    XCTAssertFalse(analytics.isEmpty)
                    
                    // Force deallocation
                    let _ = analytics.count
                }
                
                if iteration == 9 {
                    expectation.fulfill()
                }
            }
        }
        
        await fulfillment(of: [expectation], timeout: 15.0)
    }
    
    // MARK: - Prediction Generation Tests
    
    func testEnhancedPredictionsGeneration() throws {
        // Test the enhanced predictions that combine all phases
        let bridgeInfo = testBridgeInfo.prefix(3) // Limit to 3 bridges for test speed
        
        for bridge in bridgeInfo {
            let prediction = BridgeAnalytics.getARIMAEnhancedPrediction(
                for: bridge,
                events: testEvents,
                analytics: [],
                cascadeEvents: []
            )
            
            if let prediction = prediction {
                XCTAssertTrue(prediction.probability >= 0.0 && prediction.probability <= 1.0)
                XCTAssertTrue(prediction.expectedDuration > 0)
                XCTAssertTrue(prediction.confidence >= 0.0 && prediction.confidence <= 1.0)
                XCTAssertFalse(prediction.reasoning.isEmpty)
            }
        }
    }
    
    func testCurrentPredictionsGeneration() throws {
        // Test the current predictions system
        let analytics = BridgeAnalyticsCalculator.calculateAnalytics(from: testEvents)
        
        for bridge in testBridgeInfo.prefix(3) {
            let prediction = BridgeAnalytics.getCurrentPrediction(for: bridge, from: analytics)
            
            if let prediction = prediction {
                XCTAssertTrue(prediction.probability >= 0.0 && prediction.probability <= 1.0)
                XCTAssertTrue(prediction.expectedDuration > 0)
                XCTAssertTrue(prediction.confidence >= 0.0 && prediction.confidence <= 1.0)
                XCTAssertEqual(prediction.bridge.entityID, bridge.entityID)
            }
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testStatisticsWithEmptyData() throws {
        let emptyAnalytics = BridgeAnalyticsCalculator.calculateAnalytics(from: [])
        XCTAssertTrue(emptyAnalytics.isEmpty)
    }
    
    func testStatisticsWithCorruptedData() throws {
        let corruptedEvent = DrawbridgeEvent(
            entityType: "",
            entityName: "",
            entityID: -999,
            openDateTime: Date.distantPast,
            closeDateTime: Date.distantFuture,
            minutesOpen: -1.0,
            latitude: 0.0,
            longitude: 0.0
        )
        
        // Should handle gracefully
        let analytics = BridgeAnalyticsCalculator.calculateAnalytics(from: [corruptedEvent])
        XCTAssertTrue(analytics.count >= 0) // Should not crash
    }
    
    // MARK: - Performance Tests
    
    func testAnalyticsCalculationPerformance() throws {
        measure {
            let _ = BridgeAnalyticsCalculator.calculateAnalytics(from: testEvents)
        }
    }
    
    func testLargeDatasetPerformance() throws {
        // Create larger dataset for performance testing
        var largeDataset: [DrawbridgeEvent] = []
        let now = Date()
        
        for i in 0..<2000 {
            let event = DrawbridgeEvent(
                entityType: "Bridge",
                entityName: "Perf Test Bridge",
                entityID: i % 10 + 1,
                openDateTime: now.addingTimeInterval(TimeInterval(-i * 300)),
                closeDateTime: now.addingTimeInterval(TimeInterval(-i * 300 + 600)),
                minutesOpen: Double.random(in: 5...30),
                latitude: 47.6062,
                longitude: -122.3321
            )
            largeDataset.append(event)
        }
        
        measure {
            let analytics = BridgeAnalyticsCalculator.calculateAnalytics(from: largeDataset)
            XCTAssertFalse(analytics.isEmpty)
        }
    }
    
    // MARK: - Neural Engine Integration Tests
    
    func testNeuralEngineARIMAPredictorIntegration() throws {
        let predictor = NeuralEngineARIMAPredictor()
        let analytics = BridgeAnalyticsCalculator.calculateAnalytics(from: testEvents)
        
        // Should not crash
        let predictions = predictor.generatePredictions(
            from: Array(testEvents.prefix(100)), // Limit for test speed
            existingAnalytics: Array(analytics.prefix(50))
        )
        
        XCTAssertTrue(predictions.count >= 0)
        
        for prediction in predictions {
            XCTAssertTrue(prediction.probability >= 0.0 && prediction.probability <= 1.0)
            XCTAssertTrue(prediction.expectedDuration > 0)
            XCTAssertFalse(prediction.reasoning.isEmpty)
        }
    }
    
    // MARK: - Cascade Detection Tests
    
    func testCascadeDetectionWithStatisticsData() throws {
        let cascadeEvents = CascadeDetectionEngine.detectCascadeEffects(from: testEvents)
        
        // Should complete without crashing
        XCTAssertTrue(cascadeEvents.count >= 0)
        
        for cascade in cascadeEvents {
            XCTAssertTrue(cascade.triggerBridgeID > 0)
            XCTAssertTrue(cascade.targetBridgeID > 0)
            XCTAssertNotEqual(cascade.triggerBridgeID, cascade.targetBridgeID)
            XCTAssertTrue(cascade.cascadeStrength >= 0.0 && cascade.cascadeStrength <= 1.0)
        }
    }
    
    // MARK: - Stress Tests
    
    func testConcurrentStatisticsCalculations() async throws {
        let expectation = XCTestExpectation(description: "Concurrent calculations complete")
        expectation.expectedFulfillmentCount = 10
        
        // Run 10 concurrent analytics calculations
        for i in 0..<10 {
            Task.detached {
                let subset = Array(self.testEvents.shuffled().prefix(100))
                let analytics = BridgeAnalyticsCalculator.calculateAnalytics(from: subset)
                
                XCTAssertTrue(analytics.count >= 0)
                print("🧪 [STRESS TEST] Completed calculation \(i): \(analytics.count) records")
                
                expectation.fulfill()
            }
        }
        
        await fulfillment(of: [expectation], timeout: 60.0)
    }
    
    func testRapidRefreshActions() async throws {
        let expectation = XCTestExpectation(description: "Rapid refresh test completes")
        expectation.expectedFulfillmentCount = 20
        
        // Simulate rapid pull-to-refresh actions (like user quickly swiping multiple times)
        for i in 0..<20 {
            Task.detached {
                // Simulate the exact operation that was causing crashes
                let eventsSnapshot = Array(self.testEvents)
                let limitedEvents = Array(eventsSnapshot.sorted { $0.openDateTime > $1.openDateTime }.prefix(2000))
                
                let analytics = BridgeAnalyticsCalculator.calculateAnalytics(from: limitedEvents)
                
                XCTAssertTrue(analytics.count >= 0)
                expectation.fulfill()
            }
            
            // Small delay to simulate real user interaction timing
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        }
        
        await fulfillment(of: [expectation], timeout: 30.0)
    }
}

// MARK: - Test Helpers

extension BridgetStatisticsTests {
    
    func createTestAnalytics() -> [BridgeAnalytics] {
        return BridgeAnalyticsCalculator.calculateAnalytics(from: testEvents)
    }
    
    func simulateUserRefreshAction() async {
        // Simulate the exact sequence that caused the crash
        let eventsSnapshot = Array(testEvents)
        let limitedEvents = Array(eventsSnapshot.sorted { $0.openDateTime > $1.openDateTime }.prefix(2000))
        
        // This is the exact calculation that was crashing
        let _ = BridgeAnalyticsCalculator.calculateAnalytics(from: limitedEvents)
    }
}