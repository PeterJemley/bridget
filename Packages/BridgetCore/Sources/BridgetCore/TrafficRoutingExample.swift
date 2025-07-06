//
//  TrafficRoutingExample.swift
//  BridgetCore
//
//  Created by Peter Jemley on 6/19/25.
//

import Foundation
import CoreLocation
import MapKit

/// Example usage of TrafficAwareRoutingService for UW to Space Needle route
@MainActor
public class TrafficRoutingExample {
    private let routingService = TrafficAwareRoutingService()
    
    // Seattle landmarks
    private let uwSeattle = CLLocationCoordinate2D(latitude: 47.6553, longitude: -122.3035)
    private let spaceNeedle = CLLocationCoordinate2D(latitude: 47.6205, longitude: -122.3493)
    
    public init() {
        print("🗺️ [Example] Traffic routing example initialized")
    }
    
    /// Plans a route from UW to Space Needle with traffic awareness
    public func planUWToSpaceNeedleRoute() async {
        print("🗺️ [Example] Planning route: UW → Space Needle")
        
        await routingService.planRoute(
            from: uwSeattle,
            to: spaceNeedle,
            transportType: .automobile
        )
        
        // Start real-time updates
        await routingService.startRealTimeUpdates()
        
        // Print route analysis
        printRouteAnalysis()
    }
    
    @MainActor
    private func printRouteAnalysis() {
        guard let route = routingService.currentRoute else {
            print("❌ [Example] No route available")
            return
        }
        
        print("🗺️ [Example] Route Analysis:")
        print("   • Distance: \(String(format: "%.1f", route.distance/1000)) km")
        print("   • Travel Time: \(String(format: "%.0f", route.expectedTravelTime/60)) min")
        print("   • Traffic Condition: \(routingService.trafficConditions.rawValue)")
        print("   • Route Risk: \(routingService.routeRiskLevel.rawValue)")
        print("   • Congestion Points: \(routingService.congestionPoints.count)")
        
        if !routingService.congestionPoints.isEmpty {
            print("   • Congestion Details:")
            for point in routingService.congestionPoints.prefix(3) {
                print("     - \(point.description): \(point.trafficLevel.rawValue)")
            }
        }
        
        if !routingService.alternativeRoutes.isEmpty {
            print("   • Alternative Routes: \(routingService.alternativeRoutes.count)")
            for (index, altRoute) in routingService.alternativeRoutes.prefix(2).enumerated() {
                print("     \(index + 1). \(String(format: "%.0f", altRoute.expectedTravelTime/60)) min")
            }
        }
    }
    
    /// Optimizes the current route for better traffic conditions
    public func optimizeCurrentRoute() async {
        print("🗺️ [Example] Optimizing route for traffic...")
        await routingService.optimizeRouteForTraffic()
        printRouteAnalysis()
    }
    
    /// Gets real-time traffic updates
    @MainActor
    public func getRealTimeTrafficUpdate() {
        let trafficCondition = routingService.trafficConditions
        let travelTime = routingService.estimatedTravelTime
        
        print("🗺️ [Example] Real-time Update:")
        print("   • Current Traffic: \(trafficCondition.rawValue)")
        print("   • Updated Travel Time: \(String(format: "%.0f", travelTime/60)) min")
        
        if trafficCondition == .heavyTraffic {
            print("   ⚠️  Heavy traffic detected - consider alternative route")
        }
    }
}

// MARK: - Usage Example

/*
// How to use this in your app:

let example = TrafficRoutingExample()

// Plan the route
await example.planUWToSpaceNeedleRoute()

// Get real-time updates
example.getRealTimeTrafficUpdate()

// Optimize if needed
await example.optimizeCurrentRoute()

// This gives you:
// ✅ Real-time traffic data from Apple's servers
// ✅ Multiple route alternatives
// ✅ Congestion point detection
// ✅ Bridge risk analysis
// ✅ Automatic route optimization
// ✅ No need for crowdsourced accelerometer data!

// Benefits over crowdsourcing:
// ✅ Privacy-compliant (no access to other users' motion data)
// ✅ More accurate (Apple's traffic data is comprehensive)
// ✅ Real-time updates
// ✅ Works immediately (no need to build user base)
// ✅ Battery efficient (no constant motion monitoring)
*/ 