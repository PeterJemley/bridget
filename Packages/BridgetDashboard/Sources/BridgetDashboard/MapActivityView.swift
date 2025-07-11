//
//  MapActivityView.swift
//  BridgetDashboard
//
//  Created by AI Assistant on 1/15/25.
//

import SwiftUI
import MapKit
import SwiftData
import BridgetCore
import BridgetBridgeDetail

public struct MapActivityView: View {
    public let events: [DrawbridgeEvent]
    public let bridgeInfo: [DrawbridgeInfo]
    
    @Environment(\.modelContext) private var modelContext
    @State private var region: MKCoordinateRegion
    @State private var selectedEvent: DrawbridgeEvent?
    @State private var showingEventDetail = false
    
    public init(events: [DrawbridgeEvent], bridgeInfo: [DrawbridgeInfo]) {
        self.events = events
        self.bridgeInfo = bridgeInfo
        
        // Initialize map region to Seattle area
        let seattleCenter = CLLocationCoordinate2D(latitude: 47.6062, longitude: -122.3321)
        self._region = State(initialValue: MKCoordinateRegion(
            center: seattleCenter,
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        ))
    }
    
    public var body: some View {
        ZStack {
            Map(coordinateRegion: $region, annotationItems: recentEventsForMap) { event in
                MapAnnotation(coordinate: event.coordinate) {
                    BridgePinView(
                        event: event,
                        delaySeverity: calculateDelaySeverity(for: event)
                    )
                    .onTapGesture {
                        selectedEvent = event
                        showingEventDetail = true
                    }
                }
            }
            .ignoresSafeArea()
            
            // Map controls overlay
            VStack {
                HStack {
                    Spacer()
                    
                    VStack(spacing: 8) {
                        Button(action: zoomToFitAllBridges) {
                            Image(systemName: "map")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.black.opacity(0.7))
                                .clipShape(Circle())
                        }
                        
                        Button(action: zoomToSeattle) {
                            Image(systemName: "location")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.black.opacity(0.7))
                                .clipShape(Circle())
                        }
                    }
                }
                .padding()
                
                Spacer()
            }
        }
        .sheet(isPresented: $showingEventDetail) {
            if let event = selectedEvent {
                BridgeDetailView(bridgeEvent: event)
                    .environment(\.modelContext, modelContext)
            }
        }
        .onAppear {
            zoomToFitAllBridges()
        }
    }
    
    // MARK: - Computed Properties
    
    private var recentEventsForMap: [DrawbridgeEvent] {
        // Show events from the last 24 hours
        let oneDayAgo = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        return events
            .filter { $0.openDateTime >= oneDayAgo }
            .sorted { $0.openDateTime > $1.openDateTime }
    }
    
    // MARK: - Helper Methods
    
    private func calculateDelaySeverity(for event: DrawbridgeEvent) -> DelaySeverity {
        let duration = event.minutesOpen
        
        switch duration {
        case 0..<10:
            return .minimal
        case 10..<20:
            return .moderate
        default:
            return .severe
        }
    }
    
    private func zoomToFitAllBridges() {
        guard !recentEventsForMap.isEmpty else {
            zoomToSeattle()
            return
        }
        
        let coordinates = recentEventsForMap.map { $0.coordinate }
        let minLat = coordinates.map(\.latitude).min() ?? 47.6062
        let maxLat = coordinates.map(\.latitude).max() ?? 47.6062
        let minLon = coordinates.map(\.longitude).min() ?? -122.3321
        let maxLon = coordinates.map(\.longitude).max() ?? -122.3321
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.5,
            longitudeDelta: (maxLon - minLon) * 1.5
        )
        
        withAnimation(.easeInOut(duration: 0.5)) {
            region = MKCoordinateRegion(center: center, span: span)
        }
    }
    
    private func zoomToSeattle() {
        let seattleCenter = CLLocationCoordinate2D(latitude: 47.6062, longitude: -122.3321)
        withAnimation(.easeInOut(duration: 0.5)) {
            region = MKCoordinateRegion(
                center: seattleCenter,
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            )
        }
    }
}

// MARK: - Supporting Views

private struct BridgePinView: View {
    let event: DrawbridgeEvent
    let delaySeverity: DelaySeverity
    
    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: "mappin.circle.fill")
                .font(.title)
                .foregroundColor(delaySeverity.color)
                .background(Color.white)
                .clipShape(Circle())
                .shadow(radius: 2)
            
            Text(event.entityName)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.black.opacity(0.7))
                .cornerRadius(4)
                .lineLimit(1)
                .fixedSize()
        }
    }
}





// MARK: - Supporting Types

private enum DelaySeverity {
    case minimal, moderate, severe
    
    var color: Color {
        switch self {
        case .minimal:
            return .green
        case .moderate:
            return .orange
        case .severe:
            return .red
        }
    }
}

// MARK: - Extensions

private extension DrawbridgeEvent {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var relativeTimeText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: openDateTime, relativeTo: Date())
    }
}

#Preview {
    let sampleEvents = [
        DrawbridgeEvent(
            entityType: "Bridge",
            entityName: "Fremont Bridge",
            entityID: 1,
            openDateTime: Date().addingTimeInterval(-3600),
            closeDateTime: Date().addingTimeInterval(-3300),
            minutesOpen: 15.0,
            latitude: 47.6475,
            longitude: -122.3497
        ),
        DrawbridgeEvent(
            entityType: "Bridge",
            entityName: "Ballard Bridge",
            entityID: 2,
            openDateTime: Date().addingTimeInterval(-7200),
            closeDateTime: Date().addingTimeInterval(-6900),
            minutesOpen: 25.0,
            latitude: 47.6619,
            longitude: -122.3767
        )
    ]
    
    let sampleBridgeInfo = [
        DrawbridgeInfo(
            entityID: 1,
            entityName: "Fremont Bridge",
            entityType: "Bridge",
            latitude: 47.6475,
            longitude: -122.3497
        ),
        DrawbridgeInfo(
            entityID: 2,
            entityName: "Ballard Bridge",
            entityType: "Bridge",
            latitude: 47.6619,
            longitude: -122.3767
        )
    ]
    
    MapActivityView(events: sampleEvents, bridgeInfo: sampleBridgeInfo)
} 