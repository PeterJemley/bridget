import XCTest
import SwiftUI
@testable import BridgetSharedUI

final class BridgetSharedUITests: XCTestCase {
    func testStatusCardCreation() throws {
        let card = StatusCard(title: "Test", value: "42", color: .blue)
        XCTAssertNotNil(card)
    }
}