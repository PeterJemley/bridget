//
//  RecentActivityToggleView.swift
//  BridgetDashboard
//
//  Created by AI Assistant on 1/15/25.
//

import SwiftUI
import SwiftData
import BridgetCore
import BridgetBridgeDetail

public struct RecentActivityToggleView: View {
    public let events: [DrawbridgeEvent]
    public let bridgeInfo: [DrawbridgeInfo]
    
    @Environment(\.modelContext) private var modelContext
    @State private var viewMode: ViewMode = .list
    
    public init(events: [DrawbridgeEvent], bridgeInfo: [DrawbridgeInfo]) {
        self.events = events
        self.bridgeInfo = bridgeInfo
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with toggle
            HStack {
                Text("Recent Historical Activity")
                    .font(.headline)
                
                Spacer()
                
                // View mode toggle
                HStack(spacing: 0) {
                    Button(action: { viewMode = .list }) {
                        HStack(spacing: 4) {
                            Image(systemName: "list.bullet")
                                .font(.caption)
                            Text("List")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(viewMode == .list ? .white : .primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(viewMode == .list ? Color.blue : Color.clear)
                        .cornerRadius(8)
                    }
                    
                    Button(action: { viewMode = .map }) {
                        HStack(spacing: 4) {
                            Image(systemName: "map")
                                .font(.caption)
                            Text("Map")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(viewMode == .map ? .white : .primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(viewMode == .map ? Color.blue : Color.clear)
                        .cornerRadius(8)
                    }
                }
                .background(Color(.systemGray5))
                .cornerRadius(8)
            }
            
            // Content based on view mode
            Group {
                switch viewMode {
                case .list:
                    RecentActivityListView(events: events, bridgeInfo: bridgeInfo)
                case .map:
                    MapActivityView(events: events, bridgeInfo: bridgeInfo)
                        .frame(height: 300)
                        .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Supporting Views

private struct RecentActivityListView: View {
    let events: [DrawbridgeEvent]
    let bridgeInfo: [DrawbridgeInfo]
    
    var body: some View {
        let recentEvents = events.filter { event in
            let hoursSinceOpening = Date().timeIntervalSince(event.openDateTime) / 3600
            return hoursSinceOpening <= 24
        }.sorted { $0.openDateTime > $1.openDateTime }
        
        if recentEvents.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "clock")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                if let latestEvent = events.max(by: { $0.openDateTime < $1.openDateTime }) {
                    VStack(spacing: 4) {
                        Text("Latest API data from")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(latestEvent.relativeTimeText)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                    }
                } else {
                    Text("No recent bridge activity")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(8)
        } else {
            LazyVStack(spacing: 8) {
                ForEach(Array(recentEvents.prefix(5).enumerated()), id: \.element.id) { index, event in
                    NavigationLink(destination: BridgeDetailView(bridgeEvent: event)) {
                        RecentActivityRow(event: event)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    if index < min(recentEvents.count, 5) - 1 {
                        Divider()
                    }
                }
            }
        }
    }
}

private struct RecentActivityRow: View {
    let event: DrawbridgeEvent
    
    var body: some View {
        HStack {
            // Bridge icon with delay severity
            Image(systemName: "mappin.circle.fill")
                .font(.title3)
                .foregroundColor(delaySeverity.color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(event.entityName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Opened \(event.relativeTimeText) • \(Int(event.minutesOpen)) min")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Chevron for navigation
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private var delaySeverity: DelaySeverity {
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
}

// MARK: - Supporting Types

private enum ViewMode {
    case list, map
}

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
    
    RecentActivityToggleView(events: sampleEvents, bridgeInfo: sampleBridgeInfo)
        .padding()
} 