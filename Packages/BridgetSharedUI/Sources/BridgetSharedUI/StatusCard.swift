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
        VStack(spacing: 8) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(minHeight: 60)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

#Preview {
    StatusCard(
        title: "Test Card",
        value: "42",
        color: .blue
    )
    .padding()
}