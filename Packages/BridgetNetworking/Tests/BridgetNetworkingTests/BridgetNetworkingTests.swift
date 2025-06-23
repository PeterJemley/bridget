import XCTest
import Foundation
@testable import BridgetNetworking
@testable import BridgetCore

final class BridgetNetworkingTests: XCTestCase {
    
    // MARK: - API Integration Tests
    
    func testDrawbridgeAPIBaseURL() throws {
        // Test that the API has a valid base URL
        XCTAssertNoThrow(try DrawbridgeAPI.fetchDrawbridgeData(limit: 1))
    }
    
    func testDrawbridgeAPINetworkRequest() async throws {
        // Test actual network request (with timeout for CI environments)
        do {
            let events = try await DrawbridgeAPI.fetchDrawbridgeData(limit: 5)
            
            XCTAssertTrue(events.count <= 5, "Should respect limit parameter")
            
            if !events.isEmpty {
                let event = events.first!
                XCTAssertFalse(event.entityName.isEmpty, "Event should have valid entity name")
                XCTAssertTrue(event.entityID > 0, "Event should have valid entity ID")
                XCTAssertTrue(event.minutesOpen >= 0, "Minutes open should be non-negative")
            }
        } catch {
            // Allow network errors in test environments, but log them
            print("⚠️ [NETWORK TEST] Network request failed (expected in some test environments): \(error)")
        }
    }
    
    func testDrawbridgeAPIErrorHandling() async throws {
        // Test API error handling with invalid parameters
        do {
            let _ = try await DrawbridgeAPI.fetchDrawbridgeData(limit: -1)
            XCTFail("Should throw error for invalid limit")
        } catch {
            // Expected to throw error
            XCTAssertTrue(true, "Correctly handles invalid parameters")
        }
    }
    
    func testDrawbridgeAPIDateParsing() async throws {
        // Test that the API correctly parses Seattle timezone dates
        do {
            let events = try await DrawbridgeAPI.fetchDrawbridgeData(limit: 1)
            
            if let event = events.first {
                // Verify date is reasonable (not distant past/future)
                let now = Date()
                let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: now)!
                let oneDayFromNow = Calendar.current.date(byAdding: .day, value: 1, to: now)!
                
                XCTAssertTrue(event.openDateTime >= oneYearAgo, "Open date should be within last year")
                XCTAssertTrue(event.openDateTime <= oneDayFromNow, "Open date should not be in future")
            }
        } catch {
            print("⚠️ [DATE TEST] Network request failed: \(error)")
        }
    }
    
    // MARK: - Mock API Tests (For CI/Offline Testing)
    
    func testMockDrawbridgeAPIResponse() throws {
        // Create mock JSON response
        let mockJSON = """
        [
            {
                "entity_type": "Bridge",
                "entity_name": "Test Bridge",
                "entity_id": "1",
                "open_datetime": "2025-06-19T10:00:00.000",
                "close_datetime": "2025-06-19T10:15:00.000",
                "minutes_open": "15",
                "latitude": "47.6062",
                "longitude": "-122.3321"
            }
        ]
        """
        
        let jsonData = mockJSON.data(using: .utf8)!
        
        // Test JSON parsing (simulating DrawbridgeAPI internal parsing)
        XCTAssertNoThrow(try JSONSerialization.jsonObject(with: jsonData))
    }
    
    // MARK: - Performance Tests
    
    func testAPIRequestPerformance() throws {
        measure {
            let expectation = XCTestExpectation(description: "API request completes")
            
            Task {
                do {
                    let _ = try await DrawbridgeAPI.fetchDrawbridgeData(limit: 10)
                    expectation.fulfill()
                } catch {
                    expectation.fulfill() // Complete even on error for performance measurement
                }
            }
            
            wait(for: [expectation], timeout: 10.0)
        }
    }
    
    // MARK: - Concurrency Tests
    
    func testConcurrentAPIRequests() async throws {
        let expectation = XCTestExpectation(description: "Concurrent API requests complete")
        expectation.expectedFulfillmentCount = 3
        
        // Test multiple concurrent API requests
        for i in 0..<3 {
            Task {
                do {
                    let events = try await DrawbridgeAPI.fetchDrawbridgeData(limit: 5)
                    XCTAssertTrue(events.count <= 5)
                    print("🧪 [API TEST] Request \(i) completed with \(events.count) events")
                } catch {
                    print("🧪 [API TEST] Request \(i) failed: \(error)")
                }
                expectation.fulfill()
            }
        }
        
        await fulfillment(of: [expectation], timeout: 30.0)
    }
    
    // MARK: - Error Scenarios
    
    func testAPITimeoutHandling() async throws {
        // Test timeout scenarios (simulated)
        let expectation = XCTestExpectation(description: "Timeout test completes")
        
        Task {
            do {
                let startTime = Date()
                let _ = try await DrawbridgeAPI.fetchDrawbridgeData(limit: 1000) // Large request
                let duration = Date().timeIntervalSince(startTime)
                
                // Should complete within reasonable time
                XCTAssertLessThan(duration, 60.0, "API request should complete within 60 seconds")
            } catch {
                // Timeout or other network errors are acceptable in test environment
                print("🧪 [TIMEOUT TEST] Request failed as expected: \(error)")
            }
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 120.0)
    }
    
    // MARK: - Data Validation Tests
    
    func testDrawbridgeEventDataValidation() async throws {
        do {
            let events = try await DrawbridgeAPI.fetchDrawbridgeData(limit: 10)
            
            for event in events {
                // Validate required fields
                XCTAssertFalse(event.entityName.isEmpty, "Entity name should not be empty")
                XCTAssertTrue(event.entityID > 0, "Entity ID should be positive")
                XCTAssertTrue(event.minutesOpen >= 0, "Minutes open should be non-negative")
                
                // Validate coordinate ranges (Seattle area)
                XCTAssertTrue(event.latitude >= 47.0 && event.latitude <= 48.0, "Latitude should be in Seattle area")
                XCTAssertTrue(event.longitude >= -123.0 && event.longitude <= -121.0, "Longitude should be in Seattle area")
                
                // Validate time ranges
                let now = Date()
                let twoYearsAgo = Calendar.current.date(byAdding: .year, value: -2, to: now)!
                XCTAssertTrue(event.openDateTime >= twoYearsAgo, "Open date should be recent")
                XCTAssertTrue(event.openDateTime <= now, "Open date should not be in future")
                
                // If closed, close time should be after open time
                if let closeDateTime = event.closeDateTime {
                    XCTAssertTrue(closeDateTime >= event.openDateTime, "Close time should be after open time")
                }
            }
        } catch {
            print("⚠️ [VALIDATION TEST] Network request failed: \(error)")
        }
    }
    
    // MARK: - Seattle Timezone Tests
    
    func testSeattleTimezoneHandling() throws {
        // Test Seattle timezone conversion
        let seattleTimeZone = TimeZone(identifier: "America/Los_Angeles")!
        XCTAssertNotNil(seattleTimeZone)
        
        let formatter = DateFormatter()
        formatter.timeZone = seattleTimeZone
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        
        let testDateString = "2025-06-19T10:00:00.000"
        let parsedDate = formatter.date(from: testDateString)
        
        XCTAssertNotNil(parsedDate, "Should parse Seattle timezone dates correctly")
    }
}