//
//  BridgeInfoSection.swift
//  BridgetBridgeDetail
//
//  Created by Peter Jemley on 6/19/25.
//

import SwiftUI
import BridgetCore
import BridgetSharedUI

public struct BridgeInfoSection: View {
    public let event: DrawbridgeEvent
    
    public init(event: DrawbridgeEvent) {
        self.event = event
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Bridge Information")
                .font(.headline)
            
            InfoRow(label: "Type", value: event.entityType)
            InfoRow(label: "Entity ID", value: "\(event.entityID)")
            InfoRow(label: "Location", value: String(format: "%.4f, %.4f", event.latitude, event.longitude))
            
            if event.closeDateTime != nil {
                InfoRow(label: "Duration", value: String(format: "%.0f minutes", event.minutesOpen))
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    BridgeInfoSection(
        event: DrawbridgeEvent(
            entityType: "Bridge",
            entityName: "Test Bridge",
            entityID: 1,
            openDateTime: Date(),
            closeDateTime: nil,
            minutesOpen: 15.0,
            latitude: 47.6062,
            longitude: -122.3321
        )
    )
    .padding()
}