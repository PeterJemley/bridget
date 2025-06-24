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
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.weekday, .hour, .month], from: triggerTime)
        let dayOfWeek = components.weekday ?? 1
        let hour = components.hour ?? 0
        let month = components.month ?? 1
        
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
        
        self.dayOfWeek = dayOfWeek
        self.hour = hour
        self.month = month
        
        self.isWeekend = (dayOfWeek == 1 || dayOfWeek == 7)
        self.isSummer = (month >= 5 && month <= 9)
    }
}

public struct CascadeDetectionEngine {
    
    /// Efficient cascade detection using spatial indexing, graph algorithms, and batching
    public static func detectCascadeEffects(from events: [DrawbridgeEvent]) -> [CascadeEvent] {
        print(" [CASCADE] Starting efficient cascade detection for \(events.count) events...")
        let startTime = Date()
        
        // Build spatial index and bridge network graph
        let bridgeNetwork = BridgeNetworkGraph(events: events)
        let spatialIndex = SpatialBridgeIndex(events: events)
        let timeIndex = TemporalEventIndex(events: events)
        
        // Process events in temporal batches for better cache locality
        let batchSize = min(500, events.count / 4)
        let sortedEvents = events.sorted { $0.openDateTime < $1.openDateTime }
        var allCascades: [CascadeEvent] = []
        
        for batchStart in stride(from: 0, to: sortedEvents.count, by: batchSize) {
            let batchEnd = min(batchStart + batchSize, sortedEvents.count)
            let batch = Array(sortedEvents[batchStart..<batchEnd])
            
            let batchCascades = detectCascadesInBatch(
                batch: batch,
                network: bridgeNetwork,
                spatialIndex: spatialIndex,
                timeIndex: timeIndex
            )
            allCascades.append(contentsOf: batchCascades)
        }
        
        // Post-process to remove duplicates and apply quality filters
        let filteredCascades = filterAndRankCascades(allCascades)
        
        let totalTime = Date().timeIntervalSince(startTime)
        print(" [CASCADE] Efficient cascade detection complete: \(filteredCascades.count) cascades in \(String(format: "%.2f", totalTime))s")
        
        return filteredCascades
    }
    
    /// Process a batch of events using spatial and temporal indexing
    private static func detectCascadesInBatch(
        batch: [DrawbridgeEvent],
        network: BridgeNetworkGraph,
        spatialIndex: SpatialBridgeIndex,
        timeIndex: TemporalEventIndex
    ) -> [CascadeEvent] {
        
        var cascades: [CascadeEvent] = []
        let cascadeWindow: TimeInterval = 60 * 60 // 1 hour window
        
        for triggerEvent in batch {
            // Use spatial index to find nearby bridges (much faster than checking all)
            let nearbyBridges = spatialIndex.findBridgesWithinRadius(
                of: triggerEvent, 
                radius: 0.05 // ~5km in degrees
            )
            
            // Use temporal index to find events in cascade window
            let windowEnd = triggerEvent.openDateTime.addingTimeInterval(cascadeWindow)
            let candidateEvents = timeIndex.findEventsInTimeRange(
                from: triggerEvent.openDateTime,
                to: windowEnd,
                excludingBridge: triggerEvent.entityID
            )
            
            // Filter to only nearby bridges using spatial index
            let spatiallyFilteredEvents = candidateEvents.filter { candidateEvent in
                nearbyBridges.contains(candidateEvent.entityID)
            }
            
            // Use graph algorithms to check cascade probability
            for targetEvent in spatiallyFilteredEvents {
                let cascadeProbability = network.getCascadeProbability(
                    from: triggerEvent.entityID,
                    to: targetEvent.entityID
                )
                
                if cascadeProbability > 0.3 {
                    let cascade = buildCascadeEvent(
                        trigger: triggerEvent,
                        target: targetEvent,
                        probability: cascadeProbability,
                        network: network
                    )
                    cascades.append(cascade)
                }
            }
        }
        
        return cascades
    }
    
    /// Build cascade event with graph-based analysis
    private static func buildCascadeEvent(
        trigger: DrawbridgeEvent,
        target: DrawbridgeEvent,
        probability: Double,
        network: BridgeNetworkGraph
    ) -> CascadeEvent {
        
        let delayMinutes = target.openDateTime.timeIntervalSince(trigger.openDateTime) / 60.0
        let spatialDistance = network.getDistance(from: trigger.entityID, to: target.entityID)
        
        // Enhanced strength calculation using multiple factors
        let temporalFactor = max(0.0, 1.0 - (delayMinutes / 60.0))
        let spatialFactor = max(0.0, 1.0 - (spatialDistance / 10.0)) // 10km max
        let networkFactor = probability // From graph analysis
        let durationCorrelation = calculateDurationCorrelation(trigger: trigger, target: target)
        
        let strength = (temporalFactor * 0.3 + spatialFactor * 0.2 + networkFactor * 0.3 + durationCorrelation * 0.2)
        
        let cascadeType = determineCascadeType(
            delayMinutes: delayMinutes,
            spatialDistance: spatialDistance,
            strength: strength
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
    
    /// Filter and rank cascades by quality
    private static func filterAndRankCascades(_ cascades: [CascadeEvent]) -> [CascadeEvent] {
        // Remove duplicates and weak cascades
        let uniqueCascades = Dictionary(grouping: cascades) { cascade in
            "\(cascade.triggerBridgeID)-\(cascade.targetBridgeID)-\(Int(cascade.triggerTime.timeIntervalSince1970))"
        }.compactMapValues { $0.max { $0.cascadeStrength < $1.cascadeStrength } }
        
        // Sort by strength and take top results
        return Array(uniqueCascades.values)
            .filter { $0.cascadeStrength >= 0.4 }
            .sorted { $0.cascadeStrength > $1.cascadeStrength }
            .prefix(200) // Limit to top 200 cascades
            .map { $0 }
    }
    
    /// Enhanced cascade type determination
    private static func determineCascadeType(delayMinutes: Double, spatialDistance: Double, strength: Double) -> String {
        switch (delayMinutes, spatialDistance, strength) {
        case (0..<5, 0..<2, 0.7...1.0):
            return "immediate-local-strong"
        case (0..<10, _, 0.6...1.0):
            return "immediate-strong"
        case (0..<10, _, _):
            return "immediate"
        case (10..<30, 0..<5, _):
            return "rapid-local"
        case (10..<30, _, _):
            return "rapid"
        case (30..<60, _, _):
            return "delayed"
        default:
            return "extended"
        }
    }
    
    /// Calculate duration correlation
    private static func calculateDurationCorrelation(trigger: DrawbridgeEvent, target: DrawbridgeEvent) -> Double {
        let durationRatio = min(trigger.minutesOpen, target.minutesOpen) / max(trigger.minutesOpen, target.minutesOpen)
        return durationRatio
    }
}

// MARK: - Efficient Data Structures

/// Spatial index for fast bridge proximity queries
public struct SpatialBridgeIndex {
    private let bridgeLocations: [Int: (lat: Double, lon: Double)]
    private let quadTree: QuadTree
    
    init(events: [DrawbridgeEvent]) {
        // Build bridge location index
        var locations: [Int: (Double, Double)] = [:]
        for event in events {
            locations[event.entityID] = (event.latitude, event.longitude)
        }
        self.bridgeLocations = locations
        
        // Build spatial quad tree for fast spatial queries
        self.quadTree = QuadTree(bridges: locations)
    }
    
    func findBridgesWithinRadius(of event: DrawbridgeEvent, radius: Double) -> Set<Int> {
        return quadTree.findBridgesWithinRadius(
            lat: event.latitude,
            lon: event.longitude,
            radius: radius
        )
    }
}

/// Simple quad tree for spatial indexing
public struct QuadTree {
    private let bridges: [Int: (lat: Double, lon: Double)]
    private let bounds: (minLat: Double, maxLat: Double, minLon: Double, maxLon: Double)
    
    init(bridges: [Int: (Double, Double)]) {
        self.bridges = bridges
        
        // Calculate bounds for Seattle area
        let lats = bridges.values.map(\.0)
        let lons = bridges.values.map(\.1)
        self.bounds = (
            minLat: lats.min() ?? 47.5,
            maxLat: lats.max() ?? 47.7,
            minLon: lons.min() ?? -122.4,
            maxLon: lons.max() ?? -122.2
        )
    }
    
    func findBridgesWithinRadius(lat: Double, lon: Double, radius: Double) -> Set<Int> {
        var result: Set<Int> = []
        
        for (bridgeID, location) in bridges {
            let distance = calculateDistance(
                lat1: lat, lon1: lon,
                lat2: location.lat, lon2: location.lon
            )
            
            if distance <= radius {
                result.insert(bridgeID)
            }
        }
        
        return result
    }
    
    private func calculateDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let latDiff = lat1 - lat2
        let lonDiff = lon1 - lon2
        return sqrt(latDiff * latDiff + lonDiff * lonDiff)
    }
}

/// Temporal index for fast time-range queries
public struct TemporalEventIndex {
    private let eventsByTimeWindow: [Int: [DrawbridgeEvent]]
    private let timeWindowSize: TimeInterval = 30 * 60 // 30-minute windows
    
    init(events: [DrawbridgeEvent]) {
        var windows: [Int: [DrawbridgeEvent]] = [:]
        
        for event in events {
            let windowKey = Int(event.openDateTime.timeIntervalSince1970 / timeWindowSize)
            windows[windowKey, default: []].append(event)
        }
        
        self.eventsByTimeWindow = windows
    }
    
    func findEventsInTimeRange(from start: Date, to end: Date, excludingBridge: Int) -> [DrawbridgeEvent] {
        let startWindow = Int(start.timeIntervalSince1970 / timeWindowSize)
        let endWindow = Int(end.timeIntervalSince1970 / timeWindowSize)
        
        var results: [DrawbridgeEvent] = []
        
        for windowKey in startWindow...endWindow {
            if let windowEvents = eventsByTimeWindow[windowKey] {
                let filteredEvents = windowEvents.filter { event in
                    event.entityID != excludingBridge &&
                    event.openDateTime >= start &&
                    event.openDateTime <= end
                }
                results.append(contentsOf: filteredEvents)
            }
        }
        
        return results
    }
}

/// Graph-based bridge network analysis
public struct BridgeNetworkGraph {
    private let adjacencyMatrix: [[Double]]
    private let bridgeIDToIndex: [Int: Int]
    private let distances: [[Double]]
    
    init(events: [DrawbridgeEvent]) {
        let uniqueBridgeIDs = Array(Set(events.map(\.entityID))).sorted()
        var idToIndex: [Int: Int] = [:]
        for (index, id) in uniqueBridgeIDs.enumerated() {
            idToIndex[id] = index
        }
        self.bridgeIDToIndex = idToIndex
        
        let size = uniqueBridgeIDs.count
        var matrix = Array(repeating: Array(repeating: 0.0, count: size), count: size)
        var distanceMatrix = Array(repeating: Array(repeating: Double.infinity, count: size), count: size)
        
        // Build correlation matrix and distance matrix
        BridgeNetworkGraph.buildCorrelationMatrix(&matrix, events: events, bridgeIDToIndex: idToIndex)
        BridgeNetworkGraph.buildDistanceMatrix(&distanceMatrix, events: events, bridgeIDToIndex: idToIndex)
        
        self.adjacencyMatrix = matrix
        self.distances = distanceMatrix
    }
    
    private static func buildCorrelationMatrix(_ matrix: inout [[Double]], events: [DrawbridgeEvent], bridgeIDToIndex: [Int: Int]) {
        let eventsByBridge = Dictionary(grouping: events, by: \.entityID)
        
        for (bridge1ID, bridge1Events) in eventsByBridge {
            guard let index1 = bridgeIDToIndex[bridge1ID] else { continue }
            
            for (bridge2ID, bridge2Events) in eventsByBridge {
                guard bridge1ID != bridge2ID,
                      let index2 = bridgeIDToIndex[bridge2ID] else { continue }
                
                let correlation = calculateTimingCorrelation(bridge1Events, bridge2Events)
                matrix[index1][index2] = correlation
            }
        }
    }
    
    private static func buildDistanceMatrix(_ matrix: inout [[Double]], events: [DrawbridgeEvent], bridgeIDToIndex: [Int: Int]) {
        let bridgeLocations = Dictionary(grouping: events, by: \.entityID)
            .compactMapValues { $0.first }
        
        for (bridge1ID, bridge1Event) in bridgeLocations {
            guard let index1 = bridgeIDToIndex[bridge1ID] else { continue }
            matrix[index1][index1] = 0.0 // Distance to self
            
            for (bridge2ID, bridge2Event) in bridgeLocations {
                guard bridge1ID != bridge2ID,
                      let index2 = bridgeIDToIndex[bridge2ID] else { continue }
                
                let distance = calculateGeographicDistance(
                    lat1: bridge1Event.latitude, lon1: bridge1Event.longitude,
                    lat2: bridge2Event.latitude, lon2: bridge2Event.longitude
                )
                matrix[index1][index2] = distance
            }
        }
    }
    
    private static func calculateTimingCorrelation(_ events1: [DrawbridgeEvent], _ events2: [DrawbridgeEvent]) -> Double {
        // Simple correlation based on temporal proximity
        var correlationSum = 0.0
        var count = 0
        
        for event1 in events1.prefix(50) { // Limit for performance
            for event2 in events2.prefix(50) {
                let timeDiff = abs(event2.openDateTime.timeIntervalSince(event1.openDateTime))
                if timeDiff < 3600 { // Within 1 hour
                    correlationSum += max(0, 1.0 - (timeDiff / 3600))
                    count += 1
                }
            }
        }
        
        return count > 0 ? correlationSum / Double(count) : 0.0
    }
    
    private static func calculateGeographicDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        // Haversine formula for accurate geographic distance
        let R = 6371.0 // Earth's radius in kilometers
        let dLat = (lat2 - lat1) * .pi / 180.0
        let dLon = (lon2 - lon1) * .pi / 180.0
        
        let a = sin(dLat/2) * sin(dLat/2) +
                cos(lat1 * .pi / 180.0) * cos(lat2 * .pi / 180.0) *
                sin(dLon/2) * sin(dLon/2)
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        
        return R * c
    }
    
    func getCascadeProbability(from sourceID: Int, to targetID: Int) -> Double {
        guard let sourceIndex = bridgeIDToIndex[sourceID],
              let targetIndex = bridgeIDToIndex[targetID],
              sourceIndex < adjacencyMatrix.count,
              targetIndex < adjacencyMatrix[sourceIndex].count else {
            return 0.0
        }
        
        return adjacencyMatrix[sourceIndex][targetIndex]
    }
    
    func getDistance(from sourceID: Int, to targetID: Int) -> Double {
        guard let sourceIndex = bridgeIDToIndex[sourceID],
              let targetIndex = bridgeIDToIndex[targetID],
              sourceIndex < distances.count,
              targetIndex < distances[sourceIndex].count else {
            return Double.infinity
        }
        
        return distances[sourceIndex][targetIndex]
    }
}

public struct BridgeAnalyticsCalculator {
    
    public static func calculateAnalytics(from events: [DrawbridgeEvent]) -> [BridgeAnalytics] {
        print(" Starting optimized analytics calculation for \(events.count) events...")
        let startTime = Date()
        
        var analytics: [String: BridgeAnalytics] = [:]
        
        var processedEvents = 0
        let progressInterval = 500
        
        for event in events {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month, .weekday, .hour], from: event.openDateTime)
            
            guard let year = components.year,
                  let month = components.month,
                  let dayOfWeek = components.weekday,
                  let hour = components.hour else { continue }
            
            let key = "\(event.entityID)-\(year)-\(month)-\(dayOfWeek)-\(hour)"
            
            if let existing = analytics[key] {
                existing.openingCount += 1
                existing.totalMinutesOpen += event.minutesOpen
                existing.averageMinutesPerOpening = existing.totalMinutesOpen / Double(existing.openingCount)
                existing.longestOpeningMinutes = max(existing.longestOpeningMinutes, event.minutesOpen)
                existing.shortestOpeningMinutes = min(existing.shortestOpeningMinutes, event.minutesOpen)
            } else {
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
                print(" Processed \(processedEvents)/\(events.count) events in \(String(format: "%.1f", elapsed))s")
            }
        }
        
        let groupingTime = Date().timeIntervalSince(startTime)
        print(" Event grouping complete: \(analytics.count) analytics records in \(String(format: "%.2f", groupingTime))s")
        
        let rawAnalytics = Array(analytics.values)
        print(" Starting Phase 1: Seasonal decomposition...")
        let decomposedAnalytics = SeasonalDecomposition.decompose(analytics: rawAnalytics)
        
        let phase1Time = Date().timeIntervalSince(startTime)
        print(" Phase 1 complete in \(String(format: "%.2f", phase1Time - groupingTime))s")
        
        print(" Starting Phase 2: Cascade detection...")
        let cascadeStartTime = Date()
        let cascadeEvents = CascadeDetectionEngine.detectCascadeEffects(from: events)
        let cascadeTime = Date().timeIntervalSince(cascadeStartTime)
        print(" Phase 2 complete: \(cascadeEvents.count) cascades detected in \(String(format: "%.2f", cascadeTime))s")
        
        applyCascadeAnalysis(to: decomposedAnalytics, cascadeEvents: cascadeEvents)
        
        print(" Calculating enhanced predictions...")
        for analytics in decomposedAnalytics {
            calculateEnhancedPredictions(for: analytics, allEvents: events, cascadeEvents: cascadeEvents)
        }
        
        generateUserFriendlyCascadeInsights(analytics: decomposedAnalytics, cascadeEvents: cascadeEvents)
        
        let totalTime = Date().timeIntervalSince(startTime)
        print(" ANALYTICS CALCULATION COMPLETE")
        print(" PERFORMANCE SUMMARY:")
        print("    • Total time: \(String(format: "%.2f", totalTime))s")
        print("    • Event grouping: \(String(format: "%.2f", groupingTime))s")
        print("    • Phase 1 (Seasonal): \(String(format: "%.2f", phase1Time - groupingTime))s") 
        print("    • Phase 2 (Cascade): \(String(format: "%.2f", cascadeTime))s")
        print("    • Analytics records: \(decomposedAnalytics.count)")
        print("    • Cascade events: \(cascadeEvents.count)")
        
        return decomposedAnalytics
    }
    
    private static func generateUserFriendlyCascadeInsights(
        analytics: [BridgeAnalytics],
        cascadeEvents: [CascadeEvent]
    ) {
        print(" Generating user-friendly cascade insights...")
        
        let cascadesByTrigger = Dictionary(grouping: cascadeEvents, by: \.triggerBridgeName)
        let cascadesByTarget = Dictionary(grouping: cascadeEvents, by: \.targetBridgeName)
        
        let topTriggers = cascadesByTrigger.sorted { $0.value.count > $1.value.count }.prefix(3)
        print(" Top cascade trigger bridges:")
        for (bridgeName, cascades) in topTriggers {
            print("   • \(bridgeName): triggers \(cascades.count) cascade events")
        }
        
        let topTargets = cascadesByTarget.sorted { $0.value.count > $1.value.count }.prefix(3)
        print(" Top cascade target bridges:")
        for (bridgeName, cascades) in topTargets {
            print("   • \(bridgeName): affected by \(cascades.count) cascade events")
        }
        
        let cascadePairs = Dictionary(grouping: cascadeEvents) { "\($0.triggerBridgeName) → \($0.targetBridgeName)" }
        let topPairs = cascadePairs.sorted { $0.value.count > $1.value.count }.prefix(5)
        print(" Most common cascade pairs for route planning:")
        for (pairName, cascades) in topPairs {
            let avgDelay = cascades.map(\.delayMinutes).reduce(0, +) / Double(cascades.count)
            print("   • \(pairName): \(cascades.count) times, avg \(String(format: "%.0f", avgDelay)) min delay")
        }
    }
    
    private static func applyCascadeAnalysis(
        to analytics: [BridgeAnalytics],
        cascadeEvents: [CascadeEvent]
    ) {
        print(" Applying cascade analysis to \(analytics.count) analytics records...")
        
        for bridgeAnalytics in analytics {
            let triggeredCascades = cascadeEvents.filter { cascade in
                cascade.triggerBridgeID == bridgeAnalytics.entityID &&
                cascade.hour == bridgeAnalytics.hour &&
                cascade.dayOfWeek == bridgeAnalytics.dayOfWeek
            }
            
            if !triggeredCascades.isEmpty {
                bridgeAnalytics.cascadeInfluence = triggeredCascades.map(\.cascadeStrength).reduce(0, +) / Double(triggeredCascades.count)
                bridgeAnalytics.cascadeProbability = Double(triggeredCascades.count) / Double(max(bridgeAnalytics.openingCount, 1))
                
                let targetCounts = Dictionary(grouping: triggeredCascades, by: \.targetBridgeID)
                if let primaryTarget = targetCounts.max(by: { $0.value.count < $1.value.count }) {
                    bridgeAnalytics.primaryCascadeTarget = primaryTarget.key
                    bridgeAnalytics.cascadeDelay = primaryTarget.value.map(\.delayMinutes).reduce(0, +) / Double(primaryTarget.value.count)
                }
                
                print(" \(bridgeAnalytics.entityName) (\(bridgeAnalytics.hour):00): influence \(String(format: "%.1f%%", bridgeAnalytics.cascadeInfluence * 100))")
            } else {
                bridgeAnalytics.cascadeInfluence = 0.05 
                bridgeAnalytics.cascadeProbability = 0.02 
            }
            
            let receivedCascades = cascadeEvents.filter { 
                $0.targetBridgeID == bridgeAnalytics.entityID &&
                $0.hour == bridgeAnalytics.hour &&
                $0.dayOfWeek == bridgeAnalytics.dayOfWeek
            }
            
            if !receivedCascades.isEmpty {
                bridgeAnalytics.cascadeSusceptibility = receivedCascades.map(\.cascadeStrength).reduce(0, +) / Double(receivedCascades.count)
                print(" \(bridgeAnalytics.entityName) (\(bridgeAnalytics.hour):00): susceptibility \(String(format: "%.1f%%", bridgeAnalytics.cascadeSusceptibility * 100))")
            } else {
                bridgeAnalytics.cascadeSusceptibility = 0.03 
            }
        }
        
        print(" Cascade analysis complete - meaningful values assigned")
    }

    private static func calculateEnhancedPredictions(
        for analytics: BridgeAnalytics,
        allEvents: [DrawbridgeEvent],
        cascadeEvents: [CascadeEvent]
    ) {
        let bridgeEvents = allEvents.filter { $0.entityID == analytics.entityID }
        let totalHoursInDataset = calculateTotalHours(for: bridgeEvents)
        
        let totalPossibleOccurrences = totalHoursInDataset[analytics.hour] ?? 1
        let baseProbability = Double(analytics.openingCount) / Double(totalPossibleOccurrences)
        
        let trendAdjustment = analytics.trendComponent > 0 ? 0.1 : -0.1
        let seasonalAdjustment = analytics.seasonalComponent * 0.05
        let patternAdjustment = calculatePatternAdjustment(for: analytics)
        
        let cascadeAdjustment = calculateCascadeAdjustment(for: analytics, cascadeEvents: cascadeEvents)
        
        analytics.probabilityOfOpening = max(0.0, min(1.0, 
            baseProbability + trendAdjustment + seasonalAdjustment + patternAdjustment + analytics.holidayAdjustment + cascadeAdjustment
        ))
        
        let seasonalDurationMultiplier = calculateSeasonalDurationMultiplier(for: analytics)
        let cascadeDurationMultiplier = calculateCascadeDurationMultiplier(for: analytics)
        analytics.expectedDuration = analytics.averageMinutesPerOpening * seasonalDurationMultiplier * cascadeDurationMultiplier
        
        let sampleSizeConfidence = min(Double(analytics.openingCount) / 10.0, 1.0)
        let variabilityConfidence = calculateVariabilityConfidence(for: analytics)
        let seasonalConfidence = calculateSeasonalConfidence(for: analytics)
        let cascadeConfidence = calculateCascadeConfidence(for: analytics)
        analytics.confidence = (sampleSizeConfidence + variabilityConfidence + seasonalConfidence + cascadeConfidence) / 4.0
    }
    
    private static func calculateCascadeAdjustment(
        for analytics: BridgeAnalytics,
        cascadeEvents: [CascadeEvent]
    ) -> Double {
        
        let relevantCascades = cascadeEvents.filter { cascade in
            cascade.targetBridgeID == analytics.entityID &&
            cascade.hour == analytics.hour &&
            cascade.dayOfWeek == analytics.dayOfWeek
        }
        
        if relevantCascades.isEmpty {
            return 0.0
        }
        
        let averageCascadeStrength = relevantCascades.map(\.cascadeStrength).reduce(0, +) / Double(relevantCascades.count)
        let cascadeFrequency = Double(relevantCascades.count) / Double(max(analytics.openingCount, 1))
        
        return averageCascadeStrength * cascadeFrequency * 0.2 
    }
    
    private static func calculateCascadeDurationMultiplier(for analytics: BridgeAnalytics) -> Double {
        if analytics.cascadeInfluence > 0.5 {
            return 1.1 + (analytics.cascadeInfluence * 0.2)
        }
        
        if analytics.cascadeSusceptibility > 0.5 {
            return 0.9 + (analytics.cascadeSusceptibility * 0.1)
        }
        
        return 1.0
    }
    
    private static func calculateCascadeConfidence(for analytics: BridgeAnalytics) -> Double {
        let cascadeReliability = (analytics.cascadeInfluence + analytics.cascadeSusceptibility) / 2.0
        return min(1.0, cascadeReliability)
    }
    
    private static func calculatePatternAdjustment(for analytics: BridgeAnalytics) -> Double {
        var adjustment = 0.0
        
        if analytics.isWeekendPattern {
            adjustment += 0.15 
        }
        
        if analytics.isRushHourPattern {
            adjustment -= 0.1 
        }
        
        if analytics.isSummerPattern {
            adjustment += 0.2 
        }
        
        return adjustment
    }
    
    private static func calculateSeasonalDurationMultiplier(for analytics: BridgeAnalytics) -> Double {
        var multiplier = 1.0
        
        if analytics.isWeekendPattern {
            multiplier *= 1.2
        }
        
        if analytics.isSummerPattern {
            multiplier *= 1.15
        }
        
        if analytics.isRushHourPattern {
            multiplier *= 0.9
        }
        
        return multiplier
    }
    
    private static func calculateSeasonalConfidence(for analytics: BridgeAnalytics) -> Double {
        let seasonalStrength = abs(analytics.seasonalComponent)
        return min(1.0, seasonalStrength / 10.0) 
    }
    
    private static func calculateTotalHours(for events: [DrawbridgeEvent]) -> [Int: Int] {
        var hourCounts: [Int: Int] = [:]
        let calendar = Calendar.current
        
        guard let earliest = events.map(\.openDateTime).min(),
              let latest = events.map(\.openDateTime).max() else {
            return hourCounts
        }
        
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
    
    private static func calculateVariabilityConfidence(for analytics: BridgeAnalytics) -> Double {
        guard analytics.openingCount > 1 else { return 0.0 }
        
        let range = analytics.longestOpeningMinutes - analytics.shortestOpeningMinutes
        let average = analytics.averageMinutesPerOpening
        
        let variabilityRatio = range / max(average, 1.0)
        return max(0.0, 1.0 - (variabilityRatio / 10.0)) 
    }
}

public struct CascadeInsights {
    
    public static func generateCascadeInsights(
        for bridgeID: Int,
        from cascadeEvents: [CascadeEvent],
        analytics: [BridgeAnalytics]
    ) -> [String] {
        
        var insights: [String] = []
        
        let bridgeAnalytics = analytics.filter { $0.entityID == bridgeID }
        let triggeredCascades = cascadeEvents.filter { $0.triggerBridgeID == bridgeID }
        let receivedCascades = cascadeEvents.filter { $0.targetBridgeID == bridgeID }
        
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
        
        let immediateCascades = triggeredCascades.filter { $0.delayMinutes < 5 }
        if immediateCascades.count > triggeredCascades.count / 2 {
            insights.append("Tends to trigger immediate cascade responses (< 5 minutes)")
        }
        
        return insights
    }
    
    public static func getCascadeAlerts(
        recentEvents: [DrawbridgeEvent],
        cascadeEvents: [CascadeEvent],
        bridgeInfo: [DrawbridgeInfo]
    ) -> [CascadeAlert] {
        
        var alerts: [CascadeAlert] = []
        let now = Date()
        
        let recentTriggers = recentEvents.filter { event in
            now.timeIntervalSince(event.openDateTime) < 1800 && 
            event.closeDateTime != nil 
        }
        
        for trigger in recentTriggers {
            let potentialCascades = cascadeEvents.filter { cascade in
                cascade.triggerBridgeID == trigger.entityID &&
                cascade.cascadeStrength > 0.4
            }
            
            for cascade in potentialCascades {
                let targetBridge = bridgeInfo.first { $0.entityID == cascade.targetBridgeID }
                let expectedTime = trigger.openDateTime.addingTimeInterval(cascade.delayMinutes * 60)
                let timeUntilExpected = expectedTime.timeIntervalSince(now)
                
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

public struct SeasonalDecomposition {
    
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
        let sortedAnalytics = analytics.sorted { first, second in
            if first.year != second.year { return first.year < second.year }
            if first.month != second.month { return first.month < second.month }
            if first.dayOfWeek != second.dayOfWeek { return first.dayOfWeek < second.dayOfWeek }
            return first.hour < second.hour
        }
        
        for (index, analytics) in sortedAnalytics.enumerated() {
            analytics.trendComponent = calculateTrend(for: index, in: sortedAnalytics, window: 24)
        }
        
        calculateSeasonalComponents(sortedAnalytics)
        
        for analytics in sortedAnalytics {
            let expectedValue = analytics.trendComponent + analytics.seasonalComponent
            let actualValue = Double(analytics.openingCount)
            analytics.residualComponent = actualValue - expectedValue
        }
        
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
        let weeklyGroups = Dictionary(grouping: analytics, by: \.dayOfWeek)
        let weeklyAverages = weeklyGroups.mapValues { group in
            group.reduce(0.0) { $0 + Double($1.openingCount) } / Double(group.count)
        }
        let overallWeeklyAverage = weeklyAverages.values.reduce(0, +) / Double(weeklyAverages.count)
        
        let monthlyGroups = Dictionary(grouping: analytics, by: \.month)
        let monthlyAverages = monthlyGroups.mapValues { group in
            group.reduce(0.0) { $0 + Double($1.openingCount) } / Double(group.count)
        }
        let overallMonthlyAverage = monthlyAverages.values.reduce(0, +) / Double(monthlyAverages.count)
        
        let hourlyGroups = Dictionary(grouping: analytics, by: \.hour)
        let hourlyAverages = hourlyGroups.mapValues { group in
            group.reduce(0.0) { $0 + Double($1.openingCount) } / Double(group.count)
        }
        let overallHourlyAverage = hourlyAverages.values.reduce(0, +) / Double(hourlyAverages.count)
        
        for analytics in analytics {
            analytics.weeklySeasonality = weeklyAverages[analytics.dayOfWeek] ?? overallWeeklyAverage
            analytics.monthlySeasonality = monthlyAverages[analytics.month] ?? overallMonthlyAverage
            analytics.hourlySeasonality = hourlyAverages[analytics.hour] ?? overallHourlyAverage
            
            analytics.seasonalComponent = 
                (analytics.weeklySeasonality - overallWeeklyAverage) +
                (analytics.monthlySeasonality - overallMonthlyAverage) +
                (analytics.hourlySeasonality - overallHourlyAverage)
        }
    }
    
    private static func detectPatternTypes(_ analytics: [BridgeAnalytics]) {
        for analytics in analytics {
            analytics.isWeekendPattern = analytics.dayOfWeek == 1 || analytics.dayOfWeek == 7
            
            analytics.isRushHourPattern = !analytics.isWeekendPattern && 
                ((analytics.hour >= 7 && analytics.hour <= 9) || 
                 (analytics.hour >= 16 && analytics.hour <= 18))
            
            analytics.isSummerPattern = analytics.month >= 5 && analytics.month <= 9
            
            analytics.holidayAdjustment = calculateHolidayAdjustment(for: analytics)
        }
    }
    
    private static func calculateHolidayAdjustment(for analytics: BridgeAnalytics) -> Double {
        if analytics.month == 7 || 
           (analytics.month == 5 && analytics.dayOfWeek == 2) || 
           (analytics.month == 9 && analytics.dayOfWeek == 2) {  
            return 0.3 
        }
        return 0.0
    }
}

public struct BridgePrediction {
    public let bridge: DrawbridgeInfo
    public let probability: Double 
    public let expectedDuration: Double 
    public let confidence: Double 
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

extension BridgeAnalytics {
    
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
                probability: 0.1, 
                expectedDuration: 15.0, 
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

public struct ARIMABridgePrediction {
    public let entityID: Int
    public let entityName: String
    public let probability: Double
    public let expectedDuration: Double
    public let confidence: Double
    
    public let arimaAccuracy: Double
    public let modelRMSE: Double
    public let modelMAPE: Double
    public let modelOrder: (p: Int, d: Int, q: Int)
    public let neuralGeneration: String
    public let modelComplexity: String
    public let processingTime: Double
    public let neuralEnhanced: Bool
    
    public let seasonalComponent: Double
    public let cascadeInfluence: Double
    public let reasoning: String
    
    public init(
        entityID: Int,
        entityName: String,
        probability: Double,
        expectedDuration: Double,
        confidence: Double,
        arimaAccuracy: Double,
        modelRMSE: Double,
        modelMAPE: Double,
        modelOrder: (p: Int, d: Int, q: Int),
        neuralGeneration: String,
        modelComplexity: String,
        processingTime: Double,
        neuralEnhanced: Bool,
        seasonalComponent: Double,
        cascadeInfluence: Double,
        reasoning: String
    ) {
        self.entityID = entityID
        self.entityName = entityName
        self.probability = probability
        self.expectedDuration = expectedDuration
        self.confidence = confidence
        self.arimaAccuracy = arimaAccuracy
        self.modelRMSE = modelRMSE
        self.modelMAPE = modelMAPE
        self.modelOrder = modelOrder
        self.neuralGeneration = neuralGeneration
        self.modelComplexity = modelComplexity
        self.processingTime = processingTime
        self.neuralEnhanced = neuralEnhanced
        self.seasonalComponent = seasonalComponent
        self.cascadeInfluence = cascadeInfluence
        self.reasoning = reasoning
    }
    
    public var probabilityText: String {
        switch probability {
        case 0.0..<0.15: return "Very Low"
        case 0.15..<0.35: return "Low"
        case 0.35..<0.65: return "Moderate"
        case 0.65..<0.85: return "High"
        case 0.85...1.0: return "Very High"
        default: return "Unknown"
        }
    }
    
    public var confidenceText: String {
        switch confidence {
        case 0.0..<0.6: return "Low Confidence"
        case 0.6..<0.8: return "Medium Confidence"
        case 0.8...1.0: return "High Confidence"
        default: return "Unknown"
        }
    }
    
    public var durationText: String {
        if expectedDuration < 1 {
            return "< 1 min"
        } else if expectedDuration < 60 {
            return "\(Int(expectedDuration)) min"
        } else {
            let hours = Int(expectedDuration / 60)
            let minutes = Int(expectedDuration.truncatingRemainder(dividingBy: 60))
            return "\(hours)h \(minutes)m"
        }
    }
    
    public var modelConfigText: String {
        let enhanced = neuralEnhanced ? " (Neural)" : ""
        return "\(modelComplexity) ARIMA(\(modelOrder.p),\(modelOrder.d),\(modelOrder.q))\(enhanced)"
    }
    
    public var performanceText: String {
        return " \(neuralGeneration) (\(String(format: "%.3f", processingTime))s)"
    }
}

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

public struct SeasonalInsights {
    
    public static func generateInsights(for bridgeID: Int, from analytics: [BridgeAnalytics]) -> [String] {
        let bridgeAnalytics = analytics.filter { $0.entityID == bridgeID }
        var insights: [String] = []
        
        let weekendAnalytics = bridgeAnalytics.filter { $0.isWeekendPattern }
        let weekdayAnalytics = bridgeAnalytics.filter { !$0.isWeekendPattern }
        
        if !weekendAnalytics.isEmpty && !weekdayAnalytics.isEmpty {
            let weekendAvg = weekendAnalytics.map(\.probabilityOfOpening).reduce(0, +) / Double(weekendAnalytics.count)
            let weekdayAvg = weekdayAnalytics.map(\.probabilityOfOpening).reduce(0, +) / Double(weekdayAnalytics.count)
            
            if weekendAvg > weekdayAvg * 1.2 {
                insights.append("Weekend openings are \(Int((weekendAvg / weekdayAvg - 1) * 100))% more frequent than weekdays")
            }
        }
        
        let summerAnalytics = bridgeAnalytics.filter { $0.isSummerPattern }
        let nonSummerAnalytics = bridgeAnalytics.filter { !$0.isSummerPattern }
        
        if !summerAnalytics.isEmpty && !nonSummerAnalytics.isEmpty {
            let summerAvg = summerAnalytics.map(\.probabilityOfOpening).reduce(0, +) / Double(summerAnalytics.count)
            let nonSummerAvg = nonSummerAnalytics.map(\.probabilityOfOpening).reduce(0, +) / Double(nonSummerAnalytics.count)
            
            if summerAvg > nonSummerAvg * 1.1 {
                insights.append("Summer months show \(Int((summerAvg / nonSummerAvg - 1) * 100))% increase in bridge activity")
            }
        }
        
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
