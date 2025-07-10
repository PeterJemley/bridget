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
    @Query(sort: \DrawbridgeEvent.openDateTime, order: .reverse)
    private var allEvents: [DrawbridgeEvent]
    @Query private var bridgeInfo: [DrawbridgeInfo]
    
    // Loading state for automatic data fetching
    @State private var isLoadingInitialData = false
    @State private var initialDataLoaded = false
    @State private var dataFetchError: String?
    @State private var bridgeInfoSyncInProgress = false
    @State private var lastRefreshDate: Date?
    
    // Motion Detection Service
    @StateObject private var motionService = MotionDetectionService()
    
    // Background Traffic Agent
    @StateObject private var backgroundAgent: BackgroundTrafficAgent
    
    // MARK: - Computed Properties for Filtered Data
    
    /// All events sorted by date (reverse chronological)
    private var events: [DrawbridgeEvent] {
        return allEvents
    }
    
    /// Recent events (last 30 days) for performance optimization
    private var recentEvents: [DrawbridgeEvent] {
        let cutoff = Self.cutoffDate(daysAgo: 30)
        return allEvents.filter { $0.openDateTime >= cutoff }
    }
    
    /// Helper function for consistent date cutoff calculations
    private static func cutoffDate(daysAgo: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date.distantPast
    }
    
    init() {
        let motionService = MotionDetectionService()
        let trafficService = TrafficAwareRoutingService()
        self._motionService = StateObject(wrappedValue: motionService)
        self._backgroundAgent = StateObject(wrappedValue: BackgroundTrafficAgent(
            trafficService: trafficService,
            motionService: motionService
        ))
    }
    
    var body: some View {
        ZStack {
            TabView {
                // Dashboard Tab - Using modular DashboardView (optimized with recent events)
                DashboardView(events: recentEvents, bridgeInfo: bridgeInfo, motionService: motionService, backgroundAgent: backgroundAgent)
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
                
                // Bridges Tab - Using modular BridgesListView (optimized with recent events)
                BridgesListView(events: recentEvents, bridgeInfo: bridgeInfo)
                    .tabItem {
                        Image(systemName: "road.lanes")
                        Text("Bridges")
                    }
                
                // History Tab - Using modular HistoryView (full dataset for historical analysis)
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
            SecurityLogger.main("ContentView appeared - Events: \(allEvents.count), Recent: \(recentEvents.count), Bridge Info: \(bridgeInfo.count)")
            SecurityLogger.main("ContentView data load - Total: \(allEvents.count), Recent (30d): \(recentEvents.count)")
            
            // Start motion detection monitoring
            motionService.startMonitoring()
            SecurityLogger.main("Motion detection monitoring started")
            
            // IMPROVED: Always check for bridge info sync on appear
            Task {
                await ensureBridgeInfoSynchronized()
            }
        }
        .onChange(of: allEvents.count) { oldCount, newCount in
            // FIXED: Trigger bridge info sync when events change
            SecurityLogger.main("Events count changed: \(oldCount) → \(newCount)")
            
            if newCount > 0 && bridgeInfo.count == 0 && !bridgeInfoSyncInProgress {
                SecurityLogger.main("Events loaded but no bridge info - triggering sync...")
                Task {
                    await ensureBridgeInfoSynchronized()
                }
            }
        }
        .refreshable {
            SecurityLogger.main("Manual refresh triggered")
            await forceDataRefresh()
        }
    }
    
    // MARK: - API Call Tracking
    
    private func incrementApiCallCount() {
        let currentSessionCount = UserDefaults.standard.integer(forKey: "BridgetSessionAPICallCount") + 1
        let totalCount = UserDefaults.standard.integer(forKey: "BridgetAPICallCount") + 1
        
        UserDefaults.standard.set(currentSessionCount, forKey: "BridgetSessionAPICallCount")
        UserDefaults.standard.set(totalCount, forKey: "BridgetAPICallCount")
        
        SecurityLogger.api("API call count updated: Session = \(currentSessionCount), Total = \(totalCount)")
    }
    
    // IMPROVED: Dedicated bridge info synchronization function
    private func ensureBridgeInfoSynchronized() async {
        guard !events.isEmpty else {
            SecurityLogger.sync("No events available for bridge info sync")
            return
        }
        
        guard bridgeInfo.isEmpty else {
            SecurityLogger.sync("Bridge info already exists (\(bridgeInfo.count) bridges)")
            return
        }
        
        guard !bridgeInfoSyncInProgress else {
            SecurityLogger.sync("Bridge info sync already in progress")
            return
        }
        
        await MainActor.run {
            bridgeInfoSyncInProgress = true
        }
        
        SecurityLogger.sync("Starting bridge info synchronization...")
        SecurityLogger.sync("Have \(events.count) events, \(bridgeInfo.count) bridge info records")
        
        await MainActor.run {
            createBridgeInfoFromEvents()
            
            // CRITICAL: Force save and wait for completion
            do {
                try modelContext.save()
                SecurityLogger.sync("✅ Bridge info saved to SwiftData")
                
                // Give SwiftData time to update @Query
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    bridgeInfoSyncInProgress = false
                    SecurityLogger.sync("✅ Bridge info sync completed - Final count: \(bridgeInfo.count)")
                }
            } catch {
                SecurityLogger.error("Failed to save bridge info", error: error)
                bridgeInfoSyncInProgress = false
            }
        }
    }
    
    // Initial data loading function
    private func loadInitialDataIfNeeded() async {
        SecurityLogger.main("Data check - Events: \(allEvents.count), Recent: \(recentEvents.count), Bridge Info: \(bridgeInfo.count), Already loaded: \(initialDataLoaded)")
        
        guard events.isEmpty else { 
            SecurityLogger.main("Skipping data load - already have \(events.count) events")
            
            // IMPROVED: Use dedicated sync function
            await ensureBridgeInfoSynchronized()
            return 
        }
        
        await loadNewData()
    }
    
    private func loadNewData() async {
        SecurityLogger.main("Starting data load...")
        
        await MainActor.run {
            isLoadingInitialData = true
            dataFetchError = nil
            initialDataLoaded = false
        }
        
        do {
            SecurityLogger.main("Calling DrawbridgeAPI.fetchDrawbridgeData...");

            // Use the reusable clearing function
            clearAllDrawbridgeEvents()
            
            // Using modular DrawbridgeAPI from BridgetNetworking - get ALL available data
            let fetchedEventDTOs = try await DrawbridgeAPI.fetchDrawbridgeData()
            
            SecurityLogger.main("🎯 API RETURNED \(fetchedEventDTOs.count) EVENTS")
            SecurityLogger.main("📊 EXPECTED: ~4,987 events from Seattle API")
            SecurityLogger.main("📊 ACTUAL: \(fetchedEventDTOs.count) events received")
            
            if fetchedEventDTOs.count < 4000 {
                SecurityLogger.error("⚠️ DATA INTEGRITY ISSUE: Received only \(fetchedEventDTOs.count) events, expected ~4,987")
            }
            
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
                SecurityLogger.main("✅ Events saved to SwiftData")
            } catch {
                SecurityLogger.error("Failed to save events", error: error)
                await MainActor.run {
                    dataFetchError = error.localizedDescription
                    isLoadingInitialData = false
                    initialDataLoaded = false
                }
                return
            }
            
            // Log per-bridge event counts
            let bridgeGroups = Dictionary(grouping: events, by: \.entityName)
            SecurityLogger.main("📈 BRIDGE BREAKDOWN:")
            for (bridgeName, bridgeEvents) in bridgeGroups.sorted(by: { $0.value.count > $1.value.count }) {
                SecurityLogger.main("    • \(bridgeName): \(bridgeEvents.count) events")
            }
            
            await MainActor.run {
                initialDataLoaded = true
                isLoadingInitialData = false
            }
            
            SecurityLogger.main("✅ DATA LOAD COMPLETE")
            SecurityLogger.main("🎯 FINAL STATS: \(events.count) total events across \(bridgeGroups.count) bridges")
            
            // IMPROVED: Bridge info creation happens after events are saved
            await ensureBridgeInfoSynchronized()
            
        } catch {
            SecurityLogger.error("Data load failed", error: error)
            
            // FIXED: Track failed API calls too
            await MainActor.run {
                incrementApiCallCount()
                dataFetchError = error.localizedDescription
                isLoadingInitialData = false
                initialDataLoaded = false
            }
        }
    }
    
    // OPTIMIZED: Batch deletion for better performance
    private func clearAllDrawbridgeEvents() {
        Task { @MainActor in
            do {
                let fetchRequest = FetchDescriptor<DrawbridgeEvent>()
                let oldEvents = try modelContext.fetch(fetchRequest)
                
                // OPTIMIZATION: Batch deletion using forEach for better performance
                oldEvents.forEach { modelContext.delete($0) }
                try modelContext.save()
                
                SecurityLogger.main("🧹 Cleared \(oldEvents.count) old events from SwiftData (batch operation)")
            } catch {
                SecurityLogger.error("Failed to clear old events", error: error)
            }
        }
    }
    
    // SIMPLIFIED: Bridge info creation function (must run on MainActor)
    @MainActor
    private func createBridgeInfoFromEvents() {
        SecurityLogger.bridge("Starting bridge info creation...")
        
        let uniqueBridges = DrawbridgeEvent.getUniqueBridges(events)
        SecurityLogger.bridge("Found \(uniqueBridges.count) unique bridges from \(events.count) events")
        
        var createdCount = 0
        
        for bridgeData in uniqueBridges {
            // Check if bridge info already exists (prevent duplicates)
            let existingInfo = bridgeInfo.first { $0.entityID == bridgeData.entityID }
            
            if existingInfo == nil {
                SecurityLogger.bridge("Creating new info for \(bridgeData.entityName) (ID: \(bridgeData.entityID))")
                
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
                
                SecurityLogger.bridge("✅ Created \(bridgeData.entityName): \(allBridgeEvents.count) events, avg \(String(format: "%.1f", newBridgeInfo.averageOpenTimeMinutes))min")
            } else {
                SecurityLogger.bridge("Bridge info already exists for \(bridgeData.entityName)")
            }
        }
        
        SecurityLogger.bridge("✅ Bridge info creation complete - Created: \(createdCount) new records")
    }
    
    // IMPROVED: Force refresh with proper synchronization and API tracking
    public func forceDataRefresh() async {
        SecurityLogger.main("🔄 Force refresh initiated")
        
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