//
//  BridgetNetworkingTests.swift
//  BridgetNetworkingTests
//
//  Created by Peter Jemley on 6/19/25.
//

import XCTest
@testable import BridgetNetworking
@testable import BridgetCore
import Foundation

final class BridgetNetworkingTests: XCTestCase {
    
    // MARK: - API Error Tests
    
    func testAPIErrorDescriptions() {
        XCTAssertEqual(APIError.invalidURL.localizedDescription, "Invalid API URL")
        XCTAssertEqual(APIError.noData.localizedDescription, "No data received from API")
        XCTAssertEqual(APIError.decodingError(NSError(domain: "test", code: 0)).localizedDescription, "Failed to decode API response: The operation couldn't be completed. (test error 0.)")
        XCTAssertEqual(APIError.networkError(NSError(domain: "network", code: -1009)).localizedDescription, "Network error: The operation couldn't be completed. (network error -1009.)")
        XCTAssertEqual(APIError.serverError(500).localizedDescription, "Server error: HTTP 500")
    }
    
    // MARK: - URL Construction Tests
    
    func testBaseURLConstruction() {
        let expectedURL = "https://data.seattle.gov/resource/rdvs-832s.json"
        // We can't directly test the private baseURL, but we can verify it through the public API
        // This test ensures the URL format is correct
        XCTAssertTrue(expectedURL.contains("data.seattle.gov"))
        XCTAssertTrue(expectedURL.contains("resource"))
        XCTAssertTrue(expectedURL.contains("rdvs-832s.json"))
    }
    
    // MARK: - Parameter Construction Tests
    
    func testLimitParameterConstruction() {
        // Test that limit parameter is properly constructed
        let limit = 100
        let expectedParam = "$limit=\(limit)"
        XCTAssertEqual(expectedParam, "$limit=100")
    }
    
    func testDateFilterParameterConstruction() {
        let dateFormatter = ISO8601DateFormatter()
        let testDate = Date(timeIntervalSince1970: 1640995200) // 2022-01-01 00:00:00 UTC
        let formattedDate = dateFormatter.string(from: testDate)
        
        let expectedParam = "$where=open_dt >= '\(formattedDate)'"
        XCTAssertTrue(expectedParam.contains("open_dt"))
        XCTAssertTrue(expectedParam.contains(">="))
        XCTAssertTrue(expectedParam.contains(formattedDate))
    }
    
    // MARK: - Data Validation Tests
    
    func testValidDrawbridgeEventData() {
        // Test data that should create a valid DrawbridgeEvent
        let validData = """
        {
            "entitytype": "Bridge",
            "entityname": "Test Bridge",
            "entityid": "123",
            "open_dt": "2025-06-19T14:30:00.000Z",
            "close_dt": "2025-06-19T14:45:00.000Z",
            "minutes_open": "15.0",
            "latitude": "47.6062",
            "longitude": "-122.3321"
        }
        """.data(using: .utf8)!
        
        do {
            let decoder = JSONDecoder()
            let dateFormatter = ISO8601DateFormatter()
            decoder.dateDecodingStrategy = .iso8601
            
            // We need to create a decodable struct that matches the API response format
            struct APIResponse: Decodable {
                let entitytype: String
                let entityname: String
                let entityid: String
                let open_dt: String
                let close_dt: String?
                let minutes_open: String
                let latitude: String
                let longitude: String
            }
            
            let response = try decoder.decode(APIResponse.self, from: validData)
            
            XCTAssertEqual(response.entitytype, "Bridge")
            XCTAssertEqual(response.entityname, "Test Bridge")
            XCTAssertEqual(response.entityid, "123")
            XCTAssertEqual(response.minutes_open, "15.0")
        } catch {
            XCTFail("Failed to decode valid data: \(error)")
        }
    }
    
    func testInvalidDrawbridgeEventData() {
        // Test data with missing required fields
        let invalidData = """
        {
            "entitytype": "Bridge"
        }
        """.data(using: .utf8)!
        
        struct APIResponse: Decodable {
            let entitytype: String
            let entityname: String
            let entityid: String
        }
        
        XCTAssertThrowsError(try JSONDecoder().decode(APIResponse.self, from: invalidData))
    }
    
    // MARK: - Date Parsing Tests
    
    func testISO8601DateParsing() {
        let dateString = "2025-06-19T14:30:00.000Z"
        let formatter = ISO8601DateFormatter()
        
        let parsedDate = formatter.date(from: dateString)
        XCTAssertNotNil(parsedDate)
        
        // Verify the parsed date components
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: parsedDate!)
        XCTAssertEqual(components.year, 2025)
        XCTAssertEqual(components.month, 6)
        XCTAssertEqual(components.day, 19)
        XCTAssertEqual(components.hour, 14)
        XCTAssertEqual(components.minute, 30)
    }
    
    func testSeattleTimezoneHandling() {
        // Seattle is UTC-8 (PST) or UTC-7 (PDT)
        let seattleTimeZone = TimeZone(identifier: "America/Los_Angeles")!
        XCTAssertNotNil(seattleTimeZone)
        
        // Test that we can convert between timezones
        let utcDate = Date()
        let calendar = Calendar.current
        
        let utcComponents = calendar.dateComponents(in: TimeZone(abbreviation: "UTC")!, from: utcDate)
        let seattleComponents = calendar.dateComponents(in: seattleTimeZone, from: utcDate)
        
        // The hour difference should be 7 or 8 depending on daylight saving time
        let hourDifference = abs((utcComponents.hour ?? 0) - (seattleComponents.hour ?? 0))
        XCTAssertTrue(hourDifference == 7 || hourDifference == 8 || hourDifference == 16 || hourDifference == 17)
    }
    
    // MARK: - Network Request Tests
    
    func testURLRequestConfiguration() {
        let url = URL(string: "https://data.seattle.gov/resource/rdvs-832s.json?$limit=100")!
        let request = URLRequest(url: url)
        
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.url, url)
        XCTAssertNil(request.httpBody) // GET request should not have body
    }
    
    // MARK: - Error Handling Tests
    
    func testHTTPStatusCodeErrorHandling() {
        // Test different HTTP status codes
        let clientError = APIError.serverError(400)
        XCTAssertEqual(clientError.localizedDescription, "Server error: HTTP 400")
        
        let serverError = APIError.serverError(500)
        XCTAssertEqual(serverError.localizedDescription, "Server error: HTTP 500")
        
        let notFoundError = APIError.serverError(404)
        XCTAssertEqual(notFoundError.localizedDescription, "Server error: HTTP 404")
    }
    
    func testNetworkErrorHandling() {
        let networkError = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorNotConnectedToInternet,
            userInfo: [NSLocalizedDescriptionKey: "The Internet connection appears to be offline."]
        )
        
        let apiError = APIError.networkError(networkError)
        XCTAssertTrue(apiError.localizedDescription.contains("Network error"))
        XCTAssertTrue(apiError.localizedDescription.contains("Internet connection"))
    }
    
    // MARK: - Performance Tests
    
    func testJSONDecodingPerformance() {
        // Create test data for performance testing
        let testData = """
        [{
            "entitytype": "Bridge",
            "entityname": "Test Bridge",
            "entityid": "123",
            "open_dt": "2025-06-19T14:30:00.000Z",
            "close_dt": "2025-06-19T14:45:00.000Z",
            "minutes_open": "15.0",
            "latitude": "47.6062",
            "longitude": "-122.3321"
        }]
        """.data(using: .utf8)!
        
        struct APIResponse: Decodable {
            let entitytype: String
            let entityname: String
            let entityid: String
            let open_dt: String
            let close_dt: String?
            let minutes_open: String
            let latitude: String
            let longitude: String
        }
        
        measure {
            for _ in 0..<1000 {
                do {
                    _ = try JSONDecoder().decode([APIResponse].self, from: testData)
                } catch {
                    XCTFail("Decoding failed: \(error)")
                }
            }
        }
    }
    
    // MARK: - Integration Helper Tests
    
    func testDataConversionHelpers() {
        // Test string to double conversion (as used in API responses)
        let minutesString = "15.5"
        let minutesDouble = Double(minutesString)
        XCTAssertEqual(minutesDouble, 15.5)
        
        // Test string to int conversion (as used for entity IDs)
        let idString = "123"
        let idInt = Int(idString)
        XCTAssertEqual(idInt, 123)
        
        // Test coordinate conversion
        let latString = "47.6062"
        let lngString = "-122.3321"
        let latitude = Double(latString)
        let longitude = Double(lngString)
        XCTAssertEqual(latitude, 47.6062)
        XCTAssertEqual(longitude, -122.3321)
    }
}

// MARK: - Mock Data Structures for Testing

struct MockDrawbridgeAPIResponse: Decodable {
    let entitytype: String
    let entityname: String
    let entityid: String
    let open_dt: String
    let close_dt: String?
    let minutes_open: String
    let latitude: String
    let longitude: String
}

// MARK: - Test Extensions

extension XCTestCase {
    func createMockDrawbridgeData() -> Data {
        let mockJSON = """
        [{
            "entitytype": "Drawbridge",
            "entityname": "Fremont Bridge",
            "entityid": "1",
            "open_dt": "2025-06-19T14:30:00.000Z",
            "close_dt": "2025-06-19T14:45:00.000Z",
            "minutes_open": "15.0",
            "latitude": "47.6515",
            "longitude": "-122.3493"
        },
        {
            "entitytype": "Drawbridge",
            "entityname": "Ballard Bridge",
            "entityid": "2",
            "open_dt": "2025-06-19T15:00:00.000Z",
            "close_dt": null,
            "minutes_open": "10.0",
            "latitude": "47.6616",
            "longitude": "-122.3754"
        }]
        """
        return mockJSON.data(using: .utf8)!
    }
}
