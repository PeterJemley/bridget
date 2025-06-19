import XCTest
@testable import BridgetCore

final class BridgetCoreTests: XCTestCase {
    func testDrawbridgeEventCreation() throws {
        let event = DrawbridgeEvent(
            entityType: "Bridge",
            entityName: "Test Bridge",
            entityID: 1,
            openDateTime: Date(),
            closeDateTime: nil,
            minutesOpen: 15.0,
            latitude: 47.6062,
            longitude: -122.3321
        )
        
        XCTAssertEqual(event.entityName, "Test Bridge")
        XCTAssertTrue(event.isCurrentlyOpen)
        XCTAssertEqual(event.minutesOpen, 15.0)
    }
}