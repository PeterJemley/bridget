//
//  HistoryView.swift
//  BridgetHistory
//
//  Created by Peter Jemley on 6/19/25.
//

import SwiftUI
import BridgetCore

public struct HistoryView: View {
    public let events: [DrawbridgeEvent]
    
    public init(events: [DrawbridgeEvent]) {
        self.events = events
    }
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Historical Patterns")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Coming Soon")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text("This feature will show historical bridge opening patterns, trends, and analysis.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                if !events.isEmpty {
                    VStack(spacing: 8) {
                        Text("Available Data")
                            .font(.headline)
                        
                        Text("\(events.count) historical events")
                            .foregroundColor(.blue)
                        
                        if let earliest = events.map(\.openDateTime).min(),
                           let latest = events.map(\.openDateTime).max() {
                            Text("From \(earliest.formatted(.dateTime.day().month().year())) to \(latest.formatted(.dateTime.day().month().year()))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    HistoryView(events: [])
}