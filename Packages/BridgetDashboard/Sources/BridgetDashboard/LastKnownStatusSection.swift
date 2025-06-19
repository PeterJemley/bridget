//
//  LastKnownStatusSection.swift
//  BridgetDashboard
//
//  Created by Peter Jemley on 6/19/25.
//

import SwiftUI
import BridgetCore

public struct LastKnownStatusSection: View {
    public let events: [DrawbridgeEvent]
    public let bridgeInfo: [DrawbridgeInfo]
    
    public init(events: [DrawbridgeEvent], bridgeInfo: [DrawbridgeInfo]) {
        self.events = events
        self.bridgeInfo = bridgeInfo
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Last Known Status")
                    .font(.headline)
                Spacer()
                Text("Historical Data")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            if events.isEmpty {
                Text("No bridge data available")
                    .foregroundColor(.secondary)
                    .italic()
                    .padding()
            } else {
                ForEach(events) { event in
                    NavigationLink(destination: BridgeDetailPlaceholderView(event: event)) {
                        BridgeHistoricalStatusRow(event: event)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
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