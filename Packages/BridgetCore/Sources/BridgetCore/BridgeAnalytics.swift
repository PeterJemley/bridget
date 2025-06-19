//
//  BridgeAnalytics.swift
//  BridgetCore
//
//  Created by Peter Jemley on 6/19/25.
//

import Foundation
import SwiftData

@Model
public final class BridgeAnalytics {
    @Attribute(.unique) public var id: String // Format: "entityID-year-month-day-hour"
    
    public var entityID: Int
    public var entityName: String
    public var year: Int
    public var month: Int
    public var dayOfWeek: Int // 1 = Sunday, 7 = Saturday
    public var hour: Int
    
    // Analytics data
    public var openingCount: Int = 0
    public var totalMinutesOpen: Double = 0
    public var averageMinutesPerOpening: Double = 0
    public var longestOpeningMinutes: Double = 0
    public var shortestOpeningMinutes: Double = 0
    
    // PHASE 1: Seasonal Decomposition Components
    public var trendComponent: Double = 0           // Long-term trend
    public var seasonalComponent: Double = 0        // Weekly/monthly patterns
    public var residualComponent: Double = 0        // Random variations
    public var weeklySeasonality: Double = 0        // Day of week effect
    public var monthlySeasonality: Double = 0       // Month of year effect
    public var hourlySeasonality: Double = 0        // Hour of day effect
    
    // Advanced pattern detection
    public var isWeekendPattern: Bool = false       // Different weekend behavior
    public var isRushHourPattern: Bool = false      // Rush hour indicator
    public var isSummerPattern: Bool = false        // Summer recreational pattern
    public var holidayAdjustment: Double = 0        // Holiday effect
    
    // Prediction factors
    public var probabilityOfOpening: Double = 0 // 0.0 to 1.0
    public var expectedDuration: Double = 0 // in minutes
    public var confidence: Double = 0 // 0.0 to 1.0
    
    public var lastCalculated: Date
    
    public init(
        entityID: Int,
        entityName: String,
        year: Int,
        month: Int,
        dayOfWeek: Int,
        hour: Int
    ) {
        self.id = "\(entityID)-\(year)-\(month)-\(dayOfWeek)-\(hour)"
        self.entityID = entityID
        self.entityName = entityName
        self.year = year
        self.month = month
        self.dayOfWeek = dayOfWeek
        self.hour = hour
        self.lastCalculated = Date()
    }
}

// MARK: - Seasonal Decomposition Engine
public struct SeasonalDecomposition {
    
    /// Decompose time series into trend, seasonal, and residual components
    public static func decompose(analytics: [BridgeAnalytics]) -> [BridgeAnalytics] {
        let bridgeGroups = Dictionary(grouping: analytics, by: \.entityID)
        
        var enhancedAnalytics: [BridgeAnalytics] = []
        
        for (_, bridgeAnalytics) in bridgeGroups {
            let decomposed = decomposeBridgeTimeSeries(bridgeAnalytics)
            enhancedAnalytics.append(contentsOf: decomposed)
        }
        
        return enhancedAnalytics
    }
    
    private static func decomposeBridgeTimeSeries(_ analytics: [BridgeAnalytics]) -> [BridgeAnalytics] {
        // Sort by time components for proper time series analysis
        let sortedAnalytics = analytics.sorted { first, second in
            if first.year != second.year { return first.year < second.year }
            if first.month != second.month { return first.month < second.month }
            if first.dayOfWeek != second.dayOfWeek { return first.dayOfWeek < second.dayOfWeek }
            return first.hour < second.hour
        }
        
        // Calculate trend component using moving average
        let trendWindow = 24 // 24-hour moving average
        for (index, analytics) in sortedAnalytics.enumerated() {
            analytics.trendComponent = calculateTrend(for: index, in: sortedAnalytics, window: trendWindow)
        }
        
        // Calculate seasonal components
        calculateSeasonalComponents(sortedAnalytics)
        
        // Calculate residual component
        for analytics in sortedAnalytics {
            let expectedValue = analytics.trendComponent + analytics.seasonalComponent
            let actualValue = Double(analytics.openingCount)
            analytics.residualComponent = actualValue - expectedValue
        }
        
        // Detect pattern types
        detectPatternTypes(sortedAnalytics)
        
        return sortedAnalytics
    }
    
    private static func calculateTrend(for index: Int, in analytics: [BridgeAnalytics], window: Int) -> Double {
        let halfWindow = window / 2
        let startIndex = max(0, index - halfWindow)
        let endIndex = min(analytics.count - 1, index + halfWindow)
        
        let windowData = Array(analytics[startIndex...endIndex])
        let sum = windowData.reduce(0.0) { $0 + Double($1.openingCount) }
        return sum / Double(windowData.count)
    }
    
    private static func calculateSeasonalComponents(_ analytics: [BridgeAnalytics]) {
        // Calculate weekly seasonality (day of week effect)
        let weeklyGroups = Dictionary(grouping: analytics, by: \.dayOfWeek)
        let weeklyAverages = weeklyGroups.mapValues { group in
            group.reduce(0.0) { $0 + Double($1.openingCount) } / Double(group.count)
        }
        let overallWeeklyAverage = weeklyAverages.values.reduce(0, +) / Double(weeklyAverages.count)
        
        // Calculate monthly seasonality
        let monthlyGroups = Dictionary(grouping: analytics, by: \.month)
        let monthlyAverages = monthlyGroups.mapValues { group in
            group.reduce(0.0) { $0 + Double($1.openingCount) } / Double(group.count)
        }
        let overallMonthlyAverage = monthlyAverages.values.reduce(0, +) / Double(monthlyAverages.count)
        
        // Calculate hourly seasonality
        let hourlyGroups = Dictionary(grouping: analytics, by: \.hour)
        let hourlyAverages = hourlyGroups.mapValues { group in
            group.reduce(0.0) { $0 + Double($1.openingCount) } / Double(group.count)
        }
        let overallHourlyAverage = hourlyAverages.values.reduce(0, +) / Double(hourlyAverages.count)
        
        // Apply seasonal components
        for analytics in analytics {
            analytics.weeklySeasonality = weeklyAverages[analytics.dayOfWeek] ?? overallWeeklyAverage
            analytics.monthlySeasonality = monthlyAverages[analytics.month] ?? overallMonthlyAverage
            analytics.hourlySeasonality = hourlyAverages[analytics.hour] ?? overallHourlyAverage
            
            // Combined seasonal component
            analytics.seasonalComponent = 
                (analytics.weeklySeasonality - overallWeeklyAverage) +
                (analytics.monthlySeasonality - overallMonthlyAverage) +
                (analytics.hourlySeasonality - overallHourlyAverage)
        }
    }
    
    private static func detectPatternTypes(_ analytics: [BridgeAnalytics]) {
        for analytics in analytics {
            // Weekend pattern detection
            analytics.isWeekendPattern = analytics.dayOfWeek == 1 || analytics.dayOfWeek == 7
            
            // Rush hour pattern detection (7-9 AM, 4-6 PM weekdays)
            analytics.isRushHourPattern = !analytics.isWeekendPattern && 
                ((analytics.hour >= 7 && analytics.hour <= 9) || 
                 (analytics.hour >= 16 && analytics.hour <= 18))
            
            // Summer pattern detection (May-September)
            analytics.isSummerPattern = analytics.month >= 5 && analytics.month <= 9
            
            // Holiday adjustment (simplified - could be enhanced with actual holiday data)
            analytics.holidayAdjustment = calculateHolidayAdjustment(for: analytics)
        }
    }
    
    private static func calculateHolidayAdjustment(for analytics: BridgeAnalytics) -> Double {
        // Simplified holiday detection based on patterns
        // July 4th area, Memorial Day weekend, Labor Day weekend affect recreational boating
        if analytics.month == 7 || 
           (analytics.month == 5 && analytics.dayOfWeek == 2) || // Memorial Day Monday
           (analytics.month == 9 && analytics.dayOfWeek == 2) {  // Labor Day Monday
            return 0.3 // 30% increase in recreational boat traffic
        }
        return 0.0
    }
}

// MARK: - Enhanced Analytics Calculator
public struct BridgeAnalyticsCalculator {
    
    /// Calculate analytics for all bridges from historical events with seasonal decomposition
    public static func calculateAnalytics(from events: [DrawbridgeEvent]) -> [BridgeAnalytics] {
        var analytics: [String: BridgeAnalytics] = [:]
        
        // Group events by bridge, year, month, day of week, and hour
        for event in events {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month, .weekday, .hour], from: event.openDateTime)
            
            guard let year = components.year,
                  let month = components.month,
                  let dayOfWeek = components.weekday,
                  let hour = components.hour else { continue }
            
            let key = "\(event.entityID)-\(year)-\(month)-\(dayOfWeek)-\(hour)"
            
            if let existing = analytics[key] {
                // Update existing analytics
                existing.openingCount += 1
                existing.totalMinutesOpen += event.minutesOpen
                existing.averageMinutesPerOpening = existing.totalMinutesOpen / Double(existing.openingCount)
                existing.longestOpeningMinutes = max(existing.longestOpeningMinutes, event.minutesOpen)
                existing.shortestOpeningMinutes = min(existing.shortestOpeningMinutes, event.minutesOpen)
            } else {
                // Create new analytics
                let newAnalytics = BridgeAnalytics(
                    entityID: event.entityID,
                    entityName: event.entityName,
                    year: year,
                    month: month,
                    dayOfWeek: dayOfWeek,
                    hour: hour
                )
                newAnalytics.openingCount = 1
                newAnalytics.totalMinutesOpen = event.minutesOpen
                newAnalytics.averageMinutesPerOpening = event.minutesOpen
                newAnalytics.longestOpeningMinutes = event.minutesOpen
                newAnalytics.shortestOpeningMinutes = event.minutesOpen
                
                analytics[key] = newAnalytics
            }
        }
        
        // PHASE 1: Apply seasonal decomposition
        let rawAnalytics = Array(analytics.values)
        let decomposedAnalytics = SeasonalDecomposition.decompose(analytics: rawAnalytics)
        
        // Calculate enhanced predictions using seasonal components
        for analytics in decomposedAnalytics {
            calculateSeasonalPredictions(for: analytics, allEvents: events)
        }
        
        return decomposedAnalytics
    }
    
    /// Enhanced prediction calculation using seasonal decomposition
    private static func calculateSeasonalPredictions(for analytics: BridgeAnalytics, allEvents: [DrawbridgeEvent]) {
        let bridgeEvents = allEvents.filter { $0.entityID == analytics.entityID }
        let totalHoursInDataset = calculateTotalHours(for: bridgeEvents)
        
        // Base probability calculation
        let totalPossibleOccurrences = totalHoursInDataset[analytics.hour] ?? 1
        let baseProbability = Double(analytics.openingCount) / Double(totalPossibleOccurrences)
        
        // Seasonal adjustments
        let trendAdjustment = analytics.trendComponent > 0 ? 0.1 : -0.1
        let seasonalAdjustment = analytics.seasonalComponent * 0.05 // Scale seasonal effect
        let patternAdjustment = calculatePatternAdjustment(for: analytics)
        
        // Combined probability with seasonal factors
        analytics.probabilityOfOpening = max(0.0, min(1.0, 
            baseProbability + trendAdjustment + seasonalAdjustment + patternAdjustment + analytics.holidayAdjustment
        ))
        
        // Enhanced duration prediction using seasonal patterns
        let seasonalDurationMultiplier = calculateSeasonalDurationMultiplier(for: analytics)
        analytics.expectedDuration = analytics.averageMinutesPerOpening * seasonalDurationMultiplier
        
        // Enhanced confidence calculation
        let sampleSizeConfidence = min(Double(analytics.openingCount) / 10.0, 1.0)
        let variabilityConfidence = calculateVariabilityConfidence(for: analytics)
        let seasonalConfidence = calculateSeasonalConfidence(for: analytics)
        analytics.confidence = (sampleSizeConfidence + variabilityConfidence + seasonalConfidence) / 3.0
    }
    
    private static func calculatePatternAdjustment(for analytics: BridgeAnalytics) -> Double {
        var adjustment = 0.0
        
        // Weekend adjustment
        if analytics.isWeekendPattern {
            adjustment += 0.15 // Higher recreational activity on weekends
        }
        
        // Rush hour adjustment
        if analytics.isRushHourPattern {
            adjustment -= 0.1 // Lower boat traffic during rush hours
        }
        
        // Summer adjustment
        if analytics.isSummerPattern {
            adjustment += 0.2 // Higher summer recreational boating
        }
        
        return adjustment
    }
    
    private static func calculateSeasonalDurationMultiplier(for analytics: BridgeAnalytics) -> Double {
        var multiplier = 1.0
        
        // Weekend boats tend to stay longer
        if analytics.isWeekendPattern {
            multiplier *= 1.2
        }
        
        // Summer recreational boats take more time
        if analytics.isSummerPattern {
            multiplier *= 1.15
        }
        
        // Rush hour boats move faster
        if analytics.isRushHourPattern {
            multiplier *= 0.9
        }
        
        return multiplier
    }
    
    private static func calculateSeasonalConfidence(for analytics: BridgeAnalytics) -> Double {
        // Higher confidence when seasonal patterns are strong
        let seasonalStrength = abs(analytics.seasonalComponent)
        return min(1.0, seasonalStrength / 10.0) // Normalize to 0-1 range
    }
    
    /// Calculate total hours for each hour of day in the dataset
    private static func calculateTotalHours(for events: [DrawbridgeEvent]) -> [Int: Int] {
        var hourCounts: [Int: Int] = [:]
        let calendar = Calendar.current
        
        guard let earliest = events.map(\.openDateTime).min(),
              let latest = events.map(\.openDateTime).max() else {
            return hourCounts
        }
        
        // Count total hours for each hour of day in the date range
        var currentDate = calendar.startOfDay(for: earliest)
        let endDate = calendar.startOfDay(for: latest)
        
        while currentDate <= endDate {
            for hour in 0..<24 {
                hourCounts[hour, default: 0] += 1
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? endDate
        }
        
        return hourCounts
    }
    
    /// Calculate confidence based on variability in opening durations
    private static func calculateVariabilityConfidence(for analytics: BridgeAnalytics) -> Double {
        guard analytics.openingCount > 1 else { return 0.0 }
        
        let range = analytics.longestOpeningMinutes - analytics.shortestOpeningMinutes
        let average = analytics.averageMinutesPerOpening
        
        // Lower variability = higher confidence
        let variabilityRatio = range / max(average, 1.0)
        return max(0.0, 1.0 - (variabilityRatio / 10.0)) // Normalize to 0-1 range
    }
}

// MARK: - Prediction Extensions
extension BridgeAnalytics {
    
    /// Get enhanced prediction for current time using seasonal decomposition
    public static func getCurrentPrediction(
        for bridge: DrawbridgeInfo,
        from analytics: [BridgeAnalytics]
    ) -> BridgePrediction? {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month, .weekday, .hour], from: now)
        
        guard let year = components.year,
              let month = components.month,
              let dayOfWeek = components.weekday,
              let hour = components.hour else { return nil }
        
        let matchingAnalytics = analytics.filter {
            $0.entityID == bridge.entityID &&
            $0.month == month &&
            $0.dayOfWeek == dayOfWeek &&
            $0.hour == hour
        }
        
        guard let bestMatch = matchingAnalytics.max(by: { $0.confidence < $1.confidence }) else {
            return BridgePrediction(
                bridge: bridge,
                probability: 0.1, // Default low probability
                expectedDuration: 15.0, // Default duration
                confidence: 0.0,
                timeFrame: "next hour",
                reasoning: "No historical data available for this time"
            )
        }
        
        return BridgePrediction(
            bridge: bridge,
            probability: bestMatch.probabilityOfOpening,
            expectedDuration: bestMatch.expectedDuration,
            confidence: bestMatch.confidence,
            timeFrame: "next hour",
            reasoning: generateSeasonalReasoning(for: bestMatch)
        )
    }
    
    private static func generateSeasonalReasoning(for analytics: BridgeAnalytics) -> String {
        let dayName = Calendar.current.weekdaySymbols[analytics.dayOfWeek - 1]
        let hourFormat = analytics.hour == 0 ? "12 AM" : 
                        analytics.hour < 12 ? "\(analytics.hour) AM" :
                        analytics.hour == 12 ? "12 PM" : "\(analytics.hour - 12) PM"
        
        var reasoning = "Based on \(analytics.openingCount) historical openings on \(dayName)s at \(hourFormat)"
        
        // Add seasonal context
        if analytics.isSummerPattern {
            reasoning += " (summer recreational pattern)"
        }
        if analytics.isWeekendPattern {
            reasoning += " (weekend pattern)"
        }
        if analytics.isRushHourPattern {
            reasoning += " (rush hour period)"
        }
        if analytics.holidayAdjustment > 0 {
            reasoning += " (holiday adjustment +\(Int(analytics.holidayAdjustment * 100))%)"
        }
        
        return reasoning
    }
}

// MARK: - Prediction Result Model
public struct BridgePrediction {
    public let bridge: DrawbridgeInfo
    public let probability: Double // 0.0 to 1.0
    public let expectedDuration: Double // minutes
    public let confidence: Double // 0.0 to 1.0
    public let timeFrame: String
    public let reasoning: String
    
    public init(bridge: DrawbridgeInfo, probability: Double, expectedDuration: Double, confidence: Double, timeFrame: String, reasoning: String) {
        self.bridge = bridge
        self.probability = probability
        self.expectedDuration = expectedDuration
        self.confidence = confidence
        self.timeFrame = timeFrame
        self.reasoning = reasoning
    }
    
    public var probabilityText: String {
        switch probability {
        case 0.0..<0.1: return "Very Low"
        case 0.1..<0.3: return "Low"
        case 0.3..<0.6: return "Moderate"
        case 0.6..<0.8: return "High"  
        case 0.8...1.0: return "Very High"
        default: return "Unknown"
        }
    }
    
    public var confidenceText: String {
        switch confidence {
        case 0.0..<0.3: return "Low Confidence"
        case 0.3..<0.7: return "Medium Confidence"
        case 0.7...1.0: return "High Confidence"
        default: return "Unknown"
        }
    }
    
    public var durationText: String {
        if expectedDuration < 1 {
            return "< 1 minute"
        } else if expectedDuration < 60 {
            return "\(Int(expectedDuration)) minutes"
        } else {
            let hours = Int(expectedDuration / 60)
            let minutes = Int(expectedDuration.truncatingRemainder(dividingBy: 60))
            return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
        }
    }
}

// MARK: - Phase 1 Seasonal Insights
public struct SeasonalInsights {
    
    /// Generate insights about seasonal patterns for a bridge
    public static func generateInsights(for bridgeID: Int, from analytics: [BridgeAnalytics]) -> [String] {
        let bridgeAnalytics = analytics.filter { $0.entityID == bridgeID }
        var insights: [String] = []
        
        // Weekend vs weekday analysis
        let weekendAnalytics = bridgeAnalytics.filter { $0.isWeekendPattern }
        let weekdayAnalytics = bridgeAnalytics.filter { !$0.isWeekendPattern }
        
        if !weekendAnalytics.isEmpty && !weekdayAnalytics.isEmpty {
            let weekendAvg = weekendAnalytics.map(\.probabilityOfOpening).reduce(0, +) / Double(weekendAnalytics.count)
            let weekdayAvg = weekdayAnalytics.map(\.probabilityOfOpening).reduce(0, +) / Double(weekdayAnalytics.count)
            
            if weekendAvg > weekdayAvg * 1.2 {
                insights.append("Weekend openings are \(Int((weekendAvg / weekdayAvg - 1) * 100))% more frequent than weekdays")
            }
        }
        
        // Summer pattern analysis
        let summerAnalytics = bridgeAnalytics.filter { $0.isSummerPattern }
        let nonSummerAnalytics = bridgeAnalytics.filter { !$0.isSummerPattern }
        
        if !summerAnalytics.isEmpty && !nonSummerAnalytics.isEmpty {
            let summerAvg = summerAnalytics.map(\.probabilityOfOpening).reduce(0, +) / Double(summerAnalytics.count)
            let nonSummerAvg = nonSummerAnalytics.map(\.probabilityOfOpening).reduce(0, +) / Double(nonSummerAnalytics.count)
            
            if summerAvg > nonSummerAvg * 1.1 {
                insights.append("Summer months show \(Int((summerAvg / nonSummerAvg - 1) * 100))% increase in bridge activity")
            }
        }
        
        // Rush hour analysis
        let rushHourAnalytics = bridgeAnalytics.filter { $0.isRushHourPattern }
        if !rushHourAnalytics.isEmpty {
            let rushHourAvg = rushHourAnalytics.map(\.probabilityOfOpening).reduce(0, +) / Double(rushHourAnalytics.count)
            if rushHourAvg < 0.1 {
                insights.append("Bridge activity is significantly reduced during rush hours")
            }
        }
        
        return insights
    }
}