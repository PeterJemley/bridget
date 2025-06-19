import XCTest
import SwiftUI
@testable import BridgetDashboard

final class BridgetDashboardTests: XCTestCase {
    func testDashboardViewCreation() throws {
        let dashboard = DashboardView(events: [], bridgeInfo: [])
        XCTAssertNotNil(dashboard)
    }
}