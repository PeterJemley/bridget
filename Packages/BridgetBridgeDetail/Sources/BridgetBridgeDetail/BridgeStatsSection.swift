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
    
    // MARK: - ADD: Simplified Prediction Calculation
    private func calculateSimplePrediction(for bridge: DrawbridgeInfo, events: [DrawbridgeEvent]) async -> BridgePrediction? {
        print(" [PREDICTION] calculateSimplePrediction() for \(bridge.entityName)")
        
        let calendar = Calendar.current
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)
        let currentWeekday = calendar.component(.weekday, from: now)
        
        print(" [PREDICTION] Current time: \(currentWeekday) (weekday), \(currentHour) (hour)")
        
        // UPDATED: Use consistent prediction logic matching dashboard
        var baseProbability = 0.15 // Default low probability
        
        // Adjust based on time of day (common bridge opening patterns)
        switch currentHour {
        case 6...9: baseProbability = 0.4 // Morning rush hour
        case 11...13: baseProbability = 0.3 // Lunch time
        case 17...19: baseProbability = 0.5 // Evening rush hour  
        case 20...22: baseProbability = 0.25 // Evening activity
        default: baseProbability = 0.1 // Off-peak hours
        }
        
        // Weekend adjustment
        let isWeekend = currentWeekday == 1 || currentWeekday == 7
        if isWeekend {
            baseProbability *= 1.3 // Higher probability on weekends
        }
        
        // Summer adjustment (June-September)
        let isSummer = calendar.component(.month, from: now) >= 6 && calendar.component(.month, from: now) <= 9
        if isSummer {
            baseProbability *= 1.2 // Higher probability in summer
        }
        
        // Bridge-specific adjustments (based on typical Seattle bridge patterns)
        switch bridge.entityName.lowercased() {
        case let name where name.contains("fremont"):
            baseProbability *= 1.4 // Fremont is very active
        case let name where name.contains("ballard"):
            baseProbability *= 1.2 // Ballard is fairly active
        case let name where name.contains("university"):
            baseProbability *= 1.1 // University is moderately active
        default:
            baseProbability *= 1.0 // Default
        }
        
        // Cap the probability
        baseProbability = max(0.05, min(0.95, baseProbability))
        
        print(" [PREDICTION] Final probability: \(baseProbability) for \(bridge.entityName)")
        
        // Calculate expected duration based on historical data
        let bridgeEvents = events.filter { $0.entityID == bridge.entityID }
        let averageDuration = bridgeEvents.isEmpty ? 15.0 : 
            bridgeEvents.map(\.minutesOpen).reduce(0, +) / Double(bridgeEvents.count)
        
        // Calculate confidence based on data availability
        let confidence = min(1.0, Double(bridgeEvents.count) / 50.0)
        
        // Generate reasoning
        let dayName = calendar.weekdaySymbols[currentWeekday - 1]
        let hourText = currentHour == 0 ? "12 AM" : 
                      currentHour < 12 ? "\(currentHour) AM" :
                      currentHour == 12 ? "12 PM" : "\(currentHour - 12) PM"
        
        var reasoning = "Prediction for \(dayName) at \(hourText)"
        if isWeekend { reasoning += " (weekend pattern)" }
        if isSummer { reasoning += " (summer season)" }
        reasoning += " based on \(bridgeEvents.count) historical events"
        
        let prediction = BridgePrediction(
            bridge: bridge,
            probability: baseProbability,
            expectedDuration: averageDuration,
            confidence: confidence,
            timeFrame: "next hour",
            reasoning: reasoning
        )
        
        print(" [PREDICTION] Created prediction: \(prediction.probabilityText)")
        return prediction
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
                return "Calculating..."
            } else if let prediction = currentPrediction {
                return prediction.probabilityText
            } else {
                // FIXED: Show actual calculation instead of "No Data"
                let hour = Calendar.current.component(.hour, from: Date())
                let prob = calculateQuickProbability(for: events, hour: hour)
                return String(format: "%.0f%%", prob * 100)
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
                case 0.0..<0.3: return .green
                case 0.3..<0.6: return .orange
                case 0.6...1.0: return .red
                default: return .blue
                }
            } else {
                return .blue
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
    guard !events.isEmpty else { return 0.1 }
    
    // Quick probability based on current hour pattern
    let hourlyEvents = events.filter {
        Calendar.current.component(.hour, from: $0.openDateTime) == hour
    }
    
    let hourlyRate = Double(hourlyEvents.count) / Double(max(events.count, 1))
    return min(0.8, max(0.05, hourlyRate * 3.0))
}

#Preview {
    BridgeStatsSection(
        events: [],
        timePeriod: .sevenDays,
        analysisType: .patterns
    )
    .padding()
}
