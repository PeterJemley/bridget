//
//  DebugView.swift
//  Bridget
//
//  Created by Peter Jemley on 6/18/25.
//

import SwiftUI
import SwiftData

struct DebugView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var events: [DrawbridgeEvent]
    @Query private var bridgeInfo: [DrawbridgeInfo]
    
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var lastRefresh: Date?
    @State private var apiCallCount = 0
    
    var body: some View {
        NavigationView {
            List {
                Section("API Status") {
                    HStack {
                        Text("Connection Status")
                        Spacer()
                        Circle()
                            .fill(connectionStatusColor)
                            .frame(width: 12, height: 12)
                        Text(connectionStatusText)
                            .foregroundColor(.secondary)
                    }
                    
                    if let lastRefresh = lastRefresh {
                        HStack {
                            Text("Last Refresh")
                            Spacer()
                            Text(lastRefresh.formatted(.dateTime))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Text("API Calls Made")
                        Spacer()
                        Text("\(apiCallCount)")
                            .foregroundColor(.secondary)
                    }
                    
                    if let errorMessage = errorMessage {
                        Text("Error: \(errorMessage)")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Section("Data Store Statistics") {
                    HStack {
                        Text("Total Events")
                        Spacer()
                        Text("\(events.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Unique Bridges")
                        Spacer()
                        Text("\(bridgeInfo.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    if !events.isEmpty {
                        HStack {
                            Text("Currently Open")
                            Spacer()
                            Text("\(currentlyOpenCount)")
                                .foregroundColor(currentlyOpenCount > 0 ? .orange : .green)
                        }
                        
                        HStack {
                            Text("Today's Events")
                            Spacer()
                            Text("\(todaysEvents.count)")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Date Range")
                            Spacer()
                            VStack(alignment: .trailing) {
                                if let oldest = events.map(\.openDateTime).min() {
                                    Text("From: \(oldest.formatted(.dateTime.day().month().year()))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                if let newest = events.map(\.openDateTime).max() {
                                    Text("To: \(newest.formatted(.dateTime.day().month().year()))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                
                Section("Raw Data Preview") {
                    if events.isEmpty {
                        Text("No events in store")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(events.prefix(5)) { event in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(event.entityName)
                                        .font(.headline)
                                    Spacer()
                                    Text(event.isCurrentlyOpen ? "OPEN" : "CLOSED")
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(event.isCurrentlyOpen ? Color.orange : Color.green)
                                        .foregroundColor(.white)
                                        .cornerRadius(4)
                                }
                                
                                Text("Opened: \(event.openDateTime.formatted(.dateTime))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                if let closeDateTime = event.closeDateTime {
                                    Text("Closed: \(closeDateTime.formatted(.dateTime))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Text("Duration: \(event.minutesOpen, specifier: "%.1f") minutes")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text("Location: \(event.latitude, specifier: "%.6f"), \(event.longitude, specifier: "%.6f")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                        
                        if events.count > 5 {
                            Text("... and \(events.count - 5) more events")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .italic()
                        }
                    }
                }
                
                Section("Actions") {
                    Button(action: fetchData) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Fetch Latest Data")
                        }
                    }
                    .disabled(isLoading)
                    
                    Button(action: clearData) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Clear All Data")
                        }
                    }
                    .foregroundColor(.red)
                    .disabled(events.isEmpty && bridgeInfo.isEmpty)
                }
            }
            .navigationTitle("Debug Console")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }
        }
        .task {
            if events.isEmpty {
                await fetchData()
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var connectionStatusColor: Color {
        if isLoading { return .orange }
        if errorMessage != nil { return .red }
        if !events.isEmpty { return .green }
        return .gray
    }
    
    private var connectionStatusText: String {
        if isLoading { return "Loading..." }
        if errorMessage != nil { return "Error" }
        if !events.isEmpty { return "Connected" }
        return "Unknown"
    }
    
    private var currentlyOpenCount: Int {
        events.filter(\.isCurrentlyOpen).count
    }
    
    private var todaysEvents: [DrawbridgeEvent] {
        DrawbridgeEvent.eventsToday(events)
    }
    
    // MARK: - Actions
    
    private func fetchData() {
        Task {
            await MainActor.run {
                isLoading = true
                errorMessage = nil
            }
            
            do {
                let fetchedEvents = try await DrawbridgeAPI.fetchDrawbridgeData(limit: 100)
                
                await MainActor.run {
                    // Store events
                    for event in fetchedEvents {
                        modelContext.insert(event)
                    }
                    
                    // Update bridge info
                    updateBridgeInfo(from: fetchedEvents)
                    
                    try? modelContext.save()
                    
                    lastRefresh = Date()
                    apiCallCount += 1
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
    
    private func updateBridgeInfo(from events: [DrawbridgeEvent]) {
        let groupedEvents = DrawbridgeEvent.groupedByBridge(events)
        
        for (bridgeName, bridgeEvents) in groupedEvents {
            guard let firstEvent = bridgeEvents.first else { continue }
            
            // Check if bridge info already exists
            let existingInfo = bridgeInfo.first { $0.entityID == firstEvent.entityID }
            
            if let existing = existingInfo {
                // Update existing info
                existing.totalOpenings = bridgeEvents.count
                existing.averageOpenTimeMinutes = bridgeEvents.map(\.minutesOpen).reduce(0, +) / Double(bridgeEvents.count)
                existing.longestOpenTimeMinutes = bridgeEvents.map(\.minutesOpen).max() ?? 0
                existing.lastUpdated = Date()
            } else {
                // Create new bridge info
                let newBridgeInfo = DrawbridgeInfo(
                    entityID: firstEvent.entityID,
                    entityName: firstEvent.entityName,
                    entityType: firstEvent.entityType,
                    latitude: firstEvent.latitude,
                    longitude: firstEvent.longitude
                )
                newBridgeInfo.totalOpenings = bridgeEvents.count
                newBridgeInfo.averageOpenTimeMinutes = bridgeEvents.map(\.minutesOpen).reduce(0, +) / Double(bridgeEvents.count)
                newBridgeInfo.longestOpenTimeMinutes = bridgeEvents.map(\.minutesOpen).max() ?? 0
                
                modelContext.insert(newBridgeInfo)
            }
        }
    }
    
    private func clearData() {
        for event in events {
            modelContext.delete(event)
        }
        for info in bridgeInfo {
            modelContext.delete(info)
        }
        
        try? modelContext.save()
        lastRefresh = nil
        apiCallCount = 0
        errorMessage = nil
    }
}

#Preview {
    DebugView()
        .modelContainer(for: [DrawbridgeEvent.self, DrawbridgeInfo.self], inMemory: true)
}