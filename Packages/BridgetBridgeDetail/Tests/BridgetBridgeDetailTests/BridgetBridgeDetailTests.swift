import XCTest
import SwiftUI
@testable import BridgetBridgeDetail

final class BridgetBridgeDetailTests: XCTestCase {
    func testBridgeDetailViewCreation() throws {
        let event = BridgetCore.DrawbridgeEvent(
            entityType: "Bridge",
            entityName: "Test Bridge",
            entityID: 1,
            openDateTime: Date(),
            closeDateTime: nil,
            minutesOpen: 15.0,
            latitude: 47.6062,
            longitude: -122.3321
        )
        
        let detailView = BridgeDetailView(bridgeEvent: event)
        XCTAssertNotNil(detailView)
    }
}