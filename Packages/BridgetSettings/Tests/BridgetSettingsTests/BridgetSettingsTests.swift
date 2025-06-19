import XCTest
import SwiftUI
@testable import BridgetSettings

final class BridgetSettingsTests: XCTestCase {
    func testSettingsViewCreation() throws {
        let settingsView = SettingsView()
        XCTAssertNotNil(settingsView)
    }
}