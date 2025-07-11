//
//  BridgeDetailView.swift
//  BridgetBridgeDetail
//
//  Created by Peter Jemley on 6/19/25.
//

import SwiftUI
import SwiftData
import Charts
import BridgetCore
import BridgetSharedUI

// MARK: - View Model for Bridge Detail

@MainActor
public class BridgeDetailViewModel: ObservableObject {
    @Published public var selectedPeriod: TimePeriod = .sevenDays
    @Published public var selectedAnalysis: AnalysisType = .patterns
    @Published public var selectedView: ViewType = .activity
    @Published public var isDataReady = false
    @Published public var isLoading = false
    @Published public var errorMessage: String?
    
    private let bridgeEvent: DrawbridgeEvent
    private var dataCheckTimer: Timer?
    
    public init(bridgeEvent: DrawbridgeEvent) {
        self.bridgeEvent = bridgeEvent
    }
    
    // MARK: - Public Interface
    
    public func checkDataAvailability(allEvents: [DrawbridgeEvent]) {
        let bridgeSpecificEvents = allEvents.filter { $0.entityID == bridgeEvent.entityID }
        
        if !bridgeSpecificEvents.isEmpty {
            isDataReady = true
            stopDataCheckTimer()
        } else if allEvents.count > 0 {
            isDataReady = true
            stopDataCheckTimer()
        } else {
            startDataCheckTimer()
        }
    }
    
    public func forceCascadeDetection(allEvents: [DrawbridgeEvent], cascadeEvents: [CascadeEvent], modelContext: ModelContext) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let currentEvents = Array(allEvents.sorted { $0.openDateTime > $1.openDateTime }.prefix(500))
            let eventDTOs = currentEvents.toDTOs
            
            let cascadeEventsDetected = await Task.detached(priority: .userInitiated) {
                CascadeDetectionEngine.detectCascadeEffects(from: eventDTOs)
            }.value
            
            // Update SwiftData on main thread
            for existingEvent in cascadeEvents {
                modelContext.delete(existingEvent)
            }
            
            for cascadeEvent in cascadeEventsDetected {
                modelContext.insert(cascadeEvent)
            }
            
            try modelContext.save()
            
        } catch {
            errorMessage = "Failed to detect cascade events: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Private Methods
    
    private func startDataCheckTimer() {
        stopDataCheckTimer()
        dataCheckTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            // Timer will be invalidated when data is ready
        }
        
        // Failsafe: Stop checking after 10 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            if !self.isDataReady {
                self.isDataReady = true
                self.stopDataCheckTimer()
            }
        }
    }
    
    private func stopDataCheckTimer() {
        dataCheckTimer?.invalidate()
        dataCheckTimer = nil
    }
    
    deinit {
        dataCheckTimer?.invalidate()
    }
}

// MARK: - Main View

public struct BridgeDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DrawbridgeEvent.openDateTime, order: .reverse)
    private var allEvents: [DrawbridgeEvent]
    @Query private var cascadeEvents: [CascadeEvent]
    
    public let bridgeEvent: DrawbridgeEvent
    
    @StateObject private var viewModel: BridgeDetailViewModel
    
    public init(bridgeEvent: DrawbridgeEvent) {
        self.bridgeEvent = bridgeEvent
        self._viewModel = StateObject(wrappedValue: BridgeDetailViewModel(bridgeEvent: bridgeEvent))
    }
    
    public var body: some View {
        NavigationView {
            Group {
                if viewModel.isDataReady {
                    bridgeDetailContent
                } else {
                    loadingView
                }
            }
            .navigationTitle(bridgeInfo.entityName)
#if os(iOS)
            .navigationBarTitleDisplayMode(.large)
#endif
            .onAppear {
                print("🌉 [BRIDGE DETAIL] Appeared for \(bridgeInfo.entityName)")
                print("📊 [BRIDGE DETAIL] Total events: \(allEvents.count), Bridge-specific: \(bridgeSpecificEvents.count)")
                print("🔍 [BRIDGE DETAIL] ModelContext available: \(modelContext != nil)")
                print("🔍 [BRIDGE DETAIL] BridgeEvent ID: \(bridgeEvent.entityID), Name: \(bridgeEvent.entityName)")
                viewModel.checkDataAvailability(allEvents: allEvents)
            }
            .onChange(of: allEvents.count) { _, _ in
                viewModel.checkDataAvailability(allEvents: allEvents)
            }
        }
    }
    
    // MARK: - Loading View
    
    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading bridge data...")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Fetching events for \(bridgeInfo.entityName)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Debug info
            VStack(spacing: 4) {
                Text("Debug Info:")
                    .font(.caption2)
                    .fontWeight(.medium)
                Text("Total Events: \(allEvents.count)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text("Bridge Events: \(bridgeSpecificEvents.count)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text("ModelContext: \(modelContext != nil ? "Available" : "Missing")")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Main Content
    
    @ViewBuilder
    private var bridgeDetailContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Check if we have data for this bridge
                if bridgeSpecificEvents.isEmpty {
                    noDataView
                } else {
                    BridgeHeaderSection(
                        bridgeName: bridgeInfo.entityName,
                        lastKnownEvent: lastKnownEvent,
                        totalEvents: bridgeSpecificEvents.count
                    )
                    
                    FunctionalTimeFilterSection(
                        selectedPeriod: $viewModel.selectedPeriod,
                        bridgeEvents: filteredEvents
                    )
                    
                    BridgeStatsSection(
                        events: filteredEvents,
                        timePeriod: viewModel.selectedPeriod,
                        analysisType: viewModel.selectedAnalysis
                    )
                    
                    AnalysisFilterSection(selectedAnalysis: $viewModel.selectedAnalysis)
                    ViewFilterSection(selectedView: $viewModel.selectedView)
                    
                    DynamicAnalysisSection(
                        events: filteredEvents,
                        analysisType: viewModel.selectedAnalysis,
                        viewType: viewModel.selectedView,
                        bridgeName: bridgeInfo.entityName
                    )
                    
                    if let errorMessage = viewModel.errorMessage {
                        errorView(errorMessage)
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - No Data View
    
    @ViewBuilder
    private var noDataView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
            
            Text("No Data Available")
                .font(.headline)
                .fontWeight(.medium)
            
            Text("No events found for \(bridgeInfo.entityName)")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 4) {
                Text("Debug Information:")
                    .font(.caption)
                    .fontWeight(.medium)
                Text("Bridge ID: \(bridgeEvent.entityID)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text("Total Events in Database: \(allEvents.count)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text("ModelContext Available: \(modelContext != nil ? "Yes" : "No")")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 8)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Error View
    
    @ViewBuilder
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.title2)
            
            Text("Error")
                .font(.caption)
                .fontWeight(.medium)
            
            Text(message)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Retry") {
                Task {
                    await viewModel.forceCascadeDetection(
                        allEvents: allEvents,
                        cascadeEvents: cascadeEvents,
                        modelContext: modelContext
                    )
                }
            }
            .font(.caption)
            .foregroundColor(.blue)
        }
        .padding()
#if os(iOS)
        .background(Color(.systemGray6))
#else
        .background(Color(.controlBackgroundColor))
#endif
        .cornerRadius(12)
    }
    
    // MARK: - Computed Properties
    
    private var bridgeInfo: DrawbridgeEvent {
        bridgeEvent
    }
    
    private var events: [DrawbridgeEvent] {
        bridgeSpecificEvents
    }
    
    private var bridgeSpecificEvents: [DrawbridgeEvent] {
        // Data is already sorted by openDateTime in reverse order from @Query
        allEvents.filter { $0.entityID == bridgeEvent.entityID }
    }
    
    private var filteredEvents: [DrawbridgeEvent] {
        let calendar = Calendar.current
        let now = Date()
        
        let cutoffDate: Date
        switch viewModel.selectedPeriod {
        case .twentyFourHours:
            // For 24H, use a more inclusive filter to catch edge cases
            cutoffDate = calendar.date(byAdding: .hour, value: -25, to: now) ?? now
        default:
            cutoffDate = calendar.date(byAdding: .day, value: -viewModel.selectedPeriod.days, to: now) ?? now
        }
        
        let filtered = bridgeSpecificEvents.filter { $0.openDateTime >= cutoffDate }
        
        print(" [FILTER] Period: \(viewModel.selectedPeriod), Cutoff: \(cutoffDate)")
        print(" [FILTER] Total bridge events: \(bridgeSpecificEvents.count)")
        print(" [FILTER] Filtered events: \(filtered.count)")
        
        if filtered.isEmpty && !bridgeSpecificEvents.isEmpty {
            print(" [FILTER] No events in period but bridge has \(bridgeSpecificEvents.count) total events")
            print(" [FILTER] Latest event: \(bridgeSpecificEvents.first?.openDateTime.formatted() ?? "N/A")")
            print(" [FILTER] Oldest event: \(bridgeSpecificEvents.last?.openDateTime.formatted() ?? "N/A")")
        }
        
        return filtered
    }
    
    private var lastKnownEvent: DrawbridgeEvent? {
        bridgeSpecificEvents.first
    }
}

#Preview {
    BridgeDetailView(
        bridgeEvent: DrawbridgeEvent(
            entityType: "Bridge",
            entityName: "Test Bridge",
            entityID: 1,
            openDateTime: Date(),
            closeDateTime: nil,
            minutesOpen: 15.0,
            latitude: 47.6062,
            longitude: -122.3321
        )
    )
}