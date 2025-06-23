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

public struct BridgeDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allEvents: [DrawbridgeEvent]
    
    public let bridgeEvent: DrawbridgeEvent
    @State private var selectedPeriod: TimePeriod = .sevenDays
    @State private var selectedAnalysis: AnalysisType = .patterns
    @State private var selectedView: ViewType = .activity
    
    @State private var isDataReady = false
    @State private var dataCheckTimer: Timer?
    
    public init(bridgeEvent: DrawbridgeEvent) {
        self.bridgeEvent = bridgeEvent
    }
    
    public var body: some View {
        ScrollView {
            if isDataReady && !bridgeSpecificEvents.isEmpty {
                VStack(alignment: .leading, spacing: 20) {
                    // Header Section with Bridge-specific Data
                    BridgeHeaderSection(
                        bridgeName: bridgeEvent.entityName,
                        lastKnownEvent: lastKnownEvent,
                        totalEvents: bridgeSpecificEvents.count
                    )
                    
                    // Time Period Filter Buttons (Functional)
                    FunctionalTimeFilterSection(
                        selectedPeriod: $selectedPeriod,
                        bridgeEvents: bridgeSpecificEvents
                    )
                    
                    // Analysis Type Filter Buttons (NOW FUNCTIONAL)
                    AnalysisFilterSection(selectedAnalysis: $selectedAnalysis)
                    
                    // View Type Filter Buttons (NOW FUNCTIONAL)
                    ViewFilterSection(selectedView: $selectedView)
                    
                    // Bridge Statistics Section (Updated to use selected filters)
                    BridgeStatsSection(
                        events: filteredEvents,
                        timePeriod: selectedPeriod,
                        analysisType: selectedAnalysis
                    )
                    
                    // Dynamic Content Section Based on Selected Analysis and View
                    DynamicAnalysisSection(
                        events: filteredEvents,
                        analysisType: selectedAnalysis,
                        viewType: selectedView,
                        bridgeName: bridgeEvent.entityName
                    )
                    
                    // Bridge Info Section
                    BridgeInfoSection(event: bridgeEvent)
                    
                    Spacer(minLength: 100)
                }
                .padding()
            } else {
                VStack(spacing: 20) {
                    Text("Loading \(bridgeEvent.entityName) Details...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    ProgressView()
                        .scaleEffect(1.2)
                    
                    Text("Gathering bridge data...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("SwiftData Events: \(allEvents.count)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.top)
                    
                    Text("Bridge Events: \(bridgeSpecificEvents.count)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            }
        }
        .navigationTitle(bridgeEvent.entityName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            print("🏗️ [BRIDGE DETAIL] View appeared for \(bridgeEvent.entityName)")
            print("🏗️ [BRIDGE DETAIL] All events: \(allEvents.count)")
            print("🏗️ [BRIDGE DETAIL] Bridge events: \(bridgeSpecificEvents.count)")
            checkDataAvailability()
        }
        .onChange(of: allEvents.count) { oldValue, newValue in
            print("🏗️ [BRIDGE DETAIL] Events count changed: \(oldValue) → \(newValue)")
            checkDataAvailability()
        }
        .onDisappear {
            dataCheckTimer?.invalidate()
        }
    }
    
    private func checkDataAvailability() {
        print("🏗️ [BRIDGE DETAIL] Checking data availability...")
        print("🏗️ [BRIDGE DETAIL] Total events: \(allEvents.count)")
        print("🏗️ [BRIDGE DETAIL] Bridge \(bridgeEvent.entityID) events: \(bridgeSpecificEvents.count)")
        
        // Check if we have data for this specific bridge
        if !bridgeSpecificEvents.isEmpty {
            print("🏗️ [BRIDGE DETAIL] ✅ Data ready for \(bridgeEvent.entityName)")
            isDataReady = true
            dataCheckTimer?.invalidate()
        } else if allEvents.count > 0 {
            // We have events but not for this bridge - immediate ready
            print("🏗️ [BRIDGE DETAIL] ⚠️ No events for bridge \(bridgeEvent.entityID) but other data exists")
            isDataReady = true
            dataCheckTimer?.invalidate()
        } else {
            // No data yet - start polling timer
            print("🏗️ [BRIDGE DETAIL] ⏳ No data yet, starting timer...")
            startDataCheckTimer()
        }
    }
    
    private func startDataCheckTimer() {
        dataCheckTimer?.invalidate()
        dataCheckTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            print("🏗️ [BRIDGE DETAIL] Timer check - Events: \(allEvents.count)")
            if allEvents.count > 0 {
                checkDataAvailability()
            }
        }
        
        // Failsafe: Stop checking after 10 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            if !isDataReady {
                print("🏗️ [BRIDGE DETAIL] ⚠️ Timeout reached, showing view anyway")
                isDataReady = true
                dataCheckTimer?.invalidate()
            }
        }
    }
    
    // MARK: - Phase 1 Data Filtering Logic
    private var bridgeSpecificEvents: [DrawbridgeEvent] {
        allEvents.filter { $0.entityID == bridgeEvent.entityID }
            .sorted { $0.openDateTime > $1.openDateTime }
    }
    
    private var filteredEvents: [DrawbridgeEvent] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -selectedPeriod.days, to: Date()) ?? Date()
        return bridgeSpecificEvents.filter { $0.openDateTime >= cutoffDate }
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