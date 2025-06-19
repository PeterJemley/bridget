//
//  DynamicAnalysisSection.swift
//  BridgetBridgeDetail
//
//  Created by Peter Jemley on 6/19/25.
//

import SwiftUI
import BridgetCore

public struct DynamicAnalysisSection: View {
    public let events: [DrawbridgeEvent]
    public let analysisType: AnalysisType
    public let viewType: ViewType
    public let bridgeName: String
    
    public init(events: [DrawbridgeEvent], analysisType: AnalysisType, viewType: ViewType, bridgeName: String) {
        self.events = events
        self.analysisType = analysisType
        self.viewType = viewType
        self.bridgeName = bridgeName
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(sectionTitle)
                    .font(.headline)
                Spacer()
                Text(analysisDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Placeholder content for now - will be expanded in future updates
            VStack(alignment: .leading, spacing: 12) {
                Text("Analysis View: \(analysisType.description) - \(viewType.description)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Bridge: \(bridgeName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Events in period: \(events.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if !events.isEmpty {
                    Text("Latest event: \(events.first?.openDateTime.formatted(.dateTime) ?? "N/A")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Placeholder for future chart/analysis implementation
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
                    .frame(height: 120)
                    .overlay(
                        Text("Chart/Analysis View\nComing Soon")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    )
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var sectionTitle: String {
        switch analysisType {
        case .patterns: return "Pattern Analysis"
        case .cascade: return "Cascade Analysis"
        case .predictions: return "Predictive Analysis"
        case .impact: return "Traffic Impact Analysis"
        }
    }
    
    private var analysisDescription: String {
        switch (analysisType, viewType) {
        case (.patterns, .activity): return "Activity patterns over time"
        case (.patterns, .weekly): return "Weekly opening patterns"
        case (.patterns, .duration): return "Duration patterns analysis"
        case (.cascade, .activity): return "Bridge interaction timeline"
        case (.cascade, .weekly): return "Weekly cascade patterns"
        case (.cascade, .duration): return "Duration cascade effects"
        case (.predictions, .activity): return "Future activity predictions"
        case (.predictions, .weekly): return "Weekly prediction patterns"
        case (.predictions, .duration): return "Predicted durations"
        case (.impact, .activity): return "Traffic impact timeline"
        case (.impact, .weekly): return "Weekly traffic impact"
        case (.impact, .duration): return "Duration impact analysis"
        }
    }
}

// MARK: - Extensions for String representation
extension AnalysisType {
    var description: String {
        switch self {
        case .patterns: return "Patterns"
        case .cascade: return "Cascade"
        case .predictions: return "Predictions"
        case .impact: return "Impact"
        }
    }
}

extension ViewType {
    var description: String {
        switch self {
        case .activity: return "Activity"
        case .weekly: return "Weekly"
        case .duration: return "Duration"
        }
    }
}

#Preview {
    DynamicAnalysisSection(
        events: [],
        analysisType: .patterns,
        viewType: .activity,
        bridgeName: "Test Bridge"
    )
    .padding()
}