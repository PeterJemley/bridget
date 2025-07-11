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
    public let onNavigateToRoutes: (() -> Void)?
    
    @State private var showingStreakChampionModal = false
    
    public init(events: [DrawbridgeEvent], bridgeInfo: [DrawbridgeInfo], onNavigateToRoutes: (() -> Void)? = nil) {
        self.events = events
        self.bridgeInfo = bridgeInfo
        self.onNavigateToRoutes = onNavigateToRoutes
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
                // Streak Champion Card
                if let champion = StreakAnalytics.calculateWeeklyChampion(from: events) {
                    Button(action: {
                        showingStreakChampionModal = true
                    }) {
                        VStack(spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "trophy.fill")
                                    .font(.title2)
                                    .foregroundColor(.yellow)
                                Text("Weekly Champion")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                            }
                            Text(champion.bridgeName)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            Text("\(Int(champion.streakHours))h streak")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                // Route Planning Button instead of Bridges Monitored
                Button(action: {
                    onNavigateToRoutes?()
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "car.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                        
                        Text("Find My")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Text("Best Route")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
                
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
        .sheet(isPresented: $showingStreakChampionModal) {
            if let champion = StreakAnalytics.calculateWeeklyChampion(from: events) {
                StreakChampionModalView(champion: champion, allEvents: events)
            }
        }
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

// MARK: - Streak Champion Calculation
private struct StreakChampion {
    let bridgeName: String
    let streakHours: Int
    let bridgeID: Int
}

private func calculateWeeklyStreakChampion(events: [DrawbridgeEvent], bridgeInfo: [DrawbridgeInfo]) -> StreakChampion? {
    let calendar = Calendar.current
    let now = Date()
    let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
    let eventsLastWeek = events.filter { $0.openDateTime >= weekAgo && $0.openDateTime <= now }
    let bridges = Set(eventsLastWeek.map { $0.entityID })
    var champion: StreakChampion? = nil
    
    for bridgeID in bridges {
        let bridgeEvents = eventsLastWeek.filter { $0.entityID == bridgeID }.sorted { $0.openDateTime < $1.openDateTime }
        var lastClose = weekAgo
        var maxStreak: TimeInterval = 0
        for event in bridgeEvents {
            let open = event.openDateTime
            let close = event.closeDateTime ?? open
            let streak = open.timeIntervalSince(lastClose)
            if streak > maxStreak { maxStreak = streak }
            lastClose = max(close, lastClose)
        }
        // Check streak from last event to now
        let finalStreak = now.timeIntervalSince(lastClose)
        if finalStreak > maxStreak { maxStreak = finalStreak }
        let streakHours = Int(maxStreak / 3600)
        let name = bridgeInfo.first(where: { $0.entityID == bridgeID })?.entityName ?? "Bridge #\(bridgeID)"
        if champion == nil || streakHours > champion!.streakHours {
            champion = StreakChampion(bridgeName: name, streakHours: streakHours, bridgeID: bridgeID)
        }
    }
    return champion
}

#Preview {
    StatusOverviewCard(events: [], bridgeInfo: [])
        .padding()
}