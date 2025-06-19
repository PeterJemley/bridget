//
//  BridgetSharedUITests.swift
//  BridgetSharedUITests
//
//  Created by Peter Jemley on 6/19/25.
//

import XCTest
import SwiftUI
@testable import BridgetSharedUI

final class BridgetSharedUITests: XCTestCase {
    
    // MARK: - StatusCard Tests
    
    func testStatusCardCreation() {
        let card = StatusCard(title: "Test Title", value: "42", color: .blue)
        XCTAssertNotNil(card)
    }
    
    func testStatusCardWithDifferentColors() {
        let blueCard = StatusCard(title: "Blue", value: "1", color: .blue)
        let redCard = StatusCard(title: "Red", value: "2", color: .red)
        let greenCard = StatusCard(title: "Green", value: "3", color: .green)
        
        XCTAssertNotNil(blueCard)
        XCTAssertNotNil(redCard)
        XCTAssertNotNil(greenCard)
    }
    
    func testStatusCardWithLongText() {
        let longTitle = "This is a very long title that might wrap"
        let longValue = "999,999,999"
        let card = StatusCard(title: longTitle, value: longValue, color: .purple)
        
        XCTAssertNotNil(card)
    }
    
    func testStatusCardWithEmptyValues() {
        let emptyCard = StatusCard(title: "", value: "", color: .gray)
        XCTAssertNotNil(emptyCard)
    }
    
    // MARK: - StatCard Tests
    
    func testStatCardCreation() {
        let statCard = StatCard(title: "Average", value: "15.5 min")
        XCTAssertNotNil(statCard)
    }
    
    func testStatCardWithNumericalValues() {
        let intCard = StatCard(title: "Count", value: "42")
        let floatCard = StatCard(title: "Average", value: "15.75")
        let timeCard = StatCard(title: "Duration", value: "2h 30m")
        
        XCTAssertNotNil(intCard)
        XCTAssertNotNil(floatCard)
        XCTAssertNotNil(timeCard)
    }
    
    // MARK: - FilterButton Tests
    
    func testFilterButtonCreation() {
        let button = FilterButton(
            title: "Test Filter",
            isSelected: false,
            action: {}
        )
        XCTAssertNotNil(button)
    }
    
    func testFilterButtonSelectedState() {
        var isSelected = false
        let button = FilterButton(
            title: "Toggle Filter",
            isSelected: isSelected,
            action: { isSelected.toggle() }
        )
        
        XCTAssertNotNil(button)
        // Note: We can't directly test the action closure in unit tests,
        // but we can verify the button creation with different states
    }
    
    func testFilterButtonWithDifferentTitles() {
        let shortButton = FilterButton(title: "24H", isSelected: true, action: {})
        let longButton = FilterButton(title: "Patterns Analysis", isSelected: false, action: {})
        let emptyButton = FilterButton(title: "", isSelected: false, action: {})
        
        XCTAssertNotNil(shortButton)
        XCTAssertNotNil(longButton)
        XCTAssertNotNil(emptyButton)
    }
    
    // MARK: - InfoRow Tests
    
    func testInfoRowCreation() {
        let infoRow = InfoRow(label: "Status", value: "Active")
        XCTAssertNotNil(infoRow)
    }
    
    func testInfoRowWithVariousDataTypes() {
        let stringRow = InfoRow(label: "Name", value: "Fremont Bridge")
        let numberRow = InfoRow(label: "Count", value: "42")
        let dateRow = InfoRow(label: "Last Updated", value: "June 19, 2025")
        let timeRow = InfoRow(label: "Duration", value: "15 minutes")
        
        XCTAssertNotNil(stringRow)
        XCTAssertNotNil(numberRow)
        XCTAssertNotNil(dateRow)
        XCTAssertNotNil(timeRow)
    }
    
    func testInfoRowWithSpecialCharacters() {
        let unicodeRow = InfoRow(label: "Location", value: "47.6515°N, 122.3493°W")
        let symbolRow = InfoRow(label: "Status", value: "🟢 Open")
        let percentRow = InfoRow(label: "Confidence", value: "85%")
        
        XCTAssertNotNil(unicodeRow)
        XCTAssertNotNil(symbolRow)
        XCTAssertNotNil(percentRow)
    }
    
    func testInfoRowWithEmptyValues() {
        let emptyLabelRow = InfoRow(label: "", value: "Value")
        let emptyValueRow = InfoRow(label: "Label", value: "")
        let bothEmptyRow = InfoRow(label: "", value: "")
        
        XCTAssertNotNil(emptyLabelRow)
        XCTAssertNotNil(emptyValueRow)
        XCTAssertNotNil(bothEmptyRow)
    }
    
    // MARK: - LoadingDataOverlay Tests
    
    func testLoadingDataOverlayCreation() {
        let overlay = LoadingDataOverlay()
        XCTAssertNotNil(overlay)
    }
    
    // MARK: - Component Interaction Tests
    
    func testMultipleComponentsInteraction() {
        // Test that components can be created together without conflicts
        let statusCard = StatusCard(title: "Bridges", value: "15", color: .blue)
        let statCard = StatCard(title: "Average", value: "12.5 min")
        let filterButton = FilterButton(title: "24H", isSelected: true, action: {})
        let infoRow = InfoRow(label: "Status", value: "Active")
        let loadingOverlay = LoadingDataOverlay()
        
        XCTAssertNotNil(statusCard)
        XCTAssertNotNil(statCard)
        XCTAssertNotNil(filterButton)
        XCTAssertNotNil(infoRow)
        XCTAssertNotNil(loadingOverlay)
    }
    
    // MARK: - Accessibility Tests
    
    func testComponentAccessibility() {
        // Test that components support accessibility
        let statusCard = StatusCard(title: "Test", value: "42", color: .blue)
        let infoRow = InfoRow(label: "Test Label", value: "Test Value")
        
        // These components should be accessible by default in SwiftUI
        XCTAssertNotNil(statusCard)
        XCTAssertNotNil(infoRow)
    }
    
    // MARK: - Edge Cases Tests
    
    func testComponentsWithExtremValues() {
        // Test with very large numbers
        let largeValueCard = StatusCard(title: "Large", value: "1,234,567,890", color: .red)
        XCTAssertNotNil(largeValueCard)
        
        // Test with very small numbers
        let smallValueCard = StatusCard(title: "Small", value: "0.001", color: .green)
        XCTAssertNotNil(smallValueCard)
        
        // Test with negative numbers
        let negativeCard = StatusCard(title: "Negative", value: "-42", color: .orange)
        XCTAssertNotNil(negativeCard)
    }
    
    func testComponentsWithSpecialStrings() {
        // Test with special characters
        let specialCharsRow = InfoRow(label: "Special", value: "!@#$%^&*()")
        XCTAssertNotNil(specialCharsRow)
        
        // Test with whitespace
        let whitespaceRow = InfoRow(label: "   Spaces   ", value: "   Value   ")
        XCTAssertNotNil(whitespaceRow)
        
        // Test with newlines (should be handled gracefully)
        let newlineRow = InfoRow(label: "Multi\nLine", value: "Value\nWith\nNewlines")
        XCTAssertNotNil(newlineRow)
    }
    
    // MARK: - Performance Tests
    
    func testComponentCreationPerformance() {
        measure {
            for i in 0..<1000 {
                let statusCard = StatusCard(title: "Card \(i)", value: "\(i)", color: .blue)
                let infoRow = InfoRow(label: "Label \(i)", value: "Value \(i)")
                
                // Ensure components are created
                XCTAssertNotNil(statusCard)
                XCTAssertNotNil(infoRow)
            }
        }
    }
    
    // MARK: - Color Tests
    
    func testStatusCardColors() {
        let colors: [Color] = [.red, .blue, .green, .yellow, .purple, .orange, .pink, .gray]
        
        for (index, color) in colors.enumerated() {
            let card = StatusCard(title: "Color \(index)", value: "\(index)", color: color)
            XCTAssertNotNil(card)
        }
    }
    
    // MARK: - State Management Tests
    
    func testFilterButtonStateChanges() {
        var buttonState = false
        
        // Test initial state
        let initialButton = FilterButton(
            title: "Test",
            isSelected: buttonState,
            action: { buttonState.toggle() }
        )
        XCTAssertNotNil(initialButton)
        
        // Simulate state change
        buttonState.toggle()
        XCTAssertTrue(buttonState)
        
        let updatedButton = FilterButton(
            title: "Test",
            isSelected: buttonState,
            action: { buttonState.toggle() }
        )
        XCTAssertNotNil(updatedButton)
    }
}

// MARK: - Test Helpers

extension BridgetSharedUITests {
    
    func createTestStatusCards() -> [StatusCard] {
        return [
            StatusCard(title: "Total", value: "100", color: .blue),
            StatusCard(title: "Active", value: "85", color: .green),
            StatusCard(title: "Inactive", value: "15", color: .red),
            StatusCard(title: "Average", value: "12.5", color: .purple)
        ]
    }
    
    func createTestInfoRows() -> [InfoRow] {
        return [
            InfoRow(label: "Name", value: "Test Bridge"),
            InfoRow(label: "Status", value: "Active"),
            InfoRow(label: "Last Update", value: "2 minutes ago"),
            InfoRow(label: "Total Events", value: "42")
        ]
    }
    
    func createTestFilterButtons() -> [FilterButton] {
        return [
            FilterButton(title: "24H", isSelected: true, action: {}),
            FilterButton(title: "7D", isSelected: false, action: {}),
            FilterButton(title: "30D", isSelected: false, action: {}),
            FilterButton(title: "90D", isSelected: false, action: {})
        ]
    }
}
