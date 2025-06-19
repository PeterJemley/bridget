//
//  BridgesListView.swift
//  BridgetBridgesList
//
//  Created by Peter Jemley on 6/19/25.
//

import SwiftUI
import BridgetCore
import BridgetSharedUI
import BridgetBridgeDetail

public struct BridgesListView: View {
    public let events: [DrawbridgeEvent]
    public let bridgeInfo: [DrawbridgeInfo]
    
    @State private var searchText = ""
    
    public init(events: [DrawbridgeEvent], bridgeInfo: [DrawbridgeInfo]) {
        self.events = events
        self.bridgeInfo = bridgeInfo
    }
    
    public var body: some View {
        NavigationView {
            List {
                ForEach(filteredBridges, id: \.entityID) { bridge in
                    NavigationLink {
                        if let recentEvent = mostRecentEvent(for: bridge) {
                            BridgeDetailView(bridgeEvent: recentEvent)
                        } else {
                            Text("No data available for \(bridge.entityName)")
                        }
                    } label: {
                        BridgeListRow(bridge: bridge, recentEvent: mostRecentEvent(for: bridge))
                    }
                }
            }
            .navigationTitle("Bridges")
            .searchable(text: $searchText, prompt: "Search bridges...")
        }
    }
    
    private var filteredBridges: [DrawbridgeInfo] {
        if searchText.isEmpty {
            return bridgeInfo.sorted { $0.entityName < $1.entityName }
        } else {
            return bridgeInfo.filter { bridge in
                bridge.entityName.localizedCaseInsensitiveContains(searchText)
            }.sorted { $0.entityName < $1.entityName }
        }
    }
    
    private func mostRecentEvent(for bridge: DrawbridgeInfo) -> DrawbridgeEvent? {
        events
            .filter { $0.entityID == bridge.entityID }
            .max { $0.openDateTime < $1.openDateTime }
    }
}

struct BridgeListRow: View {
    let bridge: DrawbridgeInfo
    let recentEvent: DrawbridgeEvent?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(bridge.entityName)
                    .font(.headline)
                
                Spacer()
                
                if let event = recentEvent {
                    Text(event.isCurrentlyOpen ? "OPEN" : "CLOSED")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(event.isCurrentlyOpen ? Color.orange : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
            }
            
            HStack {
                Text("\(bridge.totalOpenings) total events")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let event = recentEvent {
                    Text("Last: \(event.openDateTime.formatted(.relative(presentation: .named)))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    BridgesListView(events: [], bridgeInfo: [])
}