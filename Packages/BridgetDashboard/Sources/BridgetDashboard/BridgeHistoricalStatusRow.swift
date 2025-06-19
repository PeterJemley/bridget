//
//  BridgeHistoricalStatusRow.swift
//  BridgetDashboard
//
//  Created by Peter Jemley on 6/19/25.
//

import SwiftUI
import BridgetCore

public struct BridgeHistoricalStatusRow: View {
    public let event: DrawbridgeEvent
    
    public init(event: DrawbridgeEvent) {
        self.event = event
    }
    
    public var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(event.entityName)
                    .font(.headline)
                
                HStack(spacing: 8) {
                    Text(lastKnownStatusText)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(statusColor)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                    
                    Text(timeAgoText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
    
    // MARK: - Historical Status Logic
    private var lastKnownStatusText: String {
        if event.closeDateTime != nil {
            return "CLOSED"
        } else {
            return "WAS OPEN"
        }
    }
    
    private var statusColor: Color {
        if event.closeDateTime != nil {
            return .green  // Bridge was closed (good for traffic)
        } else {
            return .orange // Bridge was open (may have affected traffic)
        }
    }
    
    private var timeAgoText: String {
        let relevantDate = event.closeDateTime ?? event.openDateTime
        return relevantDate.formatted(.relative(presentation: .named))
    }
}

#Preview {
    BridgeHistoricalStatusRow(
        event: DrawbridgeEvent(
            entityType: "Bridge",
            entityName: "Test Bridge",
            entityID: 1,
            openDateTime: Date().addingTimeInterval(-3600),
            closeDateTime: Date(),
            minutesOpen: 15.0,
            latitude: 47.6062,
            longitude: -122.3321
        )
    )
    .padding()
}