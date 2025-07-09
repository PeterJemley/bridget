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

// MARK: - View Model for Dynamic Analysis

@MainActor
public final class DynamicAnalysisViewModel: ObservableObject {
    @Published public var isAnalyzing = false
    @Published public var analysisError: String?
    @Published public var cachedAnalysisData: AnalysisData?
    
    private let events: [DrawbridgeEvent]
    private let analysisType: AnalysisType
    private let viewType: ViewType
    private let bridgeName: String
    
    public init(events: [DrawbridgeEvent], analysisType: AnalysisType, viewType: ViewType, bridgeName: String) {
        self.events = events
        self.analysisType = analysisType
        self.viewType = viewType
        self.bridgeName = bridgeName
    }
    
    // MARK: - Analysis Data Structure
    
    public struct AnalysisData {
        public let hourlyData: [HourlyData]
        public let weeklyData: [WeeklyData]
        public let durationRanges: [DurationRange]
        public let severityBreakdown: [SeverityBreakdown]
        public let cascadeConnections: [CascadeConnection]
        public let predictions: [BridgePrediction]
        public let impactMetrics: ImpactMetrics
        
        public init(hourlyData: [HourlyData], weeklyData: [WeeklyData], durationRanges: [DurationRange], severityBreakdown: [SeverityBreakdown], cascadeConnections: [CascadeConnection], predictions: [BridgePrediction], impactMetrics: ImpactMetrics) {
            self.hourlyData = hourlyData
            self.weeklyData = weeklyData
            self.durationRanges = durationRanges
            self.severityBreakdown = severityBreakdown
            self.cascadeConnections = cascadeConnections
            self.predictions = predictions
            self.impactMetrics = impactMetrics
        }
        
        public struct HourlyData {
            public let hour: Int
            public let count: Int
            public let maxCount: Int
            
            public init(hour: Int, count: Int, maxCount: Int) {
                self.hour = hour
                self.count = count
                self.maxCount = maxCount
            }
        }
        
        public struct WeeklyData {
            public let day: Int
            public let count: Int
            
            public init(day: Int, count: Int) {
                self.day = day
                self.count = count
            }
        }
        
        public struct DurationRange {
            public let range: String
            public let count: Int
            public let percentage: Double
            
            public init(range: String, count: Int, percentage: Double) {
                self.range = range
                self.count = count
                self.percentage = percentage
            }
        }
        
        public struct CascadeConnection {
            public let sourceBridge: String
            public let targetBridge: String
            public let strength: Double
            public let delayMinutes: Double
            
            public init(sourceBridge: String, targetBridge: String, strength: Double, delayMinutes: Double) {
                self.sourceBridge = sourceBridge
                self.targetBridge = targetBridge
                self.strength = strength
                self.delayMinutes = delayMinutes
            }
        }
        
        public struct ImpactMetrics {
            public let totalEvents: Int
            public let highImpactCount: Int
            public let averageDelay: Double
            public let peakHour: String
            
            public init(totalEvents: Int, highImpactCount: Int, averageDelay: Double, peakHour: String) {
                self.totalEvents = totalEvents
                self.highImpactCount = highImpactCount
                self.averageDelay = averageDelay
                self.peakHour = peakHour
            }
        }
    }
    
    // MARK: - Public Interface
    
    public func performAnalysis() async {
        guard !events.isEmpty else {
            analysisError = "No events available for analysis"
            return
        }
        
        isAnalyzing = true
        analysisError = nil
        
        do {
            let analysisData = try await computeAnalysisData()
            cachedAnalysisData = analysisData
        } catch {
            analysisError = "Analysis failed: \(error.localizedDescription)"
        }
        
        isAnalyzing = false
    }
    
    // MARK: - Private Analysis Methods
    
    private func computeAnalysisData() async throws -> AnalysisData {
        return try await Task.detached(priority: .userInitiated) {
            // Perform heavy computation on background thread
            let hourlyData = await self.calculateHourlyData()
            let weeklyData = await self.calculateWeeklyData()
            let durationRanges = await self.calculateDurationRanges()
            let severityBreakdown = await self.calculateSeverityBreakdown()
            let cascadeConnections = await self.calculateCascadeConnections()
            let predictions = await self.calculatePredictions()
            let impactMetrics = await self.calculateImpactMetrics()
            
            return AnalysisData(
                hourlyData: hourlyData,
                weeklyData: weeklyData,
                durationRanges: durationRanges,
                severityBreakdown: severityBreakdown,
                cascadeConnections: cascadeConnections,
                predictions: predictions,
                impactMetrics: impactMetrics
            )
        }.value
    }
    
    private func calculateHourlyData() -> [AnalysisData.HourlyData] {
        let hourDistribution = Dictionary(grouping: events) { event in
            Calendar.current.component(.hour, from: event.openDateTime)
        }
        
        let maxCount = hourDistribution.values.map(\.count).max() ?? 1
        
        return (0..<24).map { hour in
            let count = hourDistribution[hour]?.count ?? 0
            return AnalysisData.HourlyData(hour: hour, count: count, maxCount: maxCount)
        }
    }
    
    private func calculateWeeklyData() -> [AnalysisData.WeeklyData] {
        let dayDistribution = Dictionary(grouping: events) { event in
            Calendar.current.component(.weekday, from: event.openDateTime)
        }
        
        return (1...7).map { day in
            let count = dayDistribution[day]?.count ?? 0
            return AnalysisData.WeeklyData(day: day, count: count)
        }
    }
    
    private func calculateDurationRanges() -> [AnalysisData.DurationRange] {
        let durations = events.map(\.minutesOpen).sorted()
        let total = Double(events.count)
        
        let ranges = [
            (0.0, 15.0, "0-15 min"),
            (15.0, 30.0, "15-30 min"),
            (30.0, 60.0, "30-60 min"),
            (60.0, 120.0, "1-2 hours"),
            (120.0, Double.infinity, "2+ hours")
        ]
        
        return ranges.map { min, max, label in
            let count = durations.filter { $0 >= min && $0 < max }.count
            let percentage = total > 0 ? Double(count) / total : 0.0
            return AnalysisData.DurationRange(range: label, count: count, percentage: percentage)
        }
    }
    
    private func calculateSeverityBreakdown() -> [SeverityBreakdown] {
        let severityGroups = Dictionary(grouping: events) { event in
            self.calculateEventSeverity(event)
        }
        
        let total = Double(events.count)
        
        return ["High", "Moderate", "Low", "Minimal"].map { severity in
            let count = severityGroups[severity]?.count ?? 0
            let percentage = total > 0 ? Double(count) / total : 0.0
            let color = self.severityColor(severity)
            return SeverityBreakdown(severity: severity, count: count, percentage: percentage, color: color)
        }
    }
    
    private func calculateCascadeConnections() -> [AnalysisData.CascadeConnection] {
        // Placeholder for cascade analysis
        return []
    }
    
    private func calculatePredictions() -> [BridgePrediction] {
        // Placeholder for prediction analysis
        return []
    }
    
    private func calculateImpactMetrics() -> AnalysisData.ImpactMetrics {
        let totalEvents = events.count
        let highImpactCount = events.filter { calculateEventSeverity($0) == "High" }.count
        let averageDelay = events.map(\.minutesOpen).reduce(0, +) / Double(totalEvents)
        let peakHour = getPeakHour()
        
        return AnalysisData.ImpactMetrics(
            totalEvents: totalEvents,
            highImpactCount: highImpactCount,
            averageDelay: averageDelay,
            peakHour: peakHour
        )
    }
    
    // MARK: - Helper Methods
    
    private func calculateEventSeverity(_ event: DrawbridgeEvent) -> String {
        let duration = event.minutesOpen
        let hour = Calendar.current.component(.hour, from: event.openDateTime)
        
        // High severity: long duration during peak hours
        if duration > 60 && (hour >= 7 && hour <= 9 || hour >= 16 && hour <= 18) {
            return "High"
        }
        // Moderate severity: medium duration or peak hours
        else if duration > 30 || (hour >= 7 && hour <= 9 || hour >= 16 && hour <= 18) {
            return "Moderate"
        }
        // Low severity: short duration during off-peak
        else if duration > 15 {
            return "Low"
        }
        // Minimal severity: very short duration
        else {
            return "Minimal"
        }
    }
    
    private func severityColor(_ severity: String) -> Color {
        switch severity {
        case "High": return .red
        case "Moderate": return .orange
        case "Low": return .yellow
        case "Minimal": return .green
        default: return .gray
        }
    }
    
    private func getPeakHour() -> String {
        let hourDistribution = Dictionary(grouping: events) { event in
            Calendar.current.component(.hour, from: event.openDateTime)
        }
        
        if let peakHour = hourDistribution.max(by: { $0.value.count < $1.value.count }) {
            return "\(peakHour.key):00"
        }
        return "Unknown"
    }
}

// MARK: - Main View

public struct DynamicAnalysisSection: View {
    public let events: [DrawbridgeEvent]
    public let analysisType: AnalysisType
    public let viewType: ViewType
    public let bridgeName: String
    
    @Environment(\.modelContext) private var modelContext
    @Query private var allEvents: [DrawbridgeEvent]
    @Query private var cascadeEvents: [CascadeEvent]
    
    @StateObject private var viewModel: DynamicAnalysisViewModel
    
    public init(events: [DrawbridgeEvent], analysisType: AnalysisType, viewType: ViewType, bridgeName: String) {
        self.events = events
        self.analysisType = analysisType
        self.viewType = viewType
        self.bridgeName = bridgeName
        self._viewModel = StateObject(wrappedValue: DynamicAnalysisViewModel(
            events: events,
            analysisType: analysisType,
            viewType: viewType,
            bridgeName: bridgeName
        ))
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
                if viewModel.isAnalyzing {
                    analysisLoadingView
                } else if let error = viewModel.analysisError {
                    analysisErrorView(error)
                } else if let analysisData = viewModel.cachedAnalysisData {
                    analysisContentView(analysisData)
                } else {
                    analysisPlaceholderView
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .onAppear {
            Task {
                await viewModel.performAnalysis()
            }
        }
        .onChange(of: events) { _, _ in
            Task {
                await viewModel.performAnalysis()
            }
        }
    }
    
    // MARK: - Loading View
    
    @ViewBuilder
    private var analysisLoadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Analyzing \(events.count) events...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    // MARK: - Error View
    
    @ViewBuilder
    private func analysisErrorView(_ error: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.title2)
            
            Text("Analysis Error")
                .font(.caption)
                .fontWeight(.medium)
            
            Text(error)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Retry") {
                Task {
                    await viewModel.performAnalysis()
                }
            }
            .font(.caption)
            .foregroundColor(.blue)
        }
        .padding()
    }
    
    // MARK: - Placeholder View
    
    @ViewBuilder
    private var analysisPlaceholderView: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar.fill")
                .foregroundColor(.secondary)
                .font(.title2)
            
            Text("No analysis data available")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    // MARK: - Analysis Content View
    
    @ViewBuilder
    private func analysisContentView(_ data: DynamicAnalysisViewModel.AnalysisData) -> some View {
        switch (analysisType, viewType) {
        case (.patterns, .activity):
            patternsActivityView(data)
        case (.patterns, .weekly):
            patternsWeeklyView(data)
        case (.patterns, .duration):
            patternsDurationView(data)
        case (.cascade, .activity):
            cascadeActivityView(data)
        case (.cascade, .weekly):
            cascadeWeeklyView(data)
        case (.cascade, .duration):
            cascadeDurationView(data)
        case (.predictions, .activity):
            predictionsActivityView(data)
        case (.predictions, .weekly):
            predictionsWeeklyView(data)
        case (.predictions, .duration):
            predictionsDurationView(data)
        case (.impact, .activity):
            impactActivityView(data)
        case (.impact, .weekly):
            impactWeeklyView(data)
        case (.impact, .duration):
            impactDurationView(data)
        }
    }
    
    // MARK: - Patterns Analysis Views
    
    @ViewBuilder
    private func patternsActivityView(_ data: DynamicAnalysisViewModel.AnalysisData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Activity Patterns")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            if events.count >= 5 {
                // Hourly activity chart
                hourlyActivityChart(data.hourlyData)
                
                // Most active hours
                VStack(alignment: .leading, spacing: 8) {
                    Text("Most Active Hours")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    ForEach(data.hourlyData.sorted(by: { $0.count > $1.count }).prefix(3), id: \.hour) { hourData in
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
    private func patternsWeeklyView(_ data: DynamicAnalysisViewModel.AnalysisData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weekly Patterns")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            if events.count >= 5 {
                // Weekly pattern chart
                weeklyPatternChart(data.weeklyData)
                
                // Day breakdown
                VStack(alignment: .leading, spacing: 8) {
                    Text("Day Breakdown")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    ForEach(data.weeklyData.sorted(by: { $0.count > $1.count }), id: \.day) { dayData in
                        HStack {
                            Text(dayName(for: dayData.day))
                                .font(.caption)
                                .frame(width: 80, alignment: .leading)
                            
                            ProgressView(value: Double(dayData.count), total: Double(data.weeklyData.map(\.count).max() ?? 1))
                                .progressViewStyle(LinearProgressViewStyle(tint: .green))
                            
                            Text("\(dayData.count)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } else {
                Text("Need at least 5 events for weekly pattern analysis")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
    }
    
    @ViewBuilder
    private func patternsDurationView(_ data: DynamicAnalysisViewModel.AnalysisData) -> some View {
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
                    
                    ForEach(data.durationRanges, id: \.range) { rangeData in
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
    private func cascadeActivityView(_ data: DynamicAnalysisViewModel.AnalysisData) -> some View {
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
            
                Text("Analyzing how this bridge's openings connect to other Seattle bridges...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    @ViewBuilder
    private func cascadeWeeklyView(_ data: DynamicAnalysisViewModel.AnalysisData) -> some View {
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
    private func cascadeDurationView(_ data: DynamicAnalysisViewModel.AnalysisData) -> some View {
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
    private func predictionsActivityView(_ data: DynamicAnalysisViewModel.AnalysisData) -> some View {
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
    private func predictionsWeeklyView(_ data: DynamicAnalysisViewModel.AnalysisData) -> some View {
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
    private func predictionsDurationView(_ data: DynamicAnalysisViewModel.AnalysisData) -> some View {
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
    private func impactActivityView(_ data: DynamicAnalysisViewModel.AnalysisData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Traffic Impact Timeline")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            if events.count >= 5 {
                // Impact severity breakdown
                impactSeverityBreakdown(data.severityBreakdown)
                
                // Impact metrics
                VStack(alignment: .leading, spacing: 8) {
                    Text("Impact Metrics")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total Events")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("\(data.impactMetrics.totalEvents)")
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("High Impact")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("\(data.impactMetrics.highImpactCount)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Avg Delay")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("\(String(format: "%.0f", data.impactMetrics.averageDelay)) min")
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(8)
            } else {
                Text("Need at least 5 events for impact analysis")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
    }
    
    @ViewBuilder
    private func impactWeeklyView(_ data: DynamicAnalysisViewModel.AnalysisData) -> some View {
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
    private func impactDurationView(_ data: DynamicAnalysisViewModel.AnalysisData) -> some View {
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
    private func impactSeverityBreakdown(_ breakdown: [SeverityBreakdown]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Impact Severity Overview")
                .font(.caption)
                .fontWeight(.medium)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                ForEach(breakdown, id: \.severity) { breakdown in
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
    
    // MARK: - Chart Components
    
    @ViewBuilder
    private func hourlyActivityChart(_ hourlyData: [DynamicAnalysisViewModel.AnalysisData.HourlyData]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Hourly Activity Pattern")
                .font(.caption)
                .fontWeight(.medium)
            
            if #available(iOS 16.0, *) {
                Chart(hourlyData, id: \.hour) { hourData in
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
    private func weeklyPatternChart(_ weeklyData: [DynamicAnalysisViewModel.AnalysisData.WeeklyData]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Weekly Activity Pattern")
                .font(.caption)
                .fontWeight(.medium)
            
            if #available(iOS 16.0, *) {
                Chart(weeklyData, id: \.day) { dayData in
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
                            Text(dayName(for: day.as(Int.self) ?? 0))
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
    
    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date)
    }
    
    private func dayName(for day: Int) -> String {
        let formatter = DateFormatter()
        return formatter.weekdaySymbols[day - 1]
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
        SecurityLogger.bridge("FORCING CASCADE DETECTION...")
        
        let currentEvents = Array(allEvents.sorted { $0.openDateTime > $1.openDateTime }.prefix(500))
        let eventDTOs = currentEvents.toDTOs
        
        await Task.detached(priority: .userInitiated) {
            SecurityLogger.bridge("Running cascade detection on \(eventDTOs.count) events...")
            let cascadeEvents = CascadeDetectionEngine.detectCascadeEffects(from: eventDTOs)
            SecurityLogger.bridge("Detected \(cascadeEvents.count) cascade events!")
            
            await MainActor.run {
                SecurityLogger.bridge("SAVING \(cascadeEvents.count) CASCADE EVENTS TO SWIFTDATA")
                
                for existingEvent in self.cascadeEvents {
                    self.modelContext.delete(existingEvent)
                }
                
                for cascadeEvent in cascadeEvents {
                    self.modelContext.insert(cascadeEvent)
                }
                
                do {
                    try self.modelContext.save()
                    SecurityLogger.bridge("CASCADE EVENTS SAVED! UI should update now.")
                } catch {
                    SecurityLogger.error("Failed to save cascade events", error: error)
                }
            }
        }.value
    }
}

// MARK: - Supporting Types

public struct SeverityBreakdown {
    public let severity: String
    public let count: Int
    public let percentage: Double
    public let color: Color
    
    public init(severity: String, count: Int, percentage: Double, color: Color) {
        self.severity = severity
        self.count = count
        self.percentage = percentage
        self.color = color
    }
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