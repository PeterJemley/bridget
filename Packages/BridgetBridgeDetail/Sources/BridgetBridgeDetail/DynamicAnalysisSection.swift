//
//  DynamicAnalysisSection.swift
//  BridgetBridgeDetail
//
//  Created by Peter Jemley on 6/19/25.
//

import SwiftUI
import SwiftData
import BridgetCore
import BridgetSharedUI

public struct DynamicAnalysisSection: View {
    public let events: [DrawbridgeEvent]
    public let analysisType: AnalysisType
    public let viewType: ViewType
    public let bridgeName: String
    
    // PHASE 2: Add cascade data
    @Environment(\.modelContext) private var modelContext
    @Query private var allEvents: [DrawbridgeEvent]
    @Query private var cascadeEvents: [CascadeEvent]
    @State private var analytics: [BridgeAnalytics] = []
    @State private var isAnalyzing = false
    @State private var calculatedPrediction: BridgePrediction?
    
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
            
            // Dynamic content based on analysis type
            Group {
                switch analysisType {
                case .cascade:
                    cascadeAnalysisContent
                case .patterns:
                    patternsAnalysisContent
                case .predictions:
                    predictionsAnalysisContent
                case .impact:
                    impactAnalysisContent
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .onAppear {
            calculateAnalytics()
        }
    }
    
    // MARK: - PHASE 2: Cascade Analysis Content
    
    private var cascadeAnalysisContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            if isAnalyzing {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Analyzing cascade patterns...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                switch viewType {
                case .activity:
                    cascadeActivityView
                case .weekly:
                    cascadeWeeklyView
                case .duration:
                    cascadeDurationView
                }
            }
        }
    }
    
    private var cascadeActivityView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cascade Activity Timeline")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            // Real-time cascade alerts
            if !currentCascadeAlerts.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("🚨 Active Cascade Alerts")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                    
                    ForEach(currentCascadeAlerts.prefix(3), id: \.targetBridge) { alert in
                        cascadeAlertRow(alert)
                    }
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Cascade influence metrics
            if let bridgeAnalytics = currentBridgeAnalytics {
                cascadeMetricsView(bridgeAnalytics)
            }
            
            // Recent cascade events
            if !recentCascadeEvents.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent Cascade Events")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    ForEach(recentCascadeEvents.prefix(5), id: \.id) { cascade in
                        cascadeEventRow(cascade)
                    }
                }
            }
        }
    }
    
    private var cascadeWeeklyView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Cascade Patterns")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            if let analytics = currentBridgeAnalytics {
                weeklyPatternGrid(analytics)
            }
            
            // Day-of-week cascade analysis
            Text("Cascade frequency varies by day:")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ForEach(weeklyPattern, id: \.day) { pattern in
                HStack {
                    Text(pattern.day)
                        .font(.caption)
                        .frame(width: 30, alignment: .leading)
                    
                    ProgressView(value: pattern.frequency, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    
                    Text("\(Int(pattern.frequency * 100))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var cascadeDurationView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cascade Duration Effects")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            if let analytics = currentBridgeAnalytics {
                durationEffectsGrid(analytics)
            }
            
            // Duration correlation analysis
            Text("How cascade effects influence opening durations:")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ForEach(durationEffects, id: \.type) { effect in
                HStack {
                    Circle()
                        .fill(effect.color)
                        .frame(width: 8, height: 8)
                    
                    Text(effect.type)
                        .font(.caption)
                    
                    Spacer()
                    
                    Text(effect.effect)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Cascade Helper Views
    
    private func cascadeAlertRow(_ alert: CascadeAlert) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.caption)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(alert.targetBridge) opening expected")
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text("in \(alert.timeUntilExpected) • \(alert.probabilityText) probability")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
    
    private func cascadeMetricsView(_ analytics: BridgeAnalytics) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
            StatCard(
                title: "Cascade Influence",
                value: String(format: "%.1f%%", analytics.cascadeInfluence * 100),
                icon: "arrow.branch",
                color: analytics.cascadeInfluence > 0.5 ? .red : .blue
            )
            
            StatCard(
                title: "Susceptibility",
                value: String(format: "%.1f%%", analytics.cascadeSusceptibility * 100),
                icon: "target",
                color: analytics.cascadeSusceptibility > 0.5 ? .orange : .green
            )
            
            if analytics.cascadeProbability > 0 {
                StatCard(
                    title: "Cascade Probability",
                    value: String(format: "%.1f%%", analytics.cascadeProbability * 100),
                    icon: "percent",
                    color: .purple
                )
            }
            
            if analytics.cascadeDelay > 0 {
                StatCard(
                    title: "Avg Cascade Delay",
                    value: String(format: "%.0f min", analytics.cascadeDelay),
                    icon: "clock",
                    color: .indigo
                )
            }
        }
    }
    
    private func cascadeEventRow(_ cascade: CascadeEvent) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(cascade.triggerBridgeName) → \(cascade.targetBridgeName)")
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text("\(Int(cascade.delayMinutes)) min delay • \(cascade.cascadeType)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(String(format: "%.1f", cascade.cascadeStrength))
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(cascadeStrengthColor(cascade.cascadeStrength).opacity(0.2))
                .foregroundColor(cascadeStrengthColor(cascade.cascadeStrength))
                .cornerRadius(4)
        }
    }
    
    private func weeklyPatternGrid(_ analytics: BridgeAnalytics) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
            StatCard(
                title: "Weekend Cascade",
                value: analytics.isWeekendPattern ? "Higher" : "Lower",
                icon: "calendar.day.weekend",
                color: analytics.isWeekendPattern ? .green : .gray
            )
            
            StatCard(
                title: "Summer Effect",
                value: analytics.isSummerPattern ? "+20%" : "Normal",
                icon: "sun.max",
                color: analytics.isSummerPattern ? .orange : .blue
            )
        }
    }
    
    private func durationEffectsGrid(_ analytics: BridgeAnalytics) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
            StatCard(
                title: "Trigger Effect",
                value: analytics.cascadeInfluence > 0.5 ? "Longer" : "Normal",
                icon: "arrow.up.right",
                color: analytics.cascadeInfluence > 0.5 ? .red : .gray
            )
            
            StatCard(
                title: "Response Effect",
                value: analytics.cascadeSusceptibility > 0.5 ? "Shorter" : "Normal",
                icon: "arrow.down.left",
                color: analytics.cascadeSusceptibility > 0.5 ? .green : .gray
            )
        }
    }
    
    // MARK: - Other Analysis Types (Patterns, Predictions, Impact)
    
    private var patternsAnalysisContent: some View {
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
            
            // Placeholder for future patterns implementation
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray5))
                .frame(height: 120)
                .overlay(
                    Text("Patterns Analysis\nComing in Phase 3")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                )
        }
    }
    
    private var predictionsAnalysisContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            if isAnalyzing {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Calculating predictions...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                switch viewType {
                case .activity:
                    predictionsActivityView
                case .weekly:
                    predictionsWeeklyView
                case .duration:
                    predictionsDurationView
                }
            }
        }
    }
    
    private var impactAnalysisContent: some View {
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
            
            // Placeholder for future impact implementation
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray5))
                .frame(height: 120)
                .overlay(
                    Text("Neural Impact Analysis\nComing in Phase 4")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                )
        }
    }
    
    private var predictionsActivityView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Prediction")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            if let prediction = currentPrediction {
                predictionDetailsCard(prediction)
            } else {
                Text("No prediction data available")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
            
            // Show prediction analytics if available
            if let analytics = currentBridgeAnalytics {
                predictionAnalyticsGrid(analytics)
            }
        }
    }
    
    private var predictionsWeeklyView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Prediction Patterns")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            if !weeklyPredictionPattern.isEmpty {
                ForEach(weeklyPredictionPattern, id: \.day) { pattern in
                    HStack {
                        Text(pattern.day)
                            .font(.caption)
                            .frame(width: 30, alignment: .leading)
                        
                        ProgressView(value: pattern.probability, total: 1.0)
                            .progressViewStyle(LinearProgressViewStyle(tint: probabilityColor(pattern.probability)))
                        
                        Text("\(Int(pattern.probability * 100))%")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                Text("Not enough data for weekly patterns")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
    }
    
    private var predictionsDurationView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Duration Predictions")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            if let prediction = currentPrediction {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Expected Duration:")
                        Spacer()
                        Text(prediction.durationText)
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Confidence:")
                        Spacer()
                        Text(prediction.confidenceText)
                            .foregroundColor(confidenceColor(prediction.confidence))
                    }
                    
                    Text("Reasoning:")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Text(prediction.reasoning)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.leading, 8)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
    }
    
    
    private func predictionDetailsCard(_ prediction: BridgePrediction) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(probabilityColor(prediction.probability))
                    .frame(width: 12, height: 12)
                
                Text("Opening Probability")
                    .font(.caption)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(prediction.probabilityText)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(probabilityColor(prediction.probability))
            }
            
            HStack {
                Text("Time Frame:")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(prediction.timeFrame)
                    .font(.caption2)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("Duration: \(prediction.durationText)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Text(prediction.reasoning)
                .font(.caption2)
                .foregroundColor(.secondary)
                .italic()
        }
        .padding()
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(probabilityColor(prediction.probability).opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(8)
    }
    
    private func predictionAnalyticsGrid(_ analytics: BridgeAnalytics) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
            StatCard(
                title: "Seasonal Trend",
                value: analytics.trendComponent > 0 ? "↗ Rising" : "↘ Falling",
                icon: analytics.trendComponent > 0 ? "arrow.up.right" : "arrow.down.right",
                color: analytics.trendComponent > 0 ? .green : .red
            )
            
            StatCard(
                title: "Pattern Type",
                value: patternTypeText(analytics),
                icon: patternTypeIcon(analytics),
                color: .blue
            )
            
            StatCard(
                title: "Confidence",
                value: String(format: "%.0f%%", analytics.confidence * 100),
                icon: "checkmark.seal",
                color: confidenceColor(analytics.confidence)
            )
            
            StatCard(
                title: "Data Points",
                value: "\(analytics.openingCount)",
                icon: "chart.bar",
                color: .purple
            )
        }
    }
    
    
    private func probabilityColor(_ probability: Double) -> Color {
        switch probability {
        case 0.0..<0.3: return .green
        case 0.3..<0.6: return .orange
        case 0.6...1.0: return .red
        default: return .gray
        }
    }
    
    private func confidenceColor(_ confidence: Double) -> Color {
        switch confidence {
        case 0.0..<0.3: return .red
        case 0.3..<0.7: return .orange
        case 0.7...1.0: return .green
        default: return .gray
        }
    }
    
    private func patternTypeText(_ analytics: BridgeAnalytics) -> String {
        if analytics.isWeekendPattern { return "Weekend" }
        if analytics.isSummerPattern { return "Summer" }
        if analytics.isRushHourPattern { return "Rush Hour" }
        return "Standard"
    }
    
    private func patternTypeIcon(_ analytics: BridgeAnalytics) -> String {
        if analytics.isWeekendPattern { return "calendar.day.weekend" }
        if analytics.isSummerPattern { return "sun.max" }
        if analytics.isRushHourPattern { return "car.2" }
        return "clock"
    }

    // MARK: - Data Processing
    
    private func calculateAnalytics() {
        isAnalyzing = true
        
        Task {
            let calculatedAnalytics = BridgeAnalyticsCalculator.calculateAnalytics(from: allEvents)
            
            // Calculate current prediction if needed for predictions view
            var prediction: BridgePrediction?
            if !events.isEmpty {
                let bridgeInfo = DrawbridgeInfo(
                    entityID: events.first?.entityID ?? 0,
                    entityName: bridgeName,
                    entityType: events.first?.entityType ?? "Bridge",
                    latitude: events.first?.latitude ?? 0.0,
                    longitude: events.first?.longitude ?? 0.0
                )
                
                prediction = BridgeAnalytics.getCurrentPrediction(
                    for: bridgeInfo,
                    from: calculatedAnalytics
                )
            }
            
            await MainActor.run {
                self.analytics = calculatedAnalytics
                self.calculatedPrediction = prediction
                self.isAnalyzing = false
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var currentPrediction: BridgePrediction? {
        calculatedPrediction
    }
    
    private var currentBridgeAnalytics: BridgeAnalytics? {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.month, .weekday, .hour], from: now)
        
        return analytics.first { analytics in
            analytics.entityName == bridgeName &&
            analytics.month == components.month &&
            analytics.dayOfWeek == components.weekday &&
            analytics.hour == components.hour
        }
    }
    
    private var currentCascadeAlerts: [CascadeAlert] {
        guard let bridgeInfo = DrawbridgeEvent.getUniqueBridges(allEvents).first(where: { $0.entityName == bridgeName }) else {
            return []
        }
        
        let bridgeInfoObj = DrawbridgeInfo(
            entityID: bridgeInfo.entityID,
            entityName: bridgeInfo.entityName,
            entityType: bridgeInfo.entityType,
            latitude: bridgeInfo.latitude,
            longitude: bridgeInfo.longitude
        )
        
        let recentEvents = allEvents.filter { event in
            Date().timeIntervalSince(event.openDateTime) < 1800 // Last 30 minutes
        }
        
        return CascadeInsights.getCascadeAlerts(
            recentEvents: recentEvents,
            cascadeEvents: cascadeEvents,
            bridgeInfo: [bridgeInfoObj]
        ).filter { $0.targetBridge == bridgeName }
    }
    
    private var recentCascadeEvents: [CascadeEvent] {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        
        return cascadeEvents.filter { cascade in
            (cascade.triggerBridgeName == bridgeName || cascade.targetBridgeName == bridgeName) &&
            cascade.triggerTime >= sevenDaysAgo
        }.sorted { $0.triggerTime > $1.triggerTime }
    }
    
    private var weeklyPattern: [WeeklyPatternData] {
        let calendar = Calendar.current
        let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        
        return dayNames.enumerated().map { index, dayName in
            let dayCascades = cascadeEvents.filter { 
                ($0.triggerBridgeName == bridgeName || $0.targetBridgeName == bridgeName) &&
                $0.dayOfWeek == index + 1
            }
            
            let frequency = Double(dayCascades.count) / Double(max(cascadeEvents.count, 1))
            
            return WeeklyPatternData(day: dayName, frequency: frequency)
        }
    }
    
    private var durationEffects: [DurationEffectData] {
        return [
            DurationEffectData(type: "High Influence", effect: "+15% longer", color: .red),
            DurationEffectData(type: "High Susceptibility", effect: "-10% shorter", color: .green),
            DurationEffectData(type: "Cascade Target", effect: "Variable", color: .blue),
            DurationEffectData(type: "Independent", effect: "Baseline", color: .gray)
        ]
    }
    
    private var weeklyPredictionPattern: [WeeklyPredictionData] {
        let calendar = Calendar.current
        let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        
        return dayNames.enumerated().compactMap { index, dayName in
            let dayAnalytics = analytics.filter { $0.dayOfWeek == index + 1 }
            guard !dayAnalytics.isEmpty else { return nil }
            
            let avgProbability = dayAnalytics.map(\.probabilityOfOpening).reduce(0, +) / Double(dayAnalytics.count)
            
            return WeeklyPredictionData(day: dayName, probability: avgProbability)
        }
    }
    
    // MARK: - Helper Functions
    
    private func cascadeStrengthColor(_ strength: Double) -> Color {
        switch strength {
        case 0.0..<0.3: return .gray
        case 0.3..<0.6: return .blue
        case 0.6..<0.8: return .orange
        case 0.8...1.0: return .red
        default: return .gray
        }
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
        case (.cascade, .activity): return "Real-time cascade detection"
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

// MARK: - Supporting Data Models

struct WeeklyPatternData {
    let day: String
    let frequency: Double
}

struct DurationEffectData {
    let type: String
    let effect: String
    let color: Color
}

struct WeeklyPredictionData {
    let day: String
    let probability: Double
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
        analysisType: .cascade,
        viewType: .activity,
        bridgeName: "Test Bridge"
    )
    .padding()
}