//
//  StatusOverviewCard.swift
//  BridgetDashboard
//
//  Created by Peter Jemley on 6/19/25.
//

import SwiftUI
import BridgetCore
import BridgetSharedUI

public struct StatusOverviewCard: View {
    public let events: [DrawbridgeEvent]
    public let bridgeInfo: [DrawbridgeInfo]
    
    public init(events: [DrawbridgeEvent], bridgeInfo: [DrawbridgeInfo]) {
        self.events = events
        self.bridgeInfo = bridgeInfo
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Historical Data Overview")
                    .font(.headline)
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatusCard(
                    title: "Bridges Monitored",
                    value: "\(uniqueBridgeCount)",
                    color: .blue
                )
                
                StatusCard(
                    title: "Today's Events",
                    value: "\(todaysEventsCount)",
                    color: .purple
                )
                
                StatusCard(
                    title: totalEventsTitle,
                    value: totalEventsValue,
                    color: .gray
                )
                
                StatusCard(
                    title: "Data Range",
                    value: dataRangeText,
                    color: .green
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Data Binding Computed Properties
    private var uniqueBridgeCount: Int {
        Set(events.map(\.entityName)).count
    }
    
    private var todaysEventsCount: Int {
        DrawbridgeEvent.eventsToday(events).count
    }
    
    private var totalEventsTitle: String {
        guard let oldest = events.map(\.openDateTime).min(),
              let newest = events.map(\.openDateTime).max() else {
            return "Total Events"
        }
        
        return "Total Events"
    }
    
    private var totalEventsValue: String {
        "\(events.count)"
    }
    
    private var dataRangeText: String {
        guard let oldest = events.map(\.openDateTime).min(),
              let newest = events.map(\.openDateTime).max() else {
            return "No data"
        }
        
        let daysDifference = Calendar.current.dateComponents([.day], from: oldest, to: newest).day ?? 0
        return "\(daysDifference) days"
    }
}

#Preview {
    StatusOverviewCard(events: [], bridgeInfo: [])
        .padding()
}