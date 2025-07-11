//
//  StatusCard.swift
//  BridgetSharedUI
//
//  Created by Peter Jemley on 6/19/25.
//

import SwiftUI

public struct StatusCard: View {
    public let title: String
    public let value: String
    public let color: Color
    
    public init(title: String, value: String, color: Color) {
        self.title = title
        self.value = value
        self.color = color
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
#if os(iOS)
        .background(Color(.systemBackground))
#else
        .background(Color(.windowBackgroundColor))
#endif
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    HStack {
        StatusCard(
            title: "Bridges Monitored",
            value: "7",
            color: .blue
        )
        
        StatusCard(
            title: "Total Events",
            value: "4,187",
            color: .gray
        )
    }
    .padding()
}