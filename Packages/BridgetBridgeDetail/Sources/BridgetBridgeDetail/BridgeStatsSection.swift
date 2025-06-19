//
//  BridgeStatsSection.swift
//  BridgetBridgeDetail
//
//  Created by Peter Jemley on 6/19/25.
//

import SwiftUI
import BridgetCore
import BridgetSharedUI

public struct BridgeStatsSection: View {
    public let events: [DrawbridgeEvent]
    public let timePeriod: TimePeriod
    public let analysisType: AnalysisType
    
    public init(events: [DrawbridgeEvent], timePeriod: TimePeriod, analysisType: AnalysisType) {
        self.events = events
        self.timePeriod = timePeriod
        self.analysisType = analysisType
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistics (\(periodDescription))")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatCard(
                    title: "Total Openings",
                    value: "\(events.count)",
                    icon: "arrow.up.circle.fill",
                    color: .blue
                )
                
                StatCard(
                    title: analysisSpecificTitle,
                    value: analysisSpecificValue,
                    icon: analysisSpecificIcon,
                    color: analysisSpecificColor
                )
                
                StatCard(
                    title: "Longest Opening",
                    value: longestDurationText,
                    icon: "clock.fill",
                    color: .red
                )
                
                StatCard(
                    title: "Most Active Day",
                    value: mostActiveDayText,
                    icon: "calendar",
                    color: .green
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Computed Properties
    private var periodDescription: String {
        switch timePeriod {
        case .twentyFourHours: return "Last 24 Hours"
        case .sevenDays: return "Last 7 Days"
        case .thirtyDays: return "Last 30 Days"
        case .ninetyDays: return "Last 90 Days"
        }
    }
    
    private var analysisSpecificTitle: String {
        switch analysisType {
        case .patterns: return "Avg Duration"
        case .cascade: return "Peak Hour"
        case .predictions: return "Next Probability"
        case .impact: return "High Impact"
        }
    }
    
    private var analysisSpecificValue: String {
        switch analysisType {
        case .patterns:
            guard !events.isEmpty else { return "0 min" }
            let avg = events.map(\.minutesOpen).reduce(0, +) / Double(events.count)
            return String(format: "%.0f min", avg)
        case .cascade:
            return peakHour
        case .predictions:
            return "Coming Soon"
        case .impact:
            let highImpact = events.filter { $0.minutesOpen > 30 }.count
            return "\(highImpact)"
        }
    }
    
    private var analysisSpecificIcon: String {
        switch analysisType {
        case .patterns: return "timer"
        case .cascade: return "arrow.triangle.branch"
        case .predictions: return "crystal.ball"
        case .impact: return "exclamationmark.triangle.fill"
        }
    }
    
    private var analysisSpecificColor: Color {
        switch analysisType {
        case .patterns: return .orange
        case .cascade: return .purple
        case .predictions: return .blue
        case .impact: return .red
        }
    }
    
    private var peakHour: String {
        let calendar = Calendar.current
        var hourCounts: [Int: Int] = [:]
        
        for event in events {
            let hour = calendar.component(.hour, from: event.openDateTime)
            hourCounts[hour, default: 0] += 1
        }
        
        if let peak = hourCounts.max(by: { $0.value < $1.value }) {
            return "\(peak.key):00"
        }
        return "None"
    }
    
    private var longestDurationText: String {
        guard let longest = events.map(\.minutesOpen).max() else { return "0 min" }
        return String(format: "%.0f min", longest)
    }
    
    private var mostActiveDayText: String {
        guard !events.isEmpty else { return "None" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        
        let dayGroups = Dictionary(grouping: events) { event in
            formatter.string(from: event.openDateTime)
        }
        
        let mostActiveDay = dayGroups.max { $0.value.count < $1.value.count }
        return mostActiveDay?.key ?? "None"
    }
}

#Preview {
    BridgeStatsSection(
        events: [],
        timePeriod: .sevenDays,
        analysisType: .patterns
    )
    .padding()
}