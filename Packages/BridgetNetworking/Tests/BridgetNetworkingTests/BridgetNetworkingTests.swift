import XCTest
@testable import BridgetNetworking

final class BridgetNetworkingTests: XCTestCase {
    func testAPIErrorDescriptions() throws {
        XCTAssertEqual(APIError.invalidURL.localizedDescription, "Invalid API URL")
        XCTAssertEqual(APIError.noData.localizedDescription, "No data received from API")
    }
}