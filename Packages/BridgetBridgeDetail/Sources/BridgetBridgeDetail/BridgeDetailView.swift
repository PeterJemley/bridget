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
    
    public init(bridgeEvent: DrawbridgeEvent) {
        self.bridgeEvent = bridgeEvent
    }
    
    public var body: some View {
        ScrollView {
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
        }
        .navigationTitle(bridgeEvent.entityName)
        .navigationBarTitleDisplayMode(.inline)
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