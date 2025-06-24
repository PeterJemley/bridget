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
                VStack(spacing: 28) { 
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
                .padding(.horizontal, 16) 
                .padding(.vertical, 12) // INCREASED: From 8 to 12 for better edge spacing
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
        VStack(alignment: .leading, spacing: 24) { // INCREASED: From 20 to 24 for better separation
            Text(selectedAnalysisType.chartTitle)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .padding(.bottom, 12) // INCREASED: From 8 to 12 for more separation from chart
            
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

            .padding(.top, 16)
            .padding(.horizontal, 24)
            .padding(.bottom, 24) 
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(.systemGray5), lineWidth: 0.5)
            )
        }
        .padding(.vertical, 16) // INCREASED: From 12 to 16 for more section separation
    }
    
    // MARK: - Chart Implementations
    
    private var frequencyChart: some View {
        Chart(frequencyData.prefix(12)) { item in 
            BarMark(
                x: .value("Period", item.period),
                y: .value("Count", item.count)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [Color.blue, Color.blue.opacity(0.6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 3)) { value in 
                AxisValueLabel()
                    .font(.caption2)
                    .foregroundStyle(Color.primary)
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.gray.opacity(0.3))
                AxisValueLabel()
                    .font(.caption2)
                    .foregroundStyle(Color.primary)
            }
        }
    }
    
    private var durationChart: some View {
        Chart(durationData.prefix(8)) { item in 
            AreaMark(
                x: .value("Time", item.time, unit: .day),
                y: .value("Duration", item.avgDuration)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [Color.green.opacity(0.8), Color.green.opacity(0.2)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.catmullRom)
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 3)) { value in 
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    .font(.caption2)
                    .foregroundStyle(Color.primary)
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.gray.opacity(0.3))
                AxisValueLabel()
                    .font(.caption2)
                    .foregroundStyle(Color.primary)
            }
        }
    }
    
    private var timelineChart: some View {
        VStack(alignment: .leading, spacing: 32) { // INCREASED: From 28 to 32 for maximum separation
            // Clear summary metrics at top - with proper positioning
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 8)
                
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Busiest Week")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(busiestWeekText)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .center, spacing: 6) {
                        Text("Weekly Average")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(Int(weeklyAverage)) events")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 6) {
                        Text("Trend")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(trendDirection)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(trendColor)
                    }
                }
                .padding(.vertical, 20) // INCREASED: From 18 to 20
                .padding(.horizontal, 20)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            
            // WEEKLY CHART - with significant top margin to prevent overlap
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 16)
                
                Chart(weeklyTimelineData.prefix(5)) { item in
                    BarMark(
                        x: .value("Week", item.weekLabel),
                        y: .value("Events", item.eventCount)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: item.eventCount > weeklyAverage 
                                ? [Color.red, Color.red.opacity(0.6)]
                                : [Color.green, Color.green.opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(4)
                }
                .frame(height: 100) // REDUCED: From 110 to 100 to fit within larger container
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 3)) { value in
                        AxisValueLabel()
                            .font(.caption2)
                            .foregroundStyle(Color.primary)
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.gray.opacity(0.3))
                        AxisValueLabel()
                            .font(.caption2)
                            .foregroundStyle(Color.primary)
                    }
                }
            }
            
            // ACTIONABLE INSIGHTS CARDS - with proper spacing from chart
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 16)
                
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 16) {
                    InsightCard(
                        title: "Peak Day",
                        value: busiestDayOfWeek,
                        subtitle: "\(peakDayEventCount) avg events",
                        color: .orange
                    )
                    
                    InsightCard(
                        title: "Avg Duration",
                        value: "\(Int(averageDuration))min",
                        subtitle: "per opening",
                        color: .purple
                    )
                    
                    InsightCard(
                        title: "Top Bridge",
                        value: String(mostActiveBridge.prefix(8)),
                        subtitle: "\(Int(topBridgePercentage))% of events",
                        color: .cyan
                    )
                    
                    InsightCard(
                        title: "Recent Trend",
                        value: String(trendDirection.prefix(6)),
                        subtitle: "vs last month",
                        color: trendColor
                    )
                }
            }
        }
    }
    
    private var patternsChart: some View {
        Chart(hourlyPatternData.filter { $0.frequency > 0 }) { item in 
            LineMark(
                x: .value("Hour", item.hour),
                y: .value("Frequency", item.frequency)
            )
            .foregroundStyle(Color.purple)
            .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
            
            PointMark(
                x: .value("Hour", item.hour),
                y: .value("Frequency", item.frequency)
            )
            .foregroundStyle(Color.purple)
            .symbolSize(60)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: 6)) { value in 
                AxisValueLabel {
                    if let hour = value.as(Int.self) {
                        Text(hour == 0 ? "12A" : hour == 6 ? "6A" : hour == 12 ? "12P" : hour == 18 ? "6P" : "")
                            .font(.caption2)
                            .foregroundStyle(Color.primary)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.gray.opacity(0.3))
                AxisValueLabel()
                    .font(.caption2)
                    .foregroundStyle(Color.primary)
            }
        }
    }
    
    private var comparisonChart: some View {
        Chart(comparisonData.prefix(4)) { item in
            BarMark(
                x: .value("Total Events", item.totalEvents),
                y: .value("Bridge", item.bridgeName)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [Color.orange, Color.orange.opacity(0.6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(4)
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                AxisGridLine()
                AxisValueLabel()
                    .font(.caption2)
            }
        }
        .chartYAxis {
            AxisMarks() { _ in
                AxisValueLabel()
                    .font(.caption2)
            }
        }
        .frame(height: CGFloat(min(comparisonData.count, 4)) * 44 + 40)
        .padding(.vertical, 12)
    }
    
    // MARK: - Summary Statistics Section
    
    private var summaryStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Summary Statistics")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.bottom, 8) // INCREASED: From 4 to 8 for consistency
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                StatCard(title: "Total Events", value: "\(filteredEvents.count)", icon: "chart.bar", color: .blue)
                StatCard(title: "Avg Duration", value: String(format: "%.1f min", averageDuration), icon: "clock", color: .green)
                StatCard(title: "Most Active Bridge", value: mostActiveBridge, icon: "road.lanes", color: .purple)
                StatCard(title: "Peak Hour", value: peakHour, icon: "sun.max", color: .orange)
            }
        }
        .padding(.vertical, 12) // INCREASED: From 8 to 12 for better section separation
    }
    
    // MARK: - Timeline Section
    
    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Events Timeline")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.bottom, 8) // INCREASED: From 4 to 8 for consistency
            
            LazyVStack(spacing: 12) {
                ForEach(recentEvents.prefix(20), id: \.openDateTime) { event in
                    TimelineEventRow(event: event)
                }
            }
        }
        .padding(.vertical, 12) // INCREASED: From 8 to 12 for better section separation
    }
    
    // MARK: - Pattern Insights Section
    
    private var patternInsightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pattern Insights")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.bottom, 8) // INCREASED: From 4 to 8 for consistency
            
            VStack(spacing: 16) {
                ForEach(patternInsights, id: \.title) { insight in
                    PatternInsightCard(insight: insight)
                }
            }
        }
        .padding(.vertical, 12) // INCREASED: From 8 to 12 for better section separation
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
    
    private var frequencyData: [FrequencyDataPoint] {
        let calendar = Calendar.current
        let groupedData = Dictionary(grouping: filteredEvents) { event in
            let formatter = DateFormatter()
            formatter.dateFormat = "M/d"
            let weekStart = calendar.dateInterval(of: .weekOfYear, for: event.openDateTime)?.start ?? event.openDateTime
            return formatter.string(from: weekStart)
        }
        
        return groupedData.map { period, events in
            FrequencyDataPoint(period: period, count: events.count)
        }.sorted { 
            let formatter = DateFormatter()
            formatter.dateFormat = "M/d"
            let date1 = formatter.date(from: $0.period) ?? Date.distantPast
            let date2 = formatter.date(from: $1.period) ?? Date.distantPast
            return date1 < date2
        }
    }
    
    private var durationData: [DurationDataPoint] {
        let calendar = Calendar.current
        let groupedData = Dictionary(grouping: filteredEvents) { event in
            calendar.dateInterval(of: .weekOfYear, for: event.openDateTime)?.start ?? event.openDateTime
        }
        
        return groupedData.compactMap { date, events in
            guard !events.isEmpty else { return nil }
            let avgDuration = events.map(\.minutesOpen).reduce(0, +) / Double(events.count)
            return DurationDataPoint(time: date, avgDuration: avgDuration)
        }.sorted { $0.time < $1.time }
    }
    
    private var hourlyPatternData: [HourlyPatternDataPoint] {
        let calendar = Calendar.current
        let hourlyGroups = Dictionary(grouping: filteredEvents) { event in
            calendar.component(.hour, from: event.openDateTime)
        }
        
        return (0..<24).map { hour in
            HourlyPatternDataPoint(hour: hour, frequency: hourlyGroups[hour]?.count ?? 0)
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
        
        return insights
    }
    
    private var busiestWeekText: String {
        guard let busiestWeek = weeklyTimelineData.max(by: { $0.eventCount < $1.eventCount }) else {
            return "N/A"
        }
        return busiestWeek.weekLabel
    }
    
    private var weeklyAverage: Double {
        guard !weeklyTimelineData.isEmpty else { return 0 }
        let totalEvents = weeklyTimelineData.map(\.eventCount).reduce(0, +)
        return totalEvents / Double(weeklyTimelineData.count)
    }
    
    private var trendDirection: String {
        guard weeklyTimelineData.count >= 4 else { return "N/A" }
        
        let recent = weeklyTimelineData.suffix(2).map(\.eventCount).reduce(0, +) / 2
        let previous = weeklyTimelineData.dropLast(2).suffix(2).map(\.eventCount).reduce(0, +) / 2
        
        if recent > previous * 1.1 {
            return " Rising"
        } else if recent < previous * 0.9 {
            return " Falling"
        } else {
            return " Stable"
        }
    }
    
    private var trendColor: Color {
        if trendDirection.contains("Rising") {
            return .red
        } else if trendDirection.contains("Falling") {
            return .green
        } else {
            return .blue
        }
    }
    
    private var busiestDayOfWeek: String {
        let calendar = Calendar.current
        let dayGroups = Dictionary(grouping: filteredEvents) { event in
            calendar.component(.weekday, from: event.openDateTime)
        }
        
        guard let busiestDay = dayGroups.max(by: { $0.value.count < $1.value.count }) else {
            return "N/A"
        }
        
        return calendar.shortWeekdaySymbols[busiestDay.key - 1]
    }
    
    private var peakDayEventCount: Int {
        let calendar = Calendar.current
        let dayGroups = Dictionary(grouping: filteredEvents) { event in
            calendar.component(.weekday, from: event.openDateTime)
        }
        
        return dayGroups.max(by: { $0.value.count < $1.value.count })?.value.count ?? 0
    }
    
    private var topBridgePercentage: Double {
        let bridgeCounts = Dictionary(grouping: filteredEvents, by: \.entityName).mapValues(\.count)
        let topCount = bridgeCounts.values.max() ?? 0
        let totalCount = filteredEvents.count
        
        guard totalCount > 0 else { return 0 }
        return Double(topCount) / Double(totalCount) * 100
    }
    
    private var weeklyTimelineData: [WeeklyTimelineDataPoint] {
        let calendar = Calendar.current
        let weekGroups = Dictionary(grouping: filteredEvents) { event in
            calendar.dateInterval(of: .weekOfYear, for: event.openDateTime)?.start ?? event.openDateTime
        }
        
        return weekGroups.map { startDate, events in
            let formatter = DateFormatter()
            formatter.dateFormat = "M/d"
            
            return WeeklyTimelineDataPoint(
                weekStart: startDate,
                weekLabel: formatter.string(from: startDate),
                eventCount: Double(events.count)
            )
        }.sorted { $0.weekStart < $1.weekStart }
    }
}

// MARK: - Supporting Types and Views

struct WeeklyTimelineDataPoint: Identifiable {
    let id = UUID()
    let weekStart: Date
    let weekLabel: String
    let eventCount: Double
}

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
        case .timeline: return "Weekly Activity Summary"
        case .patterns: return "Daily Opening Patterns"
        case .comparison: return "Bridge Activity Comparison"
        }
    }
}

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
        .padding(.vertical, 12) 
        .padding(.horizontal, 16) 
        .background(Color(.systemGray6))
        .cornerRadius(10) 
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
        .padding(16) 
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2) 
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) { 
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8) 
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2) 
        }
        .frame(maxWidth: .infinity)
        .padding(20) 
        .background(Color(.systemBackground))
        .cornerRadius(16) 
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2) 
    }
}

struct InsightCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) { 
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16) 
        .background(Color(.systemBackground))
        .cornerRadius(12) 
        .shadow(color: .black.opacity(0.04), radius: 2, x: 0, y: 1) 
    }
}

#Preview {
    HistoryView(events: [])
}
