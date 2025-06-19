import XCTest
import SwiftUI
@testable import BridgetStatistics

final class BridgetStatisticsTests: XCTestCase {
    func testStatisticsViewCreation() throws {
        let statisticsView = StatisticsView(events: [], bridgeInfo: [])
        XCTAssertNotNil(statisticsView)
    }
}