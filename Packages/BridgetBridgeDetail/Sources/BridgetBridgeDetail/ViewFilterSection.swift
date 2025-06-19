//
//  ViewFilterSection.swift
//  BridgetBridgeDetail
//
//  Created by Peter Jemley on 6/19/25.
//

import SwiftUI
import BridgetCore
import BridgetSharedUI

public struct ViewFilterSection: View {
    @Binding public var selectedView: ViewType
    
    public init(selectedView: Binding<ViewType>) {
        self._selectedView = selectedView
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                FilterButton(
                    title: "Activity",
                    isSelected: selectedView == .activity,
                    action: { selectedView = .activity }
                )
                
                FilterButton(
                    title: "Weekly",
                    isSelected: selectedView == .weekly,
                    action: { selectedView = .weekly }
                )
                
                FilterButton(
                    title: "Duration",
                    isSelected: selectedView == .duration,
                    action: { selectedView = .duration }
                )
            }
        }
    }
}

#Preview {
    ViewFilterSection(selectedView: .constant(.activity))
        .padding()
}