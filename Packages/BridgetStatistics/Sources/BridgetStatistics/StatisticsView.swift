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

    public init() {}
    
    private func updateNeuralEngineStatus() {
        // DEBUG: Test Neural Engine detection
        print(" [NEURAL ENGINE] Starting detection...")
        
        // ENHANCED: Proper Neural Engine detection with specific capabilities
        let neuralGeneration = NeuralEngineManager.detectNeuralEngineGeneration()
        let coreCount = neuralGeneration.coreCount
        let topsCapability = neuralGeneration.topsCapability
        let complexity = neuralGeneration.recommendedModelComplexity.rawValue
        
        // FIXED: HIG-compliant status with specific device information
        neuralEngineStatus = "\(neuralGeneration.rawValue), \(coreCount) cores, \(String(format: "%.1f", topsCapability)) TOPS, \(complexity)"
        
        // DEBUG: Enhanced logging without special characters that might break
        print("[NEURAL ENGINE] Detection Results:")
        print("[NEURAL ENGINE] Generation: \(neuralGeneration.rawValue)")
        print("[NEURAL ENGINE] Cores: \(coreCount)")
        print("[NEURAL ENGINE] TOPS: \(String(format: "%.1f", topsCapability))")
        print("[NEURAL ENGINE] Complexity: \(complexity)")
        print("[NEURAL ENGINE] Final Status: \(neuralEngineStatus)")
        
        // FORCE: Update UI immediately
        DispatchQueue.main.async {
            // Force view refresh
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
                        .padding(.vertical, 8) // INCREASED: From 6 to 8 for better spacing with longer text
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
            // Header with better explanation
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
            
            // Better user explanation
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
                // ENHANCED: Much clearer explanation with practical examples
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
            
            // Simplified Network Diagram or Placeholder
            if cascadeEvents.isEmpty {
                cascadeAnalysisPlaceholder
            } else {
                networkDiagramView
                    .frame(height: 280)
                
                // Network Statistics
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
            // Show sample bridges in Seattle
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
            
            // Debug info to help understand why no cascades
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
        // Return top 6 bridges by cascade activity for better visualization
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
    
    private func getCascadeStrength(from sourceID: Int, to targetID: Int) -> Double {
        let relevantCascades = cascadeEvents.filter { 
            $0.triggerBridgeID == sourceID && $0.targetBridgeID == targetID 
        }
        
        guard !relevantCascades.isEmpty else { return 0.0 }
        
        return relevantCascades.map(\.cascadeStrength).reduce(0, +) / Double(relevantCascades.count)
    }
    
    private func getBridgeInfluence(for bridgeID: Int) -> Double {
        let triggeredCascades = cascadeEvents.filter { $0.triggerBridgeID == bridgeID }
        let maxCascades = max(1, cascadeEvents.map { cascade in
            cascadeEvents.filter { $0.triggerBridgeID == cascade.triggerBridgeID }.count
        }.max() ?? 1)
        
        return Double(triggeredCascades.count) / Double(maxCascades)
    }
    
    private func cascadeStrengthColor(_ strength: Double) -> Color {
        // ENHANCED: More meaningful color progression that matches legend
        switch strength {
        case 0.0..<0.3: return .gray.opacity(0.6)        // Weak connections
        case 0.3..<0.5: return .blue.opacity(0.8)        // Moderate connections  
        case 0.5..<0.7: return .orange.opacity(0.9)      // Strong connections
        case 0.7...1.0: return .red.opacity(0.95)        // Very strong connections
        default: return .gray.opacity(0.4)
        }
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
        guard !cascadeEvents.isEmpty else { return "0 min" }
        
        let avgDelay = cascadeEvents.map(\.delayMinutes).reduce(0, +) / Double(cascadeEvents.count)
        return String(format: "%.0f min", avgDelay)
    }

    // MARK: - Helper Functions for Better UX
    
    private func getSampleBridges() -> [String] {
        let uniqueBridges = Array(Set(events.map(\.entityName))).sorted()
        return Array(uniqueBridges.prefix(4))
    }
    
    private func forceCascadeDetection() async {
        print(" [STATS]  FORCING IMMEDIATE CASCADE DETECTION...")
        
        // Capture events on main thread
        let currentEvents = Array(events.sorted { $0.openDateTime > $1.openDateTime }.prefix(500))
        
        await Task.detached(priority: .userInitiated) {
            // Convert to non-SwiftData objects for thread safety
            let eventDTOs = currentEvents.map { event in
                DrawbridgeEvent(
                    entityType: event.entityType,
                    entityName: event.entityName,
                    entityID: event.entityID,
                    openDateTime: event.openDateTime,
                    closeDateTime: event.closeDateTime,
                    minutesOpen: event.minutesOpen,
                    latitude: event.latitude,
                    longitude: event.longitude
                )
            }
            
            print(" [STATS] Running cascade detection on \(eventDTOs.count) events...")
            let cascadeEvents = CascadeDetectionEngine.detectCascadeEffects(from: eventDTOs)
            print(" [STATS] Detected \(cascadeEvents.count) cascade events!")
            
            await MainActor.run {
                print(" [STATS]  SAVING \(cascadeEvents.count) CASCADE EVENTS TO SWIFTDATA")
                
                // Clear existing cascade events
                for existingEvent in self.cascadeEvents {
                    self.modelContext.delete(existingEvent)
                }
                
                // Save new cascade events
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
              let latest = events.map(\.openDateTime).max() else {
            return "Unknown"
        }
        
        let daysBetween = Calendar.current.dateComponents([.day], from: earliest, to: latest).day ?? 0
        
        if daysBetween < 30 {
            return "\(daysBetween) days"
        } else if daysBetween < 365 {
            let months = daysBetween / 30
            return "\(months) months"
        } else {
            let years = daysBetween / 365
            return "\(years) year\(years == 1 ? "" : "s")"
        }
    }

    private func generateCurrentPredictions() -> [BridgePrediction] {
        print(" [STATS] Generating current predictions from \(analytics.count) analytics records")
        
        var predictions: [BridgePrediction] = []

        let topBridges = bridgeInfo.sorted { bridge1, bridge2 in
            let events1 = events.filter { $0.entityID == bridge1.entityID }.count
            let events2 = events.filter { $0.entityID == bridge2.entityID }.count
            return events1 > events2
        }.prefix(5)

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

        let eventDTOs = events.map { event in
            EventDTO(
                id: "\(event.id)", 
                entityType: event.entityType,
                entityName: event.entityName,
                entityID: event.entityID,
                openDateTime: event.openDateTime,
                closeDateTime: event.closeDateTime,
                minutesOpen: event.minutesOpen,
                latitude: event.latitude,
                longitude: event.longitude
            )
        }
        
        print(" [STATS] Created \(eventDTOs.count) EventDTOs safely on main thread")

        Task.detached(priority: .userInitiated) { [eventDTOs] in
            print(" [STATS] Running analytics on background thread with DTOs...")
            
            let limitedEventDTOs = Array(eventDTOs.sorted { $0.openDateTime > $1.openDateTime }.prefix(1000))
            print(" [STATS] Using \(limitedEventDTOs.count) most recent events for analytics")
            
            do {
                let limitedEvents = limitedEventDTOs.map { dto in
                    DrawbridgeEvent(
                        entityType: dto.entityType,
                        entityName: dto.entityName,
                        entityID: dto.entityID,
                        openDateTime: dto.openDateTime,
                        closeDateTime: dto.closeDateTime,
                        minutesOpen: dto.minutesOpen,
                        latitude: dto.latitude,
                        longitude: dto.longitude
                    )
                }
                
                let newAnalytics = BridgeAnalyticsCalculator.calculateAnalytics(from: limitedEvents)
                
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
                // Background circle
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 1)
                    .frame(width: radius * 2, height: radius * 2)
                    .position(x: centerX, y: centerY)
                
                // Cascade connections
                cascadeConnectionsView(
                    bridges: networkBridges,
                    centerX: centerX,
                    centerY: centerY,
                    radius: radius
                )
                
                // Bridge nodes
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
        ForEach(Array(bridges.enumerated()), id: \.element.entityID) { sourceIndex, sourceBridge in
            ForEach(Array(bridges.enumerated()), id: \.element.entityID) { targetIndex, targetBridge in
                if sourceIndex != targetIndex {
                    let cascadeStrength = getCascadeStrength(from: sourceBridge.entityID, to: targetBridge.entityID)
                    if cascadeStrength > 0.2 {
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
        
        // ENHANCED: Meaningful line width calculation
        let lineWidth = calculateMeaningfulLineWidth(strength: strength)
        let connectionColor = cascadeStrengthColor(strength)
        
        Path { path in
            path.move(to: CGPoint(x: sourceX, y: sourceY))
            
            // Create curved path through center
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
        // ENHANCED: Better opacity for visual hierarchy
        .opacity(0.85)
        .shadow(color: connectionColor.opacity(0.3), radius: lineWidth * 0.5, x: 0, y: 1)
    }
    
    // MARK: - NEW: Meaningful Line Width Calculation
    private func calculateMeaningfulLineWidth(strength: Double) -> Double {
        // Convert cascade strength to visually meaningful line widths
        switch strength {
        case 0.0..<0.3: return 1.5   // Weak connections: thin lines
        case 0.3..<0.5: return 2.5   // Moderate connections: medium lines
        case 0.5..<0.7: return 4.0   // Strong connections: thick lines  
        case 0.7...1.0: return 6.0   // Very strong connections: very thick lines
        default: return 1.0          // Fallback: minimal line
        }
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
            
            // ENHANCED: User-friendly explanations instead of technical terms
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
                    subtitle: "Average delay",
                    value: getAverageCascadeDelay(),
                    icon: "clock",
                    color: .blue,
                    explanation: "How long between the first bridge opening and the chain reaction"
                )
            }
        }
    }

    // MARK: - NEW: User-Friendly Statistics Card
    
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

    // MARK: - Supporting Views

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

    private struct EventDTO {
        let id: String
        let entityType: String
        let entityName: String
        let entityID: Int
        let openDateTime: Date
        let closeDateTime: Date?
        let minutesOpen: Double
        let latitude: Double
        let longitude: Double
    }
}
