//
//  ContentViewModular.swift
//  Bridget
//
//  Created by Peter Jemley on 6/19/25.
//  
//  This is a modular version of ContentView that imports from Swift Packages
//  To be used once packages are added to the Xcode project

import SwiftUI
import SwiftData
// Modular package imports
import BridgetCore
import BridgetNetworking
import BridgetSharedUI
import BridgetDashboard
import BridgetBridgesList
import BridgetHistory
import BridgetStatistics
import BridgetSettings
import BridgetRouting

struct ContentViewModular: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allEvents: [DrawbridgeEvent]
    @Query private var bridgeInfo: [DrawbridgeInfo]
    
    // Loading state for automatic data fetching
    @State private var isLoadingInitialData = false
    @State private var initialDataLoaded = false
    @State private var dataFetchError: String?
    @State private var bridgeInfoSyncInProgress = false
    @State private var lastRefreshDate: Date?
    
    // Motion Detection Service
    @StateObject private var motionService = MotionDetectionService()
    
    private var events: [DrawbridgeEvent] {
        return allEvents 
    }
    
    var body: some View {
        ZStack {
            TabView {
                // Dashboard Tab - Using modular DashboardView
                DashboardView(events: events, bridgeInfo: bridgeInfo, motionService: motionService)
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Dashboard")
                    }
                
                // Routes Tab - Using modular RoutingView
                RoutingView()
                    .tabItem {
                        Image(systemName: "car.fill")
                        Text("Routes")
                    }
                
                // Bridges Tab - Using modular BridgesListView
                BridgesListView(events: events, bridgeInfo: bridgeInfo)
                    .tabItem {
                        Image(systemName: "road.lanes")
                        Text("Bridges")
                    }
                
                // History Tab - Using modular HistoryView
                HistoryView(events: events)
                    .tabItem {
                        Image(systemName: "clock.fill")
                        Text("History")
                    }
                
                // Statistics Tab - Using modular StatisticsView
                StatisticsView()
                    .tabItem {
                        Image(systemName: "chart.bar.fill")
                        Text("Statistics")
                    }
                
                // Settings Tab - Using modular SettingsView
                SettingsView()
                    .tabItem {
                        Image(systemName: "gear")
                        Text("Settings")
                    }
            }
            
            // Loading overlay for initial data fetch
            if isLoadingInitialData {
                LoadingDataOverlay()
            }
        }
        .task {
            await loadInitialDataIfNeeded()
        }
        .onAppear {
            print("🏠 [MAIN] ContentView appeared - Events: \(allEvents.count), Filtered: \(events.count), Bridge Info: \(bridgeInfo.count)")
            
            // Start motion detection monitoring
            motionService.startMonitoring()
            print("🏠 [MAIN] Motion detection monitoring started")
            
            // IMPROVED: Always check for bridge info sync on appear
            Task {
                await ensureBridgeInfoSynchronized()
            }
        }
        .onChange(of: allEvents.count) { oldCount, newCount in
            // FIXED: Trigger bridge info sync when events change
            print("🏠 [MAIN] Events count changed: \(oldCount) → \(newCount)")
            
            if newCount > 0 && bridgeInfo.count == 0 && !bridgeInfoSyncInProgress {
                print("🏠 [MAIN] Events loaded but no bridge info - triggering sync...")
                Task {
                    await ensureBridgeInfoSynchronized()
                }
            }
        }
        .refreshable {
            print("🏠 [MAIN] Manual refresh triggered")
            await forceDataRefresh()
        }
    }
    
    // MARK: - API Call Tracking
    
    private func incrementApiCallCount() {
        let currentSessionCount = UserDefaults.standard.integer(forKey: "BridgetSessionAPICallCount") + 1
        let totalCount = UserDefaults.standard.integer(forKey: "BridgetAPICallCount") + 1
        
        UserDefaults.standard.set(currentSessionCount, forKey: "BridgetSessionAPICallCount")
        UserDefaults.standard.set(totalCount, forKey: "BridgetAPICallCount")
        
        print("🌐 [API TRACKING] API call count updated: Session = \(currentSessionCount), Total = \(totalCount)")
    }
    
    // IMPROVED: Dedicated bridge info synchronization function
    private func ensureBridgeInfoSynchronized() async {
        guard !events.isEmpty else {
            print("🏠 [SYNC] No events available for bridge info sync")
            return
        }
        
        guard bridgeInfo.isEmpty else {
            print("🏠 [SYNC] Bridge info already exists (\(bridgeInfo.count) bridges)")
            return
        }
        
        guard !bridgeInfoSyncInProgress else {
            print("🏠 [SYNC] Bridge info sync already in progress")
            return
        }
        
        await MainActor.run {
            bridgeInfoSyncInProgress = true
        }
        
        print("🏠 [SYNC] Starting bridge info synchronization...")
        print("🏠 [SYNC] Have \(events.count) events, \(bridgeInfo.count) bridge info records")
        
        await MainActor.run {
            createBridgeInfoFromEvents()
            
            // CRITICAL: Force save and wait for completion
            do {
                try modelContext.save()
                print("🏠 [SYNC] ✅ Bridge info saved to SwiftData")
                
                // Give SwiftData time to update @Query
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    bridgeInfoSyncInProgress = false
                    print("🏠 [SYNC] ✅ Bridge info sync completed - Final count: \(bridgeInfo.count)")
                }
            } catch {
                print("❌ [SYNC ERROR] Failed to save bridge info: \(error)")
                bridgeInfoSyncInProgress = false
            }
        }
    }
    
    // Initial data loading function
    private func loadInitialDataIfNeeded() async {
        print("🏠 [MAIN] Data check - Events: \(allEvents.count), Filtered: \(events.count), Bridge Info: \(bridgeInfo.count), Already loaded: \(initialDataLoaded)")
        
        guard events.isEmpty else { 
            print("🏠 [MAIN] Skipping data load - already have \(events.count) events")
            
            // IMPROVED: Use dedicated sync function
            await ensureBridgeInfoSynchronized()
            return 
        }
        
        await loadNewData()
    }
    
    private func loadNewData() async {
        print("🏠 [MAIN] Starting data load...")
        
        await MainActor.run {
            isLoadingInitialData = true
            dataFetchError = nil
            initialDataLoaded = false
        }
        
        do {
            print("🏠 [MAIN] Calling DrawbridgeAPI.fetchDrawbridgeData...")
            
            // Using modular DrawbridgeAPI from BridgetNetworking - get all available data
            let fetchedEventDTOs = try await DrawbridgeAPI.fetchDrawbridgeData(limit: 10000)
            
            print("🏠 [MAIN] 🎯 API RETURNED \(fetchedEventDTOs.count) EVENTS")
            
            // FIXED: Track the API call that just completed successfully
            await MainActor.run {
                incrementApiCallCount()
                lastRefreshDate = Date()
            }
            
            // Store events FIRST
            for dto in fetchedEventDTOs {
                let event = DrawbridgeEvent(
                    entityType: dto.entityType,
                    entityName: dto.entityName,
                    entityID: dto.entityID,
                    openDateTime: dto.openDateTime,
                    closeDateTime: dto.closeDateTime,
                    minutesOpen: dto.minutesOpen,
                    latitude: dto.latitude,
                    longitude: dto.longitude
                )
                modelContext.insert(event)
            }
            
            // CRITICAL: Save events first, then create bridge info
            do {
                try modelContext.save()
                print("🏠 [MAIN] ✅ Events saved to SwiftData")
            } catch {
                print("❌ [MAIN ERROR] Failed to save events: \(error)")
                await MainActor.run {
                    dataFetchError = error.localizedDescription
                    isLoadingInitialData = false
                    initialDataLoaded = false
                }
                return
            }
            
            // Log per-bridge event counts
            let bridgeGroups = Dictionary(grouping: events, by: \.entityName)
            print("🏠 [MAIN] 📈 BRIDGE BREAKDOWN:")
            for (bridgeName, bridgeEvents) in bridgeGroups.sorted(by: { $0.value.count > $1.value.count }) {
                print("🏠 [MAIN]    • \(bridgeName): \(bridgeEvents.count) events")
            }
            
            await MainActor.run {
                initialDataLoaded = true
                isLoadingInitialData = false
            }
            
            print("🏠 [MAIN] ✅ DATA LOAD COMPLETE")
            print("🏠 [MAIN] 🎯 FINAL STATS: \(events.count) total events across \(bridgeGroups.count) bridges")
            
            // IMPROVED: Bridge info creation happens after events are saved
            await ensureBridgeInfoSynchronized()
            
        } catch {
            print("❌ [MAIN ERROR] Data load failed: \(error)")
            
            // FIXED: Track failed API calls too
            await MainActor.run {
                incrementApiCallCount()
                dataFetchError = error.localizedDescription
                isLoadingInitialData = false
                initialDataLoaded = false
            }
        }
    }
    
    // SIMPLIFIED: Bridge info creation function (must run on MainActor)
    @MainActor
    private func createBridgeInfoFromEvents() {
        print("🏗️ [BRIDGE INFO] Starting bridge info creation...")
        
        let uniqueBridges = DrawbridgeEvent.getUniqueBridges(events)
        print("🏗️ [BRIDGE INFO] Found \(uniqueBridges.count) unique bridges from \(events.count) events")
        
        var createdCount = 0
        
        for bridgeData in uniqueBridges {
            // Check if bridge info already exists (prevent duplicates)
            let existingInfo = bridgeInfo.first { $0.entityID == bridgeData.entityID }
            
            if existingInfo == nil {
                print("🏗️ [BRIDGE INFO] Creating new info for \(bridgeData.entityName) (ID: \(bridgeData.entityID))")
                
                // Get all events for this specific bridge
                let allBridgeEvents = events.filter { $0.entityID == bridgeData.entityID }
                
                // Create new bridge info
                let newBridgeInfo = DrawbridgeInfo(
                    entityID: bridgeData.entityID,
                    entityName: bridgeData.entityName,
                    entityType: bridgeData.entityType,
                    latitude: bridgeData.latitude,
                    longitude: bridgeData.longitude
                )
                
                // Calculate statistics
                newBridgeInfo.totalOpenings = allBridgeEvents.count
                if !allBridgeEvents.isEmpty {
                    let durations = allBridgeEvents.map(\.minutesOpen)
                    newBridgeInfo.averageOpenTimeMinutes = durations.reduce(0, +) / Double(durations.count)
                    newBridgeInfo.longestOpenTimeMinutes = durations.max() ?? 0
                }
                newBridgeInfo.lastUpdated = Date()
                
                modelContext.insert(newBridgeInfo)
                createdCount += 1
                
                print("🏗️ [BRIDGE INFO] ✅ Created \(bridgeData.entityName): \(allBridgeEvents.count) events, avg \(String(format: "%.1f", newBridgeInfo.averageOpenTimeMinutes))min")
            } else {
                print("🏗️ [BRIDGE INFO] Bridge info already exists for \(bridgeData.entityName)")
            }
        }
        
        print("🏗️ [BRIDGE INFO] ✅ Bridge info creation complete - Created: \(createdCount) new records")
    }
    
    // IMPROVED: Force refresh with proper synchronization and API tracking
    public func forceDataRefresh() async {
        print("🏠 [MAIN] 🔄 Force refresh initiated")
        
        await MainActor.run {
            initialDataLoaded = false
            bridgeInfoSyncInProgress = false
        }
        
        await loadNewData()
    }
}

// MARK: - Preview
struct ContentViewModular_Previews: PreviewProvider {
    static var previews: some View {
        ContentViewModular()
            .modelContainer(for: [DrawbridgeEvent.self, DrawbridgeInfo.self], inMemory: true)
    }
}