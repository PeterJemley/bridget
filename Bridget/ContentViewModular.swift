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
                StatisticsView(events: events, bridgeInfo: bridgeInfo)
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
    }
    
    // Initial data loading function
    private func loadInitialDataIfNeeded() async {
        // Only fetch if we have no data and haven't already tried
        guard events.isEmpty && !initialDataLoaded else { return }
        
        await MainActor.run {
            isLoadingInitialData = true
            dataFetchError = nil
        }
        
        do {
            // Using modular DrawbridgeAPI from BridgetNetworking
            let fetchedEvents = try await DrawbridgeAPI.fetchDrawbridgeData(limit: 500)
            
            await MainActor.run {
                // Store events
                for event in fetchedEvents {
                    modelContext.insert(event)
                }
                
                // Update bridge info
                updateBridgeInfo(from: fetchedEvents)
                
                try? modelContext.save()
                
                initialDataLoaded = true
                isLoadingInitialData = false
            }
        } catch {
            await MainActor.run {
                dataFetchError = error.localizedDescription
                isLoadingInitialData = false
                initialDataLoaded = true // Don't keep trying
            }
        }
    }
    
    // Bridge info update function
    private func updateBridgeInfo(from events: [DrawbridgeEvent]) {
        let uniqueBridges = DrawbridgeEvent.getUniqueBridges(events)
        
        for bridgeData in uniqueBridges {
            // Get all events for this specific bridge
            let allBridgeEvents = events.filter { $0.entityID == bridgeData.entityID }
            
            // Check if bridge info already exists
            let existingInfo = bridgeInfo.first { $0.entityID == bridgeData.entityID }
            
            if let existing = existingInfo {
                // Update existing info
                existing.totalOpenings = allBridgeEvents.count
                existing.averageOpenTimeMinutes = allBridgeEvents.map(\.minutesOpen).reduce(0, +) / Double(allBridgeEvents.count)
                existing.longestOpenTimeMinutes = allBridgeEvents.map(\.minutesOpen).max() ?? 0
                existing.lastUpdated = Date()
            } else {
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
            }
        }
    }
}

// MARK: - Preview
struct ContentViewModular_Previews: PreviewProvider {
    static var previews: some View {
        ContentViewModular()
            .modelContainer(for: [DrawbridgeEvent.self, DrawbridgeInfo.self], inMemory: true)
    }
}
