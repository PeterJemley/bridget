//
//  TrendData.swift
//  BridgetCore
//
//  Created by AI Assistant on 1/15/25.
//

import Foundation
import SwiftUI

// MARK: - Trend Data Models

public struct DailyTrendPoint: Identifiable, Equatable {
    public let id = UUID()
    public let date: Date
    public let count: Int
    public let averageDuration: Double
    
    public init(date: Date, count: Int, averageDuration: Double) {
        self.date = date
        self.count = count
        self.averageDuration = averageDuration
    }
    
    public static func == (lhs: DailyTrendPoint, rhs: DailyTrendPoint) -> Bool {
        return lhs.date == rhs.date && 
               lhs.count == rhs.count && 
               lhs.averageDuration == rhs.averageDuration
    }
}

public struct WeeklyTrendPoint: Identifiable, Equatable {
    public let id = UUID()
    public let weekStart: Date
    public let count: Int
    public let averageDuration: Double
    public let bridgeCount: Int
    
    public init(weekStart: Date, count: Int, averageDuration: Double, bridgeCount: Int) {
        self.weekStart = weekStart
        self.count = count
        self.averageDuration = averageDuration
        self.bridgeCount = bridgeCount
    }
    
    public static func == (lhs: WeeklyTrendPoint, rhs: WeeklyTrendPoint) -> Bool {
        return lhs.weekStart == rhs.weekStart && 
               lhs.count == rhs.count && 
               lhs.averageDuration == rhs.averageDuration &&
               lhs.bridgeCount == rhs.bridgeCount
    }
}

public struct TrendSummary: Equatable {
    public let currentValue: Int
    public let previousValue: Int
    public let change: Int
    public let changePercentage: Double
    public let trendDirection: TrendDirection
    public let dataPoints: [DailyTrendPoint]
    
    public init(currentValue: Int, previousValue: Int, change: Int, changePercentage: Double, trendDirection: TrendDirection, dataPoints: [DailyTrendPoint]) {
        self.currentValue = currentValue
        self.previousValue = previousValue
        self.change = change
        self.changePercentage = changePercentage
        self.trendDirection = trendDirection
        self.dataPoints = dataPoints
    }
    
    public static func == (lhs: TrendSummary, rhs: TrendSummary) -> Bool {
        return lhs.currentValue == rhs.currentValue &&
               lhs.previousValue == rhs.previousValue &&
               lhs.change == rhs.change &&
               lhs.changePercentage == rhs.changePercentage &&
               lhs.trendDirection == rhs.trendDirection &&
               lhs.dataPoints == rhs.dataPoints
    }
}

public enum TrendDirection: Equatable {
    case up
    case down
    case stable
    
    public var symbol: String {
        switch self {
        case .up: return "↗"
        case .down: return "↘"
        case .stable: return "→"
        }
    }
    
    public var color: Color {
        switch self {
        case .up: return .red
        case .down: return .green
        case .stable: return .gray
        }
    }
}

// MARK: - Trend Calculation Utilities

public struct TrendCalculator {
    
    /// Calculate daily trend data for the last N days
    public static func calculateDailyTrend(from events: [DrawbridgeEvent], days: Int = 30) -> [DailyTrendPoint] {
        let calendar = Calendar.current
        let today = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: today) ?? today
        
        var dailyData: [Date: (count: Int, totalDuration: Double)] = [:]
        
        // Initialize all days with zero counts
        for dayOffset in 0..<days {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) {
                dailyData[calendar.startOfDay(for: date)] = (count: 0, totalDuration: 0.0)
            }
        }
        
        // Aggregate events by day
        for event in events {
            let eventDate = calendar.startOfDay(for: event.openDateTime)
            if eventDate >= startDate {
                let current = dailyData[eventDate] ?? (count: 0, totalDuration: 0.0)
                dailyData[eventDate] = (
                    count: current.count + 1,
                    totalDuration: current.totalDuration + event.minutesOpen
                )
            }
        }
        
        // Convert to trend points
        return dailyData.sorted { $0.key < $1.key }.map { date, data in
            DailyTrendPoint(
                date: date,
                count: data.count,
                averageDuration: data.count > 0 ? data.totalDuration / Double(data.count) : 0.0
            )
        }
    }
    
    /// Calculate weekly trend data for the last N weeks
    public static func calculateWeeklyTrend(from events: [DrawbridgeEvent], weeks: Int = 12) -> [WeeklyTrendPoint] {
        let calendar = Calendar.current
        let today = Date()
        
        var weeklyData: [Date: (count: Int, totalDuration: Double, bridges: Set<Int>)] = [:]
        
        // Initialize all weeks with zero counts
        for weekOffset in 0..<weeks {
            if let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: today) {
                let weekStartDate = calendar.dateInterval(of: .weekOfYear, for: weekStart)?.start ?? weekStart
                weeklyData[weekStartDate] = (count: 0, totalDuration: 0.0, bridges: [])
            }
        }
        
        // Aggregate events by week
        for event in events {
            let weekStart = calendar.dateInterval(of: .weekOfYear, for: event.openDateTime)?.start ?? event.openDateTime
            if let current = weeklyData[weekStart] {
                weeklyData[weekStart] = (
                    count: current.count + 1,
                    totalDuration: current.totalDuration + event.minutesOpen,
                    bridges: current.bridges.union([event.entityID])
                )
            }
        }
        
        // Convert to trend points
        return weeklyData.sorted { $0.key < $1.key }.map { weekStart, data in
            WeeklyTrendPoint(
                weekStart: weekStart,
                count: data.count,
                averageDuration: data.count > 0 ? data.totalDuration / Double(data.count) : 0.0,
                bridgeCount: data.bridges.count
            )
        }
    }
    
    /// Calculate trend summary comparing current period to previous period
    public static func calculateTrendSummary(
        currentEvents: [DrawbridgeEvent],
        previousEvents: [DrawbridgeEvent],
        dataPoints: [DailyTrendPoint]
    ) -> TrendSummary {
        let currentCount = currentEvents.count
        let previousCount = previousEvents.count
        let change = currentCount - previousCount
        
        let changePercentage = previousCount > 0 ? 
            (Double(change) / Double(previousCount)) * 100.0 : 0.0
        
        let trendDirection: TrendDirection
        if change > 0 {
            trendDirection = .up
        } else if change < 0 {
            trendDirection = .down
        } else {
            trendDirection = .stable
        }
        
        return TrendSummary(
            currentValue: currentCount,
            previousValue: previousCount,
            change: change,
            changePercentage: changePercentage,
            trendDirection: trendDirection,
            dataPoints: dataPoints
        )
    }
    
    /// Get events for a specific time period
    public static func eventsForPeriod(_ events: [DrawbridgeEvent], days: Int) -> [DrawbridgeEvent] {
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        return events.filter { $0.openDateTime >= cutoffDate }
    }
    
    /// Get events for today
    public static func eventsForToday(_ events: [DrawbridgeEvent]) -> [DrawbridgeEvent] {
        let calendar = Calendar.current
        let today = Date()
        
        return events.filter { calendar.isDate($0.openDateTime, inSameDayAs: today) }
    }
    
    /// Get events for this week
    public static func eventsForThisWeek(_ events: [DrawbridgeEvent]) -> [DrawbridgeEvent] {
        let calendar = Calendar.current
        let today = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        
        return events.filter { $0.openDateTime >= weekStart }
    }
    
    /// Get events for last week
    public static func eventsForLastWeek(_ events: [DrawbridgeEvent]) -> [DrawbridgeEvent] {
        let calendar = Calendar.current
        let today = Date()
        let lastWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: today) ?? today
        let lastWeekInterval = calendar.dateInterval(of: .weekOfYear, for: lastWeekStart)
        let lastWeekEnd = lastWeekInterval?.end ?? today
        
        return events.filter { 
            $0.openDateTime >= lastWeekStart && $0.openDateTime < lastWeekEnd 
        }
    }
}

// MARK: - Bridge Count Trend Utilities

public extension TrendCalculator {
    
    /// Calculate bridge count trend (how many unique bridges have been active)
    static func calculateBridgeCountTrend(from events: [DrawbridgeEvent], days: Int = 7) -> TrendSummary {
        let currentEvents = eventsForPeriod(events, days: days)
        let previousEvents = eventsForPeriod(events, days: days * 2).filter { event in
            !currentEvents.contains { $0.id == event.id }
        }
        
        let currentBridges = Set(currentEvents.map(\.entityID))
        let previousBridges = Set(previousEvents.map(\.entityID))
        
        let currentCount = currentBridges.count
        let previousCount = previousBridges.count
        let change = currentCount - previousCount
        
        let changePercentage = previousCount > 0 ? 
            (Double(change) / Double(previousCount)) * 100.0 : 0.0
        
        let trendDirection: TrendDirection
        if change > 0 {
            trendDirection = .up
        } else if change < 0 {
            trendDirection = .down
        } else {
            trendDirection = .stable
        }
        
        // Create dummy data points for bridge count (since it's not daily data)
        let dataPoints = calculateDailyTrend(from: events, days: days)
        
        return TrendSummary(
            currentValue: currentCount,
            previousValue: previousCount,
            change: change,
            changePercentage: changePercentage,
            trendDirection: trendDirection,
            dataPoints: dataPoints
        )
    }
}

// MARK: - Data Range Trend Utilities

public extension TrendCalculator {
    
    /// Calculate data range trend (events per day over the data range)
    static func calculateDataRangeTrend(from events: [DrawbridgeEvent]) -> [DailyTrendPoint] {
        guard let oldestEvent = events.min(by: { $0.openDateTime < $1.openDateTime }),
              let newestEvent = events.max(by: { $0.openDateTime < $1.openDateTime }) else {
            return []
        }
        
        let calendar = Calendar.current
        let daysDifference = calendar.dateComponents([.day], from: oldestEvent.openDateTime, to: newestEvent.openDateTime).day ?? 0
        
        // Limit to last 29 days for performance
        let maxDays = min(daysDifference, 29)
        return calculateDailyTrend(from: events, days: maxDays)
    }
} 