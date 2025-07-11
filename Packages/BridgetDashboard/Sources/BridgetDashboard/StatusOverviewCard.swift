//
//  StatusOverviewCard.swift
//  BridgetDashboard
//
//  Created by Peter Jemley on 6/19/25.
//

import SwiftUI
import BridgetCore
import BridgetSharedUI

public struct StatusOverviewCard: View {
    public let events: [DrawbridgeEvent]
    public let bridgeInfo: [DrawbridgeInfo]
    
    public init(events: [DrawbridgeEvent], bridgeInfo: [DrawbridgeInfo]) {
        self.events = events
        self.bridgeInfo = bridgeInfo
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Historical Data Overview")
                    .font(.headline)
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 16) {
                TrendSummaryCard(
                    title: "Bridges Monitored",
                    value: "\(uniqueBridgeCount)",
                    trend: bridgeCountTrend,
                    color: .blue
                )
                
                TrendSummaryCard(
                    title: "Today's Events",
                    value: "\(todaysEventsCount)",
                    trend: todaysEventsTrend,
                    color: .purple
                )
                
                TrendSummaryCard(
                    title: "This Week's Events",
                    value: "\(thisWeeksEventsCount)",
                    trend: thisWeeksEventsTrend,
                    color: .orange
                )
                
                TrendSummaryCard(
                    title: totalEventsTitle,
                    value: totalEventsValue,
                    trend: totalEventsTrend,
                    color: .gray
                )
                
                TrendSummaryCard(
                    title: "Data Range",
                    value: dataRangeText,
                    trend: dataRangeTrend,
                    color: .green
                )
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private var uniqueBridgeCount: Int {
        Set(events.map(\.entityName)).count
    }
    
    private var todaysEventsCount: Int {
        DrawbridgeEvent.eventsToday(events).count
    }
    
    private var thisWeeksEventsCount: Int {
        let calendar = Calendar.current
        let today = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: today) ?? today
        
        return events.filter { event in
            event.openDateTime >= weekAgo && event.openDateTime <= today
        }.count
    }
    
    private var totalEventsTitle: String {
        guard let oldest = events.map(\.openDateTime).min(),
              let newest = events.map(\.openDateTime).max() else {
            return "Recent Events"
        }
        
        // Calculate the actual date range for clarity
        let daysDifference = Calendar.current.dateComponents([.day], from: oldest, to: newest).day ?? 0
        if daysDifference <= 30 {
            return "Recent Events (\(daysDifference) days)"
        } else {
            return "Recent Events (30 days)"
        }
    }
    
    private var totalEventsValue: String {
        "\(events.count)"
    }
    
    private var dataRangeText: String {
        guard let oldest = events.map(\.openDateTime).min(),
              let newest = events.map(\.openDateTime).max() else {
            return "No data"
        }
        
        let daysDifference = Calendar.current.dateComponents([.day], from: oldest, to: newest).day ?? 0
        return "\(daysDifference) days"
    }
    
    // MARK: - Trend Calculations
    
    private var bridgeCountTrend: TrendSummary? {
        guard !events.isEmpty else { return nil }
        return TrendCalculator.calculateBridgeCountTrend(from: events, days: 7)
    }
    
    private var todaysEventsTrend: TrendSummary? {
        guard !events.isEmpty else { return nil }
        
        let todaysEvents = TrendCalculator.eventsForToday(events)
        let yesterdaysEvents = events.filter { event in
            let calendar = Calendar.current
            let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()
            return calendar.isDate(event.openDateTime, inSameDayAs: yesterday)
        }
        
        let dataPoints = TrendCalculator.calculateDailyTrend(from: events, days: 7)
        
        return TrendCalculator.calculateTrendSummary(
            currentEvents: todaysEvents,
            previousEvents: yesterdaysEvents,
            dataPoints: dataPoints
        )
    }
    
    private var thisWeeksEventsTrend: TrendSummary? {
        guard !events.isEmpty else { return nil }
        
        let thisWeeksEvents = TrendCalculator.eventsForThisWeek(events)
        let lastWeeksEvents = TrendCalculator.eventsForLastWeek(events)
        
        let dataPoints = TrendCalculator.calculateDailyTrend(from: events, days: 14)
        
        return TrendCalculator.calculateTrendSummary(
            currentEvents: thisWeeksEvents,
            previousEvents: lastWeeksEvents,
            dataPoints: dataPoints
        )
    }
    
    private var totalEventsTrend: TrendSummary? {
        guard !events.isEmpty else { return nil }
        
        let recentEvents = TrendCalculator.eventsForPeriod(events, days: 7)
        let previousEvents = TrendCalculator.eventsForPeriod(events, days: 14).filter { event in
            !recentEvents.contains { $0.id == event.id }
        }
        
        let dataPoints = TrendCalculator.calculateDailyTrend(from: events, days: 30)
        
        return TrendCalculator.calculateTrendSummary(
            currentEvents: recentEvents,
            previousEvents: previousEvents,
            dataPoints: dataPoints
        )
    }
    
    private var dataRangeTrend: TrendSummary? {
        guard !events.isEmpty else { return nil }
        
        let dataPoints = TrendCalculator.calculateDataRangeTrend(from: events)
        guard !dataPoints.isEmpty else { return nil }
        
        // For data range, we show the trend of events per day over the data range
        let recentDataPoints = dataPoints.suffix(7)
        let previousDataPoints = dataPoints.dropLast(7).suffix(7)
        
        let recentCount = recentDataPoints.map(\.count).reduce(0, +)
        let previousCount = previousDataPoints.map(\.count).reduce(0, +)
        
        let change = recentCount - previousCount
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
            currentValue: recentCount,
            previousValue: previousCount,
            change: change,
            changePercentage: changePercentage,
            trendDirection: trendDirection,
            dataPoints: dataPoints
        )
    }
}

#Preview {
    StatusOverviewCard(events: [], bridgeInfo: [])
        .padding()
}