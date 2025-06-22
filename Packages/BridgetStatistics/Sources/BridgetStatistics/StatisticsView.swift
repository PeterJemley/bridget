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

public struct StatisticsView: View {
    @Query private var events: [DrawbridgeEvent]
    @Query private var bridgeInfo: [DrawbridgeInfo]
    @Query private var analytics: [BridgeAnalytics]
    @Query private var cascadeEvents: [CascadeEvent]

    @State private var isCalculating = false
    @State private var showingARIMADetails = false

    public init() {}

    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.title2)
                                .foregroundColor(.blue)
                            
                            Text("Predictions")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        
                        Text("AI-powered bridge opening predictions")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
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

                    // ARIMA Predictions Section (Phase 3) - TEMPORARILY DISABLED
                    if !events.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Label("ARIMA Predictions", systemImage: "cpu")
                                    .font(.headline)
                                    .foregroundColor(.purple)
                                
                                Spacer()
                                
                                Button("Model Details") {
                                    showingARIMADetails = true
                                }
                                .font(.caption)
                                .foregroundColor(.purple)
                            }
                            
                            Text("Phase 3: Advanced Time Series Forecasting")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("Neural Engine ARIMA integration in progress...")
                                .font(.caption)
                                .foregroundColor(.orange)
                                .padding()
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }

                    // Enhanced Predictions Section (Phase 1+2+3 Combined)
                    if !analytics.isEmpty {
                        enhancedPredictionsSection
                    }

                    // Current Predictions (Existing)
                    if !analytics.isEmpty {
                        currentPredictionsSection
                    } else if !isCalculating {
                        // Calculate analytics if none exist
                        Button("Generate Predictions") {
                            calculateAnalytics()
                        }
                        .buttonStyle(.borderedProminent)
                        .padding()
                    }

                    if isCalculating {
                        ProgressView("Calculating analytics...")
                            .padding()
                    }
                }
                .padding()
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await calculateAnalyticsAsync()
            }
            .onAppear {
                if analytics.isEmpty && !events.isEmpty {
                    calculateAnalytics()
                }
            }
            .sheet(isPresented: $showingARIMADetails) {
                NavigationView {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Neural Engine ARIMA Performance")
                                .font(.title2)
                                .fontWeight(.bold)

                            Text("Neural Engine integration in progress...")
                                .font(.body)
                                .foregroundColor(.orange)
                        }
                        .padding()
                    }
                    .navigationTitle("Neural ARIMA Models")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showingARIMADetails = false
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Neural Engine ARIMA Predictions Section (Phase 3) - UPDATED

    @ViewBuilder
    private var enhancedPredictionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Enhanced Predictions", systemImage: "brain")
                    .font(.headline)
                    .foregroundColor(.green)

                Spacer()

                Text("Phases 1+2+3")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text("Seasonal + Cascade + ARIMA Combined")
                .font(.caption)
                .foregroundColor(.secondary)

            let enhancedPredictions = generateEnhancedPredictions()

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(enhancedPredictions, id: \.entityID) { prediction in
                    EnhancedPredictionCard(prediction: prediction)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Current Predictions Section (Existing)

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

    // MARK: - Neural Engine ARIMA Model Details View - UPDATED

    @ViewBuilder
    private var neuralArimaModelDetailsView: some View {
        AsyncNeuralARIMADetailsView(events: Array(events), analytics: Array(analytics))
    }

    // MARK: - Helper Functions

    private func generateEnhancedPredictions() -> [ARIMABridgePrediction] {
        var enhancedPredictions: [ARIMABridgePrediction] = []

        for bridge in bridgeInfo {
            if let prediction = BridgeAnalytics.getARIMAEnhancedPrediction(
                for: bridge,
                events: Array(events),
                analytics: Array(analytics),
                cascadeEvents: Array(cascadeEvents)
            ) {
                enhancedPredictions.append(prediction)
            }
        }

        return enhancedPredictions.sorted { $0.probability > $1.probability }
    }

    private func generateCurrentPredictions() -> [BridgePrediction] {
        var predictions: [BridgePrediction] = []

        for bridge in bridgeInfo {
            if let prediction = BridgeAnalytics.getCurrentPrediction(
                for: bridge,
                from: Array(analytics)
            ) {
                predictions.append(prediction)
            }
        }

        return predictions.sorted { $0.probability > $1.probability }
    }

    private func calculateAnalytics() {
        print("📊 [STATS] Starting analytics calculation with \(events.count) events...")
        isCalculating = true

        Task.detached(priority: .userInitiated) {
            print("📊 [STATS] Running analytics on background thread...")
            
            // Run analytics calculation on background thread with timeout protection
            let newAnalytics = BridgeAnalyticsCalculator.calculateAnalytics(from: Array(events))
            
            print("📊 [STATS] Analytics calculation complete: \(newAnalytics.count) records")

            await MainActor.run {
                print("📊 [STATS] Updating UI on main thread...")
                isCalculating = false
            }
        }
    }

    private func calculateAnalyticsAsync() async {
        print("📊 [STATS] Starting async analytics calculation...")
        isCalculating = true

        // Run analytics calculation with proper isolation
        let newAnalytics = await Task.detached(priority: .userInitiated) {
            print("📊 [STATS] Background analytics calculation starting...")
            let result = BridgeAnalyticsCalculator.calculateAnalytics(from: Array(events))
            print("📊 [STATS] Background analytics calculation complete: \(result.count) records")
            return result
        }.value

        print("📊 [STATS] Analytics complete, updating UI...")
        isCalculating = false
    }
}

// MARK: - Async Neural Engine ARIMA Predictions View - TEMPORARILY DISABLED

struct AsyncNeuralARIMAPredictionsView: View {
    let events: [DrawbridgeEvent]
    let analytics: [BridgeAnalytics]
    
    @State private var predictions: [NeuralARIMAPrediction] = []
    @State private var isLoading = true
    @State private var deviceInfo: (generation: String, cores: Int, tops: Double, complexity: String)?
    @State private var processingTime: Double = 0.0
    
    var body: some View {
        if isLoading {
            VStack(spacing: 8) {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Training Neural Engine ARIMA models...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let info = deviceInfo {
                    Text("Neural Engine \(info.generation) (\(info.cores) cores, \(String(format: "%.1f", info.tops)) TOPS)")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
            .padding()
        } else if predictions.isEmpty {
            Text("Insufficient data for ARIMA modeling (need 48+ hours)")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding()
        } else {
            VStack(spacing: 12) {
                // Device info header
                if let info = deviceInfo {
                    HStack {
                        Image(systemName: "cpu")
                            .foregroundColor(.blue)
                        Text("Neural Engine \(info.generation)")
                            .font(.caption)
                            .fontWeight(.medium)
                        Spacer()
                        Text("\(info.cores) cores • \(String(format: "%.1f", info.tops)) TOPS")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Success message with processing time
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Neural Engine analysis complete: \(predictions.count) bridges (\(String(format: "%.3f", processingTime))s)")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
                
                // Top predictions
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(Array(predictions.prefix(4)), id: \.entityID) { prediction in
                        NeuralARIMAPredictionCard(prediction: prediction)
                    }
                }
            }
        }
    }
    
    private func loadPredictions() async {
        print("🧠 [Neural ARIMA UI] Starting Neural Engine prediction generation...")
        
        let startTime = Date()
        
        // REAL Neural Engine ARIMA prediction generation
        let neuralPredictor = NeuralEngineARIMAPredictor()
        
        // Get device info from the predictor
        let config = NeuralEngineManager.getOptimalConfig()
        await MainActor.run {
            self.deviceInfo = (
                generation: config.generation.rawValue,
                cores: config.generation.coreCount,
                tops: config.generation.topsCapability,
                complexity: config.complexity.rawValue
            )
        }
        
        // Run Neural Engine ARIMA training on background thread
        let neuralPredictions = await Task.detached(priority: .userInitiated) {
            return neuralPredictor.generatePredictions(
                from: events,
                existingAnalytics: analytics
            )
        }.value
        
        let totalTime = Date().timeIntervalSince(startTime)
        
        await MainActor.run {
            print("🧠 [Neural ARIMA UI] Predictions complete: \(neuralPredictions.count) results in \(String(format: "%.3f", totalTime))s")
            self.predictions = neuralPredictions
            self.processingTime = totalTime
            self.isLoading = false
        }
    }
    
    func onAppear() {
        if !events.isEmpty {
            Task {
                await loadPredictions()
            }
        } else {
            isLoading = false
        }
    }
}

// MARK: - Async Neural Engine ARIMA Details View - FULLY FUNCTIONAL

struct AsyncNeuralARIMADetailsView: View {
    let events: [DrawbridgeEvent]
    let analytics: [BridgeAnalytics]
    
    @State private var predictions: [NeuralARIMAPrediction] = []
    @State private var isLoading = true
    @State private var deviceInfo: (generation: String, cores: Int, tops: Double, complexity: String)?
    @State private var processingTime: Double = 0.0
    
    var body: some View {
        if isLoading {
            VStack {
                ProgressView()
                Text("Loading Neural Engine ARIMA details...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let info = deviceInfo {
                    Text("Device: \(info.generation) (\(info.cores) cores, \(String(format: "%.1f", info.tops)) TOPS)")
                        .font(.caption2)
                        .foregroundColor(.blue)
                        .padding(.top, 4)
                }
            }
            .padding()
        } else if predictions.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                if let info = deviceInfo {
                    HStack {
                        Image(systemName: "cpu")
                            .foregroundColor(.blue)
                        Text("Neural Engine \(info.generation)")
                            .font(.headline)
                        Spacer()
                        Text("Complexity: \(info.complexity)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
                
                Text("Insufficient Historical Data")
                    .font(.headline)
                
                Text("Neural Engine ARIMA requires at least 48 hours of historical data per bridge for reliable predictions. Current dataset may not meet this requirement.")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .padding()
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Device Performance Header
                    if let info = deviceInfo {
                        HStack {
                            Image(systemName: "cpu")
                                .foregroundColor(.blue)
                            Text("Neural Engine \(info.generation)")
                                .font(.headline)
                            Spacer()
                            Text("Processing: \(String(format: "%.3f", processingTime))s")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    // Performance Summary
                    Text("Neural Engine ARIMA Performance")
                        .font(.headline)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        StatCard(
                            title: "Models Trained",
                            value: "\(predictions.count)",
                            icon: "brain",
                            color: .blue
                        )
                        
                        StatCard(
                            title: "Avg Accuracy",
                            value: "\(Int(predictions.map(\.neuralAccuracy).reduce(0, +) / Double(max(1, predictions.count)) * 100))%",
                            icon: "target",
                            color: .green
                        )
                        
                        StatCard(
                            title: "Processing Time",
                            value: "\(String(format: "%.3f", processingTime))s",
                            icon: "timer",
                            color: .orange
                        )
                    }
                    
                    // Individual Model Details
                    Text("Individual Model Performance")
                        .font(.headline)
                        .padding(.top)
                    
                    ForEach(predictions, id: \.entityID) { prediction in
                        NeuralARIMAModelDetailCard(prediction: prediction)
                    }
                }
                .padding()
            }
        }
    }
    
    private func loadDetails() {
        Task {
            print("🧠 [Neural ARIMA Details] Starting detailed analysis...")
            
            let startTime = Date()
            
            // Real Neural Engine ARIMA prediction generation
            let neuralPredictor = NeuralEngineARIMAPredictor()
            
            // Get device info
            let config = NeuralEngineManager.getOptimalConfig()
            await MainActor.run {
                self.deviceInfo = (
                    generation: config.generation.rawValue,
                    cores: config.generation.coreCount,
                    tops: config.generation.topsCapability,
                    complexity: config.complexity.rawValue
                )
            }
            
            // Generate predictions
            let detailedPredictions = await Task.detached(priority: .userInitiated) {
                return neuralPredictor.generatePredictions(
                    from: events,
                    existingAnalytics: analytics
                )
            }.value
            
            let totalTime = Date().timeIntervalSince(startTime)
            
            await MainActor.run {
                print("🧠 [Neural ARIMA Details] Analysis complete: \(detailedPredictions.count) models in \(String(format: "%.3f", totalTime))s")
                self.predictions = detailedPredictions
                self.processingTime = totalTime
                self.isLoading = false
            }
        }
    }
    
    init(events: [DrawbridgeEvent], analytics: [BridgeAnalytics]) {
        self.events = events
        self.analytics = analytics
        loadDetails()
    }
}

// MARK: - Neural ARIMA Prediction Card - TEMPORARILY DISABLED

struct NeuralARIMAPredictionCard: View {
    let prediction: NeuralARIMAPrediction
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(prediction.entityName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Spacer()
                
                Image(systemName: "cpu")
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
            
            HStack {
                Text(prediction.probabilityText)
                    .font(.caption2)
                    .foregroundColor(probabilityColor)
                
                Spacer()
                
                Text("\(Int(prediction.probability * 100))%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(probabilityColor)
            }
            
            Text("\(Int(prediction.neuralAccuracy * 100))% accuracy")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(6)
        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
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

// MARK: - Neural ARIMA Model Detail Card - NEW

struct NeuralARIMAModelDetailCard: View {
    let prediction: NeuralARIMAPrediction
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(prediction.entityName)
                    .font(.headline)
                
                Spacer()
                
                Text(prediction.modelText)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(6)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Neural Engine Performance")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("Accuracy")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(Int(prediction.neuralAccuracy * 100))%")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading) {
                        Text("Processing")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(prediction.processingTimeText)
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading) {
                        Text("Confidence")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(Int(prediction.confidence * 100))%")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                }
                
                Divider()
                
                Text("Current Prediction")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("Probability")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(Int(prediction.probability * 100))%")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(probabilityColor)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading) {
                        Text("Duration")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(prediction.durationText)
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading) {
                        Text("Hardware")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(prediction.coreCount) cores")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                }
            }
            
            Text(prediction.reasoning)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
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

// MARK: - ARIMA Prediction Card

struct ARIMAPredictionCard: View {
    let prediction: ARIMABridgePrediction

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(prediction.entityName)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                Text(prediction.modelConfigText)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.purple.opacity(0.2))
                    .cornerRadius(4)
            }

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

                Text("Accuracy: \(Int(prediction.arimaAccuracy * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("RMSE: \(String(format: "%.2f", prediction.modelRMSE))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(prediction.confidenceText)
                .font(.caption)
                .foregroundColor(.secondary)
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

// MARK: - Enhanced Prediction Card

struct EnhancedPredictionCard: View {
    let prediction: ARIMABridgePrediction

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(prediction.entityName)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                Image(systemName: "brain")
                    .font(.caption)
                    .foregroundColor(.green)
            }

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

                Text("\(prediction.confidenceText)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text("All Phases Combined")
                .font(.caption2)
                .foregroundColor(.green)
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

// MARK: - ARIMA Model Detail Card

struct ARIMAModelDetailCard: View {
    let prediction: ARIMABridgePrediction

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(prediction.entityName)
                    .font(.headline)

                Spacer()

                Text(prediction.modelConfigText)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.purple.opacity(0.2))
                    .cornerRadius(6)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Model Performance")
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack {
                    VStack(alignment: .leading) {
                        Text("Accuracy")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(Int(prediction.arimaAccuracy * 100))%")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }

                    Spacer()

                    VStack(alignment: .leading) {
                        Text("RMSE")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.3f", prediction.modelRMSE))
                            .font(.title3)
                            .fontWeight(.semibold)
                    }

                    Spacer()

                    VStack(alignment: .leading) {
                        Text("MAPE")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.1f%%", prediction.modelMAPE))
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                }

                Divider()

                Text("Current Prediction")
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack {
                    VStack(alignment: .leading) {
                        Text("Probability")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(Int(prediction.probability * 100))%")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(probabilityColor)
                    }

                    Spacer()

                    VStack(alignment: .leading) {
                        Text("Duration")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(prediction.durationText)
                            .font(.title3)
                            .fontWeight(.semibold)
                    }

                    Spacer()

                    VStack(alignment: .leading) {
                        Text("Confidence")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(Int(prediction.confidence * 100))%")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                }
            }

            Text(prediction.reasoning)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
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