//
//  DynamicAnalysisSection.swift
//  BridgetBridgeDetail
//
//  Created by Peter Jemley on 6/19/25.
//

import SwiftUI
import SwiftData
import Charts
import BridgetCore
import BridgetSharedUI

public struct DynamicAnalysisSection: View {
    public let events: [DrawbridgeEvent]
    public let analysisType: AnalysisType
    public let viewType: ViewType
    public let bridgeName: String
    
    @Environment(\.modelContext) private var modelContext
    @Query private var allEvents: [DrawbridgeEvent]
    @Query private var cascadeEvents: [CascadeEvent]
    @State private var isAnalyzing = false
    
    public init(events: [DrawbridgeEvent], analysisType: AnalysisType, viewType: ViewType, bridgeName: String) {
        self.events = events
        self.analysisType = analysisType
        self.viewType = viewType
        self.bridgeName = bridgeName
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack {
                Text(sectionTitle)
                    .font(.headline)
                Spacer()
                Text(analysisDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Dynamic content based on analysis and view type combination
            Group {
                switch (analysisType, viewType) {
                case (.patterns, .activity):
                    patternsActivityView
                case (.patterns, .weekly):
                    patternsWeeklyView
                case (.patterns, .duration):
                    patternsDurationView
                case (.cascade, .activity):
                    cascadeActivityView
                case (.cascade, .weekly):
                    cascadeWeeklyView
                case (.cascade, .duration):
                    cascadeDurationView
                case (.predictions, .activity):
                    predictionsActivityView
                case (.predictions, .weekly):
                    predictionsWeeklyView
                case (.predictions, .duration):
                    predictionsDurationView
                case (.impact, .activity):
                    impactActivityView
                case (.impact, .weekly):
                    impactWeeklyView
                case (.impact, .duration):
                    impactDurationView
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Patterns Analysis Views
    
    @ViewBuilder
    private var patternsActivityView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Activity Patterns")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            if events.count >= 5 {
                // Hourly activity chart
                hourlyActivityChart
                
                // Most active hours
                VStack(alignment: .leading, spacing: 8) {
                    Text("Most Active Hours")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    ForEach(getMostActiveHours().prefix(3), id: \.hour) { hourData in
                        HStack {
                            Text(formatHour(hourData.hour))
                                .font(.caption)
                                .frame(width: 60, alignment: .leading)
                            
                            ProgressView(value: Double(hourData.count), total: Double(hourData.maxCount))
                                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                            
                            Text("\(hourData.count) events")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Duration insights
                VStack(alignment: .leading, spacing: 8) {
                    Text("Duration Insights")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    let avgDuration = events.map(\.minutesOpen).reduce(0, +) / Double(events.count)
                    let maxDuration = events.map(\.minutesOpen).max() ?? 0
                    
                    Text("Average: \(String(format: "%.1f", avgDuration)) min")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("Longest: \(String(format: "%.1f", maxDuration)) min")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("Limited exact-time data. Using baseline patterns from \(events.count) total bridge events.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
    }
    
    @ViewBuilder
    private var patternsWeeklyView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weekly Patterns")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            if events.count >= 7 {
                // Weekly pattern chart using SwiftUI Charts
                weeklyPatternChart
                
                // Weekly insights
                VStack(alignment: .leading, spacing: 8) {
                    Text("Weekly Insights")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    let weekdayEvents = events.filter { !isWeekend($0.openDateTime) }.count
                    let weekendEvents = events.filter { isWeekend($0.openDateTime) }.count
                    
                    Text("Weekdays: \(weekdayEvents) events")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("Weekends: \(weekendEvents) events")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if weekendEvents > weekdayEvents {
                        Text("📈 More active on weekends")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    } else {
                        Text("🏢 More active on weekdays")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
            } else {
                Text("Need at least 7 events for weekly pattern analysis")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
    }
    
    @ViewBuilder
    private var patternsDurationView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Duration Patterns")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            if events.count >= 5 {
                // Duration distribution
                VStack(alignment: .leading, spacing: 8) {
                    Text("Duration Distribution")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    let durationRanges = calculateDurationRanges()
                    
                    ForEach(durationRanges, id: \.range) { rangeData in
                        HStack {
                            Text(rangeData.range)
                                .font(.caption)
                                .frame(width: 80, alignment: .leading)
                            
                            ProgressView(value: Double(rangeData.count), total: Double(events.count))
                                .progressViewStyle(LinearProgressViewStyle(tint: .green))
                            
                            Text("\(rangeData.count)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Duration trends
                let avgDuration = events.map(\.minutesOpen).reduce(0, +) / Double(events.count)
                Text("Average Duration: \(String(format: "%.1f", avgDuration)) minutes")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("Need at least 5 events for duration pattern analysis")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
    }
    
    // MARK: - Cascade Analysis Views
    
    @ViewBuilder
    private var cascadeActivityView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Bridge Connection Activity")
                .font(.headline)
            
            if cascadeEvents.isEmpty && !allEvents.isEmpty {
                VStack(spacing: 12) {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Analyzing bridge connections...")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    
                    Text("Analyzing \(allEvents.count) bridge events to discover connection patterns")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
                .onAppear {
                    Task {
                        await forceCascadeDetectionForDetail()
                    }
                }
            } else if !cascadeEvents.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Found \(cascadeEvents.count) connection patterns")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                    
                    Text("Connections show when this bridge's openings often lead to other bridge openings nearby.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            } else {
                Text("Analyzing how this bridge's openings connect to other Seattle bridges...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    @ViewBuilder
    private var cascadeWeeklyView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weekly Bridge Connections")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text("Weekly bridge connection analysis")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    @ViewBuilder
    private var cascadeDurationView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Connection Duration Effects")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text("Connection duration effect analysis")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Predictions Analysis Views
    
    @ViewBuilder
    private var predictionsActivityView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Current Predictions")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            // Bridge-specific prediction
            if let bridgeInfo = getBridgeInfo() {
                let prediction = BridgeAnalytics.getCurrentPrediction(for: bridgeInfo, from: [])
                
                if let prediction = prediction {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Next Hour Probability")
                                .font(.caption)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Text(prediction.probabilityText)
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(probabilityColor(prediction.probability))
                        }
                        
                        Text("Expected Duration: \(prediction.durationText)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text(prediction.reasoning)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                } else {
                    Text("Generating prediction...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    @ViewBuilder
    private var predictionsWeeklyView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weekly Prediction Patterns")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text("Weekly prediction pattern analysis")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    @ViewBuilder
    private var predictionsDurationView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Duration Predictions")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text("Duration prediction analysis")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Impact Analysis Views
    
    @ViewBuilder
    private var impactActivityView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Traffic Impact Analysis")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            if events.isEmpty {
                // Show helpful message when no events in time period
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("No Bridge Openings")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                    
                    Text("Great news! No bridge openings recorded in this time period. Traffic flow was uninterrupted.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                    
                    // Suggest different time periods
                    VStack(alignment: .leading, spacing: 4) {
                        Text("💡 Try viewing a longer time period:")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                        
                        Text("• 7D or 30D for historical patterns")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text("• Check recent activity on Dashboard")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            } else if events.count >= 3 {
                // Traffic impact severity breakdown
                impactSeverityBreakdown
                
                // Impact severity detail section
                impactSeverityDetailSection
                
                // Rush hour impact analysis
                if hasRushHourEvents {
                    rushHourImpactAnalysis
                }
            } else {
                // Show analysis for 1-2 events
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        Text("Limited Data Analysis")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    
                    Text("Found \(events.count) bridge opening\(events.count == 1 ? "" : "s") in this period.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    // Show basic info about the events
                    if let firstEvent = events.first {
                        let impact = firstEvent.impactSeverity
                        
                        HStack {
                            Circle()
                                .fill(impact.color)
                                .frame(width: 12, height: 12)
                            
                            Text("\(impact.level) Impact")
                                .font(.caption)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Text("\(String(format: "%.0f", firstEvent.minutesOpen)) min")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                    }
                    
                    Text("Need 3+ events for comprehensive impact analysis")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .italic()
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
    
    @ViewBuilder
    private var impactWeeklyView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weekly Traffic Impact")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text("Weekly traffic impact analysis")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    @ViewBuilder
    private var impactDurationView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Duration Impact Analysis")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text("Duration impact analysis")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Impact Analysis Components
    
    @ViewBuilder
    private var impactSeverityBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Impact Severity Overview")
                .font(.caption)
                .fontWeight(.medium)
            
            let severityBreakdown = calculateSeverityBreakdown()
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                ForEach(severityBreakdown, id: \.severity) { breakdown in
                    VStack(spacing: 4) {
                        HStack {
                            Circle()
                                .fill(breakdown.color)
                                .frame(width: 8, height: 8)
                            Text(breakdown.severity)
                                .font(.caption2)
                                .fontWeight(.medium)
                            Spacer()
                        }
                        
                        HStack {
                            Text("\(breakdown.count)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(breakdown.color)
                            Spacer()
                            Text("\(Int(breakdown.percentage * 100))%")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(8)
                    .background(Color(.systemBackground))
                    .cornerRadius(6)
                }
            }
        }
    }
    
    @ViewBuilder
    private var impactSeverityDetailSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.pie")
                    .foregroundColor(.blue)
                Text("Impact Severity Breakdown")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            
            let severityBreakdown = calculateSeverityBreakdown()
            
            if severityBreakdown.allSatisfy({ $0.severity == "Minimal" || $0.severity == "Low" }) {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("No High-Impact Events")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                    
                    Text("All bridge openings in this period had minimal to moderate traffic impact. Great for commuters!")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    ForEach(severityBreakdown, id: \.severity) { breakdown in
                        VStack(spacing: 6) {
                            HStack {
                                Circle()
                                    .fill(breakdown.color)
                                    .frame(width: 12, height: 12)
                                
                                Text(breakdown.severity)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                
                                Spacer()
                            }
                            
                            HStack {
                                Text("\(breakdown.count)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(breakdown.color)
                                
                                Spacer()
                                
                                Text("\(Int(breakdown.percentage * 100))%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            ProgressView(value: breakdown.percentage, total: 1.0)
                                .progressViewStyle(LinearProgressViewStyle(tint: breakdown.color))
                                .frame(height: 4)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(breakdown.color.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
                
                // Severity explanation
                VStack(alignment: .leading, spacing: 4) {
                    Text("Impact Severity Criteria:")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text("• Minimal/Low: < 15 min, off-peak hours")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("• Moderate: 15-30 min or during rush hour")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("• High/Severe: 30+ min, especially during rush hour")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    @ViewBuilder
    private var rushHourImpactAnalysis: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "car.2.fill")
                    .foregroundColor(.red)
                Text("Rush Hour Impact")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            
            let rushHourEvents = events.filter { isRushHour($0.openDateTime) }
            let avgRushHourDuration = rushHourEvents.isEmpty ? 0 : 
                rushHourEvents.map(\.minutesOpen).reduce(0, +) / Double(rushHourEvents.count)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(rushHourEvents.count) events during rush hours")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("Average rush hour duration: \(String(format: "%.1f", avgRushHourDuration)) min")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                if avgRushHourDuration > 20 {
                    Text("⚠️ Significant rush hour delays expected")
                        .font(.caption2)
                        .foregroundColor(.red)
                } else {
                    Text("✅ Manageable rush hour impact")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
    
    // MARK: - Chart Components
    
    @ViewBuilder
    private var hourlyActivityChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Hourly Activity Pattern")
                .font(.caption)
                .fontWeight(.medium)
            
            if #available(iOS 16.0, *) {
                Chart(getHourlyData(), id: \.hour) { hourData in
                    BarMark(
                        x: .value("Hour", hourData.hour),
                        y: .value("Events", hourData.count)
                    )
                    .foregroundStyle(.blue)
                }
                .frame(height: 120)
                .chartXAxis {
                    AxisMarks(values: .stride(by: 4)) { hour in
                        AxisValueLabel {
                            Text("\(hour.as(Int.self) ?? 0)")
                                .font(.caption2)
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks { count in
                        AxisValueLabel {
                            Text("\(count.as(Int.self) ?? 0)")
                                .font(.caption2)
                        }
                    }
                }
            } else {
                Text("Chart requires iOS 16+")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    @ViewBuilder
    private var weeklyPatternChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Weekly Activity Pattern")
                .font(.caption)
                .fontWeight(.medium)
            
            if #available(iOS 16.0, *) {
                Chart(getWeeklyData(), id: \.day) { dayData in
                    AreaMark(
                        x: .value("Day", dayData.day),
                        y: .value("Events", dayData.count)
                    )
                    .foregroundStyle(
                        .linearGradient(
                            colors: [.blue.opacity(0.8), .blue.opacity(0.2)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .frame(height: 120)
                .chartXAxis {
                    AxisMarks { day in
                        AxisValueLabel {
                            Text(dayData(for: day.as(Int.self) ?? 0))
                                .font(.caption2)
                        }
                    }
                }
            } else {
                Text("Chart requires iOS 16+")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func getBridgeInfo() -> DrawbridgeInfo? {
        guard let firstEvent = events.first else { return nil }
        
        return DrawbridgeInfo(
            entityID: firstEvent.entityID,
            entityName: firstEvent.entityName,
            entityType: firstEvent.entityType,
            latitude: firstEvent.latitude,
            longitude: firstEvent.longitude
        )
    }
    
    private func getMostActiveHours() -> [HourData] {
        let hourGroups = Dictionary(grouping: events) { event in
            Calendar.current.component(.hour, from: event.openDateTime)
        }
        
        let maxCount = hourGroups.values.map(\.count).max() ?? 1
        
        return hourGroups.map { hour, events in
            HourData(hour: hour, count: events.count, maxCount: maxCount)
        }.sorted { $0.count > $1.count }
    }
    
    private func getHourlyData() -> [HourData] {
        let hourGroups = Dictionary(grouping: events) { event in
            Calendar.current.component(.hour, from: event.openDateTime)
        }
        
        let maxCount = hourGroups.values.map(\.count).max() ?? 1
        
        return (0...23).map { hour in
            HourData(hour: hour, count: hourGroups[hour]?.count ?? 0, maxCount: maxCount)
        }
    }
    
    private func getWeeklyData() -> [WeeklyData] {
        let weekdayGroups = Dictionary(grouping: events) { event in
            Calendar.current.component(.weekday, from: event.openDateTime)
        }
        
        return (1...7).map { weekday in
            WeeklyData(day: weekday, count: weekdayGroups[weekday]?.count ?? 0)
        }
    }
    
    private func calculateDurationRanges() -> [DurationRange] {
        let ranges = [
            (range: "< 15 min", min: 0.0, max: 15.0),
            (range: "15-30 min", min: 15.0, max: 30.0),
            (range: "30-60 min", min: 30.0, max: 60.0),
            (range: "> 60 min", min: 60.0, max: Double.infinity)
        ]
        
        return ranges.map { rangeInfo in
            let count = events.filter { event in
                event.minutesOpen >= rangeInfo.min && event.minutesOpen < rangeInfo.max
            }.count
            
            return DurationRange(range: rangeInfo.range, count: count)
        }
    }
    
    private func calculateSeverityBreakdown() -> [SeverityBreakdown] {
        let severityGroups = Dictionary(grouping: events) { event in
            event.impactSeverity.level
        }
        
        let total = events.count
        
        return severityGroups.map { severity, eventList in
            let count = eventList.count
            let percentage = total > 0 ? Double(count) / Double(total) : 0.0
            let color: Color
            
            switch severity {
            case "Minimal": color = .green
            case "Low": color = .blue
            case "Moderate": color = .orange
            case "High": color = .red
            case "Severe": color = .purple
            default: color = .gray
            }
            
            return SeverityBreakdown(
                severity: severity,
                count: count,
                percentage: percentage,
                color: color
            )
        }.sorted { $0.count > $1.count }
    }
    
    private var hasRushHourEvents: Bool {
        events.contains { isRushHour($0.openDateTime) }
    }
    
    private func isRushHour(_ date: Date) -> Bool {
        let hour = Calendar.current.component(.hour, from: date)
        return (hour >= 7 && hour <= 9) || (hour >= 17 && hour <= 19)
    }
    
    private func isWeekend(_ date: Date) -> Bool {
        let weekday = Calendar.current.component(.weekday, from: date)
        return weekday == 1 || weekday == 7
    }
    
    private func formatHour(_ hour: Int) -> String {
        if hour == 0 { return "12 AM" }
        if hour < 12 { return "\(hour) AM" }
        if hour == 12 { return "12 PM" }
        return "\(hour - 12) PM"
    }
    
    private func dayData(for weekday: Int) -> String {
        let days = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return days[safe: weekday] ?? "?"
    }
    
    private func probabilityColor(_ probability: Double) -> Color {
        switch probability {
        case 0.0..<0.3: return .green
        case 0.3..<0.6: return .orange
        case 0.6...1.0: return .red
        default: return .gray
        }
    }
    
    // MARK: - Computed Properties
    
    private var sectionTitle: String {
        switch analysisType {
        case .patterns: return "Pattern Analysis"
        case .cascade: return "Connection Analysis"
        case .predictions: return "Predictive Analysis"
        case .impact: return "Traffic Impact Analysis"
        }
    }
    
    private var analysisDescription: String {
        switch (analysisType, viewType) {
        case (.patterns, .activity): return "Activity patterns over time"
        case (.patterns, .weekly): return "Weekly opening patterns"
        case (.patterns, .duration): return "Duration patterns analysis"
        case (.cascade, .activity): return "Analyzing bridge connections"
        case (.cascade, .weekly): return "Weekly bridge connection patterns"
        case (.cascade, .duration): return "Connection duration effects"
        case (.predictions, .activity): return "Future activity predictions"
        case (.predictions, .weekly): return "Weekly prediction patterns"
        case (.predictions, .duration): return "Predicted durations"
        case (.impact, .activity): return "Traffic impact timeline"
        case (.impact, .weekly): return "Weekly traffic impact"
        case (.impact, .duration): return "Duration impact analysis"
        }
    }
    
    // MARK: - Cascade detection function for bridge detail views
    private func forceCascadeDetectionForDetail() async {
        print(" [CASCADE DETAIL]  FORCING CASCADE DETECTION FOR BRIDGE DETAIL...")
        
        let currentEvents = Array(allEvents.sorted { $0.openDateTime > $1.openDateTime }.prefix(500))
        
        await Task.detached(priority: .userInitiated) {
            let eventDTOs = currentEvents.map { event in
                DrawbridgeEvent(
                    entityType: event.entityType,
                    entityName: event.entityName,
                    entityID: event.entityID,
                    openDateTime: event.openDateTime,
                    closeDateTime: event.closeDateTime,
                    minutesOpen: event.minutesOpen,
                    latitude: event.latitude,
                    longitude: event.longitude
                )
            }
            
            let cascadeEventsDetected = CascadeDetectionEngine.detectCascadeEffects(from: eventDTOs)
            print(" [CASCADE DETAIL] Detected \(cascadeEventsDetected.count) cascade events!")
            
            await MainActor.run {
                for existingEvent in self.cascadeEvents {
                    self.modelContext.delete(existingEvent)
                }
                
                for cascadeEvent in cascadeEventsDetected {
                    self.modelContext.insert(cascadeEvent)
                }
                
                do {
                    try self.modelContext.save()
                    print(" [CASCADE DETAIL]  CASCADE EVENTS SAVED TO SWIFTDATA!")
                } catch {
                    print(" [CASCADE DETAIL] Failed to save: \(error)")
                }
            }
        }.value
    }

}

// MARK: - Supporting Data Models

struct HourData {
    let hour: Int
    let count: Int
    let maxCount: Int
}

struct WeeklyData: Identifiable {
    let id = UUID()
    let day: Int
    let count: Int
}

struct DurationRange {
    let range: String
    let count: Int
}

struct SeverityBreakdown {
    let severity: String
    let count: Int
    let percentage: Double
    let color: Color
}

// MARK: - Array Extension for Safe Access

extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    DynamicAnalysisSection(
        events: [],
        analysisType: .impact,
        viewType: .activity,
        bridgeName: "Test Bridge"
    )
    .padding()
}