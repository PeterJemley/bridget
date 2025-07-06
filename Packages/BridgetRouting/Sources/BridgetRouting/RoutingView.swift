//
//  RoutingView.swift
//  BridgetRouting
//
//  Created by Peter Jemley on 7/6/25.
//

import SwiftUI
import MapKit
import BridgetCore
import BridgetSharedUI

struct RoutingView: View {
    @StateObject private var routingService = TrafficAwareRoutingService()
    @State private var startLocation = ""
    @State private var endLocation = ""
    @State private var isPlanningRoute = false
    @State private var routeError: String?
    @State private var showingRouteDetails = false
    
    // Common Seattle destinations for quick selection
    private let commonDestinations = [
        ("University of Washington", "UW Campus"),
        ("Space Needle", "Seattle Center"),
        ("Pike Place Market", "Downtown Seattle"),
        ("Seattle-Tacoma Airport", "SEA Airport"),
        ("Fremont Bridge", "Fremont"),
        ("Ballard Bridge", "Ballard"),
        ("West Seattle Bridge", "West Seattle")
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Smart Route Planning")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Plan your route with real-time traffic and bridge status")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                
                // Route Input Section
                VStack(spacing: 16) {
                    // Start Location
                    VStack(alignment: .leading, spacing: 8) {
                        Text("From")
                            .font(.headline)
                        
                        TextField("Enter start location", text: $startLocation)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocorrectionDisabled()
                    }
                    
                    // End Location
                    VStack(alignment: .leading, spacing: 8) {
                        Text("To")
                            .font(.headline)
                        
                        TextField("Enter destination", text: $endLocation)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocorrectionDisabled()
                    }
                }
                .padding(.horizontal)
                
                // Quick Destination Buttons
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Destinations")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(commonDestinations, id: \.0) { destination in
                                Button(action: {
                                    endLocation = destination.0
                                }) {
                                    VStack(spacing: 4) {
                                        Text(destination.1)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                        Text(destination.0)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Plan Route Button
                Button(action: planRoute) {
                    HStack {
                        if isPlanningRoute {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "car.fill")
                        }
                        Text(isPlanningRoute ? "Planning Route..." : "Plan Route")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(startLocation.isEmpty || endLocation.isEmpty || isPlanningRoute)
                .padding(.horizontal)
                
                // Route Results
                if let route = routingService.currentRoute {
                    RouteResultCard(
                        route: route,
                        trafficCondition: routingService.trafficConditions,
                        routeRisk: routingService.routeRiskLevel,
                        congestionPoints: routingService.congestionPoints
                    )
                    .padding(.horizontal)
                }
                
                // Error Display
                if let error = routeError {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationTitle("Routes")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingRouteDetails) {
                RouteDetailsView(routingService: routingService)
            }
        }
    }
    
    private func planRoute() {
        guard !startLocation.isEmpty && !endLocation.isEmpty else { return }
        
        isPlanningRoute = true
        routeError = nil
        
        Task {
            do {
                // Convert text locations to coordinates (simplified for demo)
                let startCoord = getCoordinatesForLocation(startLocation)
                let endCoord = getCoordinatesForLocation(endLocation)
                
                await routingService.planRoute(
                    from: startCoord,
                    to: endCoord,
                    transportType: .automobile
                )
                
                await MainActor.run {
                    isPlanningRoute = false
                    showingRouteDetails = true
                }
                
            } catch {
                await MainActor.run {
                    isPlanningRoute = false
                    routeError = "Failed to plan route: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func getCoordinatesForLocation(_ location: String) -> CLLocationCoordinate2D {
        // Simplified coordinate lookup - in a real app, you'd use geocoding
        let coordinates: [String: CLLocationCoordinate2D] = [
            "University of Washington": CLLocationCoordinate2D(latitude: 47.6553, longitude: -122.3035),
            "Space Needle": CLLocationCoordinate2D(latitude: 47.6205, longitude: -122.3493),
            "Pike Place Market": CLLocationCoordinate2D(latitude: 47.6097, longitude: -122.3421),
            "Seattle-Tacoma Airport": CLLocationCoordinate2D(latitude: 47.4502, longitude: -122.3088),
            "Fremont Bridge": CLLocationCoordinate2D(latitude: 47.6475, longitude: -122.3497),
            "Ballard Bridge": CLLocationCoordinate2D(latitude: 47.6619, longitude: -122.3767),
            "West Seattle Bridge": CLLocationCoordinate2D(latitude: 47.5719, longitude: -122.3547)
        ]
        
        return coordinates[location] ?? CLLocationCoordinate2D(latitude: 47.6062, longitude: -122.3321) // Default to Seattle
    }
}

struct RouteResultCard: View {
    let route: MKRoute
    let trafficCondition: TrafficCondition
    let routeRisk: RouteRiskLevel
    let congestionPoints: [CongestionPoint]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Route Found")
                    .font(.headline)
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Distance")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(String(format: "%.1f", route.distance/1000)) km")
                        .font(.headline)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Travel Time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(String(format: "%.0f", route.expectedTravelTime/60)) min")
                        .font(.headline)
                }
            }
            
            HStack {
                TrafficStatusCard(condition: trafficCondition)
                Spacer()
                RouteRiskCard(riskLevel: routeRisk)
            }
            
            if !congestionPoints.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Traffic Alerts")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ForEach(congestionPoints.prefix(2), id: \.description) { point in
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text(point.description)
                                .font(.caption)
                            Spacer()
                            Text(point.trafficLevel.rawValue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct TrafficStatusCard: View {
    let condition: TrafficCondition
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: conditionIcon)
                .foregroundColor(conditionColor)
            Text(condition.rawValue)
                .font(.caption)
                .foregroundColor(conditionColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(conditionColor.opacity(0.1))
        .cornerRadius(6)
    }
    
    private var conditionIcon: String {
        switch condition {
        case .clear: return "car.fill"
        case .lightTraffic: return "car.fill"
        case .moderateTraffic: return "car.2.fill"
        case .heavyTraffic: return "car.3.fill"
        case .unknown: return "questionmark.circle.fill"
        }
    }
    
    private var conditionColor: Color {
        switch condition {
        case .clear: return .green
        case .lightTraffic: return .yellow
        case .moderateTraffic: return .orange
        case .heavyTraffic: return .red
        case .unknown: return .gray
        }
    }
}

struct RouteRiskCard: View {
    let riskLevel: RouteRiskLevel
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: riskIcon)
                .foregroundColor(riskColor)
            Text(riskLevel.rawValue)
                .font(.caption)
                .foregroundColor(riskColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(riskColor.opacity(0.1))
        .cornerRadius(6)
    }
    
    private var riskIcon: String {
        switch riskLevel {
        case .low: return "checkmark.shield.fill"
        case .medium: return "exclamationmark.shield.fill"
        case .high: return "xmark.shield.fill"
        case .unknown: return "questionmark.shield.fill"
        }
    }
    
    private var riskColor: Color {
        switch riskLevel {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        case .unknown: return .gray
        }
    }
}

#Preview {
    RoutingView()
} 