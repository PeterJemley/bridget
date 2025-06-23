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
    @Query private var events: [DrawbridgeEvent]
    @Query private var bridgeInfo: [DrawbridgeInfo]
    @Query private var analytics: [BridgeAnalytics]
    @Query private var cascadeEvents: [CascadeEvent]

    @State private var isCalculating = false
    @State private var showingARIMADetails = false
    @State private var neuralEngineStatus = "Ready"

    public init() {}
    
    private func updateNeuralEngineStatus() {
        let neuralGeneration = NeuralEngineManager.detectNeuralEngineGeneration()
        neuralEngineStatus = "\(neuralGeneration.rawValue) (\(neuralGeneration.coreCount) cores)"
    }

    public var body: some View {
        NavigationView {
            ScrollView {
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
                    
                    // FIXED: Show actual Neural Engine status instead of "integration in progress..."
                    HStack {
                        Image(systemName: "cpu")
                            .foregroundColor(.green)
                        Text("Neural Engine: \(neuralEngineStatus)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
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
                .padding()
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                print("⚙️ [STATS] StatisticsView Appeared – events.count = \(events.count)")
                if analytics.isEmpty && !events.isEmpty && !isCalculating {
                    calculateAnalytics()
                }
            }
        }
        .onAppear {
            print("⚙️ [STATS] StatisticsView Appeared – events.count = \(events.count)")
            updateNeuralEngineStatus() // ADDED: Update status on appear
            if analytics.isEmpty && !events.isEmpty && !isCalculating {
                calculateAnalytics()
            }
        }
    }

    // MARK: - Current Predictions Section (Safe Implementation)

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

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(predictions, id: \.bridge.entityID) { prediction in
                    PredictionCard(prediction: prediction)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Safe Helper Functions

    private func generateCurrentPredictions() -> [BridgePrediction] {
        print("📊 [STATS] Generating current predictions from \(analytics.count) analytics records")
        
        var predictions: [BridgePrediction] = []

        // SAFETY: Limit to top 5 bridges to prevent hanging
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

        print("📊 [STATS] Generated \(predictions.count) predictions successfully")
        return predictions.sorted { $0.probability > $1.probability }
    }

    private func calculateAnalytics() {
        print("📊 [STATS] Starting SAFE analytics calculation with \(events.count) events...")
        
        guard !events.isEmpty else {
            print("📊 [STATS] No events available for analytics")
            return
        }
        
        isCalculating = true

        // SAFE APPROACH: Create value-type DTOs from SwiftData objects on main thread
        let eventDTOs = events.map { event in
            EventDTO(
                id: event.id,
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
        
        print("📊 [STATS] Created \(eventDTOs.count) EventDTOs safely on main thread")

        Task.detached(priority: .userInitiated) { [eventDTOs] in
            print("📊 [STATS] Running analytics on background thread with DTOs...")
            
            // OPTIMIZATION: Limit events to prevent hanging (use most recent 1000 events)
            let limitedEventDTOs = Array(eventDTOs.sorted { $0.openDateTime > $1.openDateTime }.prefix(1000))
            print("📊 [STATS] Using \(limitedEventDTOs.count) most recent events for analytics")
            
            do {
                // Convert DTOs back to DrawbridgeEvent objects for analytics calculation
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
                
                print("📊 [STATS] Analytics calculation complete on background thread: \(newAnalytics.count) records")

                await MainActor.run {
                    print("📊 [STATS] Updating UI on main thread...")
                    isCalculating = false
                }
            } catch {
                print("❌ [STATS] Analytics calculation failed: \(error)")
                await MainActor.run {
                    isCalculating = false
                }
            }
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

// MARK: - Existing Prediction Card

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

                Text(prediction.confidenceText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(prediction.reasoning)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(2)
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
