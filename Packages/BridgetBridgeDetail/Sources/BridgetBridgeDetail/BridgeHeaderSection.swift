//
//  BridgeHeaderSection.swift
//  BridgetBridgeDetail
//
//  Created by Peter Jemley on 6/19/25.
//

import SwiftUI
import BridgetCore

public struct BridgeHeaderSection: View {
    public let bridgeName: String
    public let lastKnownEvent: DrawbridgeEvent?
    public let totalEvents: Int
    
    public init(bridgeName: String, lastKnownEvent: DrawbridgeEvent?, totalEvents: Int) {
        self.bridgeName = bridgeName
        self.lastKnownEvent = lastKnownEvent
        self.totalEvents = totalEvents
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(bridgeName)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(bridgeName)
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 8) {
                        Circle()
                            .fill(statusColor(for: lastKnownEvent))
                            .frame(width: 8, height: 8)
                        
                        Text(lastKnownStatusText(for: lastKnownEvent))
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Last Updated")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(lastUpdateTime)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
#if os(iOS)
        .background(Color(.systemGray6))
#else
        .background(Color(.controlBackgroundColor))
#endif
        .cornerRadius(12)
    }
    
    private func lastKnownStatusText(for event: DrawbridgeEvent?) -> String {
        guard let event = event else { return "No Data" }
        
        if event.closeDateTime != nil {
            return "Open to Traffic"
        } else {
            return "Was Open"
        }
    }
    
    private func statusColor(for event: DrawbridgeEvent?) -> Color {
        guard let event = event else { return .gray }
        
        if event.closeDateTime != nil {
            return .green  // Bridge is closed (open to traffic)
        } else {
            return .orange // Bridge was open
        }
    }
    
    private var lastUpdateTime: String {
        guard let event = lastKnownEvent else { return "N/A" }
        let relevantDate = event.closeDateTime ?? event.openDateTime
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: relevantDate)
    }
}

#Preview {
    BridgeHeaderSection(
        bridgeName: "Test Bridge",
        lastKnownEvent: nil,
        totalEvents: 42
    )
    .padding()
}