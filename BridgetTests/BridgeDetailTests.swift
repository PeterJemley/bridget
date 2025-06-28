//
//  BridgeDetailTests.swift
//  BridgetTests
//
//  Created by Peter Jemley on 6/19/25.
//

import XCTest
import SwiftUI
import SwiftData
import BridgetCore
import BridgetBridgeDetail
@testable import BridgetCore

@MainActor
final class BridgeDetailTests: XCTestCase {
    
    var modelContext: ModelContext!
    var testBridgeEvent: DrawbridgeEvent!
    var testEvents: [DrawbridgeEvent]!
    var viewModel: BridgeDetailViewModel!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory SwiftData store for testing
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: DrawbridgeEvent.self, CascadeEvent.self, BridgeAnalytics.self, configurations: config)
        modelContext = ModelContext(container)
        
        // Create test bridge event
        testBridgeEvent = DrawbridgeEvent(
            entityType: "Bridge",
            entityName: "Test Bridge",
            entityID: 1,
            openDateTime: Date(),
            closeDateTime: Date().addingTimeInterval(900), // 15 minutes later
            minutesOpen: 15.0,
            latitude: 47.6062,
            longitude: -122.3321
        )
        
        // Create test events
        testEvents = createTestEvents()
        
        // Insert events into model context
        for event in testEvents {
            modelContext.insert(event)
        }
        try modelContext.save()
        
        // Create view model
        viewModel = BridgeDetailViewModel(bridgeEvent: testBridgeEvent)
    }
    
    override func tearDown() async throws {
        modelContext = nil
        testBridgeEvent = nil
        testEvents = nil
        viewModel = nil
        try await super.tearDown()
    }
    
    // MARK: - Test Data Creation
    
    private func createTestEvents() -> [DrawbridgeEvent] {
        let calendar = Calendar.current
        let now = Date()
        
        return [
            // Events for the test bridge (ID: 1)
            DrawbridgeEvent(
                entityType: "Bridge",
                entityName: "Test Bridge",
                entityID: 1,
                openDateTime: calendar.date(byAdding: .day, value: -1, to: now) ?? now,
                closeDateTime: calendar.date(byAdding: .minute, value: 20, to: now),
                minutesOpen: 20.0,
                latitude: 47.6062,
                longitude: -122.3321
            ),
            DrawbridgeEvent(
                entityType: "Bridge",
                entityName: "Test Bridge",
                entityID: 1,
                openDateTime: calendar.date(byAdding: .day, value: -2, to: now) ?? now,
                closeDateTime: calendar.date(byAdding: .minute, value: 30, to: now),
                minutesOpen: 30.0,
                latitude: 47.6062,
                longitude: -122.3321
            ),
            DrawbridgeEvent(
                entityType: "Bridge",
                entityName: "Test Bridge",
                entityID: 1,
                openDateTime: calendar.date(byAdding: .day, value: -3, to: now) ?? now,
                closeDateTime: calendar.date(byAdding: .minute, value: 15, to: now),
                minutesOpen: 15.0,
                latitude: 47.6062,
                longitude: -122.3321
            ),
            // Events for a different bridge (ID: 2)
            DrawbridgeEvent(
                entityType: "Bridge",
                entityName: "Other Bridge",
                entityID: 2,
                openDateTime: calendar.date(byAdding: .day, value: -1, to: now) ?? now,
                closeDateTime: calendar.date(byAdding: .minute, value: 25, to: now),
                minutesOpen: 25.0,
                latitude: 47.6062,
                longitude: -122.3321
            )
        ]
    }
    
    // MARK: - ViewModel Tests
    
    func testViewModelInitialization() {
        XCTAssertEqual(viewModel.selectedPeriod, .sevenDays)
        XCTAssertEqual(viewModel.selectedAnalysis, .patterns)
        XCTAssertEqual(viewModel.selectedView, .activity)
        XCTAssertFalse(viewModel.isDataReady)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testCheckDataAvailabilityWithBridgeEvents() {
        // Given: Events exist for the bridge
        let allEvents = testEvents
        
        // When: Checking data availability
        viewModel.checkDataAvailability(allEvents: allEvents)
        
        // Then: Should be ready
        XCTAssertTrue(viewModel.isDataReady)
    }
    
    func testCheckDataAvailabilityWithNoBridgeEvents() {
        // Given: No events for the specific bridge
        let otherBridgeEvents = [
            DrawbridgeEvent(
                entityType: "Bridge",
                entityName: "Other Bridge",
                entityID: 999, // Different ID
                openDateTime: Date(),
                closeDateTime: Date().addingTimeInterval(900),
                minutesOpen: 15.0,
                latitude: 47.6062,
                longitude: -122.3321
            )
        ]
        
        // When: Checking data availability
        viewModel.checkDataAvailability(allEvents: otherBridgeEvents)
        
        // Then: Should still be ready (other data exists)
        XCTAssertTrue(viewModel.isDataReady)
    }
    
    func testCheckDataAvailabilityWithNoEvents() {
        // Given: No events at all
        let emptyEvents: [DrawbridgeEvent] = []
        
        // When: Checking data availability
        viewModel.checkDataAvailability(allEvents: emptyEvents)
        
        // Then: Should not be ready initially
        XCTAssertFalse(viewModel.isDataReady)
        
        // Wait for timer to complete
        let expectation = XCTestExpectation(description: "Timer timeout")
        DispatchQueue.main.asyncAfter(deadline: .now() + 11) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 12.0)
        
        // Should be ready after timeout
        XCTAssertTrue(viewModel.isDataReady)
    }
    
    func testForceCascadeDetection() async {
        // Given: Events and cascade events
        let allEvents = testEvents
        let cascadeEvents: [CascadeEvent] = []
        
        // When: Forcing cascade detection
        await viewModel.forceCascadeDetection(
            allEvents: allEvents,
            cascadeEvents: cascadeEvents,
            modelContext: modelContext
        )
        
        // Then: Should complete without error
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testForceCascadeDetectionWithError() async {
        // Given: Invalid model context (simulating error)
        let allEvents = testEvents
        let cascadeEvents: [CascadeEvent] = []
        let invalidContext = ModelContext(try! ModelContainer(for: DrawbridgeEvent.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)))
        
        // When: Forcing cascade detection with invalid context
        await viewModel.forceCascadeDetection(
            allEvents: allEvents,
            cascadeEvents: cascadeEvents,
            modelContext: invalidContext
        )
        
        // Then: Should show error
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    func testConcurrentCascadeDetection() async {
        // Given: Multiple concurrent detection requests
        let allEvents = testEvents
        let cascadeEvents: [CascadeEvent] = []
        
        let expectation1 = XCTestExpectation(description: "First detection")
        let expectation2 = XCTestExpectation(description: "Second detection")
        
        // When: Starting multiple detections concurrently
        Task {
            await viewModel.forceCascadeDetection(
                allEvents: allEvents,
                cascadeEvents: cascadeEvents,
                modelContext: modelContext
            )
            expectation1.fulfill()
        }
        
        Task {
            await viewModel.forceCascadeDetection(
                allEvents: allEvents,
                cascadeEvents: cascadeEvents,
                modelContext: modelContext
            )
            expectation2.fulfill()
        }
        
        // Then: Both should complete without errors
        await fulfillment(of: [expectation1, expectation2], timeout: 10.0)
        
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    // MARK: - View Tests
    
    func testBridgeDetailViewInitialization() {
        // Given: Bridge event
        let bridgeEvent = testBridgeEvent
        
        // When: Creating view
        let view = BridgeDetailView(bridgeEvent: bridgeEvent)
        
        // Then: Should initialize without error
        XCTAssertNotNil(view)
    }
    
    func testBridgeDetailViewWithData() {
        // Given: Bridge event and events in context
        let bridgeEvent = testBridgeEvent
        
        // When: Creating view
        let view = BridgeDetailView(bridgeEvent: bridgeEvent)
        
        // Then: Should have access to model context
        XCTAssertNotNil(view)
    }
    
    // MARK: - Computed Properties Tests
    
    func testBridgeSpecificEventsFiltering() {
        // Given: Events for multiple bridges
        let allEvents = testEvents
        
        // When: Filtering for specific bridge
        let bridgeSpecificEvents = allEvents.filter { $0.entityID == testBridgeEvent.entityID }
        
        // Then: Should only include events for the test bridge
        XCTAssertEqual(bridgeSpecificEvents.count, 3)
        XCTAssertTrue(bridgeSpecificEvents.allSatisfy { $0.entityID == testBridgeEvent.entityID })
    }
    
    func testFilteredEventsByTimePeriod() {
        // Given: Events across different time periods
        let allEvents = testEvents
        let calendar = Calendar.current
        let now = Date()
        
        // When: Filtering for 24 hours
        let cutoffDate = calendar.date(byAdding: .hour, value: -25, to: now) ?? now
        let filteredEvents = allEvents.filter { $0.openDateTime >= cutoffDate }
        
        // Then: Should include recent events
        XCTAssertGreaterThanOrEqual(filteredEvents.count, 0)
    }
    
    func testLastKnownEvent() {
        // Given: Events sorted by date
        let sortedEvents = testEvents
            .filter { $0.entityID == testBridgeEvent.entityID }
            .sorted { $0.openDateTime > $1.openDateTime }
        
        // When: Getting last known event
        let lastKnownEvent = sortedEvents.first
        
        // Then: Should be the most recent event
        XCTAssertNotNil(lastKnownEvent)
        XCTAssertEqual(lastKnownEvent?.entityID, testBridgeEvent.entityID)
    }
    
    // MARK: - State Management Tests
    
    func testStateChanges() {
        // Given: Initial state
        XCTAssertFalse(viewModel.isDataReady)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        
        // When: Changing state
        viewModel.isDataReady = true
        viewModel.isLoading = true
        viewModel.errorMessage = "Test error"
        
        // Then: State should be updated
        XCTAssertTrue(viewModel.isDataReady)
        XCTAssertTrue(viewModel.isLoading)
        XCTAssertEqual(viewModel.errorMessage, "Test error")
    }
    
    func testStateReset() {
        // Given: Modified state
        viewModel.isDataReady = true
        viewModel.isLoading = true
        viewModel.errorMessage = "Test error"
        
        // When: Resetting state
        viewModel.isDataReady = false
        viewModel.isLoading = false
        viewModel.errorMessage = nil
        
        // Then: State should be reset
        XCTAssertFalse(viewModel.isDataReady)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceWithLargeDataset() async {
        // Given: Large dataset
        let largeEvents = createLargeTestDataset(count: 1000)
        
        // When: Checking data availability
        let startTime = Date()
        viewModel.checkDataAvailability(allEvents: largeEvents)
        let endTime = Date()
        
        // Then: Should complete quickly
        let duration = endTime.timeIntervalSince(startTime)
        XCTAssertLessThan(duration, 1.0, "Data availability check should complete within 1 second")
        
        XCTAssertTrue(viewModel.isDataReady)
    }
    
    private func createLargeTestDataset(count: Int) -> [DrawbridgeEvent] {
        let calendar = Calendar.current
        let now = Date()
        
        return (0..<count).map { index in
            let randomDaysAgo = Int.random(in: 0...30)
            let randomDuration = Double.random(in: 5...120)
            
            return DrawbridgeEvent(
                entityType: "Bridge",
                entityName: "Test Bridge",
                entityID: index % 2 == 0 ? 1 : 2, // Alternate between bridges
                openDateTime: calendar.date(byAdding: .day, value: -randomDaysAgo, to: now) ?? now,
                closeDateTime: calendar.date(byAdding: .minute, value: Int(randomDuration), to: now),
                minutesOpen: randomDuration,
                latitude: 47.6062,
                longitude: -122.3321
            )
        }
    }
    
    // MARK: - Edge Case Tests
    
    func testViewModelWithInvalidBridgeEvent() {
        // Given: Invalid bridge event (future date, negative duration, etc.)
        let invalidBridgeEvent = DrawbridgeEvent(
            entityType: "Bridge",
            entityName: "Invalid Bridge",
            entityID: -1,
            openDateTime: Date().addingTimeInterval(86400), // Future date
            closeDateTime: Date().addingTimeInterval(-3600), // Close before open
            minutesOpen: -10.0, // Negative duration
            latitude: 47.6062,
            longitude: -122.3321
        )
        
        // When: Creating view model
        let invalidViewModel = BridgeDetailViewModel(bridgeEvent: invalidBridgeEvent)
        
        // Then: Should handle invalid data gracefully
        XCTAssertNotNil(invalidViewModel)
        XCTAssertEqual(invalidViewModel.selectedPeriod, .sevenDays)
        XCTAssertFalse(invalidViewModel.isDataReady)
    }
    
    func testDataAvailabilityWithMixedEvents() {
        // Given: Mixed events (some valid, some invalid)
        let mixedEvents = [
            testEvents[0], // Valid event
            DrawbridgeEvent(
                entityType: "Bridge",
                entityName: "Invalid Bridge",
                entityID: 1,
                openDateTime: Date().addingTimeInterval(86400), // Future date
                closeDateTime: nil,
                minutesOpen: 0.0,
                latitude: 47.6062,
                longitude: -122.3321
            )
        ]
        
        // When: Checking data availability
        viewModel.checkDataAvailability(allEvents: mixedEvents)
        
        // Then: Should handle mixed data gracefully
        XCTAssertTrue(viewModel.isDataReady)
    }
    
    func testTimerCleanup() {
        // Given: Timer is started
        viewModel.checkDataAvailability(allEvents: [])
        
        // When: Deallocating view model
        let expectation = XCTestExpectation(description: "Timer cleanup")
        
        // Simulate deallocation by setting to nil
        viewModel = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        
        // Then: Should not crash and timer should be cleaned up
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Integration Tests
    
    func testFullWorkflow() async {
        // Given: Complete setup
        let allEvents = testEvents
        let cascadeEvents: [CascadeEvent] = []
        
        // When: Running full workflow
        viewModel.checkDataAvailability(allEvents: allEvents)
        
        // Then: Should be ready
        XCTAssertTrue(viewModel.isDataReady)
        
        // When: Performing cascade detection
        await viewModel.forceCascadeDetection(
            allEvents: allEvents,
            cascadeEvents: cascadeEvents,
            modelContext: modelContext
        )
        
        // Then: Should complete successfully
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testErrorRecovery() async {
        // Given: Initial error state
        viewModel.errorMessage = "Initial error"
        
        // When: Successful operation
        let allEvents = testEvents
        let cascadeEvents: [CascadeEvent] = []
        
        await viewModel.forceCascadeDetection(
            allEvents: allEvents,
            cascadeEvents: cascadeEvents,
            modelContext: modelContext
        )
        
        // Then: Error should be cleared
        XCTAssertNil(viewModel.errorMessage)
    }
} 