//
//  DynamicAnalysisTests.swift
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
final class DynamicAnalysisTests: XCTestCase {
    
    var modelContext: ModelContext!
    var testEvents: [DrawbridgeEvent]!
    var viewModel: DynamicAnalysisViewModel!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory SwiftData store for testing
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: DrawbridgeEvent.self, CascadeEvent.self, BridgeAnalytics.self, configurations: config)
        modelContext = ModelContext(container)
        
        // Create test events
        testEvents = createTestEvents()
        
        // Create view model
        viewModel = DynamicAnalysisViewModel(
            events: testEvents,
            analysisType: .patterns,
            viewType: .activity,
            bridgeName: "Test Bridge"
        )
    }
    
    override func tearDown() async throws {
        modelContext = nil
        testEvents = nil
        viewModel = nil
        try await super.tearDown()
    }
    
    // MARK: - Test Data Creation
    
    private func createTestEvents() -> [DrawbridgeEvent] {
        let calendar = Calendar.current
        let now = Date()
        
        return [
            // Morning rush hour events
            DrawbridgeEvent(
                entityType: "Bridge",
                entityName: "Test Bridge",
                entityID: 1,
                openDateTime: calendar.date(bySettingHour: 8, minute: 30, second: 0, of: now) ?? now,
                closeDateTime: calendar.date(bySettingHour: 8, minute: 45, second: 0, of: now),
                minutesOpen: 15.0,
                latitude: 47.6062,
                longitude: -122.3321
            ),
            DrawbridgeEvent(
                entityType: "Bridge",
                entityName: "Test Bridge",
                entityID: 1,
                openDateTime: calendar.date(bySettingHour: 9, minute: 15, second: 0, of: now) ?? now,
                closeDateTime: calendar.date(bySettingHour: 9, minute: 50, second: 0, of: now),
                minutesOpen: 35.0,
                latitude: 47.6062,
                longitude: -122.3321
            ),
            // Afternoon events
            DrawbridgeEvent(
                entityType: "Bridge",
                entityName: "Test Bridge",
                entityID: 1,
                openDateTime: calendar.date(bySettingHour: 14, minute: 0, second: 0, of: now) ?? now,
                closeDateTime: calendar.date(bySettingHour: 14, minute: 20, second: 0, of: now),
                minutesOpen: 20.0,
                latitude: 47.6062,
                longitude: -122.3321
            ),
            // Evening rush hour events
            DrawbridgeEvent(
                entityType: "Bridge",
                entityName: "Test Bridge",
                entityID: 1,
                openDateTime: calendar.date(bySettingHour: 17, minute: 30, second: 0, of: now) ?? now,
                closeDateTime: calendar.date(bySettingHour: 18, minute: 15, second: 0, of: now),
                minutesOpen: 45.0,
                latitude: 47.6062,
                longitude: -122.3321
            ),
            // Late night event
            DrawbridgeEvent(
                entityType: "Bridge",
                entityName: "Test Bridge",
                entityID: 1,
                openDateTime: calendar.date(bySettingHour: 23, minute: 0, second: 0, of: now) ?? now,
                closeDateTime: calendar.date(bySettingHour: 23, minute: 10, second: 0, of: now),
                minutesOpen: 10.0,
                latitude: 47.6062,
                longitude: -122.3321
            )
        ]
    }
    
    // MARK: - ViewModel Tests
    
    func testViewModelInitialization() {
        XCTAssertEqual(viewModel.isAnalyzing, false)
        XCTAssertNil(viewModel.analysisError)
        XCTAssertNil(viewModel.cachedAnalysisData)
    }
    
    func testPerformAnalysisWithValidEvents() async {
        // Given: Valid events
        XCTAssertFalse(testEvents.isEmpty)
        
        // When: Performing analysis
        await viewModel.performAnalysis()
        
        // Then: Analysis should complete successfully
        XCTAssertFalse(viewModel.isAnalyzing)
        XCTAssertNil(viewModel.analysisError)
        XCTAssertNotNil(viewModel.cachedAnalysisData)
        
        // Verify analysis data structure
        guard let analysisData = viewModel.cachedAnalysisData else {
            XCTFail("Analysis data should not be nil")
            return
        }
        
        XCTAssertEqual(analysisData.hourlyData.count, 24) // 24 hours
        XCTAssertEqual(analysisData.weeklyData.count, 7) // 7 days
        XCTAssertEqual(analysisData.durationRanges.count, 5) // 5 duration ranges
        XCTAssertEqual(analysisData.severityBreakdown.count, 4) // 4 severity levels
    }
    
    func testPerformAnalysisWithEmptyEvents() async {
        // Given: Empty events
        let emptyViewModel = DynamicAnalysisViewModel(
            events: [],
            analysisType: .patterns,
            viewType: .activity,
            bridgeName: "Test Bridge"
        )
        
        // When: Performing analysis
        await emptyViewModel.performAnalysis()
        
        // Then: Should show error
        XCTAssertFalse(emptyViewModel.isAnalyzing)
        XCTAssertNotNil(emptyViewModel.analysisError)
        XCTAssertNil(emptyViewModel.cachedAnalysisData)
        XCTAssertEqual(emptyViewModel.analysisError, "No events available for analysis")
    }
    
    func testHourlyDataCalculation() async {
        // Given: Test events with known hours
        await viewModel.performAnalysis()
        
        // Then: Verify hourly data
        guard let analysisData = viewModel.cachedAnalysisData else {
            XCTFail("Analysis data should not be nil")
            return
        }
        
        // Check specific hours where we have events
        let hour8Data = analysisData.hourlyData.first { $0.hour == 8 }
        let hour9Data = analysisData.hourlyData.first { $0.hour == 9 }
        let hour14Data = analysisData.hourlyData.first { $0.hour == 14 }
        let hour17Data = analysisData.hourlyData.first { $0.hour == 17 }
        let hour23Data = analysisData.hourlyData.first { $0.hour == 23 }
        
        XCTAssertNotNil(hour8Data)
        XCTAssertEqual(hour8Data?.count, 1)
        
        XCTAssertNotNil(hour9Data)
        XCTAssertEqual(hour9Data?.count, 1)
        
        XCTAssertNotNil(hour14Data)
        XCTAssertEqual(hour14Data?.count, 1)
        
        XCTAssertNotNil(hour17Data)
        XCTAssertEqual(hour17Data?.count, 1)
        
        XCTAssertNotNil(hour23Data)
        XCTAssertEqual(hour23Data?.count, 1)
        
        // Check that all 24 hours are present
        XCTAssertEqual(analysisData.hourlyData.count, 24)
        
        // Check that maxCount is calculated correctly
        let maxCount = analysisData.hourlyData.map(\.count).max() ?? 0
        XCTAssertEqual(maxCount, 1) // All hours have at most 1 event in our test data
    }
    
    func testDurationRangesCalculation() async {
        // Given: Test events with known durations
        await viewModel.performAnalysis()
        
        // Then: Verify duration ranges
        guard let analysisData = viewModel.cachedAnalysisData else {
            XCTFail("Analysis data should not be nil")
            return
        }
        
        // Check that we have duration ranges
        XCTAssertFalse(analysisData.durationRanges.isEmpty, "Should have duration ranges")
        XCTAssertEqual(analysisData.durationRanges.count, 5, "Should have 5 duration ranges")
        
        // Check that all ranges have valid data
        for rangeData in analysisData.durationRanges {
            XCTAssertNotNil(rangeData.range)
            XCTAssertGreaterThanOrEqual(rangeData.count, 0)
            XCTAssertGreaterThanOrEqual(rangeData.percentage, 0.0)
            XCTAssertLessThanOrEqual(rangeData.percentage, 1.0)
        }
        
        // Check that percentages add up to approximately 1.0 (allowing for floating point precision)
        let totalPercentage = analysisData.durationRanges.map(\.percentage).reduce(0, +)
        XCTAssertEqual(totalPercentage, 1.0, accuracy: 0.01, "Percentages should sum to 1.0")
        
        // Check that total count matches event count
        let totalCount = analysisData.durationRanges.map(\.count).reduce(0, +)
        XCTAssertEqual(totalCount, testEvents.count, "Total count should match event count")
        
        // Verify specific ranges exist (but don't assume specific counts)
        let rangeLabels = analysisData.durationRanges.map(\.range)
        XCTAssertTrue(rangeLabels.contains("0-15 min"))
        XCTAssertTrue(rangeLabels.contains("15-30 min"))
        XCTAssertTrue(rangeLabels.contains("30-60 min"))
        XCTAssertTrue(rangeLabels.contains("1-2 hours"))
        XCTAssertTrue(rangeLabels.contains("2+ hours"))
    }
    
    func testSeverityBreakdownCalculation() async {
        // Given: Test events with known characteristics
        await viewModel.performAnalysis()
        
        // Then: Verify severity breakdown
        guard let analysisData = viewModel.cachedAnalysisData else {
            XCTFail("Analysis data should not be nil")
            return
        }
        
        // Check severity levels
        let highSeverity = analysisData.severityBreakdown.first { $0.severity == "High" }
        let moderateSeverity = analysisData.severityBreakdown.first { $0.severity == "Moderate" }
        let lowSeverity = analysisData.severityBreakdown.first { $0.severity == "Low" }
        let minimalSeverity = analysisData.severityBreakdown.first { $0.severity == "Minimal" }
        
        XCTAssertNotNil(highSeverity)
        XCTAssertNotNil(moderateSeverity)
        XCTAssertNotNil(lowSeverity)
        XCTAssertNotNil(minimalSeverity)
        
        // Verify colors
        XCTAssertEqual(highSeverity?.color, .red)
        XCTAssertEqual(moderateSeverity?.color, .orange)
        XCTAssertEqual(lowSeverity?.color, .yellow)
        XCTAssertEqual(minimalSeverity?.color, .green)
        
        // Verify total adds up to 5 events
        let totalCount = analysisData.severityBreakdown.map(\.count).reduce(0, +)
        XCTAssertEqual(totalCount, 5)
    }
    
    func testImpactMetricsCalculation() async {
        // Given: Test events
        await viewModel.performAnalysis()
        
        // Then: Verify impact metrics
        guard let analysisData = viewModel.cachedAnalysisData else {
            XCTFail("Analysis data should not be nil")
            return
        }
        
        XCTAssertEqual(analysisData.impactMetrics.totalEvents, 5)
        XCTAssertGreaterThanOrEqual(analysisData.impactMetrics.highImpactCount, 0)
        XCTAssertGreaterThan(analysisData.impactMetrics.averageDelay, 0)
        XCTAssertNotEqual(analysisData.impactMetrics.peakHour, "Unknown")
    }
    
    func testConcurrentAnalysisRequests() async {
        // Given: Multiple concurrent analysis requests
        let expectation1 = XCTestExpectation(description: "First analysis")
        let expectation2 = XCTestExpectation(description: "Second analysis")
        
        // When: Starting multiple analyses concurrently
        Task {
            await viewModel.performAnalysis()
            expectation1.fulfill()
        }
        
        Task {
            await viewModel.performAnalysis()
            expectation2.fulfill()
        }
        
        // Then: Both should complete without errors
        await fulfillment(of: [expectation1, expectation2], timeout: 5.0)
        
        XCTAssertFalse(viewModel.isAnalyzing)
        XCTAssertNil(viewModel.analysisError)
        XCTAssertNotNil(viewModel.cachedAnalysisData)
    }
    
    func testAnalysisWithDifferentTypes() async {
        // Test different analysis types
        let analysisTypes: [AnalysisType] = [.patterns, .cascade, .predictions, .impact]
        
        for analysisType in analysisTypes {
            let testViewModel = DynamicAnalysisViewModel(
                events: testEvents,
                analysisType: analysisType,
                viewType: .activity,
                bridgeName: "Test Bridge"
            )
            
            await testViewModel.performAnalysis()
            
            XCTAssertFalse(testViewModel.isAnalyzing)
            XCTAssertNil(testViewModel.analysisError)
            XCTAssertNotNil(testViewModel.cachedAnalysisData)
        }
    }
    
    func testAnalysisWithDifferentViewTypes() async {
        // Test different view types
        let viewTypes: [ViewType] = [.activity, .weekly, .duration]
        
        for viewType in viewTypes {
            let testViewModel = DynamicAnalysisViewModel(
                events: testEvents,
                analysisType: .patterns,
                viewType: viewType,
                bridgeName: "Test Bridge"
            )
            
            await testViewModel.performAnalysis()
            
            XCTAssertFalse(testViewModel.isAnalyzing)
            XCTAssertNil(testViewModel.analysisError)
            XCTAssertNotNil(testViewModel.cachedAnalysisData)
        }
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceWithLargeDataset() async {
        // Given: Large dataset
        let largeEvents = createLargeTestDataset(count: 1000)
        let largeViewModel = DynamicAnalysisViewModel(
            events: largeEvents,
            analysisType: .patterns,
            viewType: .activity,
            bridgeName: "Test Bridge"
        )
        
        // When: Performing analysis
        let startTime = Date()
        await largeViewModel.performAnalysis()
        let endTime = Date()
        
        // Then: Should complete within reasonable time
        let duration = endTime.timeIntervalSince(startTime)
        XCTAssertLessThan(duration, 5.0, "Analysis should complete within 5 seconds")
        
        XCTAssertFalse(largeViewModel.isAnalyzing)
        XCTAssertNil(largeViewModel.analysisError)
        XCTAssertNotNil(largeViewModel.cachedAnalysisData)
    }
    
    private func createLargeTestDataset(count: Int) -> [DrawbridgeEvent] {
        let calendar = Calendar.current
        let now = Date()
        
        return (0..<count).map { index in
            let randomHour = Int.random(in: 0...23)
            let randomMinute = Int.random(in: 0...59)
            let randomDuration = Double.random(in: 5...120)
            
            return DrawbridgeEvent(
                entityType: "Bridge",
                entityName: "Test Bridge",
                entityID: 1,
                openDateTime: calendar.date(bySettingHour: randomHour, minute: randomMinute, second: 0, of: now) ?? now,
                closeDateTime: calendar.date(byAdding: .minute, value: Int(randomDuration), to: now),
                minutesOpen: randomDuration,
                latitude: 47.6062,
                longitude: -122.3321
            )
        }
    }
    
    // MARK: - Edge Case Tests
    
    func testAnalysisWithSingleEvent() async {
        // Given: Single event
        let singleEvent = [testEvents[0]]
        let singleViewModel = DynamicAnalysisViewModel(
            events: singleEvent,
            analysisType: .patterns,
            viewType: .activity,
            bridgeName: "Test Bridge"
        )
        
        // When: Performing analysis
        await singleViewModel.performAnalysis()
        
        // Then: Should handle single event gracefully
        XCTAssertFalse(singleViewModel.isAnalyzing)
        XCTAssertNil(singleViewModel.analysisError)
        XCTAssertNotNil(singleViewModel.cachedAnalysisData)
    }
    
    func testAnalysisWithInvalidData() async {
        // Given: Events with invalid data (negative durations, future dates, etc.)
        let invalidEvents = [
            DrawbridgeEvent(
                entityType: "Bridge",
                entityName: "Test Bridge",
                entityID: 1,
                openDateTime: Date(),
                closeDateTime: Date().addingTimeInterval(-3600), // Close before open
                minutesOpen: -10.0, // Negative duration
                latitude: 47.6062,
                longitude: -122.3321
            )
        ]
        
        let invalidViewModel = DynamicAnalysisViewModel(
            events: invalidEvents,
            analysisType: .patterns,
            viewType: .activity,
            bridgeName: "Test Bridge"
        )
        
        // When: Performing analysis
        await invalidViewModel.performAnalysis()
        
        // Then: Should handle invalid data gracefully
        XCTAssertFalse(invalidViewModel.isAnalyzing)
        // Should either complete successfully or show appropriate error
        XCTAssertNotNil(invalidViewModel.cachedAnalysisData ?? invalidViewModel.analysisError)
    }
} 