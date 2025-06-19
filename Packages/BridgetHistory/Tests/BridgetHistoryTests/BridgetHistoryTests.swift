import XCTest
import SwiftUI
@testable import BridgetHistory

final class BridgetHistoryTests: XCTestCase {
    func testHistoryViewCreation() throws {
        let historyView = HistoryView(events: [])
        XCTAssertNotNil(historyView)
    }
}