// 
//  StatisticsView.swift
//  BridgetStatistics
//
//  Created by Peter Jemley on 6/19/25.
//

import SwiftUI
import SwiftData
import BridgetCore
import BridgetSharedUI
import Foundation

@MainActor
public struct StatisticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var events: [DrawbridgeEvent]
    @Query private var bridgeInfo: [DrawbridgeInfo]
    @Query private var analytics: [BridgeAnalytics]
    @Query private var cascadeEvents: [CascadeEvent]

    @State private var isCalculating = false
    @State private var showingARIMADetails = false
    @State private var neuralEngineStatus = "Ready"

    // MARK: - Cached Statistics for Performance
    private var triggerCounts: [Int: Int] {
        Dictionary(grouping: cascadeEvents, by: \.triggerBridgeID).mapValues { $0.count }
    }
    private var maxTriggerCount: Int { 
        triggerCounts.values.max() ?? 1 
    }
    
    private var cachedDelayStats: (mean: Double, median: Double, std: Double) {
        getCascadeDelayStats()
    }
    
    private var cachedDataDrivenThresholds: (weak: Double, moderate: Double, strong: Double) {
        getDataDrivenThresholds()
    }
    
    private var cachedBridgeRates: [(bridge: DrawbridgeInfo, rate: Double)] {
        getBridgeEventRates()
    }

    public init() {}
    
    private func updateNeuralEngineStatus() {
        print(" [NEURAL ENGINE] Starting detection...")
        
        let neuralGeneration = NeuralEngineManager.detectNeuralEngineGeneration()
        let coreCount = neuralGeneration.coreCount
        let topsCapability = neuralGeneration.topsCapability
        let complexity = neuralGeneration.recommendedModelComplexity.rawValue
        
        neuralEngineStatus = "\(neuralGeneration.rawValue), \(coreCount) cores, \(String(format: "%.1f", topsCapability)) TOPS, \(complexity)"
        
        print("[NEURAL ENGINE] Detection Results:")
        print("[NEURAL ENGINE] Generation: \(neuralGeneration.rawValue)")
        print("[NEURAL ENGINE] Cores: \(coreCount)")
        print("[NEURAL ENGINE] TOPS: \(String(format: "%.1f", topsCapability))")
        print("[NEURAL ENGINE] Complexity: \(complexity)")
        print("[NEURAL ENGINE] Final Status: \(neuralEngineStatus)")
        
        DispatchQueue.main.async {
            print("[NEURAL ENGINE] Forcing view update with status: \(self.neuralEngineStatus)")
        }
    }

    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.title2)
                                .foregroundColor(.blue)
                            
                            Text("Analytics & Predictions")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        
                        Text("AI-powered bridge opening predictions")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Image(systemName: "cpu")
                                .foregroundColor(.green)
                            Text("Neural Engine: \(neuralEngineStatus)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        
                        HStack {
                            Image(systemName: "database")
                                .foregroundColor(.green)
                            Text("Dataset: \(events.count) total events across \(Set(events.map(\.entityID)).count) bridges")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    
                    currentPredictionsSection
                        .padding(.horizontal)
                    
                    cascadeNetworkVisualization
                        .padding(.horizontal)
                }
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                print(" [STATS] StatisticsView Appeared")
                print(" [STATS] Events: \(events.count)")
                print(" [STATS] Bridge Info: \(bridgeInfo.count)")
                print(" [STATS] Analytics: \(analytics.count)")
                print(" [STATS] Cascade Events: \(cascadeEvents.count)")
                updateNeuralEngineStatus()
                
                if cascadeEvents.isEmpty && !events.isEmpty {
                    print(" [STATS]  NO CASCADE EVENTS FOUND - FORCING IMMEDIATE DETECTION")
                    Task {
                        await forceCascadeDetection()
                    }
                }
                
                if analytics.isEmpty && !events.isEmpty && !isCalculating {
                    calculateAnalytics()
                }
            }
        }
    }
    
    @ViewBuilder
    private var cascadeNetworkVisualization: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Bridge Connection Analysis", systemImage: "arrow.triangle.branch")
                    .font(.headline)
                    .foregroundColor(.purple)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    if cascadeEvents.isEmpty {
                        Text("Analyzing connections...")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text("from \(events.count) bridge events")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    } else {
                        Text("\(cascadeEvents.count) connections found")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text("between Seattle bridges")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if cascadeEvents.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        Text("What This Analysis Shows")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    
                    Text("We're looking for patterns where opening one Seattle bridge might cause another bridge to open soon after (within 30-90 minutes).")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Why This Matters for Commuters:")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                        
                        Text("• If Fremont Bridge opens, other bridges might follow")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text("• Helps predict traffic delays across Seattle")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text("• Plan alternate routes before congestion hits")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    if events.count < 1000 {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.orange)
                            Text("Building analysis with \(events.count) bridge events...")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                        Text("How to Read This Traffic Pattern:")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 16, height: 16)
                                Text("Bridge")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                            }
                            
                            Text("Each circle = Seattle bridge")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Rectangle()
                                    .fill(LinearGradient(colors: [.gray, .red], startPoint: .leading, endPoint: .trailing))
                                    .frame(width: 24, height: 3)
                                    .cornerRadius(1.5)
                                Text("Connection")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                            }
                            
                            Text("Line = traffic chain reaction")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Real Example:")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                        
                        Text("Red thick line from Fremont to Ballard = \"When Fremont opens, Ballard often opens within an hour, causing major traffic delays\"")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .italic()
                        
                        Text("Thin gray lines = weak connections, thick red lines = strong patterns")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            
            if cascadeEvents.isEmpty {
                cascadeAnalysisPlaceholder
            } else {
                networkDiagramView
                    .frame(height: 280)
                
                networkStatisticsSection
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var cascadeAnalysisPlaceholder: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                ForEach(getSampleBridges(), id: \.self) { bridgeName in
                    VStack(spacing: 4) {
                        Circle()
                            .fill(Color.blue.opacity(0.7))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Text(getBridgeAbbreviation(bridgeName))
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            )
                        
                        Text(bridgeName.components(separatedBy: .whitespaces).first ?? bridgeName)
                            .font(.caption2)
                            .lineLimit(1)
                    }
                }
            }
            
            Text("Connections will appear as lines between bridges that frequently open together")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 4) {
                Text("Analysis Status:")
                    .font(.caption2)
                    .fontWeight(.medium)
                
                Text("• Total events: \(events.count)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("• Unique bridges: \(Set(events.map(\.entityID)).count)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("• Time span: \(getDataTimeSpan())")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(8)
        }
        .frame(height: 280)
    }
    
    @ViewBuilder
    private var currentPredictionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Current Predictions", systemImage: "clock")
                    .font(.headline)
                    .foregroundColor(.blue)

                Spacer()

                Text("Next Hour")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            let predictions = generateCurrentPredictions()

            if predictions.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text("Calculating predictions...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(8)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(predictions, id: \.bridge.entityID) { prediction in
                        PredictionCard(prediction: prediction)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Network Helper Functions
    
    private func getNetworkBridges() -> [DrawbridgeInfo] {
        let bridgesCascadeActivity = bridgeInfo.map { bridge in
            let triggerCount = cascadeEvents.filter { $0.triggerBridgeID == bridge.entityID }.count
            let targetCount = cascadeEvents.filter { $0.targetBridgeID == bridge.entityID }.count
            return (bridge: bridge, activity: triggerCount + targetCount)
        }
        
        return bridgesCascadeActivity
            .sorted { $0.activity > $1.activity }
            .prefix(6)
            .map(\.bridge)
    }
    
    private func getBridgeInfluence(for bridgeID: Int) -> Double {
        Double(triggerCounts[bridgeID] ?? 0) / Double(maxTriggerCount)
    }
    
    private func bridgeInfluenceColor(_ influence: Double) -> Color {
        switch influence {
        case 0.0..<0.3: return .blue
        case 0.3..<0.6: return .green
        case 0.6..<0.8: return .orange
        case 0.8...1.0: return .red
        default: return .blue
        }
    }
    
    private func getBridgeAbbreviation(_ bridgeName: String) -> String {
        let words = bridgeName.components(separatedBy: .whitespaces)
        if words.count >= 2 {
            return String(words[0].prefix(2) + words[1].prefix(1)).uppercased()
        } else {
            return String(bridgeName.prefix(3)).uppercased()
        }
    }
    
    private func getStrongestTriggerBridge() -> String {
        let triggerCounts = Dictionary(grouping: cascadeEvents, by: \.triggerBridgeName)
        if let strongest = triggerCounts.max(by: { $0.value.count < $1.value.count }) {
            return strongest.key.components(separatedBy: .whitespaces).first ?? "Unknown"
        }
        return "None"
    }
    
    private func getMostAffectedBridge() -> String {
        let targetCounts = Dictionary(grouping: cascadeEvents, by: \.targetBridgeName)
        if let mostAffected = targetCounts.max(by: { $0.value.count < $1.value.count }) {
            return mostAffected.key.components(separatedBy: .whitespaces).first ?? "Unknown"
        }
        return "None"
    }
    
    private func getAverageCascadeDelay() -> String {
        return String(format: "%.0f min", cachedDelayStats.mean)
    }

    // MARK: - Helper Functions for Better UX
    
    private func getSampleBridges() -> [String] {
        let uniqueBridges = Array(Set(events.map(\.entityName))).sorted()
        return Array(uniqueBridges.prefix(4))
    }
    
    private func forceCascadeDetection() async {
        print(" [STATS]  FORCING IMMEDIATE CASCADE DETECTION...")
        
        let currentEvents = Array(events.sorted { $0.openDateTime > $1.openDateTime }.prefix(500))
        let eventDTOs = currentEvents.toDTOs
        
        await Task.detached(priority: .userInitiated) {
            print(" [STATS] Running cascade detection on \(eventDTOs.count) events...")
            let cascadeEvents = CascadeDetectionEngine.detectCascadeEffects(from: eventDTOs)
            print(" [STATS] Detected \(cascadeEvents.count) cascade events!")
            
            await MainActor.run {
                print(" [STATS]  SAVING \(cascadeEvents.count) CASCADE EVENTS TO SWIFTDATA")
                
                for existingEvent in self.cascadeEvents {
                    self.modelContext.delete(existingEvent)
                }
                
                for cascadeEvent in cascadeEvents {
                    self.modelContext.insert(cascadeEvent)
                }
                
                do {
                    try self.modelContext.save()
                    print(" [STATS]  CASCADE EVENTS SAVED! UI should update now.")
                } catch {
                    print(" [STATS] Failed to save cascade events: \(error)")
                }
            }
        }.value
    }
    
    private func getDataTimeSpan() -> String {
        guard let earliest = events.map(\.openDateTime).min(),
              let latest = events.map(\.openDateTime).max() else { return "Unknown" }
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.year, .month, .day]
        formatter.unitsStyle = .full
        return formatter.string(from: earliest, to: latest) ?? "Unknown"
    }

    private func generateCurrentPredictions() -> [BridgePrediction] {
        print(" [STATS] Generating current predictions from \(analytics.count) analytics records")
        
        var predictions: [BridgePrediction] = []

        let topBridges = getTopBridgesByRate()

        for bridge in topBridges {
            if let prediction = BridgeAnalytics.getCurrentPrediction(
                for: bridge,
                from: Array(analytics)
            ) {
                predictions.append(prediction)
            }
        }

        print(" [STATS] Generated \(predictions.count) predictions successfully")
        return predictions.sorted { $0.probability > $1.probability }
    }

    private func calculateAnalytics() {
        print(" [STATS] Starting SAFE analytics calculation with \(events.count) events...")
        
        guard !events.isEmpty else {
            print(" [STATS] No events available for analytics")
            return
        }
        
        isCalculating = true

        let eventDTOs = events.toDTOs
        
        print(" [STATS] Created \(eventDTOs.count) EventDTOs safely on main thread")

        Task.detached(priority: .userInitiated) { [eventDTOs] in
            print(" [STATS] Running analytics on background thread with DTOs...")
            
            let limitedEventDTOs = Array(eventDTOs.sorted { $0.openDateTime > $1.openDateTime }.prefix(1000))
            print(" [STATS] Using \(limitedEventDTOs.count) most recent events for analytics")
            
            do {
                let newAnalytics = BridgeAnalyticsCalculator.calculateAnalytics(from: limitedEventDTOs)
                
                print(" [STATS] Analytics calculation complete on background thread: \(newAnalytics.count) records")

                await MainActor.run {
                    print(" [STATS] Updating UI on main thread...")
                    
                    let pendingCascadeEvents = CascadeEventStorage.consumePendingEvents()
                    if !pendingCascadeEvents.isEmpty {
                        print(" [STATS]  SAVING \(pendingCascadeEvents.count) CASCADE EVENTS TO SWIFTDATA")
                        
                        for existingEvent in self.cascadeEvents {
                            self.modelContext.delete(existingEvent)
                        }
                        
                        for cascadeEvent in pendingCascadeEvents {
                            self.modelContext.insert(cascadeEvent)
                        }
                        
                        do {
                            try self.modelContext.save()
                            print(" [STATS]  CASCADE EVENTS SAVED SUCCESSFULLY!")
                            print(" [STATS] Cascade events should now appear in UI")
                        } catch {
                            print("Failed to save cascade events: \(error)")
                        }
                    }
                    
                    isCalculating = false
                }
            } catch {
                print("Analytics calculation failed: \(error)")
                await MainActor.run {
                    isCalculating = false
                }
            }
        }
    }

    // MARK: - Network Diagram Components

    @ViewBuilder
    private var networkDiagramView: some View {
        GeometryReader { geometry in
            let networkBridges = getNetworkBridges()
            let centerX = geometry.size.width / 2
            let centerY = geometry.size.height / 2
            let radius = min(geometry.size.width, geometry.size.height) * 0.35
            
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 1)
                    .frame(width: radius * 2, height: radius * 2)
                    .position(x: centerX, y: centerY)
                
                cascadeConnectionsView(
                    bridges: networkBridges,
                    centerX: centerX,
                    centerY: centerY,
                    radius: radius
                )
                
                bridgeNodesView(
                    bridges: networkBridges,
                    centerX: centerX,
                    centerY: centerY,
                    radius: radius
                )
            }
        }
    }

    @ViewBuilder
    private func cascadeConnectionsView(
        bridges: [DrawbridgeInfo],
        centerX: Double,
        centerY: Double,
        radius: Double
    ) -> some View {
        let thresholds = cachedDataDrivenThresholds
        let minStrengthThreshold = thresholds.weak * 0.5
        
        ForEach(Array(bridges.enumerated()), id: \.element.entityID) { sourceIndex, sourceBridge in
            ForEach(Array(bridges.enumerated()), id: \.element.entityID) { targetIndex, targetBridge in
                if sourceIndex != targetIndex {
                    let cascadeStrength = getCascadeStrength(from: sourceBridge.entityID, to: targetBridge.entityID)
                    if cascadeStrength > minStrengthThreshold {
                        cascadeConnectionPath(
                            sourceIndex: sourceIndex,
                            targetIndex: targetIndex,
                            bridgeCount: bridges.count,
                            centerX: centerX,
                            centerY: centerY,
                            radius: radius,
                            strength: cascadeStrength
                        )
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func cascadeConnectionPath(
        sourceIndex: Int,
        targetIndex: Int,
        bridgeCount: Int,
        centerX: Double,
        centerY: Double,
        radius: Double,
        strength: Double
    ) -> some View {
        let sourceAngle = Double(sourceIndex) * 2 * .pi / Double(bridgeCount)
        let targetAngle = Double(targetIndex) * 2 * .pi / Double(bridgeCount)
        
        let sourceX = centerX + cos(sourceAngle) * radius
        let sourceY = centerY + sin(sourceAngle) * radius
        let targetX = centerX + cos(targetAngle) * radius
        let targetY = centerY + sin(targetAngle) * radius
        
        let lineWidth = calculateMeaningfulLineWidth(strength: strength)
        let connectionColor = cascadeStrengthColor(strength)
        
        Path { path in
            path.move(to: CGPoint(x: sourceX, y: sourceY))
            
            let controlX = centerX + cos((sourceAngle + targetAngle) / 2) * (radius * 0.3)
            let controlY = centerY + sin((sourceAngle + targetAngle) / 2) * (radius * 0.3)
            
            path.addQuadCurve(
                to: CGPoint(x: targetX, y: targetY),
                control: CGPoint(x: controlX, y: controlY)
            )
        }
        .stroke(
            connectionColor,
            style: StrokeStyle(
                lineWidth: lineWidth,
                lineCap: .round
            )
        )
        .opacity(0.85)
        .shadow(color: connectionColor.opacity(0.3), radius: lineWidth * 0.5, x: 0, y: 1)
    }

    @ViewBuilder
    private func bridgeNodesView(
        bridges: [DrawbridgeInfo],
        centerX: Double,
        centerY: Double,
        radius: Double
    ) -> some View {
        ForEach(Array(bridges.enumerated()), id: \.element.entityID) { index, bridge in
            let angle = Double(index) * 2 * .pi / Double(bridges.count)
            let x = centerX + cos(angle) * radius
            let y = centerY + sin(angle) * radius
            let bridgeInfluence = getBridgeInfluence(for: bridge.entityID)
            let nodeSize = 35 + (bridgeInfluence * 15)
            
            ZStack {
                Circle()
                    .fill(bridgeInfluenceColor(bridgeInfluence))
                    .frame(width: nodeSize, height: nodeSize)
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                
                Text(getBridgeAbbreviation(bridge.entityName))
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            .position(x: x, y: y)
        }
    }

    @ViewBuilder
    private var networkStatisticsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Traffic Impact Summary")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                UserFriendlyStatCard(
                    title: "Chain Starter",
                    subtitle: "Often triggers others",
                    value: getStrongestTriggerBridge(),
                    icon: "arrow.up.circle.fill",
                    color: .red,
                    explanation: "This bridge opening often leads to traffic problems at other bridges"
                )
                
                UserFriendlyStatCard(
                    title: "Gets Affected Most",
                    subtitle: "Reacts to others",
                    value: getMostAffectedBridge(),
                    icon: "target",
                    color: .orange,
                    explanation: "This bridge often opens after other bridges, creating cascade delays"
                )
                
                UserFriendlyStatCard(
                    title: "Chain Reaction Time",
                    subtitle: getCascadeDelayDetails(),
                    value: getAverageCascadeDelay(),
                    icon: "clock",
                    color: .blue,
                    explanation: "Average delay with standard deviation showing variability"
                )
            }
            
            if !cascadeEvents.isEmpty {
                VStack(spacing: 8) {
                    HStack {
                        Text("Statistical Insights")
                            .font(.caption)
                            .fontWeight(.medium)
                        Spacer()
                    }
                    
                    let thresholds = cachedDataDrivenThresholds
                    let delayStats = cachedDelayStats
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Connection Strength Thresholds")
                                .font(.caption2)
                                .fontWeight(.medium)
                            
                            Text("Weak: \(String(format: "%.2f", thresholds.weak))")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Text("Moderate: \(String(format: "%.2f", thresholds.moderate))")
                                .font(.caption2)
                                .foregroundColor(.blue)
                            Text("Strong: \(String(format: "%.2f", thresholds.strong))")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                        .padding(8)
                        .background(Color(.systemBackground))
                        .cornerRadius(6)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Delay Statistics")
                                .font(.caption2)
                                .fontWeight(.medium)
                            
                            Text("Mean: \(String(format: "%.0f min", delayStats.mean))")
                                .font(.caption2)
                                .foregroundColor(.blue)
                            Text("Median: \(String(format: "%.0f min", delayStats.median))")
                                .font(.caption2)
                                .foregroundColor(.green)
                            Text("Std Dev: \(String(format: "%.1f min", delayStats.std))")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                        .padding(8)
                        .background(Color(.systemBackground))
                        .cornerRadius(6)
                    }
                }
            }
        }
    }

    // MARK: - Enhanced Statistical Calculations
    
    /// Computes comprehensive statistics for cascade strength between two bridges
    /// Returns: (mean, median, standard deviation, count) for robust analysis
    /// This addresses the original concern about outlier sensitivity by providing median alongside mean
    private func getCascadeStrengthStats(from sourceID: Int, to targetID: Int) -> (mean: Double, median: Double, std: Double, count: Int) {
        let relevantCascades = cascadeEvents.filter { 
            $0.triggerBridgeID == sourceID && $0.targetBridgeID == targetID 
        }
        
        guard !relevantCascades.isEmpty else { return (0, 0, 0, 0) }
        
        let strengths = relevantCascades.map(\.cascadeStrength).sorted()
        let mean = strengths.reduce(0, +) / Double(strengths.count)
        let median = strengths[strengths.count / 2]
        let variance = strengths.map { pow($0 - mean, 2) }.reduce(0, +) / Double(strengths.count)
        let std = sqrt(variance)
        
        return (mean, median, std, strengths.count)
    }
    
    /// Returns the mean cascade strength (maintains backward compatibility)
    private func getCascadeStrength(from sourceID: Int, to targetID: Int) -> Double {
        return getCascadeStrengthStats(from: sourceID, to: targetID).mean
    }
    
    // MARK: - Data-Driven Thresholds
    
    /// Computes data-driven thresholds using 25th, 50th, and 75th percentiles
    /// This replaces arbitrary hard-coded thresholds (0.3, 0.5, 0.7) with natural data breakpoints
    /// Fallback defaults ensure the system works even with minimal data
    private func getDataDrivenThresholds() -> (weak: Double, moderate: Double, strong: Double) {
        let allStrengths = cascadeEvents.map(\.cascadeStrength).sorted()
        guard !allStrengths.isEmpty else { return (0.2, 0.4, 0.6) } // Fallback defaults
        
        func quantile(_ q: Double) -> Double {
            let idx = Int(Double(allStrengths.count - 1) * q)
            return allStrengths[idx]
        }
        
        // Use 25th, 50th, and 75th percentiles as natural breakpoints
        return (quantile(0.25), quantile(0.5), quantile(0.75))
    }
    
    /// Returns color based on data-driven thresholds instead of arbitrary cutoffs
    private func cascadeStrengthColor(_ strength: Double) -> Color {
        let thresholds = cachedDataDrivenThresholds
        
        switch strength {
        case 0.0..<thresholds.weak: return .gray.opacity(0.6)        // Weak connections
        case thresholds.weak..<thresholds.moderate: return .blue.opacity(0.8)        // Moderate connections  
        case thresholds.moderate..<thresholds.strong: return .orange.opacity(0.9)      // Strong connections
        case thresholds.strong...1.0: return .red.opacity(0.95)        // Very strong connections
        default: return .gray.opacity(0.4)
        }
    }
    
    /// Calculates line width using data-driven thresholds for visual consistency
    private func calculateMeaningfulLineWidth(strength: Double) -> Double {
        let thresholds = cachedDataDrivenThresholds
        
        // Convert cascade strength to visually meaningful line widths using data-driven thresholds
        switch strength {
        case 0.0..<thresholds.weak: return 1.5   // Weak connections: thin lines
        case thresholds.weak..<thresholds.moderate: return 2.5   // Moderate connections: medium lines
        case thresholds.moderate..<thresholds.strong: return 4.0   // Strong connections: thick lines  
        case thresholds.strong...1.0: return 6.0   // Very strong connections: very thick lines
        default: return 1.0          // Fallback: minimal line
        }
    }
    
    // MARK: - Enhanced Delay Statistics
    
    /// Returns mean delay with standard deviation to show variability
    /// Addresses the original concern about loss of variability information
    private func getCascadeDelayDetails() -> String {
        return String(format: "%.0f min (σ=%.1f)", cachedDelayStats.mean, cachedDelayStats.std)
    }
    
    // MARK: - Enhanced Bridge Selection by Rate
    
    /// Selects top bridges by event rate (events per day) instead of raw count
    /// This addresses the concern about temporal spacing of events
    private func getTopBridgesByRate() -> [DrawbridgeInfo] {
        return cachedBridgeRates
            .sorted { $0.rate > $1.rate }
            .prefix(5)
            .map(\.bridge)
    }
    
    // MARK: - Supporting Functions
    
    private func getCascadeDelayStats() -> (mean: Double, median: Double, std: Double) {
        let delays = cascadeEvents.map(\.delayMinutes).sorted()
        guard !delays.isEmpty else { return (0, 0, 0) }
        let mean = delays.reduce(0, +) / Double(delays.count)
        let median = delays[delays.count/2]
        let std = sqrt(delays.map { pow($0 - mean, 2) }.reduce(0, +) / Double(delays.count))
        return (mean, median, std)
    }

    private func getBridgeEventRates() -> [(bridge: DrawbridgeInfo, rate: Double)] {
        guard let earliest = events.map(\.openDateTime).min(),
              let latest = events.map(\.openDateTime).max() else {
            return bridgeInfo.map { ($0, 0.0) }
        }
        
        let spanDays = max(1, Calendar.current.dateComponents([.day], from: earliest, to: latest).day ?? 1)
        return bridgeInfo.map { bridge in
            let count = events.filter { $0.entityID == bridge.entityID }.count
            return (bridge, Double(count) / Double(spanDays))
        }
    }

    // MARK: - Supporting Views

    struct UserFriendlyStatCard: View {
        let title: String
        let subtitle: String
        let value: String
        let icon: String
        let color: Color
        let explanation: String
        
        var body: some View {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Text(value)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                    .lineLimit(1)
                
                VStack(spacing: 2) {
                    Text(title)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }

    struct NetworkStatCard: View {
        let title: String
        let value: String
        let icon: String
        let color: Color
        
        var body: some View {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Text(value)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .padding(8)
            .background(Color(.systemBackground))
            .cornerRadius(6)
        }
    }

    struct PredictionCard: View {
        let prediction: BridgePrediction

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text(prediction.bridge.entityName)
                    .font(.headline)
                    .lineLimit(1)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(prediction.probabilityText)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(probabilityColor)

                        Spacer()

                        Text("\(Int(prediction.probability * 100))%")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(probabilityColor)
                    }

                    Text("Duration: \(prediction.durationText)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(prediction.reasoning)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(8)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }

        private var probabilityColor: Color {
            switch prediction.probability {
            case 0.8...1.0: return .red
            case 0.6..<0.8: return .orange
            case 0.3..<0.6: return .yellow
            default: return .green
            }
        }
    }

    // MARK: - Value Type DTOs for Thread Safety

    private struct EventDTO: Sendable {
        let entityType: String
        let entityName: String
        let entityID: Int
        let openDateTime: Date
        let closeDateTime: Date?
        let minutesOpen: Double
        let latitude: Double
        let longitude: Double

        init(from event: DrawbridgeEvent) {
            self.entityType = event.entityType
            self.entityName = event.entityName
            self.entityID = event.entityID
            self.openDateTime = event.openDateTime
            self.closeDateTime = event.closeDateTime
            self.minutesOpen = event.minutesOpen
            self.latitude = event.latitude
            self.longitude = event.longitude
        }
    }
} 
