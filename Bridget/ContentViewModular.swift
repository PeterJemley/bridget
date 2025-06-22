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

struct ContentViewModular: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var events: [DrawbridgeEvent]
    @Query private var bridgeInfo: [DrawbridgeInfo]
    
    // Loading state for automatic data fetching
    @State private var isLoadingInitialData = false
    @State private var initialDataLoaded = false
    @State private var dataFetchError: String?
    
    var body: some View {
        ZStack {
            TabView {
                // Dashboard Tab - Using modular DashboardView
                DashboardView(events: events, bridgeInfo: bridgeInfo)
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Dashboard")
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
            print("🏠 [MAIN] ContentView appeared - Events: \(events.count), Bridge Info: \(bridgeInfo.count)")
            
            // If we have events but no bridge info, create it
            if !events.isEmpty && bridgeInfo.isEmpty {
                print("🏠 [MAIN] Events exist but no bridge info - updating...")
                updateBridgeInfo(from: events)
                do {
                    try modelContext.save()
                    print("🏠 [MAIN] ✅ Bridge info created and saved")
                } catch {
                    print("❌ [MAIN ERROR] Failed to save bridge info: \(error)")
                }
            }
        }
    }
    
    // Initial data loading function
    private func loadInitialDataIfNeeded() async {
        // Only fetch if we have no data and haven't already tried
        guard events.isEmpty && !initialDataLoaded else { 
            print("🏠 [MAIN] Skipping data load - Events: \(events.count), Already loaded: \(initialDataLoaded)")
            return 
        }
        
        print("🏠 [MAIN] Starting initial data load...")
        
        await MainActor.run {
            isLoadingInitialData = true
            dataFetchError = nil
        }
        
        do {
            print("🏠 [MAIN] Calling DrawbridgeAPI.fetchDrawbridgeData with NO LIMIT...")
            
            // Using modular DrawbridgeAPI from BridgetNetworking - get all available data
            let fetchedEvents = try await DrawbridgeAPI.fetchDrawbridgeData(limit: 10000)
            
            print("🏠 [MAIN] 🎯 API RETURNED \(fetchedEvents.count) EVENTS")
            print("🏠 [MAIN] 📊 EXPECTED vs ACTUAL:")
            print("🏠 [MAIN]    • Expected (based on CSV): ~4,000+ events")
            print("🏠 [MAIN]    • Actual received: \(fetchedEvents.count) events")
            print("🏠 [MAIN]    • Data completeness: \(fetchedEvents.count >= 3000 ? "✅ GOOD" : "⚠️ MAY BE INCOMPLETE")")
            
            await MainActor.run {
                print("🏠 [MAIN] Storing \(fetchedEvents.count) events in SwiftData...")
                
                // Store events
                var insertedCount = 0
                for event in fetchedEvents {
                    modelContext.insert(event)
                    insertedCount += 1
                }
                
                print("🏠 [MAIN] ✅ Inserted \(insertedCount) events into SwiftData")
                print("🏠 [MAIN] 📈 BRIDGE BREAKDOWN:")
                
                // Log per-bridge event counts
                let bridgeGroups = Dictionary(grouping: fetchedEvents, by: \.entityName)
                for (bridgeName, bridgeEvents) in bridgeGroups.sorted(by: { $0.value.count > $1.value.count }) {
                    print("🏠 [MAIN]    • \(bridgeName): \(bridgeEvents.count) events")
                }
                
                // Update bridge info
                print("🏠 [MAIN] Updating bridge info...")
                updateBridgeInfo(from: fetchedEvents)
                
                do {
                    try modelContext.save()
                    print("🏠 [MAIN] ✅ SwiftData context saved successfully")
                } catch {
                    print("❌ [MAIN ERROR] Failed to save SwiftData context: \(error)")
                }
                
                initialDataLoaded = true
                isLoadingInitialData = false
                
                print("🏠 [MAIN] ✅ INITIAL DATA LOAD COMPLETE")
                print("🏠 [MAIN] 🎯 FINAL STATS: \(fetchedEvents.count) total events across \(bridgeGroups.count) bridges")
            }
        } catch {
            print("❌ [MAIN ERROR] Initial data load failed: \(error)")
            await MainActor.run {
                dataFetchError = error.localizedDescription
                isLoadingInitialData = false
                initialDataLoaded = true // Don't keep trying
            }
        }
    }
    
    // Bridge info update function
    private func updateBridgeInfo(from events: [DrawbridgeEvent]) {
        print("🏗️ [BRIDGE INFO] Starting bridge info update...")
        
        let uniqueBridges = DrawbridgeEvent.getUniqueBridges(events)
        print("🏗️ [BRIDGE INFO] Found \(uniqueBridges.count) unique bridges")
        
        var updatedCount = 0
        var createdCount = 0
        
        for bridgeData in uniqueBridges {
            // Get all events for this specific bridge
            let allBridgeEvents = events.filter { $0.entityID == bridgeData.entityID }
            print("🏗️ [BRIDGE INFO] \(bridgeData.entityName) (ID: \(bridgeData.entityID)): \(allBridgeEvents.count) events")
            
            // Check if bridge info already exists
            let existingInfo = bridgeInfo.first { $0.entityID == bridgeData.entityID }
            
            if let existing = existingInfo {
                print("🏗️ [BRIDGE INFO] Updating existing info for \(bridgeData.entityName)")
                // Update existing info
                existing.totalOpenings = allBridgeEvents.count
                existing.averageOpenTimeMinutes = allBridgeEvents.map(\.minutesOpen).reduce(0, +) / Double(allBridgeEvents.count)
                existing.longestOpenTimeMinutes = allBridgeEvents.map(\.minutesOpen).max() ?? 0
                existing.lastUpdated = Date()
                updatedCount += 1
            } else {
                print("🏗️ [BRIDGE INFO] Creating new info for \(bridgeData.entityName)")
                // Create new bridge info
                let newBridgeInfo = DrawbridgeInfo(
                    entityID: bridgeData.entityID,
                    entityName: bridgeData.entityName,
                    entityType: bridgeData.entityType,
                    latitude: bridgeData.latitude,
                    longitude: bridgeData.longitude
                )
                newBridgeInfo.totalOpenings = allBridgeEvents.count
                newBridgeInfo.averageOpenTimeMinutes = allBridgeEvents.map(\.minutesOpen).reduce(0, +) / Double(allBridgeEvents.count)
                newBridgeInfo.longestOpenTimeMinutes = allBridgeEvents.map(\.minutesOpen).max() ?? 0
                
                modelContext.insert(newBridgeInfo)
                createdCount += 1
            }
        }
        
        print("🏗️ [BRIDGE INFO] ✅ Bridge info update complete - Created: \(createdCount), Updated: \(updatedCount)")
    }
}

// MARK: - Preview
struct ContentViewModular_Previews: PreviewProvider {
    static var previews: some View {
        ContentViewModular()
            .modelContainer(for: [DrawbridgeEvent.self, DrawbridgeInfo.self], inMemory: true)
    }
}
