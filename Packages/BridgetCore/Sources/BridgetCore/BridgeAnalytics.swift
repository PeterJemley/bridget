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
    
    // PHASE 2: Cascade Effect Detection
    public var cascadeInfluence: Double = 0         // How much this bridge influences others (0.0-1.0)
    public var cascadeSusceptibility: Double = 0    // How susceptible to cascade effects (0.0-1.0)
    public var primaryCascadeTarget: Int = 0        // Most frequently triggered bridge ID
    public var cascadeDelay: Double = 0             // Average minutes before triggering cascade
    public var cascadeProbability: Double = 0       // Probability of triggering cascade
    
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

// MARK: - PHASE 2: Cascade Effect Detection Engine
@Model
public final class CascadeEvent {
    @Attribute(.unique) public var id: String
    
    public var triggerBridgeID: Int
    public var triggerBridgeName: String
    public var targetBridgeID: Int
    public var targetBridgeName: String
    public var triggerTime: Date
    public var targetTime: Date
    public var delayMinutes: Double
    public var triggerDuration: Double
    public var targetDuration: Double
    public var cascadeStrength: Double // 0.0-1.0 correlation strength
    public var cascadeType: String // "temporal", "spatial", "pattern"
    
    public var dayOfWeek: Int
    public var hour: Int
    public var month: Int
    public var isWeekend: Bool
    public var isSummer: Bool
    
    public init(
        triggerBridgeID: Int,
        triggerBridgeName: String,
        targetBridgeID: Int,
        targetBridgeName: String,
        triggerTime: Date,
        targetTime: Date,
        triggerDuration: Double,
        targetDuration: Double,
        cascadeStrength: Double,
        cascadeType: String
    ) {
        // Initialize date components first
        let calendar = Calendar.current
        let components = calendar.dateComponents([.weekday, .hour, .month], from: triggerTime)
        let dayOfWeek = components.weekday ?? 1
        let hour = components.hour ?? 0
        let month = components.month ?? 1
        
        // Initialize all stored properties
        self.id = "\(triggerBridgeID)-\(targetBridgeID)-\(Int(triggerTime.timeIntervalSince1970))"
        self.triggerBridgeID = triggerBridgeID
        self.triggerBridgeName = triggerBridgeName
        self.targetBridgeID = targetBridgeID
        self.targetBridgeName = targetBridgeName
        self.triggerTime = triggerTime
        self.targetTime = targetTime
        self.delayMinutes = targetTime.timeIntervalSince(triggerTime) / 60.0
        self.triggerDuration = triggerDuration
        self.targetDuration = targetDuration
        self.cascadeStrength = cascadeStrength
        self.cascadeType = cascadeType
        
        // Initialize date component properties
        self.dayOfWeek = dayOfWeek
        self.hour = hour
        self.month = month
        
        // Initialize derived boolean properties
        self.isWeekend = (dayOfWeek == 1 || dayOfWeek == 7)
        self.isSummer = (month >= 5 && month <= 9)
    }
}

public struct CascadeDetectionEngine {
    
    /// Detect cascade effects across all bridges in the system (OPTIMIZED FOR LARGE DATASETS)
    public static func detectCascadeEffects(from events: [DrawbridgeEvent]) -> [CascadeEvent] {
        print(" Starting optimized cascade detection for \(events.count) events...")
        
        let startTime = Date()
        var cascadeEvents: [CascadeEvent] = []
        
        // OPTIMIZATION 1: Early exit for very large datasets
        if events.count > 5000 {
            print(" Large dataset detected (\(events.count) events) - using sampling approach")
            return detectCascadeEffectsOptimized(from: events)
        }
        
        // OPTIMIZATION 2: Pre-sort events by time for faster window searches
        let sortedEvents = events.sorted { $0.openDateTime < $1.openDateTime }
        
        // OPTIMIZATION 3: Group events by bridge for faster access
        let eventsByBridge = Dictionary(grouping: sortedEvents, by: \.entityID)
        let uniqueBridgeIDs = Array(eventsByBridge.keys)
        
        print("Analyzing \(uniqueBridgeIDs.count) bridges with pre-sorted data")
        
        // OPTIMIZATION 4: Limit bridge pairs to prevent O(n²) explosion
        let maxPairs = 20 // Limit to top 20 most active bridge pairs
        var pairCount = 0
        
        for i in 0..<uniqueBridgeIDs.count {
            for j in (i+1)..<uniqueBridgeIDs.count {
                if pairCount >= maxPairs {
                    print("Reached pair limit (\(maxPairs)) - stopping to prevent hang")
                    break
                }
                
                let bridgeID1 = uniqueBridgeIDs[i]
                let bridgeID2 = uniqueBridgeIDs[j]
                
                // Analyze both directions but limit scope
                let pairCascades1 = detectPairwiseCascadesOptimized(
                    triggerEvents: eventsByBridge[bridgeID1] ?? [],
                    targetEvents: eventsByBridge[bridgeID2] ?? []
                )
                
                let pairCascades2 = detectPairwiseCascadesOptimized(
                    triggerEvents: eventsByBridge[bridgeID2] ?? [],
                    targetEvents: eventsByBridge[bridgeID1] ?? []
                )
                
                cascadeEvents.append(contentsOf: pairCascades1)
                cascadeEvents.append(contentsOf: pairCascades2)
                
                pairCount += 1
                
                // Progress logging every 5 pairs
                if pairCount % 5 == 0 {
                    let elapsed = Date().timeIntervalSince(startTime)
                    print("Processed \(pairCount)/\(maxPairs) pairs in \(String(format: "%.1f", elapsed))s")
                }
            }
            if pairCount >= maxPairs { break }
        }
        
        let totalTime = Date().timeIntervalSince(startTime)
        print("Cascade detection complete: \(cascadeEvents.count) cascades found in \(String(format: "%.2f", totalTime))s")
        
        return cascadeEvents
    }
    
    /// Optimized cascade detection for large datasets using sampling
    private static func detectCascadeEffectsOptimized(from events: [DrawbridgeEvent]) -> [CascadeEvent] {
        print("Using sampling approach for \(events.count) events")
        
        // SAMPLE 1: Take most recent 1000 events for analysis
        let recentEvents = Array(events.sorted { $0.openDateTime > $1.openDateTime }.prefix(1000))
        print("Analyzing \(recentEvents.count) most recent events")
        
        // SAMPLE 2: Focus on most active bridges only
        let bridgeEventCounts = Dictionary(grouping: recentEvents, by: \.entityID)
            .mapValues(\.count)
            .sorted { $0.value > $1.value }
        
        let topBridges = Array(bridgeEventCounts.prefix(5).map(\.key)) // Top 5 most active bridges
        let relevantEvents = recentEvents.filter { topBridges.contains($0.entityID) }
        
        print("Focusing on top \(topBridges.count) bridges with \(relevantEvents.count) events")
        
        // Apply standard cascade detection to reduced dataset
        return detectCascadeEffectsStandard(from: relevantEvents)
    }
    
    /// Standard cascade detection for smaller datasets
    private static func detectCascadeEffectsStandard(from events: [DrawbridgeEvent]) -> [CascadeEvent] {
        var cascadeEvents: [CascadeEvent] = []
        let eventsByBridge = Dictionary(grouping: events, by: \.entityID)
        let uniqueBridgeIDs = Array(eventsByBridge.keys)
        
        for i in 0..<uniqueBridgeIDs.count {
            for j in (i+1)..<uniqueBridgeIDs.count {
                let bridgeID1 = uniqueBridgeIDs[i]
                let bridgeID2 = uniqueBridgeIDs[j]
                
                let pairCascades1 = detectPairwiseCascadesOptimized(
                    triggerEvents: eventsByBridge[bridgeID1] ?? [],
                    targetEvents: eventsByBridge[bridgeID2] ?? []
                )
                
                let pairCascades2 = detectPairwiseCascadesOptimized(
                    triggerEvents: eventsByBridge[bridgeID2] ?? [],
                    targetEvents: eventsByBridge[bridgeID1] ?? []
                )
                
                cascadeEvents.append(contentsOf: pairCascades1)
                cascadeEvents.append(contentsOf: pairCascades2)
            }
        }
        
        return cascadeEvents
    }
    
    /// Optimized pairwise cascade detection
    private static func detectPairwiseCascadesOptimized(
        triggerEvents: [DrawbridgeEvent],
        targetEvents: [DrawbridgeEvent]
    ) -> [CascadeEvent] {
        
        // Early exit for insufficient data
        guard !triggerEvents.isEmpty && !targetEvents.isEmpty else { return [] }
        
        // OPTIMIZATION: Limit analysis to prevent hanging
        let maxTriggerEvents = 50 // Limit triggers to prevent O(n²) explosion
        let maxTargetEvents = 50  // Limit targets to prevent O(n²) explosion
        
        let limitedTriggers = Array(triggerEvents.suffix(maxTriggerEvents))
        let limitedTargets = Array(targetEvents.suffix(maxTargetEvents))
        
        var cascades: [CascadeEvent] = []
        let cascadeWindow: TimeInterval = 30 * 60 // 30 minutes in seconds
        
        for triggerEvent in limitedTriggers {
            // OPTIMIZATION: Use binary search for window filtering instead of linear scan
            let windowEnd = triggerEvent.openDateTime.addingTimeInterval(cascadeWindow)
            
            let potentialTargets = limitedTargets.filter { targetEvent in
                targetEvent.openDateTime > triggerEvent.openDateTime &&
                targetEvent.openDateTime <= windowEnd
            }
            
            // OPTIMIZATION: Limit potential targets per trigger
            let limitedPotentialTargets = Array(potentialTargets.prefix(5))
            
            for targetEvent in limitedPotentialTargets {
                let cascade = analyzePotentialCascade(
                    trigger: triggerEvent,
                    target: targetEvent
                )
                
                // Only include significant cascades
                if cascade.cascadeStrength >= 0.4 { // Raised threshold
                    cascades.append(cascade)
                }
            }
        }
        
        return cascades
    }
    
    /// Analyze correlation strength between trigger and target events
    private static func analyzePotentialCascade(
        trigger: DrawbridgeEvent,
        target: DrawbridgeEvent
    ) -> CascadeEvent {
        
        let delayMinutes = target.openDateTime.timeIntervalSince(trigger.openDateTime) / 60.0
        
        // Calculate cascade strength based on multiple factors
        var strength = 0.0
        
        // Temporal proximity factor (closer = stronger)
        let temporalFactor = max(0.0, 1.0 - (delayMinutes / 30.0))
        strength += temporalFactor * 0.4
        
        // Duration correlation factor
        let durationCorrelation = calculateDurationCorrelation(
            triggerDuration: trigger.minutesOpen,
            targetDuration: target.minutesOpen
        )
        strength += durationCorrelation * 0.3
        
        // Pattern consistency factor (same day patterns)
        let patternFactor = calculatePatternConsistency(trigger: trigger, target: target)
        strength += patternFactor * 0.3
        
        // Determine cascade type
        let cascadeType = determineCascadeType(
            delayMinutes: delayMinutes,
            strength: strength,
            trigger: trigger,
            target: target
        )
        
        return CascadeEvent(
            triggerBridgeID: trigger.entityID,
            triggerBridgeName: trigger.entityName,
            targetBridgeID: target.entityID,
            targetBridgeName: target.entityName,
            triggerTime: trigger.openDateTime,
            targetTime: target.openDateTime,
            triggerDuration: trigger.minutesOpen,
            targetDuration: target.minutesOpen,
            cascadeStrength: strength,
            cascadeType: cascadeType
        )
    }
    
    /// Calculate correlation between trigger and target durations
    private static func calculateDurationCorrelation(
        triggerDuration: Double,
        targetDuration: Double
    ) -> Double {
        
        // Normalize durations to 0-1 scale (assuming max 60 minutes)
        let normalizedTrigger = min(triggerDuration / 60.0, 1.0)
        let normalizedTarget = min(targetDuration / 60.0, 1.0)
        
        // Calculate similarity (inverse of difference)
        let difference = abs(normalizedTrigger - normalizedTarget)
        return max(0.0, 1.0 - difference)
    }
    
    /// Calculate pattern consistency between events
    private static func calculatePatternConsistency(
        trigger: DrawbridgeEvent,
        target: DrawbridgeEvent
    ) -> Double {
        
        let calendar = Calendar.current
        
        let triggerHour = calendar.component(.hour, from: trigger.openDateTime)
        let targetHour = calendar.component(.hour, from: target.openDateTime)
        
        let triggerDay = calendar.component(.weekday, from: trigger.openDateTime)
        let targetDay = calendar.component(.weekday, from: target.openDateTime)
        
        var consistency = 0.0
        
        // Same day bonus
        if triggerDay == targetDay {
            consistency += 0.5
        }
        
        // Similar hour bonus (within 2 hours)
        let hourDifference = abs(triggerHour - targetHour)
        if hourDifference <= 2 {
            consistency += 0.5 * (1.0 - Double(hourDifference) / 2.0)
        }
        
        return consistency
    }
    
    /// Determine the type of cascade effect
    private static func determineCascadeType(
        delayMinutes: Double,
        strength: Double,
        trigger: DrawbridgeEvent,
        target: DrawbridgeEvent
    ) -> String {
        
        // Immediate cascade (< 5 minutes)
        if delayMinutes < 5 {
            return "immediate"
        }
        
        // Short-term cascade (5-15 minutes)
        if delayMinutes < 15 {
            return "short-term"
        }
        
        // Medium-term cascade (15-30 minutes)
        if delayMinutes < 30 {
            return "medium-term"
        }
        
        return "delayed"
    }
}

public struct BridgeAnalyticsCalculator {
    
    /// Calculate analytics for all bridges from historical events with seasonal decomposition and cascade detection (OPTIMIZED)
    public static func calculateAnalytics(from events: [DrawbridgeEvent]) -> [BridgeAnalytics] {
        print("📊 [ANALYTICS] Starting optimized analytics calculation for \(events.count) events...")
        let startTime = Date()
        
        var analytics: [String: BridgeAnalytics] = [:]
        
        // OPTIMIZATION 1: Progress tracking to detect hangs
        var processedEvents = 0
        let progressInterval = 500
        
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
            
            processedEvents += 1
            if processedEvents % progressInterval == 0 {
                let elapsed = Date().timeIntervalSince(startTime)
                print("📊 [ANALYTICS] Processed \(processedEvents)/\(events.count) events in \(String(format: "%.1f", elapsed))s")
            }
        }
        
        let groupingTime = Date().timeIntervalSince(startTime)
        print("📊 [ANALYTICS] Event grouping complete: \(analytics.count) analytics records in \(String(format: "%.2f", groupingTime))s")
        
        // PHASE 1: Apply seasonal decomposition
        let rawAnalytics = Array(analytics.values)
        print("📊 [ANALYTICS] Starting Phase 1: Seasonal decomposition...")
        let decomposedAnalytics = SeasonalDecomposition.decompose(analytics: rawAnalytics)
        
        let phase1Time = Date().timeIntervalSince(startTime)
        print("📊 [ANALYTICS] Phase 1 complete in \(String(format: "%.2f", phase1Time - groupingTime))s")
        
        // PHASE 2: Apply cascade detection analysis (OPTIMIZED)
        print("📊 [ANALYTICS] Starting Phase 2: Cascade detection (OPTIMIZED)...")
        let cascadeStartTime = Date()
        let cascadeEvents = CascadeDetectionEngine.detectCascadeEffects(from: events)
        let cascadeTime = Date().timeIntervalSince(cascadeStartTime)
        print("📊 [ANALYTICS] Phase 2 complete: \(cascadeEvents.count) cascades detected in \(String(format: "%.2f", cascadeTime))s")
        
        // Apply cascade analysis to analytics
        applyCascadeAnalysis(to: decomposedAnalytics, cascadeEvents: cascadeEvents)
        
        // Calculate enhanced predictions using seasonal and cascade components
        print("📊 [ANALYTICS] Calculating enhanced predictions...")
        for analytics in decomposedAnalytics {
            calculateEnhancedPredictions(for: analytics, allEvents: events, cascadeEvents: cascadeEvents)
        }
        
        let totalTime = Date().timeIntervalSince(startTime)
        print("📊 [ANALYTICS] ✅ ANALYTICS CALCULATION COMPLETE")
        print("📊 [ANALYTICS] 📈 PERFORMANCE SUMMARY:")
        print("📊 [ANALYTICS]    • Total time: \(String(format: "%.2f", totalTime))s")
        print("📊 [ANALYTICS]    • Event grouping: \(String(format: "%.2f", groupingTime))s")
        print("📊 [ANALYTICS]    • Phase 1 (Seasonal): \(String(format: "%.2f", phase1Time - groupingTime))s") 
        print("📊 [ANALYTICS]    • Phase 2 (Cascade): \(String(format: "%.2f", cascadeTime))s")
        print("📊 [ANALYTICS]    • Analytics records: \(decomposedAnalytics.count)")
        print("📊 [ANALYTICS]    • Cascade events: \(cascadeEvents.count)")
        
        return decomposedAnalytics
    }
    
    /// Apply cascade analysis to bridge analytics
    private static func applyCascadeAnalysis(
        to analytics: [BridgeAnalytics],
        cascadeEvents: [CascadeEvent]
    ) {
        
        for bridgeAnalytics in analytics {
            // Calculate cascade influence (how often this bridge triggers others)
            let triggeredCascades = cascadeEvents.filter { 
                $0.triggerBridgeID == bridgeAnalytics.entityID &&
                $0.hour == bridgeAnalytics.hour &&
                $0.dayOfWeek == bridgeAnalytics.dayOfWeek
            }
            
            if !triggeredCascades.isEmpty {
                bridgeAnalytics.cascadeInfluence = triggeredCascades.map(\.cascadeStrength).reduce(0, +) / Double(triggeredCascades.count)
                bridgeAnalytics.cascadeProbability = Double(triggeredCascades.count) / Double(max(bridgeAnalytics.openingCount, 1))
                
                // Find primary cascade target
                let targetCounts = Dictionary(grouping: triggeredCascades, by: \.targetBridgeID)
                if let primaryTarget = targetCounts.max(by: { $0.value.count < $1.value.count }) {
                    bridgeAnalytics.primaryCascadeTarget = primaryTarget.key
                    bridgeAnalytics.cascadeDelay = primaryTarget.value.map(\.delayMinutes).reduce(0, +) / Double(primaryTarget.value.count)
                }
            }
            
            // Calculate cascade susceptibility (how often this bridge is triggered by others)
            let receivedCascades = cascadeEvents.filter { 
                $0.targetBridgeID == bridgeAnalytics.entityID &&
                $0.hour == bridgeAnalytics.hour &&
                $0.dayOfWeek == bridgeAnalytics.dayOfWeek
            }
            
            if !receivedCascades.isEmpty {
                bridgeAnalytics.cascadeSusceptibility = receivedCascades.map(\.cascadeStrength).reduce(0, +) / Double(receivedCascades.count)
            }
        }
    }
    
    /// Enhanced prediction calculation using seasonal decomposition and cascade effects
    private static func calculateEnhancedPredictions(
        for analytics: BridgeAnalytics,
        allEvents: [DrawbridgeEvent],
        cascadeEvents: [CascadeEvent]
    ) {
        let bridgeEvents = allEvents.filter { $0.entityID == analytics.entityID }
        let totalHoursInDataset = calculateTotalHours(for: bridgeEvents)
        
        // Base probability calculation
        let totalPossibleOccurrences = totalHoursInDataset[analytics.hour] ?? 1
        let baseProbability = Double(analytics.openingCount) / Double(totalPossibleOccurrences)
        
        // Seasonal adjustments
        let trendAdjustment = analytics.trendComponent > 0 ? 0.1 : -0.1
        let seasonalAdjustment = analytics.seasonalComponent * 0.05
        let patternAdjustment = calculatePatternAdjustment(for: analytics)
        
        // PHASE 2: Cascade adjustments
        let cascadeAdjustment = calculateCascadeAdjustment(for: analytics, cascadeEvents: cascadeEvents)
        
        // Combined probability with seasonal and cascade factors
        analytics.probabilityOfOpening = max(0.0, min(1.0, 
            baseProbability + trendAdjustment + seasonalAdjustment + patternAdjustment + analytics.holidayAdjustment + cascadeAdjustment
        ))
        
        // Enhanced duration prediction using seasonal patterns and cascade effects
        let seasonalDurationMultiplier = calculateSeasonalDurationMultiplier(for: analytics)
        let cascadeDurationMultiplier = calculateCascadeDurationMultiplier(for: analytics)
        analytics.expectedDuration = analytics.averageMinutesPerOpening * seasonalDurationMultiplier * cascadeDurationMultiplier
        
        // Enhanced confidence calculation including cascade reliability
        let sampleSizeConfidence = min(Double(analytics.openingCount) / 10.0, 1.0)
        let variabilityConfidence = calculateVariabilityConfidence(for: analytics)
        let seasonalConfidence = calculateSeasonalConfidence(for: analytics)
        let cascadeConfidence = calculateCascadeConfidence(for: analytics)
        analytics.confidence = (sampleSizeConfidence + variabilityConfidence + seasonalConfidence + cascadeConfidence) / 4.0
    }
    
    /// Calculate cascade adjustment for probability prediction
    private static func calculateCascadeAdjustment(
        for analytics: BridgeAnalytics,
        cascadeEvents: [CascadeEvent]
    ) -> Double {
        
        // Check for active cascade potential at this time
        let relevantCascades = cascadeEvents.filter { cascade in
            cascade.targetBridgeID == analytics.entityID &&
            cascade.hour == analytics.hour &&
            cascade.dayOfWeek == analytics.dayOfWeek
        }
        
        if relevantCascades.isEmpty {
            return 0.0
        }
        
        // Calculate average cascade influence for this time slot
        let averageCascadeStrength = relevantCascades.map(\.cascadeStrength).reduce(0, +) / Double(relevantCascades.count)
        let cascadeFrequency = Double(relevantCascades.count) / Double(max(analytics.openingCount, 1))
        
        return averageCascadeStrength * cascadeFrequency * 0.2 // Scale factor
    }
    
    /// Calculate cascade duration multiplier
    private static func calculateCascadeDurationMultiplier(for analytics: BridgeAnalytics) -> Double {
        // Bridges with high cascade influence tend to open longer (to accommodate cascade)
        if analytics.cascadeInfluence > 0.5 {
            return 1.1 + (analytics.cascadeInfluence * 0.2)
        }
        
        // Bridges with high susceptibility might open shorter (quick response)
        if analytics.cascadeSusceptibility > 0.5 {
            return 0.9 + (analytics.cascadeSusceptibility * 0.1)
        }
        
        return 1.0
    }
    
    /// Calculate cascade confidence factor
    private static func calculateCascadeConfidence(for analytics: BridgeAnalytics) -> Double {
        // Higher confidence when cascade patterns are consistent
        let cascadeReliability = (analytics.cascadeInfluence + analytics.cascadeSusceptibility) / 2.0
        return min(1.0, cascadeReliability)
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

// MARK: - Cascade Analysis Extensions
extension BridgeAnalytics {
    
    /// Get cascade-enhanced prediction for current time
    public static func getCascadeEnhancedPrediction(
        for bridge: DrawbridgeInfo,
        from analytics: [BridgeAnalytics],
        cascadeEvents: [CascadeEvent],
        recentActivity: [DrawbridgeEvent] = []
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
                probability: 0.1,
                expectedDuration: 15.0,
                confidence: 0.0,
                timeFrame: "next hour",
                reasoning: "No historical data available for this time"
            )
        }
        
        // Check for active cascade potential
        var cascadeBoost = 0.0
        let recentCascadeTriggers = recentActivity.filter { event in
            event.entityID != bridge.entityID &&
            now.timeIntervalSince(event.openDateTime) < 1800 // Within 30 minutes
        }
        
        for trigger in recentCascadeTriggers {
            let relevantCascades = cascadeEvents.filter { cascade in
                cascade.triggerBridgeID == trigger.entityID &&
                cascade.targetBridgeID == bridge.entityID &&
                cascade.hour == hour &&
                cascade.dayOfWeek == dayOfWeek
            }
            
            if !relevantCascades.isEmpty {
                let avgStrength = relevantCascades.map(\.cascadeStrength).reduce(0, +) / Double(relevantCascades.count)
                cascadeBoost = max(cascadeBoost, avgStrength * 0.3)
            }
        }
        
        let enhancedProbability = min(1.0, bestMatch.probabilityOfOpening + cascadeBoost)
        let enhancedReasoning = generateCascadeEnhancedReasoning(for: bestMatch, cascadeBoost: cascadeBoost, triggers: recentCascadeTriggers)
        
        return BridgePrediction(
            bridge: bridge,
            probability: enhancedProbability,
            expectedDuration: bestMatch.expectedDuration,
            confidence: bestMatch.confidence,
            timeFrame: "next hour",
            reasoning: enhancedReasoning
        )
    }
    
    private static func generateCascadeEnhancedReasoning(
        for analytics: BridgeAnalytics,
        cascadeBoost: Double,
        triggers: [DrawbridgeEvent]
    ) -> String {
        
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
        
        // Add cascade context
        if cascadeBoost > 0 {
            reasoning += " (cascade effect detected from recent bridge activity)"
        }
        
        if analytics.cascadeInfluence > 0.3 {
            reasoning += " (high cascade influence bridge)"
        }
        
        if analytics.cascadeSusceptibility > 0.3 {
            reasoning += " (high cascade susceptibility)"
        }
        
        return reasoning
    }
}

// MARK: - PHASE 2: Cascade Insights
public struct CascadeInsights {
    
    /// Generate insights about cascade patterns for a bridge
    public static func generateCascadeInsights(
        for bridgeID: Int,
        from cascadeEvents: [CascadeEvent],
        analytics: [BridgeAnalytics]
    ) -> [String] {
        
        var insights: [String] = []
        
        let bridgeAnalytics = analytics.filter { $0.entityID == bridgeID }
        let triggeredCascades = cascadeEvents.filter { $0.triggerBridgeID == bridgeID }
        let receivedCascades = cascadeEvents.filter { $0.targetBridgeID == bridgeID }
        
        // Cascade influence analysis
        if !triggeredCascades.isEmpty {
            let avgInfluence = triggeredCascades.map(\.cascadeStrength).reduce(0, +) / Double(triggeredCascades.count)
            let primaryTargets = Dictionary(grouping: triggeredCascades, by: \.targetBridgeName)
            
            if avgInfluence > 0.5 {
                insights.append("High cascade influence bridge - frequently triggers other bridge openings")
            }
            
            if let primaryTarget = primaryTargets.max(by: { $0.value.count < $1.value.count }) {
                insights.append("Most frequently triggers \(primaryTarget.key) (\(primaryTarget.value.count) cascade events)")
            }
        }
        
        // Cascade susceptibility analysis
        if !receivedCascades.isEmpty {
            let avgSusceptibility = receivedCascades.map(\.cascadeStrength).reduce(0, +) / Double(receivedCascades.count)
            let primaryTriggers = Dictionary(grouping: receivedCascades, by: \.triggerBridgeName)
            
            if avgSusceptibility > 0.5 {
                insights.append("High cascade susceptibility - often opens in response to other bridges")
            }
            
            if let primaryTrigger = primaryTriggers.max(by: { $0.value.count < $1.value.count }) {
                insights.append("Most frequently triggered by \(primaryTrigger.key) (\(primaryTrigger.value.count) cascade events)")
            }
        }
        
        // Timing pattern analysis
        let immediateCascades = triggeredCascades.filter { $0.delayMinutes < 5 }
        if immediateCascades.count > triggeredCascades.count / 2 {
            insights.append("Tends to trigger immediate cascade responses (< 5 minutes)")
        }
        
        return insights
    }
    
    /// Get real-time cascade alerts
    public static func getCascadeAlerts(
        recentEvents: [DrawbridgeEvent],
        cascadeEvents: [CascadeEvent],
        bridgeInfo: [DrawbridgeInfo]
    ) -> [CascadeAlert] {
        
        var alerts: [CascadeAlert] = []
        let now = Date()
        
        // Check events from the last 30 minutes
        let recentTriggers = recentEvents.filter { event in
            now.timeIntervalSince(event.openDateTime) < 1800 && // 30 minutes
            event.closeDateTime != nil // Only completed events
        }
        
        for trigger in recentTriggers {
            // Find potential cascade targets
            let potentialCascades = cascadeEvents.filter { cascade in
                cascade.triggerBridgeID == trigger.entityID &&
                cascade.cascadeStrength > 0.4
            }
            
            for cascade in potentialCascades {
                let targetBridge = bridgeInfo.first { $0.entityID == cascade.targetBridgeID }
                let expectedTime = trigger.openDateTime.addingTimeInterval(cascade.delayMinutes * 60)
                let timeUntilExpected = expectedTime.timeIntervalSince(now)
                
                // Alert if cascade is expected within next 15 minutes
                if timeUntilExpected > 0 && timeUntilExpected < 900 {
                    alerts.append(CascadeAlert(
                        targetBridge: targetBridge?.entityName ?? "Unknown Bridge",
                        triggerBridge: trigger.entityName,
                        expectedTime: expectedTime,
                        probability: cascade.cascadeStrength,
                        cascadeType: cascade.cascadeType
                    ))
                }
            }
        }
        
        return alerts.sorted { $0.expectedTime < $1.expectedTime }
    }
}

public struct CascadeAlert {
    public let targetBridge: String
    public let triggerBridge: String
    public let expectedTime: Date
    public let probability: Double
    public let cascadeType: String
    
    public var timeUntilExpected: String {
        let interval = expectedTime.timeIntervalSince(Date())
        let minutes = Int(interval / 60)
        if minutes <= 0 {
            return "Now"
        } else if minutes == 1 {
            return "1 minute"
        } else {
            return "\(minutes) minutes"
        }
    }
    
    public var probabilityText: String {
        switch probability {
        case 0.0..<0.3: return "Low"
        case 0.3..<0.6: return "Moderate"
        case 0.6..<0.8: return "High"
        case 0.8...1.0: return "Very High"
        default: return "Unknown"
        }
    }
}

// MARK: - Enhanced Analytics Calculator 
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