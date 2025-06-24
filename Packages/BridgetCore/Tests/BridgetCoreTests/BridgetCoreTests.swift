import XCTest
import SwiftData
import Foundation
@testable import BridgetCore

final class BridgetCoreTests: XCTestCase {
    
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
        
        // Create test data
        createTestData()
    }
    
    override func tearDown() async throws {
        // Clean up test data
        testEvents.removeAll()
        testBridgeInfo.removeAll()
        modelContext = nil
        modelContainer = nil
        
        try await super.tearDown()
    }
    
    private func createTestData() {
        let now = Date()
        let calendar = Calendar.current
        
        // Create test events for multiple bridges
        for bridgeID in 1...3 {
            for i in 0..<10 {
                let openDate = calendar.date(byAdding: .hour, value: -i, to: now) ?? now
                let closeDate = calendar.date(byAdding: .minute, value: 15, to: openDate)
                
                let event = DrawbridgeEvent(
                    entityType: "Bridge",
                    entityName: "Test Bridge \(bridgeID)",
                    entityID: bridgeID,
                    openDateTime: openDate,
                    closeDateTime: closeDate,
                    minutesOpen: 15.0,
                    latitude: 47.6000 + Double(bridgeID) * 0.01,
                    longitude: -122.3300 - Double(bridgeID) * 0.01
                )
                testEvents.append(event)
                modelContext.insert(event)
            }
            
            // Create corresponding bridge info
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
    
    // MARK: - DrawbridgeEvent Tests
    
    func testDrawbridgeEventCreation() throws {
        let event = DrawbridgeEvent(
            entityType: "Bridge",
            entityName: "Test Bridge",
            entityID: 1,
            openDateTime: Date(),
            closeDateTime: nil,
            minutesOpen: 15.0,
            latitude: 47.6062,
            longitude: -122.3321
        )
        
        XCTAssertEqual(event.entityName, "Test Bridge")
        XCTAssertEqual(event.entityID, 1)
        XCTAssertTrue(event.isCurrentlyOpen)
        XCTAssertEqual(event.minutesOpen, 15.0)
        XCTAssertEqual(event.latitude, 47.6062, accuracy: 0.0001)
        XCTAssertEqual(event.longitude, -122.3321, accuracy: 0.0001)
    }
    
    func testDrawbridgeEventUniqueID() throws {
        let now = Date()
        let event1 = DrawbridgeEvent(
            entityType: "Bridge",
            entityName: "Test Bridge 1",
            entityID: 1,
            openDateTime: now,
            closeDateTime: nil,
            minutesOpen: 15.0,
            latitude: 47.6062,
            longitude: -122.3321
        )
        
        let event2 = DrawbridgeEvent(
            entityType: "Bridge",
            entityName: "Test Bridge 2",
            entityID: 2,
            openDateTime: now,
            closeDateTime: nil,
            minutesOpen: 20.0,
            latitude: 47.6063,
            longitude: -122.3322
        )
        
        XCTAssertNotEqual(event1.id, event2.id, "Events should have unique IDs")
    }
    
    func testDrawbridgeEventIsCurrentlyOpen() throws {
        let openEvent = DrawbridgeEvent(
            entityType: "Bridge",
            entityName: "Open Bridge",
            entityID: 1,
            openDateTime: Date(),
            closeDateTime: nil,
            minutesOpen: 15.0,
            latitude: 47.6062,
            longitude: -122.3321
        )
        
        let closedEvent = DrawbridgeEvent(
            entityType: "Bridge",
            entityName: "Closed Bridge",
            entityID: 2,
            openDateTime: Date().addingTimeInterval(-3600),
            closeDateTime: Date().addingTimeInterval(-3300),
            minutesOpen: 5.0,
            latitude: 47.6063,
            longitude: -122.3322
        )
        
        XCTAssertTrue(openEvent.isCurrentlyOpen)
        XCTAssertFalse(closedEvent.isCurrentlyOpen)
    }
    
    func testDrawbridgeEventDuration() throws {
        let openDate = Date()
        let closeDate = openDate.addingTimeInterval(900) // 15 minutes
        
        let event = DrawbridgeEvent(
            entityType: "Bridge",
            entityName: "Test Bridge",
            entityID: 1,
            openDateTime: openDate,
            closeDateTime: closeDate,
            minutesOpen: 15.0,
            latitude: 47.6062,
            longitude: -122.3321
        )
        
        XCTAssertEqual(event.minutesOpen, 15.0)
        XCTAssertEqual(event.minutesOpen * 60, 900, accuracy: 1.0) // 15 minutes = 900 seconds
    }
    
    func testDrawbridgeEventRelativeTimeText() throws {
        let event = DrawbridgeEvent(
            entityType: "Bridge",
            entityName: "Test Bridge",
            entityID: 1,
            openDateTime: Date().addingTimeInterval(-3600), // 1 hour ago
            closeDateTime: nil,
            minutesOpen: 15.0,
            latitude: 47.6062,
            longitude: -122.3321
        )
        
        XCTAssertFalse(event.relativeTimeText.isEmpty)
        XCTAssertTrue(event.relativeTimeText.contains("hour"))
    }
    
    // MARK: - DrawbridgeEvent Extensions Tests
    
    func testDrawbridgeEventGroupedByBridge() throws {
        let groupedEvents = DrawbridgeEvent.groupedByBridge(testEvents)
        
        XCTAssertEqual(groupedEvents.count, 3, "Should have 3 bridge groups")
        XCTAssertEqual(groupedEvents["Test Bridge 1"]?.count, 10)
        XCTAssertEqual(groupedEvents["Test Bridge 2"]?.count, 10)
        XCTAssertEqual(groupedEvents["Test Bridge 3"]?.count, 10)
    }
    
    func testDrawbridgeEventGetUniqueBridges() throws {
        let uniqueBridges = DrawbridgeEvent.getUniqueBridges(testEvents)
        
        XCTAssertEqual(uniqueBridges.count, 3, "Should have 3 unique bridges")
        
        let bridgeIDs = uniqueBridges.map(\.entityID).sorted()
        XCTAssertEqual(bridgeIDs, [1, 2, 3])
    }
    
    func testDrawbridgeEventEventsToday() throws {
        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        
        let todayEvent = DrawbridgeEvent(
            entityType: "Bridge",
            entityName: "Today Bridge",
            entityID: 99,
            openDateTime: now,
            closeDateTime: nil,
            minutesOpen: 15.0,
            latitude: 47.6062,
            longitude: -122.3321
        )
        
        let yesterdayEvent = DrawbridgeEvent(
            entityType: "Bridge",
            entityName: "Yesterday Bridge",
            entityID: 98,
            openDateTime: yesterday,
            closeDateTime: nil,
            minutesOpen: 10.0,
            latitude: 47.6063,
            longitude: -122.3322
        )
        
        let allEvents = testEvents + [todayEvent, yesterdayEvent]
        let todayEvents = DrawbridgeEvent.eventsToday(allEvents)
        
        // Should include today's events (testEvents are all recent) plus the explicitly today event
        XCTAssertTrue(todayEvents.contains { $0.entityID == 99 })
        XCTAssertFalse(todayEvents.contains { $0.entityID == 98 })
    }
    
    func testDrawbridgeEventCurrentlyOpenBridges() throws {
        let openEvent = DrawbridgeEvent(
            entityType: "Bridge",
            entityName: "Open Bridge",
            entityID: 99,
            openDateTime: Date(),
            closeDateTime: nil,
            minutesOpen: 15.0,
            latitude: 47.6062,
            longitude: -122.3321
        )
        
        let allEvents = testEvents + [openEvent] // testEvents are all closed
        let openBridges = DrawbridgeEvent.currentlyOpenBridges(allEvents)
        
        XCTAssertEqual(openBridges.count, 1)
        XCTAssertEqual(openBridges.first?.entityID, 99)
    }
    
    // MARK: - BridgeAnalytics Tests
    
    func testBridgeAnalyticsCreation() throws {
        let analytics = BridgeAnalytics(
            entityID: 1,
            entityName: "Test Bridge",
            year: 2025,
            month: 6,
            dayOfWeek: 3,
            hour: 14
        )
        
        XCTAssertEqual(analytics.entityID, 1)
        XCTAssertEqual(analytics.entityName, "Test Bridge")
        XCTAssertEqual(analytics.year, 2025)
        XCTAssertEqual(analytics.month, 6)
        XCTAssertEqual(analytics.dayOfWeek, 3)
        XCTAssertEqual(analytics.hour, 14)
        XCTAssertEqual(analytics.openingCount, 0) // Default value
    }
    
    func testBridgeAnalyticsCalculatorWithRealData() throws {
        let analytics = BridgeAnalyticsCalculator.calculateAnalytics(from: testEvents)
        
        XCTAssertFalse(analytics.isEmpty, "Analytics should be calculated")
        XCTAssertTrue(analytics.count > 0, "Should have analytics records")
        
        // Verify each bridge has analytics
        let bridgeIDs = Set(analytics.map(\.entityID))
        XCTAssertEqual(bridgeIDs, Set([1, 2, 3]))
    }
    
    // MARK: - Concurrency Tests (Would have caught the Statistics crash)
    
    func testBridgeAnalyticsCalculatorConcurrency() async throws {
        let expectation = XCTestExpectation(description: "Analytics calculation completes")
        expectation.expectedFulfillmentCount = 3
        
        // Run multiple concurrent analytics calculations
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<3 {
                group.addTask {
                    let analytics = BridgeAnalyticsCalculator.calculateAnalytics(from: self.testEvents)
                    XCTAssertFalse(analytics.isEmpty)
                    expectation.fulfill()
                }
            }
        }
        
        await fulfillment(of: [expectation], timeout: 10.0)
    }
    
    func testBridgeAnalyticsThreadSafety() async throws {
        let expectation = XCTestExpectation(description: "Thread safety test completes")
        expectation.expectedFulfillmentCount = 5
        
        // Test concurrent access to analytics calculation
        for i in 0..<5 {
            Task.detached {
                let eventsSubset = Array(self.testEvents.prefix(10 + i))
                let analytics = BridgeAnalyticsCalculator.calculateAnalytics(from: eventsSubset)
                XCTAssertTrue(analytics.count >= 0) // Should not crash
                expectation.fulfill()
            }
        }
        
        await fulfillment(of: [expectation], timeout: 15.0)
    }
    
    // MARK: - Memory Management Tests
    
    func testLargeDatasetMemoryUsage() throws {
        // Create a large dataset to test memory handling
        var largeEventSet: [DrawbridgeEvent] = []
        let now = Date()
        
        for i in 0..<1000 {
            let event = DrawbridgeEvent(
                entityType: "Bridge",
                entityName: "Memory Test Bridge",
                entityID: 1,
                openDateTime: now.addingTimeInterval(TimeInterval(-i * 3600)),
                closeDateTime: now.addingTimeInterval(TimeInterval(-i * 3600 + 900)),
                minutesOpen: 15.0,
                latitude: 47.6062,
                longitude: -122.3321
            )
            largeEventSet.append(event)
        }
        
        // This should not crash or cause excessive memory usage
        let analytics = BridgeAnalyticsCalculator.calculateAnalytics(from: largeEventSet)
        
        XCTAssertFalse(analytics.isEmpty)
        
        // Clean up
        largeEventSet.removeAll()
    }
    
    // MARK: - Neural Engine Tests
    
    func testNeuralEngineManagerConfiguration() throws {
        let config = NeuralEngineManager.getOptimalConfig()
        
        XCTAssertNotNil(config.generation)
        XCTAssertTrue(config.generation.coreCount > 0)
        XCTAssertTrue(config.generation.topsCapability > 0)
        XCTAssertNotNil(config.complexity)
    }
    
    func testNeuralEngineARIMAPredictor() throws {
        let predictor = NeuralEngineARIMAPredictor()
        XCTAssertNotNil(predictor)
        
        // Test with small dataset
        let predictions = predictor.generatePredictions(from: Array(testEvents.prefix(5)))
        
        // Should not crash and return some result
        XCTAssertTrue(predictions.count >= 0)
    }
    
    // MARK: - Cascade Detection Tests
    
    func testCascadeDetectionEngine() throws {
        let cascadeEvents = CascadeDetectionEngine.detectCascadeEffects(from: testEvents)
        
        // Should not crash and return results
        XCTAssertTrue(cascadeEvents.count >= 0)
    }
    
    func testCascadeDetectionWithEmptyData() throws {
        let cascadeEvents = CascadeDetectionEngine.detectCascadeEffects(from: [])
        
        XCTAssertTrue(cascadeEvents.isEmpty)
    }
    
    // MARK: - Error Handling Tests
    
    func testAnalyticsWithCorruptedData() throws {
        // Create events with edge case data
        let corruptedEvents = [
            DrawbridgeEvent(
                entityType: "",
                entityName: "",
                entityID: -1,
                openDateTime: Date.distantPast,
                closeDateTime: Date.distantFuture,
                minutesOpen: -1.0,
                latitude: 0.0,
                longitude: 0.0
            )
        ]
        
        // Should handle gracefully without crashing
        let analytics = BridgeAnalyticsCalculator.calculateAnalytics(from: corruptedEvents)
        XCTAssertTrue(analytics.count >= 0) // May be empty, but shouldn't crash
    }
    
    // MARK: - Performance Tests
    
    func testAnalyticsPerformance() throws {
        measure {
            let _ = BridgeAnalyticsCalculator.calculateAnalytics(from: testEvents)
        }
    }
    
    func testEventGroupingPerformance() throws {
        measure {
            let _ = DrawbridgeEvent.groupedByBridge(testEvents)
        }
    }
}

// MARK: - Test Extensions

extension BridgetCoreTests {
    
    func createTestEvent(id: Int, name: String, isOpen: Bool = false) -> DrawbridgeEvent {
        let now = Date()
        return DrawbridgeEvent(
            entityType: "Bridge",
            entityName: name,
            entityID: id,
            openDateTime: now,
            closeDateTime: isOpen ? nil : now.addingTimeInterval(900),
            minutesOpen: 15.0,
            latitude: 47.6062 + Double(id) * 0.001,
            longitude: -122.3321 - Double(id) * 0.001
        )
    }
}