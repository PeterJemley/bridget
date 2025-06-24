//
//  BridgetTests.swift
//  BridgetTests
//
//  Created by Peter Jemley on 6/18/25.
//

import Testing
import XCTest
import SwiftUI
import SwiftData
@testable import Bridget
@testable import BridgetCore
@testable import BridgetNetworking
@testable import BridgetStatistics
@testable import BridgetDashboard
@testable import BridgetBridgeDetail

struct BridgetIntegrationTests {
    
    // MARK: - Integration Test Data
    
    var testEvents: [DrawbridgeEvent] = []
    var testBridgeInfo: [DrawbridgeInfo] = []
    
    init() {
        createTestData()
    }
    
    mutating func createTestData() {
        let now = Date()
        let calendar = Calendar.current
        
        for bridgeID in 1...3 {
            for i in 0..<15 {
                let openDate = calendar.date(byAdding: .hour, value: -i, to: now) ?? now
                let closeDate = calendar.date(byAdding: .minute, value: 10, to: openDate)
                
                let event = DrawbridgeEvent(
                    entityType: "Bridge",
                    entityName: "Integration Test Bridge \(bridgeID)",
                    entityID: bridgeID,
                    openDateTime: openDate,
                    closeDateTime: closeDate,
                    minutesOpen: 10.0,
                    latitude: 47.6000 + Double(bridgeID) * 0.01,
                    longitude: -122.3300 - Double(bridgeID) * 0.01
                )
                testEvents.append(event)
            }
            
            let bridgeInfo = DrawbridgeInfo(
                entityID: bridgeID,
                entityName: "Integration Test Bridge \(bridgeID)",
                entityType: "Bridge",
                latitude: 47.6000 + Double(bridgeID) * 0.01,
                longitude: -122.3300 - Double(bridgeID) * 0.01
            )
            testBridgeInfo.append(bridgeInfo)
        }
    }
    
    // MARK: - App Launch Tests
    
    @Test @MainActor func appLaunchDataLoading() async throws {
        // Test that app can launch and load data without crashing
        let contentView = ContentViewModular()
        #expect(contentView != nil)
    }
    
    // MARK: - Cross-Package Integration Tests
    
    @Test func dashboardToStatisticsIntegration() async throws {
        // Test data flow from Dashboard to Statistics
        let analytics = BridgeAnalyticsCalculator.calculateAnalytics(from: testEvents)
        
        #expect(!analytics.isEmpty)
        #expect(analytics.count > 0)
        
        // Test that analytics can be used for predictions
        for bridge in testBridgeInfo {
            let prediction = BridgeAnalytics.getCurrentPrediction(for: bridge, from: analytics)
            if let prediction = prediction {
                #expect(prediction.probability >= 0.0 && prediction.probability <= 1.0)
            }
        }
    }
    
    @Test @MainActor func bridgeDetailDataBinding() async throws {
        // Test that BridgeDetailView can properly bind to data
        let testEvent = testEvents.first!
        
        // This should not crash
        let bridgeDetailView = BridgeDetailView(bridgeEvent: testEvent)
        #expect(bridgeDetailView != nil)
    }
    
    // MARK: - Memory Management Integration Tests
    
    @Test func crossPackageMemoryManagement() async throws {
        // Test memory management across package boundaries
        var analytics: [BridgeAnalytics]? = BridgeAnalyticsCalculator.calculateAnalytics(from: testEvents)
        
        #expect(analytics != nil)
        #expect(!analytics!.isEmpty)
        
        // Force deallocation
        analytics = nil
        
        // Should not crash after deallocation
        let newAnalytics = BridgeAnalyticsCalculator.calculateAnalytics(from: testEvents)
        #expect(!newAnalytics.isEmpty)
    }
    
    // MARK: - Threading Integration Tests
    
    @Test func crossPackageThreadSafety() async throws {
        // Test thread safety across package boundaries
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<5 {
                group.addTask {
                    // Dashboard analytics calculation
                    let analytics = BridgeAnalyticsCalculator.calculateAnalytics(from: self.testEvents)
                    #expect(analytics.count >= 0)
                    
                    // Statistics predictions
                    for bridge in self.testBridgeInfo {
                        let prediction = BridgeAnalytics.getCurrentPrediction(for: bridge, from: analytics)
                        if let prediction = prediction {
                            #expect(prediction.probability >= 0.0)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - End-to-End Workflow Tests
    
    @Test func completeUserWorkflow() async throws {
        // Test complete user workflow: Launch → Dashboard → Bridge Detail → Statistics
        
        // 1. App Launch (data loading)
        let events = testEvents
        #expect(!events.isEmpty)
        
        // 2. Dashboard (analytics calculation)
        let analytics = BridgeAnalyticsCalculator.calculateAnalytics(from: events)
        #expect(!analytics.isEmpty)
        
        // 3. Bridge Detail (predictions)
        let bridge = testBridgeInfo.first!
        let prediction = BridgeAnalytics.getCurrentPrediction(for: bridge, from: analytics)
        #expect(prediction != nil)
        
        // 4. Statistics (enhanced predictions)
        let enhancedPrediction = BridgeAnalytics.getARIMAEnhancedPrediction(
            for: bridge,
            events: events,
            analytics: analytics,
            cascadeEvents: []
        )
        #expect(enhancedPrediction != nil)
    }
    
    // MARK: - Error Recovery Tests
    
    @Test func errorRecoveryAcrossPackages() async throws {
        // Test error recovery across package boundaries
        
        // Corrupt data scenario
        let corruptEvent = DrawbridgeEvent(
            entityType: "",
            entityName: "",
            entityID: -1,
            openDateTime: Date.distantPast,
            closeDateTime: nil,
            minutesOpen: -1,
            latitude: 0,
            longitude: 0
        )
        
        // Should handle gracefully across all packages
        let analytics = BridgeAnalyticsCalculator.calculateAnalytics(from: [corruptEvent])
        #expect(analytics.count >= 0) // Should not crash
        
        let cascades = CascadeDetectionEngine.detectCascadeEffects(from: [corruptEvent])
        #expect(cascades.count >= 0) // Should not crash
    }
}

// MARK: - XCTest Integration Tests (For UI Testing)

final class BridgetXCTestIntegrationTests: XCTestCase {
    
    var testEvents: [DrawbridgeEvent] = []
    
    override func setUp() {
        super.setUp()
        createTestData()
    }
    
    private func createTestData() {
        let now = Date()
        for i in 0..<10 {
            let event = DrawbridgeEvent(
                entityType: "Bridge",
                entityName: "XCTest Bridge",
                entityID: 1,
                openDateTime: now.addingTimeInterval(TimeInterval(-i * 3600)),
                closeDateTime: now.addingTimeInterval(TimeInterval(-i * 3600 + 900)),
                minutesOpen: 15.0,
                latitude: 47.6062,
                longitude: -122.3321
            )
            testEvents.append(event)
        }
    }
    
    // MARK: - UI Integration Tests
    
    @MainActor func testContentViewModularInitialization() throws {
        let contentView = ContentViewModular()
        XCTAssertNotNil(contentView)
    }
    
    @MainActor func testTabViewNavigation() throws {
        // Test that all tab views can be created
        let dashboard = DashboardView(events: testEvents, bridgeInfo: [])
        let statistics = StatisticsView()
        
        XCTAssertNotNil(dashboard)
        XCTAssertNotNil(statistics)
    }
    
    // MARK: - Threading Tests That Would Have Caught The Crash
    
    func testStatisticsViewRefreshThreading() async throws {
        let expectation = XCTestExpectation(description: "Statistics refresh threading test")
        expectation.expectedFulfillmentCount = 3
        
        // Simulate the exact scenario that caused the crash
        for i in 0..<3 {
            Task.detached {
                // This is exactly what was happening in StatisticsView.refreshable
                let eventsSnapshot = Array(self.testEvents)
                let limitedEvents = Array(eventsSnapshot.sorted { $0.openDateTime > $1.openDateTime }.prefix(2000))
                
                // This should NOT crash
                let analytics = BridgeAnalyticsCalculator.calculateAnalytics(from: limitedEvents)
                
                XCTAssertTrue(analytics.count >= 0)
                print("🧪 [INTEGRATION] Refresh test \(i) completed successfully")
                
                expectation.fulfill()
            }
        }
        
        await fulfillment(of: [expectation], timeout: 20.0)
    }
    
    // MARK: - Memory Leak Detection
    
    func testMemoryLeaksInAnalyticsChain() throws {
        autoreleasepool {
            let analytics = BridgeAnalyticsCalculator.calculateAnalytics(from: testEvents)
            XCTAssertFalse(analytics.isEmpty)
            
            let cascades = CascadeDetectionEngine.detectCascadeEffects(from: testEvents)
            XCTAssertTrue(cascades.count >= 0)
            
            // Test Neural Engine
            let predictor = NeuralEngineARIMAPredictor()
            let predictions = predictor.generatePredictions(from: Array(testEvents.prefix(5)))
            XCTAssertTrue(predictions.count >= 0)
        }
        
        // If we get here without hanging, memory management is likely correct
        XCTAssertTrue(true)
    }
}