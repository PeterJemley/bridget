//
//  InfoRow.swift
//  BridgetSharedUI
//
//  Created by Peter Jemley on 6/19/25.
//

import SwiftUI

public struct InfoRow: View {
    public let label: String
    public let value: String
    
    public init(label: String, value: String) {
        self.label = label
        self.value = value
    }
    
    public var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    InfoRow(label: "Type", value: "Bridge")
        .padding()
}