import XCTest
import SwiftUI
@testable import BridgetBridgesList

final class BridgetBridgesListTests: XCTestCase {
    func testBridgesListViewCreation() throws {
        let bridgesListView = BridgesListView(events: [], bridgeInfo: [])
        XCTAssertNotNil(bridgesListView)
    }
}