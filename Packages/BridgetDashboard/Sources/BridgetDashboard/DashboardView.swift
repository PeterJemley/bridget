//
//  DashboardView.swift
//  BridgetDashboard
//
//  Created by Peter Jemley on 6/19/25.
//

import SwiftUI
import BridgetCore
import BridgetSharedUI

public struct DashboardView: View {
    public let events: [DrawbridgeEvent]
    public let bridgeInfo: [DrawbridgeInfo]
    
    public init(events: [DrawbridgeEvent], bridgeInfo: [DrawbridgeInfo]) {
        self.events = events
        self.bridgeInfo = bridgeInfo
    }
    
    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Section
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "laurel.leading")
                                .font(.largeTitle)
                                .foregroundColor(.green)
                            
                            Text("Bridget")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Image(systemName: "laurel.trailing")
                                .font(.largeTitle)
                                .foregroundColor(.green)
                        }
                        
                        (Text("Ditch the spanxiety and bridge the gap between ") +
                         Text("you").italic() +
                         Text(" and ") +
                         Text("on time").italic())
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)
                    
                    // Data source information
                    if !events.isEmpty {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                            Text("Data provided by Seattle Open Data API")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    
                    // Status Overview Card
                    StatusOverviewCard(events: events, bridgeInfo: bridgeInfo)
                    
                    // Last Known Status Section
                    LastKnownStatusSection(events: lastKnownStatusPerBridge)
                    
                    // Recent Activity Section (Historical)
                    RecentActivitySection(events: recentEvents)
                    
                    Spacer(minLength: 100) // Bottom padding for tab bar
                }
                .padding(.horizontal)
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Computed Properties with Historical Data Binding
    private var lastKnownStatusPerBridge: [DrawbridgeEvent] {
        let groupedEvents = DrawbridgeEvent.groupedByBridge(events)
        return groupedEvents.compactMap { (_, bridgeEvents) in
            bridgeEvents.max(by: { $0.openDateTime < $1.openDateTime })
        }.sorted { $0.openDateTime > $1.openDateTime }
    }
    
    private var recentEvents: [DrawbridgeEvent] {
        events.sorted { $0.openDateTime > $1.openDateTime }.prefix(5).map { $0 }
    }
    
    private var todaysEvents: [DrawbridgeEvent] {
        DrawbridgeEvent.eventsToday(events)
    }
}

#Preview {
    DashboardView(events: [], bridgeInfo: [])
}