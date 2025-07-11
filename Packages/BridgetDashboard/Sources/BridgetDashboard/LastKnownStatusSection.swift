//
//  LastKnownStatusSection.swift
//  BridgetDashboard
//
//  Created by Peter Jemley on 6/19/25.
//

import SwiftUI
import SwiftData
import BridgetCore
import BridgetBridgeDetail

public struct LastKnownStatusSection: View {
    public let events: [DrawbridgeEvent]
    public let bridgeInfo: [DrawbridgeInfo]
    
    @Environment(\.modelContext) private var modelContext
    
    public init(events: [DrawbridgeEvent], bridgeInfo: [DrawbridgeInfo]) {
        self.events = events
        self.bridgeInfo = bridgeInfo
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recently Active Bridges")
                    .font(.headline)
                Spacer()
                Text("Last 24H")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            if recentlyActiveBridges.isEmpty {
                Text("No recent bridge activity")
                    .foregroundColor(.secondary)
                    .italic()
                    .padding()
            } else {
                ForEach(recentlyActiveBridges.prefix(3), id: \.entityID) { bridgeInfo in
                    NavigationLink(destination: BridgeDetailView(
                        bridgeEvent: getMostRecentEvent(for: bridgeInfo.entityID)
                    ).environment(\.modelContext, modelContext)) {
                        BridgeHistoricalStatusRow(event: getMostRecentEvent(for: bridgeInfo.entityID))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                if recentlyActiveBridges.count > 3 {
                    NavigationLink("View All Bridges") {
                        // This will navigate to the Bridges tab content
                        Text("All Bridges View")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Methods
    
    private var recentlyActiveBridges: [DrawbridgeInfo] {
        let oneDayAgo = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let recentEvents = events.filter { $0.openDateTime >= oneDayAgo }
        let recentBridgeIDs = Set(recentEvents.map(\.entityID))
        
        return bridgeInfo.filter { recentBridgeIDs.contains($0.entityID) }
            .sorted { bridge1, bridge2 in
                let events1 = recentEvents.filter { $0.entityID == bridge1.entityID }
                let events2 = recentEvents.filter { $0.entityID == bridge2.entityID }
                
                // Sort by most recent activity
                let mostRecent1 = events1.map(\.openDateTime).max() ?? Date.distantPast
                let mostRecent2 = events2.map(\.openDateTime).max() ?? Date.distantPast
                
                return mostRecent1 > mostRecent2
            }
    }
    
    private func getMostRecentEvent(for entityID: Int) -> DrawbridgeEvent {
        let bridgeEvents = events.filter { $0.entityID == entityID }
        return bridgeEvents.max { $0.openDateTime < $1.openDateTime } ?? bridgeEvents.first!
    }
}

// MARK: - Bridge Detail Placeholder View
struct BridgeDetailPlaceholderView: View {
    let event: DrawbridgeEvent
    
    var body: some View {
        // TODO: Import BridgeDetailView from its own module when created
        VStack {
            Text("Bridge Detail")
                .font(.largeTitle)
            Text(event.entityName)
                .font(.headline)
            Text("Feature coming from BridgeDetail module")
                .foregroundColor(.secondary)
        }
        .navigationTitle(event.entityName)
    }
}

#Preview {
    LastKnownStatusSection(events: [], bridgeInfo: [])
        .padding()
}