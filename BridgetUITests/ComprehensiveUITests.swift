//
//  ComprehensiveUITests.swift
//  BridgetUITests
//
//  Created by Peter Jemley on 6/19/25.
//

import XCTest
import SwiftUI
import SwiftData
import BridgetCore
import BridgetBridgeDetail
import BridgetDashboard
import BridgetStatistics

@MainActor
final class ComprehensiveUITests: XCTestCase {
    
    var app: XCUIApplication!
    var modelContext: ModelContext!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory SwiftData store for testing
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: DrawbridgeEvent.self, CascadeEvent.self, BridgeAnalytics.self, configurations: config)
        modelContext = ModelContext(container)
        
        // Insert test data
        insertTestData()
        
        // Launch app
        app = XCUIApplication()
        app.launchArguments = ["UI-Testing"]
        app.launch()
    }
    
    override func tearDown() async throws {
        app = nil
        modelContext = nil
        try await super.tearDown()
    }
    
    // MARK: - Test Data Setup
    
    private func insertTestData() {
        let testEvents = createTestEvents()
        
        for event in testEvents {
            modelContext.insert(event)
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save test data: \(error)")
        }
    }
    
    private func createTestEvents() -> [DrawbridgeEvent] {
        let calendar = Calendar.current
        let now = Date()
        
        return [
            // Fremont Bridge events
            DrawbridgeEvent(
                entityType: "Bridge",
                entityName: "Fremont Bridge",
                entityID: 1,
                openDateTime: calendar.date(byAdding: .hour, value: -2, to: now) ?? now,
                closeDateTime: calendar.date(byAdding: .minute, value: 20, to: now),
                minutesOpen: 20.0,
                latitude: 47.6488,
                longitude: -122.3497
            ),
            DrawbridgeEvent(
                entityType: "Bridge",
                entityName: "Fremont Bridge",
                entityID: 1,
                openDateTime: calendar.date(byAdding: .day, value: -1, to: now) ?? now,
                closeDateTime: calendar.date(byAdding: .minute, value: 35, to: now),
                minutesOpen: 35.0,
                latitude: 47.6488,
                longitude: -122.3497
            ),
            // Ballard Bridge events
            DrawbridgeEvent(
                entityType: "Bridge",
                entityName: "Ballard Bridge",
                entityID: 2,
                openDateTime: calendar.date(byAdding: .hour, value: -1, to: now) ?? now,
                closeDateTime: calendar.date(byAdding: .minute, value: 15, to: now),
                minutesOpen: 15.0,
                latitude: 47.6688,
                longitude: -122.3847
            ),
            // University Bridge events
            DrawbridgeEvent(
                entityType: "Bridge",
                entityName: "University Bridge",
                entityID: 3,
                openDateTime: calendar.date(byAdding: .day, value: -2, to: now) ?? now,
                closeDateTime: calendar.date(byAdding: .minute, value: 25, to: now),
                minutesOpen: 25.0,
                latitude: 47.6188,
                longitude: -122.3147
            )
        ]
    }
    
    // MARK: - Dashboard Tests
    
    func testDashboardLoadsCorrectly() {
        // Given: App is launched with test data
        
        // When: Dashboard is displayed
        let dashboardTab = app.tabBars.buttons["Dashboard"]
        dashboardTab.tap()
        
        // Then: Dashboard should show bridge information
        XCTAssertTrue(app.staticTexts["Dashboard"].exists)
        XCTAssertTrue(app.staticTexts["Fremont Bridge"].exists)
        XCTAssertTrue(app.staticTexts["Ballard Bridge"].exists)
        XCTAssertTrue(app.staticTexts["University Bridge"].exists)
    }
    
    func testDashboardShowsRecentActivity() {
        // Given: Dashboard is displayed
        let dashboardTab = app.tabBars.buttons["Dashboard"]
        dashboardTab.tap()
        
        // When: Looking for recent activity
        let recentActivitySection = app.staticTexts["Recent Activity"]
        
        // Then: Recent activity should be visible
        XCTAssertTrue(recentActivitySection.exists)
        
        // And: Should show bridge events
        XCTAssertTrue(app.staticTexts["Fremont Bridge"].exists)
        XCTAssertTrue(app.staticTexts["Ballard Bridge"].exists)
    }
    
    func testDashboardShowsStatusOverview() {
        // Given: Dashboard is displayed
        let dashboardTab = app.tabBars.buttons["Dashboard"]
        dashboardTab.tap()
        
        // When: Looking for status overview
        let statusOverviewSection = app.staticTexts["Status Overview"]
        
        // Then: Status overview should be visible
        XCTAssertTrue(statusOverviewSection.exists)
        
        // And: Should show bridge status cards
        let bridgeCards = app.otherElements.matching(identifier: "StatusCard")
        XCTAssertGreaterThan(bridgeCards.count, 0)
    }
    
    // MARK: - Bridge Detail Tests
    
    func testBridgeDetailNavigation() {
        // Given: Dashboard is displayed
        let dashboardTab = app.tabBars.buttons["Dashboard"]
        dashboardTab.tap()
        
        // When: Tapping on a bridge
        let fremontBridge = app.staticTexts["Fremont Bridge"]
        fremontBridge.tap()
        
        // Then: Bridge detail view should be displayed
        XCTAssertTrue(app.staticTexts["Fremont Bridge"].exists)
        XCTAssertTrue(app.staticTexts["Pattern Analysis"].exists)
    }
    
    func testBridgeDetailTimeFilter() {
        // Given: Bridge detail view is displayed
        let dashboardTab = app.tabBars.buttons["Dashboard"]
        dashboardTab.tap()
        
        let fremontBridge = app.staticTexts["Fremont Bridge"]
        fremontBridge.tap()
        
        // When: Changing time filter
        let timeFilterButton = app.buttons["24H"]
        timeFilterButton.tap()
        
        // Then: Time filter should change
        XCTAssertTrue(app.buttons["24H"].isSelected)
        
        // When: Changing to 7 days
        let sevenDaysButton = app.buttons["7D"]
        sevenDaysButton.tap()
        
        // Then: 7 days should be selected
        XCTAssertTrue(app.buttons["7D"].isSelected)
    }
    
    func testBridgeDetailAnalysisFilter() {
        // Given: Bridge detail view is displayed
        let dashboardTab = app.tabBars.buttons["Dashboard"]
        dashboardTab.tap()
        
        let fremontBridge = app.staticTexts["Fremont Bridge"]
        fremontBridge.tap()
        
        // When: Changing analysis type
        let cascadeButton = app.buttons["Cascade"]
        cascadeButton.tap()
        
        // Then: Cascade analysis should be selected
        XCTAssertTrue(app.buttons["Cascade"].isSelected)
        XCTAssertTrue(app.staticTexts["Connection Analysis"].exists)
        
        // When: Changing to predictions
        let predictionsButton = app.buttons["Predictions"]
        predictionsButton.tap()
        
        // Then: Predictions should be selected
        XCTAssertTrue(app.buttons["Predictions"].isSelected)
        XCTAssertTrue(app.staticTexts["Predictive Analysis"].exists)
    }
    
    func testBridgeDetailViewFilter() {
        // Given: Bridge detail view is displayed
        let dashboardTab = app.tabBars.buttons["Dashboard"]
        dashboardTab.tap()
        
        let fremontBridge = app.staticTexts["Fremont Bridge"]
        fremontBridge.tap()
        
        // When: Changing view type
        let weeklyButton = app.buttons["Weekly"]
        weeklyButton.tap()
        
        // Then: Weekly view should be selected
        XCTAssertTrue(app.buttons["Weekly"].isSelected)
        
        // When: Changing to duration
        let durationButton = app.buttons["Duration"]
        durationButton.tap()
        
        // Then: Duration view should be selected
        XCTAssertTrue(app.buttons["Duration"].isSelected)
    }
    
    func testBridgeDetailShowsEventData() {
        // Given: Bridge detail view is displayed
        let dashboardTab = app.tabBars.buttons["Dashboard"]
        dashboardTab.tap()
        
        let fremontBridge = app.staticTexts["Fremont Bridge"]
        fremontBridge.tap()
        
        // Then: Should show event statistics
        XCTAssertTrue(app.staticTexts["Total Events"].exists)
        XCTAssertTrue(app.staticTexts["Average Duration"].exists)
        
        // And: Should show recent events
        let recentEvents = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'min'"))
        XCTAssertGreaterThan(recentEvents.count, 0)
    }
    
    // MARK: - Statistics Tests
    
    func testStatisticsViewLoads() {
        // Given: App is launched
        
        // When: Navigating to statistics
        let statisticsTab = app.tabBars.buttons["Statistics"]
        statisticsTab.tap()
        
        // Then: Statistics view should be displayed
        XCTAssertTrue(app.staticTexts["Statistics"].exists)
        XCTAssertTrue(app.staticTexts["Analytics & Predictions"].exists)
    }
    
    func testStatisticsShowsNeuralEngineStatus() {
        // Given: Statistics view is displayed
        let statisticsTab = app.tabBars.buttons["Statistics"]
        statisticsTab.tap()
        
        // When: Looking for neural engine status
        let neuralEngineStatus = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Neural Engine'"))
        
        // Then: Neural engine status should be visible
        XCTAssertGreaterThan(neuralEngineStatus.count, 0)
    }
    
    func testStatisticsShowsDatasetInfo() {
        // Given: Statistics view is displayed
        let statisticsTab = app.tabBars.buttons["Statistics"]
        statisticsTab.tap()
        
        // When: Looking for dataset information
        let datasetInfo = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Dataset'"))
        
        // Then: Dataset information should be visible
        XCTAssertGreaterThan(datasetInfo.count, 0)
    }
    
    func testStatisticsShowsCurrentPredictions() {
        // Given: Statistics view is displayed
        let statisticsTab = app.tabBars.buttons["Statistics"]
        statisticsTab.tap()
        
        // When: Looking for current predictions
        let currentPredictions = app.staticTexts["Current Predictions"]
        
        // Then: Current predictions section should be visible
        XCTAssertTrue(currentPredictions.exists)
    }
    
    func testStatisticsShowsCascadeAnalysis() {
        // Given: Statistics view is displayed
        let statisticsTab = app.tabBars.buttons["Statistics"]
        statisticsTab.tap()
        
        // When: Looking for cascade analysis
        let cascadeAnalysis = app.staticTexts["Bridge Connection Analysis"]
        
        // Then: Cascade analysis should be visible
        XCTAssertTrue(cascadeAnalysis.exists)
    }
    
    // MARK: - Navigation Tests
    
    func testTabBarNavigation() {
        // Given: App is launched
        
        // When: Navigating between tabs
        let dashboardTab = app.tabBars.buttons["Dashboard"]
        let statisticsTab = app.tabBars.buttons["Statistics"]
        let historyTab = app.tabBars.buttons["History"]
        let settingsTab = app.tabBars.buttons["Settings"]
        
        // Then: All tabs should be accessible
        XCTAssertTrue(dashboardTab.exists)
        XCTAssertTrue(statisticsTab.exists)
        XCTAssertTrue(historyTab.exists)
        XCTAssertTrue(settingsTab.exists)
        
        // When: Tapping each tab
        dashboardTab.tap()
        XCTAssertTrue(app.staticTexts["Dashboard"].exists)
        
        statisticsTab.tap()
        XCTAssertTrue(app.staticTexts["Statistics"].exists)
        
        historyTab.tap()
        XCTAssertTrue(app.staticTexts["Historical Analysis"].exists)
        
        settingsTab.tap()
        XCTAssertTrue(app.staticTexts["Settings"].exists)
    }
    
    func testBackNavigation() {
        // Given: Bridge detail view is displayed
        let dashboardTab = app.tabBars.buttons["Dashboard"]
        dashboardTab.tap()
        
        let fremontBridge = app.staticTexts["Fremont Bridge"]
        fremontBridge.tap()
        
        // When: Tapping back button
        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        backButton.tap()
        
        // Then: Should return to dashboard
        XCTAssertTrue(app.staticTexts["Dashboard"].exists)
    }
    
    // MARK: - Loading State Tests
    
    func testLoadingStates() {
        // Given: App is launched
        
        // When: Navigating to statistics (which may trigger analysis)
        let statisticsTab = app.tabBars.buttons["Statistics"]
        statisticsTab.tap()
        
        // Then: Should show loading indicators if needed
        let loadingIndicators = app.activityIndicators
        if loadingIndicators.count > 0 {
            // Wait for loading to complete
            let expectation = XCTestExpectation(description: "Loading complete")
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 6.0)
        }
        
        // Then: Content should be visible after loading
        XCTAssertTrue(app.staticTexts["Statistics"].exists)
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorStates() {
        // Given: App is launched with test data
        
        // When: Navigating to bridge detail
        let dashboardTab = app.tabBars.buttons["Dashboard"]
        dashboardTab.tap()
        
        let fremontBridge = app.staticTexts["Fremont Bridge"]
        fremontBridge.tap()
        
        // Then: Should handle any errors gracefully
        let errorMessages = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Error' OR label CONTAINS 'Failed'"))
        
        // If errors exist, they should have retry buttons
        if errorMessages.count > 0 {
            let retryButtons = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Retry'"))
            XCTAssertGreaterThan(retryButtons.count, 0)
        }
    }
    
    // MARK: - Accessibility Tests
    
    func testAccessibilityLabels() {
        // Given: App is launched
        
        // When: Navigating to dashboard
        let dashboardTab = app.tabBars.buttons["Dashboard"]
        dashboardTab.tap()
        
        // Then: Elements should have accessibility labels
        let bridgeElements = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Bridge'"))
        XCTAssertGreaterThan(bridgeElements.count, 0)
        
        for element in bridgeElements.allElements {
            XCTAssertFalse(element.label.isEmpty, "Bridge element should have accessibility label")
        }
    }
    
    func testAccessibilityTraits() {
        // Given: App is launched
        
        // When: Navigating to dashboard
        let dashboardTab = app.tabBars.buttons["Dashboard"]
        dashboardTab.tap()
        
        // Then: Interactive elements should have proper traits
        let buttons = app.buttons
        for button in buttons.allElements {
            XCTAssertTrue(button.isEnabled, "Button should be enabled")
        }
    }
    
    // MARK: - Performance Tests
    
    func testAppLaunchPerformance() {
        // Given: App is ready to launch
        
        // When: Measuring launch time
        measure(metrics: [XCTCPUMetric(), XCTMemoryMetric()]) {
            app.launch()
        }
    }
    
    func testNavigationPerformance() {
        // Given: App is launched
        app.launch()
        
        // When: Measuring navigation performance
        measure(metrics: [XCTCPUMetric()]) {
            let dashboardTab = app.tabBars.buttons["Dashboard"]
            dashboardTab.tap()
            
            let statisticsTab = app.tabBars.buttons["Statistics"]
            statisticsTab.tap()
            
            let historyTab = app.tabBars.buttons["History"]
            historyTab.tap()
            
            let settingsTab = app.tabBars.buttons["Settings"]
            settingsTab.tap()
        }
    }
    
    // MARK: - Data Persistence Tests
    
    func testDataPersistence() {
        // Given: App is launched with test data
        app.launch()
        
        // When: Navigating to dashboard
        let dashboardTab = app.tabBars.buttons["Dashboard"]
        dashboardTab.tap()
        
        // Then: Test data should be visible
        XCTAssertTrue(app.staticTexts["Fremont Bridge"].exists)
        XCTAssertTrue(app.staticTexts["Ballard Bridge"].exists)
        XCTAssertTrue(app.staticTexts["University Bridge"].exists)
        
        // When: Terminating and relaunching app
        app.terminate()
        app.launch()
        
        // Then: Data should persist
        dashboardTab.tap()
        XCTAssertTrue(app.staticTexts["Fremont Bridge"].exists)
        XCTAssertTrue(app.staticTexts["Ballard Bridge"].exists)
        XCTAssertTrue(app.staticTexts["University Bridge"].exists)
    }
    
    // MARK: - Edge Case Tests
    
    func testEmptyStateHandling() {
        // Given: App with no data
        app.terminate()
        
        // Clear test data and relaunch
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: DrawbridgeEvent.self, CascadeEvent.self, BridgeAnalytics.self, configurations: config)
        let emptyContext = ModelContext(container)
        
        app.launch()
        
        // When: Navigating to dashboard
        let dashboardTab = app.tabBars.buttons["Dashboard"]
        dashboardTab.tap()
        
        // Then: Should handle empty state gracefully
        let emptyStateMessages = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'No data' OR label CONTAINS 'Empty' OR label CONTAINS 'Loading'"))
        XCTAssertGreaterThan(emptyStateMessages.count, 0)
    }
    
    func testLargeDatasetHandling() {
        // Given: App with large dataset
        insertLargeTestDataset()
        
        // When: Navigating to statistics
        let statisticsTab = app.tabBars.buttons["Statistics"]
        statisticsTab.tap()
        
        // Then: Should handle large dataset without performance issues
        XCTAssertTrue(app.staticTexts["Statistics"].exists)
        
        // Wait for any background processing
        let expectation = XCTestExpectation(description: "Background processing")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 4.0)
        
        // Then: UI should remain responsive
        XCTAssertTrue(app.staticTexts["Statistics"].exists)
    }
    
    private func insertLargeTestDataset() {
        let largeEvents = createLargeTestDataset(count: 100)
        
        for event in largeEvents {
            modelContext.insert(event)
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save large test dataset: \(error)")
        }
    }
    
    private func createLargeTestDataset(count: Int) -> [DrawbridgeEvent] {
        let calendar = Calendar.current
        let now = Date()
        
        return (0..<count).map { index in
            let randomDaysAgo = Int.random(in: 0...30)
            let randomDuration = Double.random(in: 5...120)
            let bridgeNames = ["Fremont Bridge", "Ballard Bridge", "University Bridge", "Montlake Bridge"]
            let bridgeName = bridgeNames[index % bridgeNames.count]
            let bridgeID = (index % 4) + 1
            
            return DrawbridgeEvent(
                entityType: "Bridge",
                entityName: bridgeName,
                entityID: bridgeID,
                openDateTime: calendar.date(byAdding: .day, value: -randomDaysAgo, to: now) ?? now,
                closeDateTime: calendar.date(byAdding: .minute, value: Int(randomDuration), to: now),
                minutesOpen: randomDuration,
                latitude: 47.6062 + Double.random(in: -0.1...0.1),
                longitude: -122.3321 + Double.random(in: -0.1...0.1)
            )
        }
    }
} 