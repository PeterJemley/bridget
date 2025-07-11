//
//  FilterButton.swift
//  BridgetSharedUI
//
//  Created by Peter Jemley on 6/19/25.
//

import SwiftUI

public struct FilterButton: View {
    public let title: String
    public let isSelected: Bool
    public let action: () -> Void
    
    public init(title: String, isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.isSelected = isSelected
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
#if os(iOS)
                .background(isSelected ? Color.blue : Color(.systemGray5))
#else
                .background(isSelected ? Color.blue : Color(.controlBackgroundColor))
#endif
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(8)
        }
    }
}

#Preview {
    HStack {
        FilterButton(title: "Active", isSelected: true) { }
        FilterButton(title: "Inactive", isSelected: false) { }
    }
    .padding()
}