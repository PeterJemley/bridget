//
//  RouteDetailsView.swift
//  BridgetRouting
//
//  Created by Peter Jemley on 7/6/25.
//

import SwiftUI
import MapKit
import BridgetCore

struct RouteDetailsView: View {
    @ObservedObject var routingService: TrafficAwareRoutingService
    @Environment(\.dismiss) private var dismiss
    @State private var showingMap = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Route Summary Card
                    RouteSummaryCard(routingService: routingService)
                    
                    // Traffic Analysis
                    TrafficAnalysisCard(routingService: routingService)
                    
                    // Route Steps
                    if let route = routingService.currentRoute {
                        RouteStepsCard(route: route)
                    }
                    
                    // Alternative Routes
                    if !routingService.alternativeRoutes.isEmpty {
                        AlternativeRoutesCard(routes: routingService.alternativeRoutes)
                    }
                    
                    // Action Buttons
                    ActionButtonsCard(routingService: routingService)
                }
                .padding()
            }
            .navigationTitle("Route Details")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingMap) {
            RouteMapView(routingService: routingService)
        }
    }
}

struct RouteSummaryCard: View {
    @ObservedObject var routingService: TrafficAwareRoutingService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "route")
                    .foregroundColor(.blue)
                Text("Route Summary")
                    .font(.headline)
                Spacer()
            }
            
            if let route = routingService.currentRoute {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Distance")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(String(format: "%.1f", route.distance/1000)) km")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .center) {
                        Text("Travel Time")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(String(format: "%.0f", route.expectedTravelTime/60)) min")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Traffic")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(routingService.trafficConditions.rawValue)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(trafficColor)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private var trafficColor: Color {
        switch routingService.trafficConditions {
        case .clear: return .green
        case .lightTraffic: return .yellow
        case .moderateTraffic: return .orange
        case .heavyTraffic: return .red
        case .unknown: return .gray
        }
    }
}

struct TrafficAnalysisCard: View {
    @ObservedObject var routingService: TrafficAwareRoutingService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.orange)
                Text("Traffic Analysis")
                    .font(.headline)
                Spacer()
            }
            
            VStack(spacing: 12) {
                HStack {
                    Text("Route Risk Level")
                    Spacer()
                    Text(routingService.routeRiskLevel.rawValue)
                        .fontWeight(.medium)
                        .foregroundColor(riskColor)
                }
                
                if !routingService.congestionPoints.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Congestion Points")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        ForEach(routingService.congestionPoints.prefix(3), id: \.description) { point in
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
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private var riskColor: Color {
        switch routingService.routeRiskLevel {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        case .unknown: return .gray
        }
    }
}

struct RouteStepsCard: View {
    let route: MKRoute
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "list.bullet")
                    .foregroundColor(.blue)
                Text("Directions")
                    .font(.headline)
                Spacer()
            }
            
            VStack(spacing: 12) {
                ForEach(Array(route.steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 20, height: 20)
                            .background(Color.blue)
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(step.instructions)
                                .font(.subheadline)
                            
                            if step.distance > 0 {
                                Text("\(String(format: "%.0f", step.distance))m")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
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

struct AlternativeRoutesCard: View {
    let routes: [MKRoute]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "arrow.triangle.branch")
                    .foregroundColor(.green)
                Text("Alternative Routes")
                    .font(.headline)
                Spacer()
            }
            
            VStack(spacing: 12) {
                ForEach(Array(routes.prefix(3).enumerated()), id: \.offset) { index, route in
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Route \(index + 1)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("\(String(format: "%.1f", route.distance/1000)) km")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("\(String(format: "%.0f", route.expectedTravelTime/60)) min")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct ActionButtonsCard: View {
    @ObservedObject var routingService: TrafficAwareRoutingService
    @State private var showingMap = false
    
    var body: some View {
        VStack(spacing: 12) {
            Button(action: {
                showingMap = true
            }) {
                HStack {
                    Image(systemName: "map.fill")
                    Text("View on Map")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            
            Button(action: {
                Task {
                    await routingService.optimizeRouteForTraffic()
                }
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Optimize Route")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .sheet(isPresented: $showingMap) {
            RouteMapView(routingService: routingService)
        }
    }
}

struct RouteMapView: View {
    @ObservedObject var routingService: TrafficAwareRoutingService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Text("Map View - Coming Soon")
                .navigationTitle("Route Map")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

#Preview {
    RouteDetailsView(routingService: TrafficAwareRoutingService())
} 