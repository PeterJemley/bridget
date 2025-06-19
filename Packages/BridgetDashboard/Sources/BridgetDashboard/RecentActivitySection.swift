//
//  RecentActivitySection.swift
//  BridgetDashboard
//
//  Created by Peter Jemley on 6/19/25.
//

import SwiftUI
import BridgetCore

public struct RecentActivitySection: View {
    public let events: [DrawbridgeEvent]
    public let bridgeInfo: [DrawbridgeInfo]
    
    public init(events: [DrawbridgeEvent], bridgeInfo: [DrawbridgeInfo]) {
        self.events = events
        self.bridgeInfo = bridgeInfo
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Historical Activity")
                    .font(.headline)
                Spacer()
            }
            
            if events.isEmpty {
                Text("No recent activity")
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

#Preview {
    RecentActivitySection(events: [], bridgeInfo: [])
        .padding()
}