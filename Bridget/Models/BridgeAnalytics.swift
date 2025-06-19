//
//  BridgeAnalytics.swift
//  Bridget
//
//  Created by Peter Jemley on 6/18/25.
//

import Foundation
import SwiftData

@Model
final class BridgeAnalytics {
    @Attribute(.unique) var id: String // Format: "entityID-year-month-day-hour"
    
    var entityID: Int
    var entityName: String
    var year: Int
    var month: Int
    var dayOfWeek: Int // 1 = Sunday, 7 = Saturday
    var hour: Int
    
    // Analytics data
    var openingCount: Int = 0
    var totalMinutesOpen: Double = 0
    var averageMinutesPerOpening: Double = 0
    var longestOpeningMinutes: Double = 0
    var shortestOpeningMinutes: Double = 0
    
    // Prediction factors
    var probabilityOfOpening: Double = 0 // 0.0 to 1.0
    var expectedDuration: Double = 0 // in minutes
    var confidence: Double = 0 // 0.0 to 1.0
    
    var lastCalculated: Date
    
    init(
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

// MARK: - Analytics Calculator
struct BridgeAnalyticsCalculator {
    
    /// Calculate analytics for all bridges from historical events
    static func calculateAnalytics(from events: [DrawbridgeEvent]) -> [BridgeAnalytics] {
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
        
        // Calculate predictions for each analytics entry
        for analytics in analytics.values {
            calculatePredictions(for: analytics, allEvents: events)
        }
        
        return Array(analytics.values)
    }
    
    /// Calculate prediction probabilities and confidence
    private static func calculatePredictions(for analytics: BridgeAnalytics, allEvents: [DrawbridgeEvent]) {
        let bridgeEvents = allEvents.filter { $0.entityID == analytics.entityID }
        let totalHoursInDataset = calculateTotalHours(for: bridgeEvents)
        
        // Calculate probability of opening in this specific hour/day combination
        let totalPossibleOccurrences = totalHoursInDataset[analytics.hour] ?? 1
        analytics.probabilityOfOpening = Double(analytics.openingCount) / Double(totalPossibleOccurrences)
        
        // Expected duration is the average
        analytics.expectedDuration = analytics.averageMinutesPerOpening
        
        // Confidence based on sample size and consistency
        let sampleSizeConfidence = min(Double(analytics.openingCount) / 10.0, 1.0) // Max confidence at 10+ samples
        let variabilityConfidence = calculateVariabilityConfidence(for: analytics)
        analytics.confidence = (sampleSizeConfidence + variabilityConfidence) / 2.0
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
    
    /// Get prediction for current time
    static func getCurrentPrediction(
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
            reasoning: generateReasoning(for: bestMatch)
        )
    }
    
    private static func generateReasoning(for analytics: BridgeAnalytics) -> String {
        let dayName = Calendar.current.weekdaySymbols[analytics.dayOfWeek - 1]
        let hourFormat = analytics.hour == 0 ? "12 AM" : 
                        analytics.hour < 12 ? "\(analytics.hour) AM" :
                        analytics.hour == 12 ? "12 PM" : "\(analytics.hour - 12) PM"
        
        return "Based on \(analytics.openingCount) historical openings on \(dayName)s at \(hourFormat)"
    }
}

// MARK: - Prediction Result Model
struct BridgePrediction {
    let bridge: DrawbridgeInfo
    let probability: Double // 0.0 to 1.0
    let expectedDuration: Double // minutes
    let confidence: Double // 0.0 to 1.0
    let timeFrame: String
    let reasoning: String
    
    var probabilityText: String {
        switch probability {
        case 0.0..<0.1: return "Very Low"
        case 0.1..<0.3: return "Low"
        case 0.3..<0.6: return "Moderate"
        case 0.6..<0.8: return "High"
        case 0.8...1.0: return "Very High"
        default: return "Unknown"
        }
    }
    
    var confidenceText: String {
        switch confidence {
        case 0.0..<0.3: return "Low Confidence"
        case 0.3..<0.7: return "Medium Confidence"
        case 0.7...1.0: return "High Confidence"
        default: return "Unknown"
        }
    }
    
    var durationText: String {
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