//
//  TrafficAwareRoutingService.swift
//  BridgetCore
//
//  Created by Peter Jemley on 6/19/25.
//

import Foundation
import CoreLocation
import MapKit
import Combine

@MainActor
public class TrafficAwareRoutingService: ObservableObject {
    private let locationManager = CLLocationManager()
    private var cancellables = Set<AnyCancellable>()
    
    @Published public var currentRoute: MKRoute?
    @Published public var alternativeRoutes: [MKRoute] = []
    @Published public var trafficConditions: TrafficCondition = .unknown
    @Published public var estimatedTravelTime: TimeInterval = 0
    @Published public var isCalculatingRoute = false
    @Published public var routeError: String?
    
    // Traffic analysis
    @Published public var congestionPoints: [CongestionPoint] = []
    @Published public var routeRiskLevel: RiskLevel = .low
    
    public init() {
        print("🗺️ [Routing] TrafficAwareRoutingService initialized")
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    // MARK: - Traffic-Aware Route Planning
    
    /// Plans a route with traffic awareness and bridge predictions
    public func planRoute(
        from origin: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D,
        transportType: MKDirectionsTransportType = .automobile
    ) async {
        isCalculatingRoute = true
        routeError = nil
        
        print("🗺️ [Routing] Planning route from \(origin) to \(destination)")
        
        do {
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: origin))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
            request.transportType = transportType
            request.requestsAlternateRoutes = true
            
            let directions = MKDirections(request: request)
            let response = try await directions.calculate()
            
            await MainActor.run {
                self.processRouteResponse(response)
            }
            
        } catch {
            await MainActor.run {
                self.routeError = "Failed to calculate route: \(error.localizedDescription)"
                self.isCalculatingRoute = false
            }
        }
    }
    
    private func processRouteResponse(_ response: MKDirections.Response) {
        guard let primaryRoute = response.routes.first else {
            routeError = "No routes found"
            isCalculatingRoute = false
            return
        }
        
        currentRoute = primaryRoute
        alternativeRoutes = Array(response.routes.dropFirst())
        estimatedTravelTime = primaryRoute.expectedTravelTime
        
        // Analyze traffic conditions along the route
        analyzeTrafficConditions(route: primaryRoute)
        
        // Check for bridge-related risks
        checkBridgeRisks(route: primaryRoute)
        
        isCalculatingRoute = false
        print("🗺️ [Routing] Route calculated: \(String(format: "%.0f", estimatedTravelTime/60)) min")
    }
    
    // MARK: - Traffic Analysis
    
    private func analyzeTrafficConditions(route: MKRoute) {
        let steps = route.steps
        var congestionPoints: [CongestionPoint] = []
        
        for step in steps {
            let trafficLevel = analyzeStepTraffic(step)
            if trafficLevel != .freeFlow {
                let congestionPoint = CongestionPoint(
                    coordinate: step.polyline.coordinate,
                    trafficLevel: trafficLevel,
                    description: step.instructions,
                    distance: step.distance
                )
                congestionPoints.append(congestionPoint)
            }
        }
        
        self.congestionPoints = congestionPoints
        
        // Determine overall traffic condition
        let avgTrafficLevel = congestionPoints.isEmpty ? TrafficCondition.freeFlow : 
            congestionPoints.map(\.trafficLevel).reduce(.freeFlow) { $0.rawValue > $1.rawValue ? $0 : $1 }
        
        trafficConditions = avgTrafficLevel
        
        print("🗺️ [Routing] Traffic analysis: \(congestionPoints.count) congestion points, overall: \(trafficConditions.rawValue)")
    }
    
    private func analyzeStepTraffic(_ step: MKRoute.Step) -> TrafficCondition {
        // Analyze based on step properties
        // Use distance and route-level travel time for speed calculation
        let speed = step.distance / max(currentRoute?.expectedTravelTime ?? 60, 1)
        let speedMph = speed * 2.237 // Convert m/s to mph
        
        switch speedMph {
        case 0..<10: return .heavyTraffic
        case 10..<25: return .moderateTraffic
        case 25..<45: return .normalTraffic
        default: return .freeFlow
        }
    }
    
    // MARK: - Bridge Risk Analysis
    
    private func checkBridgeRisks(route: MKRoute) {
        // Get bridges along the route
        let routeBridges = findBridgesAlongRoute(route)
        
        var totalRisk = 0.0
        var bridgeRisks: [BridgeRisk] = []
        
        for bridge in routeBridges {
            let risk = calculateBridgeRisk(bridge)
            totalRisk += risk.probability
            bridgeRisks.append(risk)
        }
        
        // Determine overall route risk
        routeRiskLevel = determineRouteRiskLevel(totalRisk: totalRisk, bridgeCount: routeBridges.count)
        
        print("🗺️ [Routing] Route risk analysis: \(bridgeRisks.count) bridges, risk level: \(routeRiskLevel.rawValue)")
    }
    
    private func findBridgesAlongRoute(_ route: MKRoute) -> [DrawbridgeInfo] {
        // This would integrate with your existing bridge data
        // For now, return sample bridges near the route
        return []
    }
    
    private func calculateBridgeRisk(_ bridge: DrawbridgeInfo) -> BridgeRisk {
        // This would use your existing prediction engine
        return BridgeRisk(
            bridge: bridge,
            probability: 0.1, // Placeholder
            estimatedDelay: 300, // 5 minutes
            riskLevel: .low
        )
    }
    
    private func determineRouteRiskLevel(totalRisk: Double, bridgeCount: Int) -> RiskLevel {
        let averageRisk = bridgeCount > 0 ? totalRisk / Double(bridgeCount) : 0
        
        switch averageRisk {
        case 0.0..<0.3: return .low
        case 0.3..<0.6: return .medium
        default: return .high
        }
    }
    
    // MARK: - Real-time Updates
    
    public func startRealTimeUpdates() async {
        // Set up timer for periodic route updates
        Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.updateRouteIfNeeded()
                }
            }
            .store(in: &cancellables)
    }
    
    private func updateRouteIfNeeded() async {
        guard let currentRoute = currentRoute else { return }
        
        // Recalculate route to get updated traffic conditions
        Task {
            await planRoute(
                from: currentRoute.steps.first?.polyline.coordinate ?? CLLocationCoordinate2D(),
                to: currentRoute.steps.last?.polyline.coordinate ?? CLLocationCoordinate2D()
            )
        }
    }
    
    // MARK: - Route Optimization
    
    public func optimizeRouteForTraffic() async {
        guard let currentRoute = currentRoute else { return }
        
        print("🗺️ [Routing] Optimizing route for traffic conditions...")
        
        // Try to find alternative routes with less congestion
        let optimizedRoute = alternativeRoutes.first { route in
            let routeCongestion = analyzeRouteCongestion(route)
            let currentCongestion = analyzeRouteCongestion(currentRoute)
            return routeCongestion < currentCongestion
        }
        
        if let optimizedRoute = optimizedRoute {
            self.currentRoute = optimizedRoute
            alternativeRoutes = alternativeRoutes.filter { $0 != optimizedRoute }
            alternativeRoutes.append(optimizedRoute)
            
            print("🗺️ [Routing] Route optimized for better traffic conditions")
        }
    }
    
    private func analyzeRouteCongestion(_ route: MKRoute) -> Double {
        let steps = route.steps
        let congestionScores = steps.map { step in
            let speed = step.distance / max(route.expectedTravelTime, 1)
            return max(0, 1 - (speed / 20)) // Normalize to 0-1 scale
        }
        return congestionScores.reduce(0, +) / Double(congestionScores.count)
    }
}

// MARK: - Supporting Types

public struct CongestionPoint: Identifiable {
    public let id = UUID()
    public let coordinate: CLLocationCoordinate2D
    public let trafficLevel: TrafficCondition
    public let description: String
    public let distance: CLLocationDistance
    
    public init(
        coordinate: CLLocationCoordinate2D,
        trafficLevel: TrafficCondition,
        description: String,
        distance: CLLocationDistance
    ) {
        self.coordinate = coordinate
        self.trafficLevel = trafficLevel
        self.description = description
        self.distance = distance
    }
}

public struct BridgeRisk {
    public let bridge: DrawbridgeInfo
    public let probability: Double
    public let estimatedDelay: TimeInterval
    public let riskLevel: RiskLevel
    
    public init(
        bridge: DrawbridgeInfo,
        probability: Double,
        estimatedDelay: TimeInterval,
        riskLevel: RiskLevel
    ) {
        self.bridge = bridge
        self.probability = probability
        self.estimatedDelay = estimatedDelay
        self.riskLevel = riskLevel
    }
}

// MARK: - Extensions

extension CLLocationCoordinate2D: CustomStringConvertible {
    public var description: String {
        return "(\(latitude), \(longitude))"
    }
} 