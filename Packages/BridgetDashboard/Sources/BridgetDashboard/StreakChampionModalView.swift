//
//  StreakChampionModalView.swift
//  BridgetDashboard
//
//  Created by AI Assistant on 1/15/25.
//

import SwiftUI
import BridgetCore

/**
 * Comprehensive modal view for displaying Weekly Streak Champion analytics
 * 
 * This view provides detailed drill-down analytics for the bridge with the longest
 * current streak, including historical patterns, predictions, and bridge comparisons.
 * 
 * Features:
 * - Champion header with confidence indicators
 * - Current streak visualization
 * - Historical analysis with timeline
 * - Next opening predictions
 * - Bridge ranking comparisons
 * 
 * Usage:
 * ```swift
 * StreakChampionModalView(champion: champion, allEvents: events)
 * ```
 */
public struct StreakChampionModalView: View {
    public let champion: StreakAnalytics.WeeklyChampion
    public let allEvents: [DrawbridgeEvent]
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTimeframe: TimeframeFilter = .week
    @State private var showingPredictionDetails = false
    
    public init(champion: StreakAnalytics.WeeklyChampion, allEvents: [DrawbridgeEvent]) {
        self.champion = champion
        self.allEvents = allEvents
    }
    
    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Section
                    championHeaderSection
                    
                    // Current Streak Section
                    currentStreakSection
                    
                    // Historical Analysis Section
                    historicalAnalysisSection
                    
                    // Prediction Section
                    predictionSection
                    
                    // Bridge Comparison Section
                    bridgeComparisonSection
                }
                .padding()
            }
            .navigationTitle("Weekly Champion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingPredictionDetails) {
            PredictionDetailsView(champion: champion, allEvents: allEvents)
        }
    }
    
    // MARK: - Header Section
    
    /**
     * Champion header section with trophy icon, bridge name, and confidence indicator
     * 
     * Displays the champion bridge with visual emphasis and confidence metrics
     * to provide immediate context about the streak's reliability.
     */
    private var championHeaderSection: some View {
        VStack(spacing: 16) {
            // Champion Badge
            VStack(spacing: 8) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.yellow)
                    .shadow(color: .yellow.opacity(0.3), radius: 8)
                
                Text("🏆 Weekly Champion")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            
            // Bridge Name and Stats
            VStack(spacing: 4) {
                Text(champion.bridgeName)
                    .font(.title)
                    .fontWeight(.heavy)
                    .foregroundColor(.primary)
                
                Text(champion.historicalContext)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Confidence Indicator
            HStack {
                Text("Confidence:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ProgressView(value: champion.confidenceLevel)
                    .progressViewStyle(LinearProgressViewStyle(tint: confidenceColor))
                    .frame(width: 100)
                
                Text("\(Int(champion.confidenceLevel * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(confidenceColor)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Current Streak Section
    
    /**
     * Current streak section showing duration and start time
     * 
     * Displays the current streak duration in a prominent format with
     * contextual information about when the streak began.
     */
    private var currentStreakSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.blue)
                Text("Current Streak")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            HStack(alignment: .bottom, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatStreakHours(champion.streakHours))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                    
                    Text("without opening")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Started")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let startDate = calculateStreakStartDate() {
                        Text(startDate, style: .relative)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 1)
    }
    
    // MARK: - Historical Analysis Section
    
    /**
     * Historical analysis section with statistics and timeline
     * 
     * Provides comprehensive historical context including longest streak,
     * average performance, and recent streak patterns in a visual timeline.
     */
    private var historicalAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.green)
                Text("Historical Analysis")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            let streakData = StreakAnalytics.calculateStreakData(
                for: champion.bridgeName,
                events: allEvents.filter { $0.entityName == champion.bridgeName },
                lookbackDays: 30
            )
            
            VStack(spacing: 12) {
                // Historical Stats Grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    StatCard(
                        title: "Longest Streak",
                        value: streakData.formattedLongestStreak,
                        icon: "trophy",
                        color: .orange
                    )
                    
                    StatCard(
                        title: "Average Streak",
                        value: formatStreakHours(streakData.averageStreakHours),
                        icon: "chart.bar",
                        color: .green
                    )
                    
                    StatCard(
                        title: "Total Streaks",
                        value: "\(streakData.streakCount)",
                        icon: "number",
                        color: .purple
                    )
                    
                    StatCard(
                        title: "Success Rate",
                        value: "\(Int(streakData.confidenceLevel * 100))%",
                        icon: "checkmark.circle",
                        color: .blue
                    )
                }
                
                // Streak Timeline
                if !streakData.historicalPatterns.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recent Streaks")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(Array(streakData.historicalPatterns.prefix(5).enumerated()), id: \.offset) { index, pattern in
                                    StreakTimelineCard(pattern: pattern, isCurrent: index == 0)
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 1)
    }
    
    // MARK: - Prediction Section
    
    /**
     * Prediction section showing next expected opening
     * 
     * Displays AI-powered predictions for when the bridge is likely to open next,
     * including confidence levels and methodology details.
     */
    private var predictionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "crystal.ball")
                    .foregroundColor(.purple)
                Text("Next Opening Prediction")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                
                Button("Details") {
                    showingPredictionDetails = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            let streakData = StreakAnalytics.calculateStreakData(
                for: champion.bridgeName,
                events: allEvents.filter { $0.entityName == champion.bridgeName }
            )
            
            if let predictedDate = streakData.nextPredictedOpening {
                VStack(spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Predicted Opening")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text(predictedDate, style: .date)
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Text(predictedDate, style: .time)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("In")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(predictedDate, style: .relative)
                                .font(.headline)
                                .fontWeight(.medium)
                                .foregroundColor(.purple)
                        }
                    }
                    
                    // Confidence Bar
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Prediction Confidence")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(streakData.confidenceLevel * 100))%")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        
                        ProgressView(value: streakData.confidenceLevel)
                            .progressViewStyle(LinearProgressViewStyle(tint: .purple))
                    }
                }
            } else {
                Text("Insufficient data for prediction")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 1)
    }
    
    // MARK: - Bridge Comparison Section
    
    /**
     * Bridge comparison section showing rankings
     * 
     * Displays how all bridges compare in terms of current streak duration,
     * with the champion highlighted and ranked positions shown.
     */
    private var bridgeComparisonSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "list.bullet")
                    .foregroundColor(.indigo)
                Text("Bridge Rankings")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            let bridgeRankings = calculateBridgeRankings()
            
            VStack(spacing: 8) {
                ForEach(Array(bridgeRankings.enumerated()), id: \.offset) { index, ranking in
                    BridgeRankingRow(
                        rank: index + 1,
                        bridgeName: ranking.bridgeName,
                        streakHours: ranking.streakHours,
                        isChampion: ranking.bridgeName == champion.bridgeName
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 1)
    }
    
    // MARK: - Helper Methods
    
    /**
     * Get confidence color based on confidence level
     * 
     * Returns appropriate color for confidence indicators:
     * - Green: High confidence (80%+)
     * - Orange: Medium confidence (60-79%)
     * - Red: Low confidence (<60%)
     */
    private var confidenceColor: Color {
        switch champion.confidenceLevel {
        case 0.8...:
            return .green
        case 0.6..<0.8:
            return .orange
        default:
            return .red
        }
    }
    
    /**
     * Format streak hours for display
     * 
     * Converts hours to human-readable format:
     * - Less than 24 hours: "Xh"
     * - 24+ hours: "Xd Xh"
     * 
     * - Parameter hours: Duration in hours
     * - Returns: Formatted string
     */
    private func formatStreakHours(_ hours: Double) -> String {
        if hours < 24 {
            return "\(Int(hours))h"
        } else {
            let days = Int(hours / 24)
            let remainingHours = Int(hours.truncatingRemainder(dividingBy: 24))
            return "\(days)d \(remainingHours)h"
        }
    }
    
    /**
     * Calculate when the current streak started
     * 
     * - Returns: Date when the streak began, or nil if no data
     */
    private func calculateStreakStartDate() -> Date? {
        let bridgeEvents = allEvents.filter { $0.entityName == champion.bridgeName }
        let sortedEvents = bridgeEvents.sorted { $0.openDateTime > $1.openDateTime }
        guard let lastEvent = sortedEvents.first else { return nil }
        
        return Calendar.current.date(byAdding: .hour, value: -Int(champion.streakHours), to: Date())
    }
    
    /**
     * Calculate bridge rankings by current streak duration
     * 
     * - Returns: Array of bridge rankings sorted by streak duration (descending)
     */
    private func calculateBridgeRankings() -> [(bridgeName: String, streakHours: Double)] {
        let bridgeGroups = Dictionary(grouping: allEvents, by: \.entityName)
        var rankings: [(bridgeName: String, streakHours: Double)] = []
        
        for (bridgeName, bridgeEvents) in bridgeGroups {
            let streakData = StreakAnalytics.calculateStreakData(
                for: bridgeName,
                events: bridgeEvents,
                lookbackDays: 7
            )
            rankings.append((bridgeName: bridgeName, streakHours: streakData.currentStreakHours))
        }
        
        return rankings.sorted { $0.streakHours > $1.streakHours }
    }
}

// MARK: - Supporting Views

/**
 * Statistic card component for displaying metrics
 * 
 * Reusable component for showing key statistics with icons and colors
 */
private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

/**
 * Timeline card for displaying streak patterns
 * 
 * Shows individual streak periods in a horizontal scrollable timeline
 */
private struct StreakTimelineCard: View {
    let pattern: StreakAnalytics.StreakPattern
    let isCurrent: Bool
    
    var body: some View {
        VStack(spacing: 6) {
            Text(formatStreakHours(pattern.durationHours))
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(isCurrent ? .blue : .primary)
            
            Text(pattern.startDate, style: .date)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            if isCurrent {
                Text("Current")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .frame(width: 80)
        .padding()
        .background(isCurrent ? Color.blue.opacity(0.1) : Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private func formatStreakHours(_ hours: Double) -> String {
        if hours < 24 {
            return "\(Int(hours))h"
        } else {
            let days = Int(hours / 24)
            return "\(days)d"
        }
    }
}

/**
 * Bridge ranking row component
 * 
 * Displays a single bridge in the ranking list with highlighting for the champion
 */
private struct BridgeRankingRow: View {
    let rank: Int
    let bridgeName: String
    let streakHours: Double
    let isChampion: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank
            Text("\(rank)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(isChampion ? .yellow : .secondary)
                .frame(width: 30)
            
            // Bridge Name
            Text(bridgeName)
                .font(.subheadline)
                .fontWeight(isChampion ? .bold : .medium)
                .foregroundColor(.primary)
            
            Spacer()
            
            // Streak Hours
            Text(formatStreakHours(streakHours))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(isChampion ? .blue : .secondary)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(isChampion ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(6)
    }
    
    private func formatStreakHours(_ hours: Double) -> String {
        if hours < 24 {
            return "\(Int(hours))h"
        } else {
            let days = Int(hours / 24)
            let remainingHours = Int(hours.truncatingRemainder(dividingBy: 24))
            return "\(days)d \(remainingHours)h"
        }
    }
}

// MARK: - Prediction Details View

/**
 * Modal view explaining prediction methodology
 * 
 * Provides transparency about how predictions are calculated and
 * what factors influence confidence levels.
 */
private struct PredictionDetailsView: View {
    let champion: StreakAnalytics.WeeklyChampion
    let allEvents: [DrawbridgeEvent]
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Prediction Methodology")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        PredictionMethodCard(
                            title: "Historical Pattern Analysis",
                            description: "Analyzes past opening patterns to identify recurring time intervals and seasonal variations.",
                            icon: "chart.line.uptrend.xyaxis",
                            color: .blue
                        )
                        
                        PredictionMethodCard(
                            title: "Statistical Modeling",
                            description: "Uses standard deviation and coefficient of variation to assess prediction reliability.",
                            icon: "function",
                            color: .green
                        )
                        
                        PredictionMethodCard(
                            title: "Confidence Scoring",
                            description: "Combines data density, pattern consistency, and historical accuracy for confidence assessment.",
                            icon: "checkmark.shield",
                            color: .orange
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Prediction Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

/**
 * Method card component for prediction details
 * 
 * Displays individual prediction methodology components with descriptions
 */
private struct PredictionMethodCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Supporting Types

/**
 * Timeframe filter options for analytics
 */
private enum TimeframeFilter: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case quarter = "Quarter"
}

#Preview {
    let sampleChampion = StreakAnalytics.WeeklyChampion(
        bridgeName: "Fremont Bridge",
        bridgeID: 3,
        streakHours: 72.5,
        confidenceLevel: 0.85,
        historicalContext: "Near record-breaking streak"
    )
    
    let sampleEvents = [
        DrawbridgeEvent(
            entityType: "Bridge",
            entityName: "Fremont Bridge",
            entityID: 3,
            openDateTime: Date().addingTimeInterval(-259200), // 3 days ago
            closeDateTime: Date().addingTimeInterval(-259200),
            minutesOpen: 15.0,
            latitude: 47.6475,
            longitude: -122.3497
        )
    ]
    
    StreakChampionModalView(champion: sampleChampion, allEvents: sampleEvents)
} 