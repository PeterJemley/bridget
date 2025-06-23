//
//  BridgeHistoricalStatusRow.swift
//  BridgetDashboard
//
//  Created by Peter Jemley on 6/19/25.
//

import SwiftUI
import BridgetCore

public struct BridgeHistoricalStatusRow: View {
    public let event: DrawbridgeEvent
    @State private var prediction: BridgePrediction?
    @State private var isCalculatingPrediction = false
    
    public init(event: DrawbridgeEvent) {
        self.event = event
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            // Bridge Status Icon
            Circle()
                .fill(statusColor)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(event.entityName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    // Prediction Display
                    if isCalculatingPrediction {
                        HStack(spacing: 4) {
                            ProgressView()
                                .scaleEffect(0.6)
                            Text("Calculating...")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    } else if let prediction = prediction {
                        Text(prediction.probabilityText)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(predictionColor.opacity(0.2))
                            .foregroundColor(predictionColor)
                            .cornerRadius(4)
                    } else {
                        Text("No Prediction")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    Text(statusText)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(statusColor)
                    
                    Spacer()
                    
                    Text(event.relativeTimeText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Navigation Arrow
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .onAppear {
            calculatePrediction()
        }
    }
    
    // MARK: - Prediction Calculation
    
    private func calculatePrediction() {
        isCalculatingPrediction = true
        
        Task.detached(priority: .userInitiated) {
            let bridgeInfo = DrawbridgeInfo(
                entityID: event.entityID,
                entityName: event.entityName,
                entityType: event.entityType,
                latitude: event.latitude,
                longitude: event.longitude
            )
            
            // Use simplified prediction for consistency
            let calculatedPrediction = await calculateSimplifiedPrediction(for: bridgeInfo)
            
            await MainActor.run {
                self.prediction = calculatedPrediction
                self.isCalculatingPrediction = false
            }
        }
    }
    
    private func calculateSimplifiedPrediction(for bridge: DrawbridgeInfo) async -> BridgePrediction {
        let calendar = Calendar.current
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)
        let currentWeekday = calendar.component(.weekday, from: now)
        
        // Simplified prediction based on current time patterns
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
        
        let dayName = calendar.weekdaySymbols[currentWeekday - 1]
        let hourText = currentHour == 0 ? "12 AM" : 
                      currentHour < 12 ? "\(currentHour) AM" :
                      currentHour == 12 ? "12 PM" : "\(currentHour - 12) PM"
        
        var reasoning = "Prediction for \(dayName) at \(hourText)"
        if isWeekend { reasoning += " (weekend pattern)" }
        if isSummer { reasoning += " (summer season)" }
        
        return BridgePrediction(
            bridge: bridge,
            probability: baseProbability,
            expectedDuration: 15.0,
            confidence: 0.7,
            timeFrame: "next hour",
            reasoning: reasoning
        )
    }
    
    // MARK: - Computed Properties
    
    private var statusText: String {
        // Show historical status
        return event.isCurrentlyOpen ? "WAS OPEN" : "CLOSED"
    }
    
    private var statusColor: Color {
        return event.isCurrentlyOpen ? .red : .green
    }
    
    private var predictionColor: Color {
        guard let prediction = prediction else { return .blue }
        
        switch prediction.probability {
        case 0.0..<0.3: return .green
        case 0.3..<0.6: return .orange  
        case 0.6...1.0: return .red
        default: return .blue
        }
    }
}

#Preview {
    VStack {
        BridgeHistoricalStatusRow(event: DrawbridgeEvent(
            entityType: "Bridge",
            entityName: "Fremont Bridge",
            entityID: 1,
            openDateTime: Date().addingTimeInterval(-3600),
            closeDateTime: nil,
            minutesOpen: 15.0,
            latitude: 47.6519,
            longitude: -122.3531
        ))
        
        BridgeHistoricalStatusRow(event: DrawbridgeEvent(
            entityType: "Bridge", 
            entityName: "Ballard Bridge",
            entityID: 2,
            openDateTime: Date().addingTimeInterval(-7200),
            closeDateTime: nil,
            minutesOpen: 8.0,
            latitude: 47.6613,
            longitude: -122.3750
        ))
    }
    .padding()
}