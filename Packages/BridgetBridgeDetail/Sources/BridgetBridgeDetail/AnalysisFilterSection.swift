//
//  AnalysisFilterSection.swift
//  BridgetBridgeDetail
//
//  Created by Peter Jemley on 6/19/25.
//

import SwiftUI
import BridgetCore
import BridgetSharedUI

public struct AnalysisFilterSection: View {
    @Binding public var selectedAnalysis: AnalysisType
    
    public init(selectedAnalysis: Binding<AnalysisType>) {
        self._selectedAnalysis = selectedAnalysis
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                FilterButton(
                    title: "Patterns",
                    isSelected: selectedAnalysis == .patterns,
                    action: { selectedAnalysis = .patterns }
                )
                
                FilterButton(
                    title: "Cascade",
                    isSelected: selectedAnalysis == .cascade,
                    action: { selectedAnalysis = .cascade }
                )
                
                FilterButton(
                    title: "Predictions", 
                    isSelected: selectedAnalysis == .predictions,
                    action: { selectedAnalysis = .predictions }
                )
                
                FilterButton(
                    title: "Impact",
                    isSelected: selectedAnalysis == .impact,
                    action: { selectedAnalysis = .impact }
                )
            }
        }
    }
}

#Preview {
    AnalysisFilterSection(selectedAnalysis: .constant(.patterns))
        .padding()
}