//
//  DebugView.swift
//  BridgetSettings
//
//  Created by Peter Jemley on 6/19/25.
//

import SwiftUI
import SwiftData
import BridgetCore
import BridgetNetworking

public struct DebugView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var events: [DrawbridgeEvent]
    @Query private var bridgeInfo: [DrawbridgeInfo]
    
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var lastRefresh: Date?
    @State private var apiCallCount = 0
    
    public init() {}
    
    public var body: some View {
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
                            Text("Last API Fetch")
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
                        Text("\(uniqueBridgeCount)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Bridge Info Records")
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
    
    private var uniqueBridgeCount: Int {
        Set(events.map(\.entityName)).count
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