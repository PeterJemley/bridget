//
//  StatCard.swift
//  BridgetSharedUI
//
//  Created by Peter Jemley on 6/19/25.
//

import SwiftUI

public struct StatCard: View {
    public let title: String
    public let value: String
    public let icon: String
    public let color: Color
    
    public init(title: String, value: String, icon: String, color: Color) {
        self.title = title
        self.value = value
        self.icon = icon
        self.color = color
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
        }
        .frame(minHeight: 80)
        .padding()
#if os(iOS)
        .background(Color(.systemBackground))
#else
        .background(Color(.windowBackgroundColor))
#endif
        .cornerRadius(8)
    }
}

#Preview {
    StatCard(
        title: "Total Openings",
        value: "42",
        icon: "arrow.up.circle.fill",
        color: .blue
    )
    .padding()
}