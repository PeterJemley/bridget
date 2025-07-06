//
//  BridgetRoutingTests.swift
//  BridgetRoutingTests
//
//  Created by Peter Jemley on 7/6/25.
//

import XCTest
@testable import BridgetRouting
@testable import BridgetCore

final class BridgetRoutingTests: XCTestCase {
    
    func testRoutingViewInitialization() {
        let view = RoutingView()
        XCTAssertNotNil(view)
    }
    
    func testRouteDetailsViewInitialization() {
        let routingService = TrafficAwareRoutingService()
        let view = RouteDetailsView(routingService: routingService)
        XCTAssertNotNil(view)
    }
    
    func testCoordinateLookup() {
        let view = RoutingView()
        
        // Test UW coordinates
        let uwCoord = view.getCoordinatesForLocation("University of Washington")
        XCTAssertEqual(uwCoord.latitude, 47.6553, accuracy: 0.0001)
        XCTAssertEqual(uwCoord.longitude, -122.3035, accuracy: 0.0001)
        
        // Test Space Needle coordinates
        let spaceNeedleCoord = view.getCoordinatesForLocation("Space Needle")
        XCTAssertEqual(spaceNeedleCoord.latitude, 47.6205, accuracy: 0.0001)
        XCTAssertEqual(spaceNeedleCoord.longitude, -122.3493, accuracy: 0.0001)
    }
    
    static var allTests = [
        ("testRoutingViewInitialization", testRoutingViewInitialization),
        ("testRouteDetailsViewInitialization", testRouteDetailsViewInitialization),
        ("testCoordinateLookup", testCoordinateLookup)
    ]
} 