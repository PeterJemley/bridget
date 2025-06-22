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
                    LastKnownStatusSection(events: lastKnownStatusEvents, bridgeInfo: bridgeInfo)
                    
                    // Recent Activity Section
                    RecentActivitySection(events: recentEvents, bridgeInfo: bridgeInfo)
                    
                    // Data Source Info
                    dataSourceInfo
                }
                .padding()
            }
            .navigationBarBackButtonHidden(true)
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Computed Properties
    
    private var lastKnownStatusEvents: [DrawbridgeEvent] {
        let uniqueBridges = Set(events.map { $0.entityID })
        return uniqueBridges.compactMap { entityID in
            events.filter { $0.entityID == entityID }
                  .sorted { $0.openDateTime > $1.openDateTime }
                  .first
        }
        .sorted { $0.openDateTime > $1.openDateTime }
    }
    
    private var recentEvents: [DrawbridgeEvent] {
        let sortedEvents = events.sorted { $0.openDateTime > $1.openDateTime }
        return Array(sortedEvents.prefix(10))
    }
    
    private var dataSourceInfo: some View {
        VStack(spacing: 8) {
            Text("Data provided by Seattle Open Data API")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Updated automatically on app launch")
                .font(.caption2)
                .foregroundColor(.secondary.opacity(0.7))
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    DashboardView(events: [], bridgeInfo: [])
}
