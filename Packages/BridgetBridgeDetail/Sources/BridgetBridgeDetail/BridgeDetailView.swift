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
    @Query private var cascadeEvents: [CascadeEvent]
    
    public let bridgeEvent: DrawbridgeEvent
    @State private var selectedPeriod: TimePeriod = .sevenDays
    @State private var selectedAnalysis: AnalysisType = .patterns
    @State private var selectedView: ViewType = .activity
    
    @State private var isDataReady = false
    @State private var dataCheckTimer: Timer?
    
    public var bridgeInfo: DrawbridgeEvent {
        bridgeEvent
    }
    
    public var events: [DrawbridgeEvent] {
        bridgeSpecificEvents
    }
    
    public init(bridgeEvent: DrawbridgeEvent) {
        self.bridgeEvent = bridgeEvent
    }
    
    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    BridgeHeaderSection(
                        bridgeName: bridgeInfo.entityName,
                        lastKnownEvent: lastKnownEvent,
                        totalEvents: bridgeSpecificEvents.count
                    )
                    
                    FunctionalTimeFilterSection(
                        selectedPeriod: $selectedPeriod,
                        bridgeEvents: filteredEvents
                    )
                    
                    BridgeStatsSection(
                        events: filteredEvents,
                        timePeriod: selectedPeriod,
                        analysisType: selectedAnalysis
                    )
                    
                    AnalysisFilterSection(selectedAnalysis: $selectedAnalysis)
                    ViewFilterSection(selectedView: $selectedView)
                    
                    DynamicAnalysisSection(
                        events: filteredEvents,
                        analysisType: selectedAnalysis,
                        viewType: selectedView,
                        bridgeName: bridgeInfo.entityName
                    )
                }
                .padding()
            }
            .navigationTitle(bridgeInfo.entityName)
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                print("🌉 [BRIDGE DETAIL] Appeared for \(bridgeInfo.entityName)")
                print("🌉 [BRIDGE DETAIL] Events: \(events.count), Filtered: \(filteredEvents.count)")
                
                print("🏗️ [BRIDGE DETAIL] View appeared for \(bridgeEvent.entityName)")
                print("🏗️ [BRIDGE DETAIL] All events: \(allEvents.count)")
                print("🏗️ [BRIDGE DETAIL] Bridge events: \(bridgeSpecificEvents.count)")
                checkDataAvailability()
            }
            .onChange(of: allEvents.count) { oldValue, newValue in
                print(" [BRIDGE DETAIL] Events count changed: \(oldValue) → \(newValue)")
                checkDataAvailability()
            }
            .onDisappear {
                dataCheckTimer?.invalidate()
            }
        }
    }
    
    // MARK: - Cascade Detection
    private func forceCascadeDetectionForBridge() async {
        print(" [BRIDGE DETAIL]  FORCING CASCADE DETECTION...")
        
        let currentEvents = Array(allEvents.sorted { $0.openDateTime > $1.openDateTime }.prefix(500))
        
        await Task.detached(priority: .userInitiated) {
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
            
            let cascadeEvents = CascadeDetectionEngine.detectCascadeEffects(from: eventDTOs)
            print(" [BRIDGE DETAIL] Detected \(cascadeEvents.count) cascade events!")
            
            await MainActor.run {
                for existingEvent in self.cascadeEvents {
                    self.modelContext.delete(existingEvent)
                }
                
                for cascadeEvent in cascadeEvents {
                    self.modelContext.insert(cascadeEvent)
                }
                
                do {
                    try self.modelContext.save()
                    print(" [BRIDGE DETAIL]  CASCADE EVENTS SAVED!")
                } catch {
                    print(" [BRIDGE DETAIL] Failed to save: \(error)")
                }
            }
        }.value
    }
    
    // MARK: - Data Availability Checking
    private func checkDataAvailability() {
        print(" [BRIDGE DETAIL] Checking data availability...")
        print(" [BRIDGE DETAIL] Total events: \(allEvents.count)")
        print(" [BRIDGE DETAIL] Bridge \(bridgeEvent.entityID) events: \(bridgeSpecificEvents.count)")
        
        // Check if we have data for this specific bridge
        if !bridgeSpecificEvents.isEmpty {
            print(" [BRIDGE DETAIL]  Data ready for \(bridgeEvent.entityName)")
            isDataReady = true
            dataCheckTimer?.invalidate()
        } else if allEvents.count > 0 {
            // We have events but not for this bridge - immediate ready
            print(" [BRIDGE DETAIL]  No events for bridge \(bridgeEvent.entityID) but other data exists")
            isDataReady = true
            dataCheckTimer?.invalidate()
        } else {
            // No data yet - start polling timer
            print(" [BRIDGE DETAIL]  No data yet, starting timer...")
            startDataCheckTimer()
        }
    }
    
    private func startDataCheckTimer() {
        dataCheckTimer?.invalidate()
        dataCheckTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            print(" [BRIDGE DETAIL] Timer check - Events: \(allEvents.count)")
            if allEvents.count > 0 {
                checkDataAvailability()
            }
        }
        
        // Failsafe: Stop checking after 10 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            if !isDataReady {
                print(" [BRIDGE DETAIL]  Timeout reached, showing view anyway")
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
        let calendar = Calendar.current
        let now = Date()
        
        let cutoffDate: Date
        switch selectedPeriod {
        case .twentyFourHours:
            // For 24H, use a more inclusive filter to catch edge cases
            cutoffDate = calendar.date(byAdding: .hour, value: -25, to: now) ?? now
        default:
            cutoffDate = calendar.date(byAdding: .day, value: -selectedPeriod.days, to: now) ?? now
        }
        
        let filtered = bridgeSpecificEvents.filter { $0.openDateTime >= cutoffDate }
        
        print(" [FILTER] Period: \(selectedPeriod), Cutoff: \(cutoffDate)")
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