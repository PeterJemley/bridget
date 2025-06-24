//
//  BridgeStatsSection.swift
//  BridgetBridgeDetail
//
//  Created by Peter Jemley on 6/19/25.
//

import SwiftUI
import SwiftData
import BridgetCore
import BridgetSharedUI

public struct BridgeStatsSection: View {
    public let events: [DrawbridgeEvent]
    public let timePeriod: TimePeriod
    public let analysisType: AnalysisType
    
    @Environment(\.modelContext) private var modelContext
    @Query private var allEvents: [DrawbridgeEvent]
    @State private var analytics: [BridgeAnalytics] = []
    @State private var currentPrediction: BridgePrediction?
    @State private var isCalculatingPrediction = false
    
    public init(events: [DrawbridgeEvent], timePeriod: TimePeriod, analysisType: AnalysisType) {
        self.events = events
        self.timePeriod = timePeriod
        self.analysisType = analysisType
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistics (\(periodDescription))")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatCard(
                    title: "Total Openings",
                    value: "\(events.count)",
                    icon: "arrow.up.circle.fill",
                    color: .blue
                )
                
                StatCard(
                    title: analysisSpecificTitle,
                    value: analysisSpecificValue,
                    icon: analysisSpecificIcon,
                    color: analysisSpecificColor
                )
                
                StatCard(
                    title: "Longest Opening",
                    value: longestDurationText,
                    icon: "clock.fill",
                    color: .red
                )
                
                StatCard(
                    title: "Most Active Day",
                    value: mostActiveDayText,
                    icon: "calendar",
                    color: .green
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .onAppear {
            calculatePredictions()
        }
        .onChange(of: analysisType) { oldValue, newValue in
            print(" [PREDICTION] Analysis type changed from \(oldValue) to \(newValue)")
            calculatePredictions()
        }
    }
    
    // MARK: - ADD: Prediction Calculation
    private func calculatePredictions() {
        print(" [PREDICTION] calculatePredictions() called")
        print(" [PREDICTION] analysisType: \(analysisType)")
        print(" [PREDICTION] events.count: \(events.count)")
        print(" [PREDICTION] allEvents.count: \(allEvents.count)")
        
        guard analysisType == .predictions else { 
            print(" [PREDICTION]  Wrong analysis type: \(analysisType)")
            return 
        }
        
        guard !events.isEmpty else { 
            print(" [PREDICTION]  No events available")
            return 
        }
        
        print(" [PREDICTION]  Starting prediction calculation...")
        isCalculatingPrediction = true
        
        Task.detached(priority: .userInitiated) {
            do {
                // Get bridge info from events
                guard let firstEvent = events.first else { 
                    print(" [PREDICTION]  No first event found")
                    await MainActor.run {
                        self.isCalculatingPrediction = false
                    }
                    return 
                }
                
                print(" [PREDICTION] Bridge: \(firstEvent.entityName) (ID: \(firstEvent.entityID))")
                
                let bridgeInfo = DrawbridgeInfo(
                    entityID: firstEvent.entityID,
                    entityName: firstEvent.entityName,
                    entityType: firstEvent.entityType,
                    latitude: firstEvent.latitude,
                    longitude: firstEvent.longitude
                )
                
                // Use a simplified prediction calculation for better performance
                let prediction = await calculateSimplePrediction(for: bridgeInfo, events: allEvents)
                
                await MainActor.run {
                    self.currentPrediction = prediction
                    self.isCalculatingPrediction = false
                    print(" [PREDICTION]  Updated prediction for \(bridgeInfo.entityName): \(prediction?.probabilityText ?? "No Data")")
                }
            } catch {
                print(" [PREDICTION]  Error: \(error)")
                await MainActor.run {
                    self.isCalculatingPrediction = false
                }
            }
        }
    }
    
    // MARK: - REWRITE: Statistical Prediction Calculation
    private func calculateSimplePrediction(for bridge: DrawbridgeInfo, events: [DrawbridgeEvent]) async -> BridgePrediction? {
        print("📊 [STATS] Statistical prediction for \(bridge.entityName)")
        
        let calendar = Calendar.current
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)
        let currentWeekday = calendar.component(.weekday, from: now)
        
        // Get all bridge events for analysis
        let bridgeEvents = events.filter { $0.entityID == bridge.entityID }
        
        print("📊 [STATS] Total bridge events: \(bridgeEvents.count)")
        
        // STATISTICAL TIME WINDOWS - Use increasingly wider windows until we have sufficient data
        let timeWindows = [
            ("exact", 0),     // Exact hour and weekday
            ("±1hr", 1),      // ±1 hour, same weekday  
            ("±2hr", 2),      // ±2 hours, same weekday
            ("weekday", -1),  // Any hour, same weekday type (weekend/weekday)
            ("alltime", -2)   // All historical data for this bridge
        ]
        
        var bestWindow: (name: String, events: [DrawbridgeEvent], confidence: Double)?
        
        for (windowName, hourRange) in timeWindows {
            let windowEvents: [DrawbridgeEvent]
            
            switch hourRange {
            case 0: // Exact time
                windowEvents = bridgeEvents.filter { 
                    calendar.component(.hour, from: $0.openDateTime) == currentHour &&
                    calendar.component(.weekday, from: $0.openDateTime) == currentWeekday
                }
            case 1, 2: // Hour range, same weekday
                windowEvents = bridgeEvents.filter { event in
                    let eventHour = calendar.component(.hour, from: event.openDateTime)
                    let eventWeekday = calendar.component(.weekday, from: event.openDateTime)
                    return eventWeekday == currentWeekday && abs(eventHour - currentHour) <= hourRange
                }
            case -1: // Same weekday type (weekend vs weekday)
                let isCurrentWeekend = currentWeekday == 1 || currentWeekday == 7
                windowEvents = bridgeEvents.filter { event in
                    let eventWeekday = calendar.component(.weekday, from: event.openDateTime)
                    let isEventWeekend = eventWeekday == 1 || eventWeekday == 7
                    return isCurrentWeekend == isEventWeekend
                }
            case -2: // All time
                windowEvents = bridgeEvents
            default:
                continue
            }
            
            let confidence = calculateWindowConfidence(
                windowName: windowName,
                eventCount: windowEvents.count,
                totalEvents: bridgeEvents.count
            )
            
            print("📊 [WINDOW] \(windowName): \(windowEvents.count) events, confidence: \(String(format: "%.2f", confidence))")
            
            // Use the first window with reasonable data
            if windowEvents.count >= 3 || windowName == "alltime" {
                bestWindow = (windowName, windowEvents, confidence)
                break
            }
        }
        
        guard let selectedWindow = bestWindow else {
            // Fallback to system-wide analysis
            return createSystemWideFallback(bridge: bridge, allEvents: events, currentHour: currentHour, currentWeekday: currentWeekday)
        }
        
        // Calculate probability based on selected window
        let probability = calculateWindowProbability(
            events: selectedWindow.events,
            windowName: selectedWindow.name,
            currentHour: currentHour,
            currentWeekday: currentWeekday,
            totalBridgeEvents: bridgeEvents.count
        )
        
        // Calculate expected duration
        let averageDuration = selectedWindow.events.isEmpty ? 
            15.0 : selectedWindow.events.map(\.minutesOpen).reduce(0, +) / Double(selectedWindow.events.count)
        
        // Create detailed reasoning
        let reasoning = createStatisticalReasoning(
            windowName: selectedWindow.name,
            eventCount: selectedWindow.events.count,
            totalEvents: bridgeEvents.count,
            currentHour: currentHour,
            currentWeekday: currentWeekday
        )
        
        print("📊 [FINAL] Window: \(selectedWindow.name), Probability: \(String(format: "%.1f%%", probability * 100)), Confidence: \(String(format: "%.2f", selectedWindow.confidence))")
        
        return BridgePrediction(
            bridge: bridge,
            probability: probability,
            expectedDuration: averageDuration,
            confidence: selectedWindow.confidence,
            timeFrame: "next hour",
            reasoning: reasoning
        )
    }
    
    // MARK: - NEW: Window Confidence Calculation
    private func calculateWindowConfidence(windowName: String, eventCount: Int, totalEvents: Int) -> Double {
        let baseConfidence: Double
        
        switch windowName {
        case "exact":
            baseConfidence = eventCount >= 10 ? 0.9 : (eventCount >= 5 ? 0.7 : 0.4)
        case "±1hr":
            baseConfidence = eventCount >= 15 ? 0.8 : (eventCount >= 8 ? 0.6 : 0.4)
        case "±2hr":
            baseConfidence = eventCount >= 20 ? 0.7 : (eventCount >= 10 ? 0.5 : 0.3)
        case "weekday":
            baseConfidence = eventCount >= 30 ? 0.6 : (eventCount >= 15 ? 0.4 : 0.25)
        case "alltime":
            baseConfidence = eventCount >= 50 ? 0.5 : (eventCount >= 20 ? 0.3 : 0.2)
        default:
            baseConfidence = 0.2
        }
        
        // Adjust for total sample size
        let sampleSizeMultiplier = min(1.0, Double(totalEvents) / 50.0)
        
        return baseConfidence * sampleSizeMultiplier
    }
    
    // MARK: - NEW: Window Probability Calculation
    private func calculateWindowProbability(
        events: [DrawbridgeEvent],
        windowName: String,
        currentHour: Int,
        currentWeekday: Int,
        totalBridgeEvents: Int
    ) -> Double {
        
        guard !events.isEmpty else { return 0.05 }
        
        let probability: Double
        
        switch windowName {
        case "exact":
            // Direct probability calculation for exact time match
            let totalPossibleHours = calculateTotalPossibleHours(for: events, weekday: currentWeekday, hour: currentHour)
            probability = Double(events.count) / Double(max(totalPossibleHours, 1))
            
        case "±1hr", "±2hr":
            // Adjust for time window size
            let windowSize = windowName == "±1hr" ? 3.0 : 5.0 // ±1hr = 3 hours total, ±2hr = 5 hours total
            let windowRate = Double(events.count) / Double(totalBridgeEvents)
            probability = windowRate * (windowSize / 24.0) // Scale to single hour
            
        case "weekday":
            // Weekend vs weekday probability
            let weekdayTypeRate = Double(events.count) / Double(totalBridgeEvents)
            let hoursInWeekdayType = (currentWeekday == 1 || currentWeekday == 7) ? (2.0 * 24.0) : (5.0 * 24.0)
            probability = weekdayTypeRate / hoursInWeekdayType * 24.0 // Scale to single hour
            
        case "alltime":
            // Overall rate scaled to current time patterns
            let overallRate = Double(events.count) / Double(totalBridgeEvents)
            probability = overallRate / 24.0 // Assume even distribution across hours
            
        default:
            probability = 0.05
        }
        
        return max(0.01, min(0.75, probability))
    }
    
    // MARK: - NEW: Statistical Reasoning Generator
    private func createStatisticalReasoning(
        windowName: String,
        eventCount: Int,
        totalEvents: Int,
        currentHour: Int,
        currentWeekday: Int
    ) -> String {
        
        let dayName = Calendar.current.weekdaySymbols[currentWeekday - 1]
        let hourText = formatHour(currentHour)
        
        let windowDescription: String
        switch windowName {
        case "exact":
            windowDescription = "exact time match (\(dayName)s at \(hourText))"
        case "±1hr":
            windowDescription = "±1 hour window on \(dayName)s"
        case "±2hr":
            windowDescription = "±2 hour window on \(dayName)s"
        case "weekday":
            let dayType = (currentWeekday == 1 || currentWeekday == 7) ? "weekend" : "weekday"
            windowDescription = "\(dayType) patterns"
        case "alltime":
            windowDescription = "historical patterns (all times)"
        default:
            windowDescription = "statistical analysis"
        }
        
        return "Based on \(eventCount) events from \(windowDescription). Total dataset: \(totalEvents) events."
    }
    
    // MARK: - NEW: System-Wide Fallback
    private func createSystemWideFallback(
        bridge: DrawbridgeInfo,
        allEvents: [DrawbridgeEvent],
        currentHour: Int,
        currentWeekday: Int
    ) -> BridgePrediction {
        
        let systemWidePattern = calculateSystemWidePattern(
            hour: currentHour,
            weekday: currentWeekday,
            allEvents: allEvents
        )
        
        let reasoning = "Insufficient bridge-specific data. Using system-wide patterns from \(allEvents.count) total events across all bridges."
        
        return BridgePrediction(
            bridge: bridge,
            probability: systemWidePattern.probability,
            expectedDuration: calculateSystemWideAverageDuration(allEvents: allEvents),
            confidence: 0.3,
            timeFrame: "next hour",
            reasoning: reasoning
        )
    }
    
    // MARK: - NEW: System-Wide Pattern Analysis
    private func calculateSystemWidePattern(
        hour: Int,
        weekday: Int,
        allEvents: [DrawbridgeEvent]
    ) -> (probability: Double, confidence: Double) {
        
        let calendar = Calendar.current
        let systemWideEvents = allEvents.filter { event in
            calendar.component(.hour, from: event.openDateTime) == hour &&
            calendar.component(.weekday, from: event.openDateTime) == weekday
        }
        
        // Calculate system-wide rate for this time slot
        let totalBridges = Set(allEvents.map(\.entityID)).count
        let averageEventsPerBridge = Double(systemWideEvents.count) / Double(max(totalBridges, 1))
        
        // Convert to probability (assuming each bridge could have opened in each hour)
        let totalPossibleHours = calculateSystemWidePossibleHours(
            hour: hour,
            weekday: weekday,
            allEvents: allEvents
        )
        
        let systemProbability = averageEventsPerBridge / Double(max(totalPossibleHours, 1))
        
        print("📊 [SYSTEM] System-wide: \(systemWideEvents.count) events, \(totalBridges) bridges, probability: \(String(format: "%.1f%%", systemProbability * 100))")
        
        return (max(0.01, min(0.30, systemProbability)), 0.4)
    }
    
    // MARK: - NEW: Utility Functions
    private func calculateSystemWideAverageDuration(allEvents: [DrawbridgeEvent]) -> Double {
        guard !allEvents.isEmpty else { return 15.0 }
        return allEvents.map(\.minutesOpen).reduce(0, +) / Double(allEvents.count)
    }
    
    private func calculateSystemWidePossibleHours(hour: Int, weekday: Int, allEvents: [DrawbridgeEvent]) -> Int {
        guard let earliest = allEvents.map(\.openDateTime).min(),
              let latest = allEvents.map(\.openDateTime).max() else {
            return 1
        }
        
        let calendar = Calendar.current
        var count = 0
        var currentDate = earliest
        
        while currentDate <= latest {
            let components = calendar.dateComponents([.weekday, .hour], from: currentDate)
            if components.weekday == weekday && components.hour == hour {
                count += 1
            }
            currentDate = calendar.date(byAdding: .hour, value: 1, to: currentDate) ?? latest
        }
        
        return max(count, 1)
    }
    
    private func calculateTotalPossibleHours(for events: [DrawbridgeEvent], weekday: Int, hour: Int) -> Int {
        guard let earliest = events.map(\.openDateTime).min(),
              let latest = events.map(\.openDateTime).max() else {
            return 1
        }
        
        let calendar = Calendar.current
        var count = 0
        var currentDate = earliest
        
        while currentDate <= latest {
            let components = calendar.dateComponents([.weekday, .hour], from: currentDate)
            if components.weekday == weekday && components.hour == hour {
                count += 1
            }
            currentDate = calendar.date(byAdding: .hour, value: 1, to: currentDate) ?? latest
        }
        
        return max(count, 1)
    }
    
    private func formatHour(_ hour: Int) -> String {
        return hour == 0 ? "12 AM" : 
               hour < 12 ? "\(hour) AM" :
               hour == 12 ? "12 PM" : "\(hour - 12) PM"
    }
    
    // MARK: - RESTORED: Utility Functions
    private func calculatePatternBasedProbability(hour: Int, weekday: Int, bridge: DrawbridgeInfo) -> Double {
        print(" [PATTERN] Using pattern-based probability fallback (insufficient data)")
        
        var baseProbability = 0.10 // Conservative default
        
        // Time-based patterns (reduced from previous overly optimistic values)
        switch hour {
        case 6...9: baseProbability = 0.15    // Morning - reduced from 0.25
        case 11...13: baseProbability = 0.12  // Lunch - reduced from 0.20
        case 17...19: baseProbability = 0.18  // Evening - reduced from 0.30
        case 20...22: baseProbability = 0.14  // Evening activity - reduced from 0.18
        default: baseProbability = 0.05       // Off-peak - reduced from 0.08
        }
        
        // Weekend adjustment (more conservative)
        let isWeekend = weekday == 1 || weekday == 7
        if isWeekend {
            baseProbability *= 1.1 // Reduced from 1.2
        }
        
        // Bridge-specific adjustments (more conservative)
        switch bridge.entityName.lowercased() {
        case let name where name.contains("fremont"):
            baseProbability *= 1.15 // Reduced from 1.3
        case let name where name.contains("ballard"):
            baseProbability *= 1.05 // Reduced from 1.1
        case let name where name.contains("university"):
            baseProbability *= 0.95 // Reduced from 0.9
        default:
            baseProbability *= 1.0
        }
        
        // More conservative caps
        return max(0.02, min(0.25, baseProbability)) // Reduced max from 0.40 to 0.25
    }
    
    // MARK: - Computed Properties
    private var periodDescription: String {
        switch timePeriod {
        case .twentyFourHours: return "Last 24 Hours"
        case .sevenDays: return "Last 7 Days"
        case .thirtyDays: return "Last 30 Days"
        case .ninetyDays: return "Last 90 Days"
        }
    }
    
    private var analysisSpecificTitle: String {
        switch analysisType {
        case .patterns: return "Avg Duration"
        case .cascade: return "Peak Hour"
        case .predictions: return "Next Probability"
        case .impact: return "High Impact"
        }
    }
    
    private var analysisSpecificValue: String {
        switch analysisType {
        case .patterns:
            guard !events.isEmpty else { return "0 min" }
            let avg = events.map(\.minutesOpen).reduce(0, +) / Double(events.count)
            return String(format: "%.0f min", avg)
        case .cascade:
            return peakHour
        case .predictions:
            if isCalculatingPrediction {
                return "..."
            } else if let prediction = currentPrediction {
                return prediction.probabilityText
            } else {
                let hour = Calendar.current.component(.hour, from: Date())
                let weekday = Calendar.current.component(.weekday, from: Date())
                let bridgeEvents = events.filter { event in
                    Calendar.current.component(.hour, from: event.openDateTime) == hour &&
                    Calendar.current.component(.weekday, from: event.openDateTime) == weekday
                }
                
                if bridgeEvents.count < 5 {
                    return "Low Data"
                } else {
                    let prob = calculateQuickProbability(for: events, hour: hour)
                    switch prob {
                    case 0.0..<0.15: return "Very Low"
                    case 0.15..<0.35: return "Low"
                    case 0.35..<0.65: return "Moderate"
                    case 0.65..<0.85: return "High"
                    case 0.85...1.0: return "Very High"
                    default: return "Unknown"
                    }
                }
            }
        case .impact:
            let highImpact = events.filter { $0.minutesOpen > 30 }.count
            return "\(highImpact)"
        }
    }
    
    private var analysisSpecificIcon: String {
        switch analysisType {
        case .patterns: return "timer"
        case .cascade: return "arrow.triangle.branch"
        case .predictions: return "crystal.ball"
        case .impact: return "exclamationmark.triangle.fill"
        }
    }
    
    private var analysisSpecificColor: Color {
        switch analysisType {
        case .patterns: return .orange
        case .cascade: return .purple
        case .predictions: 
            if let prediction = currentPrediction {
                switch prediction.probability {
                case 0.0..<0.15: return .green
                case 0.15..<0.35: return .green
                case 0.35..<0.65: return .orange
                case 0.65..<0.85: return .red
                case 0.85...1.0: return .red
                default: return .gray
                }
            } else {
                return .gray
            }
        case .impact: return .red
        }
    }
    
    private var peakHour: String {
        let calendar = Calendar.current
        var hourCounts: [Int: Int] = [:]
        
        for event in events {
            let hour = calendar.component(.hour, from: event.openDateTime)
            hourCounts[hour, default: 0] += 1
        }
        
        if let peak = hourCounts.max(by: { $0.value < $1.value }) {
            return "\(peak.key):00"
        }
        return "None"
    }
    
    private var longestDurationText: String {
        guard let longest = events.map(\.minutesOpen).max() else { return "0 min" }
        return String(format: "%.0f min", longest)
    }
    
    private var mostActiveDayText: String {
        guard !events.isEmpty else { return "None" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        
        let dayGroups = Dictionary(grouping: events) { event in
            formatter.string(from: event.openDateTime)
        }
        
        let mostActiveDay = dayGroups.max { $0.value.count < $1.value.count }
        return mostActiveDay?.key ?? "None"
    }
}

private func calculateQuickProbability(for events: [DrawbridgeEvent], hour: Int) -> Double {
    guard !events.isEmpty else { return 0.05 }
    
    let hourlyEvents = events.filter {
        Calendar.current.component(.hour, from: $0.openDateTime) == hour
    }
    
    print(" [QUICK] Found \(hourlyEvents.count) events at hour \(hour) out of \(events.count) total")
    
    if hourlyEvents.count < 3 {
        return 0.05 
    }
    
    let hourlyRate = Double(hourlyEvents.count) / Double(events.count)
    let scaledProbability = hourlyRate * 24.0 
    
    return min(0.80, max(0.05, scaledProbability))
}

#Preview {
    BridgeStatsSection(
        events: [],
        timePeriod: .sevenDays,
        analysisType: .patterns
    )
    .padding()
}