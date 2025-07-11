//
//  StreakAnalytics.swift
//  BridgetCore
//
//  Created by AI Assistant on 1/15/25.
//

import Foundation

/**
 * Comprehensive analytics for bridge opening streaks and patterns
 * 
 * This module provides sophisticated streak analysis capabilities for bridge activity monitoring,
 * including current streak calculations, historical pattern analysis, and predictive modeling.
 * 
 * Key Features:
 * - Weekly streak champion identification
 * - Historical streak pattern analysis
 * - Next opening prediction with confidence scoring
 * - Bridge performance ranking and comparison
 * 
 * Usage:
 * ```swift
 * let champion = StreakAnalytics.calculateWeeklyChampion(from: events)
 * let streakData = StreakAnalytics.calculateStreakData(for: "Fremont Bridge", events: events)
 * ```
 */
public struct StreakAnalytics {
    
    // MARK: - Data Structures
    
    /**
     * Comprehensive streak data for a specific bridge
     * 
     * Contains current streak information, historical patterns, and predictive analytics
     * for a single bridge's opening behavior.
     */
    public struct StreakData {
        public let bridgeName: String
        public let bridgeID: Int
        public let currentStreakHours: Double
        public let longestStreakHours: Double
        public let averageStreakHours: Double
        public let streakCount: Int
        public let lastOpeningDate: Date?
        public let nextPredictedOpening: Date?
        public let confidenceLevel: Double
        public let historicalPatterns: [StreakPattern]
        
        public init(
            bridgeName: String,
            bridgeID: Int,
            currentStreakHours: Double,
            longestStreakHours: Double,
            averageStreakHours: Double,
            streakCount: Int,
            lastOpeningDate: Date?,
            nextPredictedOpening: Date?,
            confidenceLevel: Double,
            historicalPatterns: [StreakPattern]
        ) {
            self.bridgeName = bridgeName
            self.bridgeID = bridgeID
            self.currentStreakHours = currentStreakHours
            self.longestStreakHours = longestStreakHours
            self.averageStreakHours = averageStreakHours
            self.streakCount = streakCount
            self.lastOpeningDate = lastOpeningDate
            self.nextPredictedOpening = nextPredictedOpening
            self.confidenceLevel = confidenceLevel
            self.historicalPatterns = historicalPatterns
        }
    }
    
    /**
     * Represents a single streak period between bridge openings
     * 
     * A streak is defined as a period of time when a bridge remains closed
     * without any openings. This structure tracks the duration and context
     * of each streak period.
     */
    public struct StreakPattern {
        public let startDate: Date
        public let endDate: Date
        public let durationHours: Double
        public let wasInterrupted: Bool
        public let interruptionReason: String?
        
        public init(
            startDate: Date,
            endDate: Date,
            durationHours: Double,
            wasInterrupted: Bool = false,
            interruptionReason: String? = nil
        ) {
            self.startDate = startDate
            self.endDate = endDate
            self.durationHours = durationHours
            self.wasInterrupted = wasInterrupted
            self.interruptionReason = interruptionReason
        }
    }
    
    /**
     * Weekly champion bridge with the longest current streak
     * 
     * Represents the bridge that has gone the longest without opening
     * in the past 7 days, along with confidence metrics and historical context.
     */
    public struct WeeklyChampion {
        public let bridgeName: String
        public let bridgeID: Int
        public let streakHours: Double
        public let confidenceLevel: Double
        public let historicalContext: String
        
        public init(
            bridgeName: String,
            bridgeID: Int,
            streakHours: Double,
            confidenceLevel: Double,
            historicalContext: String
        ) {
            self.bridgeName = bridgeName
            self.bridgeID = bridgeID
            self.streakHours = streakHours
            self.confidenceLevel = confidenceLevel
            self.historicalContext = historicalContext
        }
    }
    
    // MARK: - Public API
    
    /**
     * Calculate the weekly streak champion (longest streak without opening in past 7 days)
     * 
     * This method analyzes all bridges and identifies which one has maintained
     * the longest streak of being closed without any openings in the past week.
     * 
     * - Parameter events: Array of all bridge events to analyze
     * - Returns: WeeklyChampion object with the bridge having the longest streak, or nil if no data
     * 
     * Example:
     * ```swift
     * if let champion = StreakAnalytics.calculateWeeklyChampion(from: events) {
     *     print("Weekly champion: \(champion.bridgeName) with \(champion.streakHours) hours")
     * }
     * ```
     */
    public static func calculateWeeklyChampion(from events: [DrawbridgeEvent]) -> WeeklyChampion? {
        SecurityLogger.main("🏆 [STREAK] Calculating weekly champion from \(events.count) events")
        
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recentEvents = events.filter { $0.openDateTime >= oneWeekAgo }
        
        SecurityLogger.main("🏆 [STREAK] Recent events (7 days): \(recentEvents.count)")
        
        // Group events by bridge
        let bridgeGroups = Dictionary(grouping: events, by: \.entityName)
        var champion: WeeklyChampion?
        var maxStreakHours: Double = 0
        
        for (bridgeName, bridgeEvents) in bridgeGroups {
            let streakData = calculateStreakData(for: bridgeName, events: bridgeEvents, lookbackDays: 7)
            
            if streakData.currentStreakHours > maxStreakHours {
                maxStreakHours = streakData.currentStreakHours
                champion = WeeklyChampion(
                    bridgeName: bridgeName,
                    bridgeID: streakData.bridgeID,
                    streakHours: streakData.currentStreakHours,
                    confidenceLevel: streakData.confidenceLevel,
                    historicalContext: generateHistoricalContext(for: streakData)
                )
                
                SecurityLogger.main("🏆 [STREAK] New champion: \(bridgeName) with \(streakData.currentStreakHours) hours")
            }
        }
        
        if let champion = champion {
            SecurityLogger.main("🏆 [STREAK] Weekly champion: \(champion.bridgeName) (\(champion.streakHours) hours)")
        } else {
            SecurityLogger.main("🏆 [STREAK] No weekly champion found")
        }
        
        return champion
    }
    
    /**
     * Calculate comprehensive streak data for a specific bridge
     * 
     * Provides detailed analytics for a single bridge including current streak,
     * historical patterns, and predictive insights.
     * 
     * - Parameters:
     *   - bridgeName: Name of the bridge to analyze
     *   - events: Array of all bridge events
     *   - lookbackDays: Number of days to look back for analysis (default: 30)
     * - Returns: StreakData object with comprehensive analytics
     * 
     * Example:
     * ```swift
     * let streakData = StreakAnalytics.calculateStreakData(
     *     for: "Fremont Bridge",
     *     events: events,
     *     lookbackDays: 30
     * )
     * print("Current streak: \(streakData.formattedCurrentStreak)")
     * ```
     */
    public static func calculateStreakData(
        for bridgeName: String,
        events: [DrawbridgeEvent],
        lookbackDays: Int = 30
    ) -> StreakData {
        SecurityLogger.main("🏆 [STREAK] Calculating streak data for \(bridgeName) (\(events.count) events, \(lookbackDays) days)")
        
        let lookbackDate = Calendar.current.date(byAdding: .day, value: -lookbackDays, to: Date()) ?? Date()
        let relevantEvents = events.filter { $0.openDateTime >= lookbackDate }
        
        // Sort events by date (newest first)
        let sortedEvents = relevantEvents.sorted { $0.openDateTime > $1.openDateTime }
        
        // Calculate current streak
        let currentStreakHours = calculateCurrentStreakHours(from: sortedEvents)
        
        // Calculate historical streaks
        let historicalStreaks = calculateHistoricalStreaks(from: sortedEvents)
        let longestStreak = historicalStreaks.map(\.durationHours).max() ?? 0
        let averageStreak = historicalStreaks.isEmpty ? 0 : historicalStreaks.map(\.durationHours).reduce(0, +) / Double(historicalStreaks.count)
        
        // Predict next opening
        let prediction = predictNextOpening(from: sortedEvents, currentStreakHours: currentStreakHours)
        
        // Calculate confidence level
        let confidenceLevel = calculateConfidenceLevel(
            eventCount: relevantEvents.count,
            streakCount: historicalStreaks.count,
            lookbackDays: lookbackDays
        )
        
        let bridgeID = sortedEvents.first?.entityID ?? 0
        let lastOpening = sortedEvents.first?.openDateTime
        
        let streakData = StreakData(
            bridgeName: bridgeName,
            bridgeID: bridgeID,
            currentStreakHours: currentStreakHours,
            longestStreakHours: longestStreak,
            averageStreakHours: averageStreak,
            streakCount: historicalStreaks.count,
            lastOpeningDate: lastOpening,
            nextPredictedOpening: prediction.date,
            confidenceLevel: confidenceLevel,
            historicalPatterns: historicalStreaks
        )
        
        SecurityLogger.main("🏆 [STREAK] \(bridgeName) - Current: \(currentStreakHours)h, Longest: \(longestStreak)h, Avg: \(averageStreak)h")
        
        return streakData
    }
    
    // MARK: - Private Calculation Methods
    
    /**
     * Calculate the current streak hours since the last bridge opening
     * 
     * - Parameter events: Sorted events (newest first) for the bridge
     * - Returns: Hours since the last opening, or 0 if no events
     */
    private static func calculateCurrentStreakHours(from events: [DrawbridgeEvent]) -> Double {
        guard let lastEvent = events.first else {
            // No events - calculate from start of data
            return 0
        }
        
        let timeSinceLastOpening = Date().timeIntervalSince(lastEvent.openDateTime)
        let hoursSinceLastOpening = timeSinceLastOpening / 3600
        
        SecurityLogger.main("🏆 [STREAK] Last opening: \(lastEvent.openDateTime.formatted()), Hours since: \(hoursSinceLastOpening)")
        
        return max(0, hoursSinceLastOpening)
    }
    
    /**
     * Calculate historical streak patterns from event data
     * 
     * Identifies periods where bridges remained closed for extended periods
     * (12+ hours) between openings.
     * 
     * - Parameter events: Sorted events for the bridge
     * - Returns: Array of StreakPattern objects representing historical streaks
     */
    private static func calculateHistoricalStreaks(from events: [DrawbridgeEvent]) -> [StreakPattern] {
        guard events.count >= 2 else { return [] }
        
        var streaks: [StreakPattern] = []
        let sortedEvents = events.sorted { $0.openDateTime < $1.openDateTime }
        
        for i in 0..<(sortedEvents.count - 1) {
            let currentEvent = sortedEvents[i]
            let nextEvent = sortedEvents[i + 1]
            
            let timeBetweenEvents = nextEvent.openDateTime.timeIntervalSince(currentEvent.openDateTime)
            let hoursBetweenEvents = timeBetweenEvents / 3600
            
            // Consider it a streak if more than 12 hours between openings
            if hoursBetweenEvents >= 12 {
                let streak = StreakPattern(
                    startDate: currentEvent.openDateTime,
                    endDate: nextEvent.openDateTime,
                    durationHours: hoursBetweenEvents
                )
                streaks.append(streak)
            }
        }
        
        SecurityLogger.main("🏆 [STREAK] Found \(streaks.count) historical streaks")
        return streaks
    }
    
    /**
     * Predict the next bridge opening based on historical patterns
     * 
     * Uses statistical analysis of past opening intervals to predict
     * when the bridge is likely to open next.
     * 
     * - Parameters:
     *   - events: Historical events for the bridge
     *   - currentStreakHours: Current streak duration
     * - Returns: Tuple with predicted date and confidence level
     */
    private static func predictNextOpening(
        from events: [DrawbridgeEvent],
        currentStreakHours: Double
    ) -> (date: Date?, confidence: Double) {
        guard !events.isEmpty else { return (nil, 0) }
        
        // Calculate average time between openings
        let timeBetweenEvents = calculateAverageTimeBetweenEvents(from: events)
        let averageHoursBetweenOpenings = timeBetweenEvents / 3600
        
        // Predict next opening based on current streak and historical average
        let predictedHoursFromNow = max(0, averageHoursBetweenOpenings - currentStreakHours)
        let predictedDate = Calendar.current.date(byAdding: .hour, value: Int(predictedHoursFromNow), to: Date())
        
        // Calculate confidence based on data consistency
        let confidence = calculatePredictionConfidence(from: events, averageHours: averageHoursBetweenOpenings)
        
        SecurityLogger.main("🏆 [STREAK] Prediction: \(predictedDate?.formatted() ?? "Unknown") (confidence: \(confidence))")
        
        return (predictedDate, confidence)
    }
    
    /**
     * Calculate average time between bridge openings
     * 
     * - Parameter events: Historical events for the bridge
     * - Returns: Average time interval in seconds
     */
    private static func calculateAverageTimeBetweenEvents(from events: [DrawbridgeEvent]) -> TimeInterval {
        guard events.count >= 2 else { return 0 }
        
        let sortedEvents = events.sorted { $0.openDateTime < $1.openDateTime }
        var totalTime: TimeInterval = 0
        var count = 0
        
        for i in 0..<(sortedEvents.count - 1) {
            let timeBetween = sortedEvents[i + 1].openDateTime.timeIntervalSince(sortedEvents[i].openDateTime)
            totalTime += timeBetween
            count += 1
        }
        
        return count > 0 ? totalTime / Double(count) : 0
    }
    
    /**
     * Calculate prediction confidence based on data consistency
     * 
     * Uses coefficient of variation to assess how reliable the prediction is
     * based on the consistency of historical patterns.
     * 
     * - Parameters:
     *   - events: Historical events for the bridge
     *   - averageHours: Average hours between openings
     * - Returns: Confidence level between 0.1 and 0.95
     */
    private static func calculatePredictionConfidence(from events: [DrawbridgeEvent], averageHours: Double) -> Double {
        guard events.count >= 3 else { return 0.3 }
        
        // Calculate standard deviation of time between events
        let sortedEvents = events.sorted { $0.openDateTime < $1.openDateTime }
        var deviations: [Double] = []
        
        for i in 0..<(sortedEvents.count - 1) {
            let timeBetween = sortedEvents[i + 1].openDateTime.timeIntervalSince(sortedEvents[i].openDateTime) / 3600
            let deviation = abs(timeBetween - averageHours)
            deviations.append(deviation)
        }
        
        let averageDeviation = deviations.reduce(0, +) / Double(deviations.count)
        let coefficientOfVariation = averageDeviation / averageHours
        
        // Convert to confidence (lower CV = higher confidence)
        let confidence = max(0.1, min(0.95, 1.0 - coefficientOfVariation))
        
        return confidence
    }
    
    /**
     * Calculate overall confidence level for streak analysis
     * 
     * Based on data availability and consistency over the analysis period.
     * 
     * - Parameters:
     *   - eventCount: Number of events in the analysis period
     *   - streakCount: Number of streaks identified
     *   - lookbackDays: Analysis period in days
     * - Returns: Confidence level between 0.1 and 0.95
     */
    private static func calculateConfidenceLevel(
        eventCount: Int,
        streakCount: Int,
        lookbackDays: Int
    ) -> Double {
        // Base confidence on data availability and consistency
        let dataDensity = Double(eventCount) / Double(lookbackDays)
        let streakDensity = Double(streakCount) / Double(lookbackDays)
        
        let confidence = min(0.95, (dataDensity * 0.6) + (streakDensity * 0.4))
        
        return max(0.1, confidence)
    }
    
    /**
     * Generate historical context description for streak performance
     * 
     * Compares current streak against historical patterns to provide
     * meaningful context about the bridge's current performance.
     * 
     * - Parameter streakData: Streak data for the bridge
     * - Returns: Descriptive string about historical performance
     */
    private static func generateHistoricalContext(for streakData: StreakData) -> String {
        let currentStreak = streakData.currentStreakHours
        let longestStreak = streakData.longestStreakHours
        let averageStreak = streakData.averageStreakHours
        
        if currentStreak > longestStreak * 0.8 {
            return "Near record-breaking streak"
        } else if currentStreak > averageStreak * 1.5 {
            return "Above average performance"
        } else if currentStreak < averageStreak * 0.5 {
            return "Below average streak"
        } else {
            return "Typical performance"
        }
    }
}

// MARK: - Extensions

extension StreakAnalytics.StreakData {
    /**
     * Format current streak for display (e.g., "72h" or "3d 12h")
     */
    public var formattedCurrentStreak: String {
        if currentStreakHours < 24 {
            return "\(Int(currentStreakHours))h"
        } else {
            let days = Int(currentStreakHours / 24)
            let hours = Int(currentStreakHours.truncatingRemainder(dividingBy: 24))
            return "\(days)d \(hours)h"
        }
    }
    
    /**
     * Format longest streak for display (e.g., "120h" or "5d")
     */
    public var formattedLongestStreak: String {
        if longestStreakHours < 24 {
            return "\(Int(longestStreakHours))h"
        } else {
            let days = Int(longestStreakHours / 24)
            let hours = Int(longestStreakHours.truncatingRemainder(dividingBy: 24))
            return "\(days)d \(hours)h"
        }
    }
    
    /**
     * Get streak status color for UI display
     * 
     * Returns color category based on current streak performance:
     * - "record": Near record-breaking performance
     * - "good": Above average performance
     * - "normal": Typical performance
     * - "poor": Below average performance
     */
    public var streakStatusColor: String {
        if currentStreakHours > longestStreakHours * 0.8 {
            return "record"
        } else if currentStreakHours > averageStreakHours * 1.2 {
            return "good"
        } else if currentStreakHours < averageStreakHours * 0.8 {
            return "poor"
        } else {
            return "normal"
        }
    }
} 