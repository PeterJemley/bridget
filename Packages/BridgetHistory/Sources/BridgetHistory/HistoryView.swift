//
//  HistoryView.swift
//  BridgetHistory
//
//  Created by Peter Jemley on 6/19/25.
//

import SwiftUI
import Charts
import BridgetCore
import BridgetSharedUI

public struct HistoryView: View {
    public let events: [DrawbridgeEvent]
    
    @State private var selectedTimeRange: TimeRange = .month
    @State private var selectedBridge: DrawbridgeInfo?
    @State private var selectedAnalysisType: AnalysisType = .frequency
    @State private var showingBridgePicker = false
    
    public init(events: [DrawbridgeEvent]) {
        self.events = events
    }
    
    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Time Range Selection
                    timeRangeSection
                    
                    // Bridge Selection
                    bridgeSelectionSection
                    
                    // Analysis Type Selection
                    analysisTypeSection
                    
                    // Main Chart
                    mainChartSection
                    
                    // Summary Statistics
                    summaryStatsSection
                    
                    // Detailed Timeline
                    if selectedAnalysisType == .timeline {
                        timelineSection
                    }
                    
                    // Pattern Insights
                    if selectedAnalysisType == .patterns {
                        patternInsightsSection
                    }
                }
                .padding()
            }
            .navigationTitle("Historical Analysis")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingBridgePicker) {
                bridgePickerSheet
            }
        }
    }
    
    // MARK: - Time Range Section
    
    private var timeRangeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Time Range")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    FilterButton(
                        title: range.displayName,
                        isSelected: selectedTimeRange == range,
                        action: { selectedTimeRange = range }
                    )
                }
                Spacer()
            }
        }
    }
    
    // MARK: - Bridge Selection Section
    
    private var bridgeSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Bridge Focus")
                .font(.headline)
                .fontWeight(.semibold)
            
            Button(action: { showingBridgePicker = true }) {
                HStack {
                    Text(selectedBridge?.entityName ?? "All Bridges")
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
        }
    }
    
    // MARK: - Analysis Type Section
    
    private var analysisTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Analysis Type")
                .font(.headline)
                .fontWeight(.semibold)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(AnalysisType.allCases, id: \.self) { type in
                        FilterButton(
                            title: type.displayName,
                            isSelected: selectedAnalysisType == type,
                            action: { selectedAnalysisType = type }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Main Chart Section
    
    private var mainChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(selectedAnalysisType.chartTitle)
                .font(.headline)
                .fontWeight(.semibold)
            
            Group {
                switch selectedAnalysisType {
                case .frequency:
                    frequencyChart
                case .duration:
                    durationChart
                case .timeline:
                    timelineChart
                case .patterns:
                    patternsChart
                case .comparison:
                    comparisonChart
                }
            }
            .frame(height: 300)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
    }
    
    // MARK: - Chart Implementations
    
    private var frequencyChart: some View {
        Chart(frequencyData) { item in
            BarMark(
                x: .value("Period", item.period),
                y: .value("Count", item.count)
            )
            .foregroundStyle(Color.blue.gradient)
        }
        .chartXAxis(.visible)
        .chartYAxis(.visible)
    }
    
    private var durationChart: some View {
        Chart(durationData) { item in
            AreaMark(
                x: .value("Time", item.time),
                y: .value("Duration", item.avgDuration)
            )
            .foregroundStyle(Color.green.gradient)
            .interpolationMethod(.catmullRom)
        }
        .chartXAxis(.visible)
        .chartYAxis(.visible)
    }
    
    private var timelineChart: some View {
        Chart(timelineData) { item in
            PointMark(
                x: .value("Time", item.timestamp),
                y: .value("Bridge", item.bridgeName)
            )
            .foregroundStyle(Color.red)
            .symbolSize(CGSize(width: 8, height: 8))
        }
        .chartXAxis(.visible)
        .chartYAxis(.visible)
    }
    
    private var patternsChart: some View {
        Chart(hourlyPatternData) { item in
            LineMark(
                x: .value("Hour", item.hour),
                y: .value("Frequency", item.frequency)
            )
            .foregroundStyle(Color.purple)
            .lineStyle(StrokeStyle(lineWidth: 3))
        }
        .chartXAxis(.visible)
        .chartYAxis(.visible)
    }
    
    private var comparisonChart: some View {
        Chart(comparisonData) { item in
            BarMark(
                x: .value("Bridge", item.bridgeName),
                y: .value("Total Events", item.totalEvents)
            )
            .foregroundStyle(Color.orange.gradient)
        }
        .chartXAxis(.visible)
        .chartYAxis(.visible)
    }
    
    // MARK: - Summary Stats Section
    
    private var summaryStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Summary Statistics")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                StatCard(title: "Total Events", value: "\(filteredEvents.count)", icon: "chart.bar", color: .blue)
                StatCard(title: "Avg Duration", value: String(format: "%.1f min", averageDuration), icon: "clock", color: .green)
                StatCard(title: "Most Active Bridge", value: mostActiveBridge, icon: "road.lanes", color: .purple)
                StatCard(title: "Peak Hour", value: peakHour, icon: "sun.max", color: .orange)
            }
        }
    }
    
    // MARK: - Timeline Section
    
    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Events Timeline")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVStack(spacing: 8) {
                ForEach(recentEvents.prefix(20), id: \.openDateTime) { event in
                    TimelineEventRow(event: event)
                }
            }
        }
    }
    
    // MARK: - Pattern Insights Section
    
    private var patternInsightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pattern Insights")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                ForEach(patternInsights, id: \.title) { insight in
                    PatternInsightCard(insight: insight)
                }
            }
        }
    }
    
    // MARK: - Bridge Picker Sheet
    
    private var bridgePickerSheet: some View {
        NavigationView {
            List {
                Button("All Bridges") {
                    selectedBridge = nil
                    showingBridgePicker = false
                }
                .foregroundColor(selectedBridge == nil ? .blue : .primary)
                
                ForEach(uniqueBridges, id: \.entityID) { bridge in
                    Button(bridge.entityName) {
                        selectedBridge = bridge
                        showingBridgePicker = false
                    }
                    .foregroundColor(selectedBridge?.entityID == bridge.entityID ? .blue : .primary)
                }
            }
            .navigationTitle("Select Bridge")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                showingBridgePicker = false
            })
        }
    }
}

// MARK: - Computed Properties

extension HistoryView {
    
    private var filteredEvents: [DrawbridgeEvent] {
        let cutoffDate = Calendar.current.date(byAdding: selectedTimeRange.dateComponent, value: -selectedTimeRange.value, to: Date()) ?? Date.distantPast
        
        var filtered = events.filter { $0.openDateTime >= cutoffDate }
        
        if let selectedBridge = selectedBridge {
            filtered = filtered.filter { $0.entityID == selectedBridge.entityID }
        }
        
        return filtered
    }
    
    private var uniqueBridges: [DrawbridgeInfo] {
        let uniqueData = DrawbridgeEvent.getUniqueBridges(events)
        return uniqueData.map { data in
            DrawbridgeInfo(
                entityID: data.entityID,
                entityName: data.entityName,
                entityType: data.entityType,
                latitude: data.latitude,
                longitude: data.longitude
            )
        }
    }
    
    private var averageDuration: Double {
        guard !filteredEvents.isEmpty else { return 0 }
        return filteredEvents.map(\.minutesOpen).reduce(0, +) / Double(filteredEvents.count)
    }
    
    private var mostActiveBridge: String {
        let bridgeCounts = Dictionary(grouping: filteredEvents, by: \.entityName).mapValues(\.count)
        return bridgeCounts.max(by: { $0.value < $1.value })?.key ?? "N/A"
    }
    
    private var peakHour: String {
        let calendar = Calendar.current
        let hourCounts = Dictionary(grouping: filteredEvents) { event in
            calendar.component(.hour, from: event.openDateTime)
        }.mapValues(\.count)
        
        guard let peak = hourCounts.max(by: { $0.value < $1.value }) else { return "N/A" }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        let date = calendar.date(bySettingHour: peak.key, minute: 0, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date).lowercased()
    }
    
    private var recentEvents: [DrawbridgeEvent] {
        filteredEvents.sorted { $0.openDateTime > $1.openDateTime }
    }
    
    // MARK: - Chart Data
    
    private var frequencyData: [FrequencyDataPoint] {
        let calendar = Calendar.current
        let groupedData = Dictionary(grouping: filteredEvents) { event in
            calendar.startOfDay(for: event.openDateTime)
        }
        
        return groupedData.map { date, events in
            FrequencyDataPoint(
                period: date.formatted(.dateTime.month().day()),
                count: events.count
            )
        }.sorted { $0.period < $1.period }
    }
    
    private var durationData: [DurationDataPoint] {
        let calendar = Calendar.current
        let groupedData = Dictionary(grouping: filteredEvents) { event in
            calendar.startOfDay(for: event.openDateTime)
        }
        
        return groupedData.map { date, events in
            let avgDuration = events.map(\.minutesOpen).reduce(0, +) / Double(events.count)
            return DurationDataPoint(time: date, avgDuration: avgDuration)
        }.sorted { $0.time < $1.time }
    }
    
    private var timelineData: [TimelineDataPoint] {
        filteredEvents.prefix(50).map { event in
            TimelineDataPoint(
                timestamp: event.openDateTime,
                bridgeName: event.entityName
            )
        }
    }
    
    private var hourlyPatternData: [HourlyPatternDataPoint] {
        let calendar = Calendar.current
        let hourlyGroups = Dictionary(grouping: filteredEvents) { event in
            calendar.component(.hour, from: event.openDateTime)
        }
        
        return (0..<24).map { hour in
            HourlyPatternDataPoint(
                hour: hour,
                frequency: hourlyGroups[hour]?.count ?? 0
            )
        }
    }
    
    private var comparisonData: [ComparisonDataPoint] {
        let bridgeGroups = Dictionary(grouping: filteredEvents, by: \.entityName)
        return bridgeGroups.map { name, events in
            ComparisonDataPoint(bridgeName: name, totalEvents: events.count)
        }.sorted { $0.totalEvents > $1.totalEvents }
    }
    
    private var patternInsights: [PatternInsight] {
        var insights: [PatternInsight] = []
        
        // Peak day insight
        let calendar = Calendar.current
        let dayGroups = Dictionary(grouping: filteredEvents) { event in
            calendar.component(.weekday, from: event.openDateTime)
        }
        
        if let peakDay = dayGroups.max(by: { $0.value.count < $1.value.count }) {
            let dayName = calendar.weekdaySymbols[peakDay.key - 1]
            insights.append(PatternInsight(
                title: "Peak Day",
                description: "\(dayName) has the most bridge openings with \(peakDay.value.count) events",
                impact: .high
            ))
        }
        
        // Duration trend insight
        let recentDuration = filteredEvents.suffix(50).map(\.minutesOpen).reduce(0, +) / 50
        let overallDuration = averageDuration
        
        if recentDuration > overallDuration * 1.2 {
            insights.append(PatternInsight(
                title: "Increasing Duration Trend",
                description: "Recent openings are 20% longer than average",
                impact: .medium
            ))
        }
        
        return insights
    }
}

// MARK: - Supporting Types

public enum TimeRange: CaseIterable {
    case week, month, quarter, year
    
    var displayName: String {
        switch self {
        case .week: return "7D"
        case .month: return "30D"
        case .quarter: return "90D"
        case .year: return "1Y"
        }
    }
    
    var dateComponent: Calendar.Component {
        switch self {
        case .week: return .day
        case .month: return .day
        case .quarter: return .day
        case .year: return .day
        }
    }
    
    var value: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .quarter: return 90
        case .year: return 365
        }
    }
}

public enum AnalysisType: CaseIterable {
    case frequency, duration, timeline, patterns, comparison
    
    var displayName: String {
        switch self {
        case .frequency: return "Frequency"
        case .duration: return "Duration"
        case .timeline: return "Timeline"
        case .patterns: return "Patterns"
        case .comparison: return "Compare"
        }
    }
    
    var chartTitle: String {
        switch self {
        case .frequency: return "Opening Frequency Over Time"
        case .duration: return "Average Duration Trends"
        case .timeline: return "Bridge Opening Timeline"
        case .patterns: return "Daily Opening Patterns"
        case .comparison: return "Bridge Activity Comparison"
        }
    }
}

// MARK: - Data Models

struct FrequencyDataPoint: Identifiable {
    let id = UUID()
    let period: String
    let count: Int
}

struct DurationDataPoint: Identifiable {
    let id = UUID()
    let time: Date
    let avgDuration: Double
}

struct TimelineDataPoint: Identifiable {
    let id = UUID()
    let timestamp: Date
    let bridgeName: String
}

struct HourlyPatternDataPoint: Identifiable {
    let id = UUID()
    let hour: Int
    let frequency: Int
}

struct ComparisonDataPoint: Identifiable {
    let id = UUID()
    let bridgeName: String
    let totalEvents: Int
}

struct PatternInsight {
    let title: String
    let description: String
    let impact: InsightImpact
}

enum InsightImpact {
    case low, medium, high
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
}

// MARK: - Supporting Views

struct TimelineEventRow: View {
    let event: DrawbridgeEvent
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(event.entityName)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text(event.relativeTimeText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(event.isCurrentlyOpen ? "WAS OPEN" : "CLOSED")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(event.isCurrentlyOpen ? .red : .green)
                
                Text("\(Int(event.minutesOpen)) min")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct PatternInsightCard: View {
    let insight: PatternInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(insight.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Circle()
                    .fill(insight.impact.color)
                    .frame(width: 8, height: 8)
            }
            
            Text(insight.description)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
    }
}

#Preview {
    HistoryView(events: [])
}