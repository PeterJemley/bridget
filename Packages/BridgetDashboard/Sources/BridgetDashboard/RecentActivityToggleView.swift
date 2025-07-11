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
        VStack(spacing: 12) {
            // Header with toggle
            HStack {
                Text("Latest API Data")
                    .font(.headline)
                    .fontWeight(.semibold)
                
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
        .onAppear {
            SecurityLogger.main("📱 [RECENT ACTIVITY] RecentActivityToggleView appeared")
            SecurityLogger.main("📱 [RECENT ACTIVITY] Total events: \(events.count)")
            SecurityLogger.main("📱 [RECENT ACTIVITY] Total bridge info: \(bridgeInfo.count)")
            SecurityLogger.main("📱 [RECENT ACTIVITY] Current view mode: \(viewMode)")
            
            // COMPREHENSIVE DATA AUDIT FOR LIST VIEW
            SecurityLogger.main("📱 [RECENT ACTIVITY] ===== COMPREHENSIVE DATA AUDIT =====")
            
            // 1. All bridge info records
            SecurityLogger.main("📱 [RECENT ACTIVITY] ALL BRIDGE INFO RECORDS:")
            for bridge in bridgeInfo.sorted(by: { $0.entityName < $1.entityName }) {
                SecurityLogger.main("    • \(bridge.entityName) (ID: \(bridge.entityID)) - Coords: (\(bridge.latitude), \(bridge.longitude))")
            }
            
            // 2. All events by entity name and ID
            SecurityLogger.main("📱 [RECENT ACTIVITY] ALL EVENTS BY ENTITY:")
            let eventsByName = Dictionary(grouping: events, by: \.entityName)
            let eventsByID = Dictionary(grouping: events, by: \.entityID)
            
            for (bridgeName, bridgeEvents) in eventsByName.sorted(by: { $0.key < $1.key }) {
                let uniqueIDs = Set(bridgeEvents.map { $0.entityID })
                SecurityLogger.main("    • \(bridgeName): \(bridgeEvents.count) events, IDs: \(uniqueIDs)")
                
                // Special investigation for Lower Spokane St
                if bridgeName.contains("Lower Spokane") {
                    SecurityLogger.main("📱 [RECENT ACTIVITY] 🔍 LOWER SPOKANE ST DETAILED ANALYSIS:")
                    for event in bridgeEvents.sorted(by: { $0.openDateTime > $1.openDateTime }) {
                        SecurityLogger.main("        - Event ID: \(event.id), Entity ID: \(event.entityID), Date: \(event.openDateTime.formatted())")
                    }
                }
            }
            
            // 3. Check for duplicate entity names in bridgeInfo
            SecurityLogger.main("📱 [RECENT ACTIVITY] ===== DUPLICATE DETECTION =====")
            let bridgeNames = bridgeInfo.map { $0.entityName }
            let uniqueBridgeNames = Set(bridgeNames)
            if bridgeNames.count != uniqueBridgeNames.count {
                SecurityLogger.main("📱 [RECENT ACTIVITY] ⚠️ DUPLICATE BRIDGE NAMES IN BRIDGEINFO:")
                let duplicates = bridgeNames.filter { name in bridgeNames.filter { $0 == name }.count > 1 }
                SecurityLogger.main("📱 [RECENT ACTIVITY] Duplicate names: \(Set(duplicates))")
            }
            
            // 4. Check for duplicate entity IDs in bridgeInfo
            let bridgeIDs = bridgeInfo.map { $0.entityID }
            let uniqueBridgeIDs = Set(bridgeIDs)
            if bridgeIDs.count != uniqueBridgeIDs.count {
                SecurityLogger.main("📱 [RECENT ACTIVITY] ⚠️ DUPLICATE BRIDGE IDs IN BRIDGEINFO:")
                let duplicateIDs = bridgeIDs.filter { id in bridgeIDs.filter { $0 == id }.count > 1 }
                SecurityLogger.main("📱 [RECENT ACTIVITY] Duplicate IDs: \(Set(duplicateIDs))")
            }
            
            // 5. South Park bridge search in events
            SecurityLogger.main("📱 [RECENT ACTIVITY] ===== SOUTH PARK BRIDGE SEARCH IN EVENTS =====")
            let southParkEvents = events.filter { $0.entityName.localizedCaseInsensitiveContains("South Park") }
            if !southParkEvents.isEmpty {
                SecurityLogger.main("📱 [RECENT ACTIVITY] 🔍 FOUND SOUTH PARK EVENTS:")
                for event in southParkEvents {
                    SecurityLogger.main("    • Event ID: \(event.id), Entity ID: \(event.entityID), Date: \(event.openDateTime.formatted())")
                }
            } else {
                SecurityLogger.main("📱 [RECENT ACTIVITY] No South Park events found in database")
            }
            
            // Original logging
            let bridgeGroups = Dictionary(grouping: events, by: \.entityName)
            SecurityLogger.main("📱 [RECENT ACTIVITY] BRIDGE BREAKDOWN:")
            for (bridgeName, bridgeEvents) in bridgeGroups.sorted(by: { $0.value.count > $1.value.count }) {
                SecurityLogger.main("    • \(bridgeName): \(bridgeEvents.count) events")
            }
        }
    }
}

// MARK: - Supporting Views

private struct RecentActivityListView: View {
    let events: [DrawbridgeEvent]
    let bridgeInfo: [DrawbridgeInfo]
    
    private var recentEvents: [DrawbridgeEvent] {
        let oneDayAgo = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let filtered = events
            .filter { $0.openDateTime >= oneDayAgo }
            .sorted { $0.openDateTime > $1.openDateTime }
        
        SecurityLogger.main("📋 [LIST] Filtering events: \(events.count) total → \(filtered.count) recent (last 24h)")
        
        // Group events by bridge (entityID) and select the most recent event for each bridge
        let bridgeGroups = Dictionary(grouping: filtered, by: \.entityID)
        let uniqueBridges = bridgeGroups.compactMap { (entityID, events) -> DrawbridgeEvent? in
            // Get the most recent event for each bridge
            return events.max(by: { $0.openDateTime < $1.openDateTime })
        }.sorted { $0.openDateTime > $1.openDateTime }
        
        SecurityLogger.main("📋 [LIST] Grouped events by bridge: \(filtered.count) events → \(uniqueBridges.count) unique bridges")
        
        // Additional deduplication check by entity name to handle any edge cases
        var finalBridges: [DrawbridgeEvent] = []
        var seenBridgeNames = Set<String>()
        
        for bridge in uniqueBridges {
            if !seenBridgeNames.contains(bridge.entityName) {
                finalBridges.append(bridge)
                seenBridgeNames.insert(bridge.entityName)
            } else {
                SecurityLogger.main("📋 [LIST] ⚠️ Skipping duplicate bridge name: \(bridge.entityName)")
            }
        }
        
        SecurityLogger.main("📋 [LIST] Final deduplicated bridges: \(finalBridges.count)")
        return finalBridges
        
        // Debug: Log all bridges being displayed in list
        SecurityLogger.main("📋 [LIST] BRIDGES FOR LIST VIEW:")
        for (index, event) in uniqueBridges.enumerated() {
            SecurityLogger.main("    \(index + 1). \(event.entityName) (ID: \(event.entityID)) - \(event.openDateTime.formatted())")
            
            // Special investigation for Lower Spokane St
            if event.entityName.contains("Lower Spokane") {
                SecurityLogger.main("📋 [LIST] 🔍 LOWER SPOKANE ST FOUND:")
                SecurityLogger.main("    • Index: \(index + 1)")
                SecurityLogger.main("    • Entity ID: \(event.entityID)")
                SecurityLogger.main("    • Entity Name: \(event.entityName)")
                SecurityLogger.main("    • Date: \(event.openDateTime.formatted())")
            }
        }
        
        // Check for any duplicate entity names (should be none now)
        let entityNames = uniqueBridges.map { $0.entityName }
        let uniqueNames = Set(entityNames)
        if entityNames.count != uniqueNames.count {
            SecurityLogger.main("📋 [LIST] ⚠️ Duplicate entity names detected!")
            let duplicates = entityNames.filter { name in entityNames.filter { $0 == name }.count > 1 }
            SecurityLogger.main("📋 [LIST] Duplicate names: \(Set(duplicates))")
        }
        
        // Check for any duplicate entity IDs (should be none now)
        let entityIDs = uniqueBridges.map { $0.entityID }
        let uniqueIDs = Set(entityIDs)
        if entityIDs.count != uniqueIDs.count {
            SecurityLogger.main("📋 [LIST] ⚠️ Duplicate entity IDs detected!")
            let duplicateIDs = entityIDs.filter { id in entityIDs.filter { $0 == id }.count > 1 }
            SecurityLogger.main("📋 [LIST] Duplicate IDs: \(Set(duplicateIDs))")
        }
        
        return uniqueBridges
    }
    
    var body: some View {
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