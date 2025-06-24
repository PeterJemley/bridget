//
//  RecentActivitySection.swift
//  BridgetDashboard
//
//  Created by Peter Jemley on 6/19/25.
//

import SwiftUI
import BridgetCore
import BridgetBridgeDetail

public struct RecentActivitySection: View {
    public let events: [DrawbridgeEvent]
    public let bridgeInfo: [DrawbridgeInfo]
    
    public init(events: [DrawbridgeEvent], bridgeInfo: [DrawbridgeInfo]) {
        self.events = events
        self.bridgeInfo = bridgeInfo
    }
    
    @ViewBuilder
    private var recentActivityContent: some View {
        let recentEvents = events.filter { event in
            let hoursSinceOpening = Date().timeIntervalSince(event.openDateTime) / 3600
            return hoursSinceOpening <= 24
        }.sorted { $0.openDateTime > $1.openDateTime }
        
        if recentEvents.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "clock")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                // IMPROVED: Show latest API data instead of generic message
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
                ForEach(Array(recentEvents.prefix(3).enumerated()), id: \.element.id) { index, event in
                    Text("\(event.entityName) - \(event.relativeTimeText)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if index < min(recentEvents.count, 3) - 1 {
                        Divider()
                    }
                }
            }
        }
    }
    
    func getBridgeInfo(for entityID: Int) -> DrawbridgeInfo? {
        return bridgeInfo.first(where: { $0.entityID == entityID })
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Historical Activity")
                    .font(.headline)
                Spacer()
            }
            recentActivityContent
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