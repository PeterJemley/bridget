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
    @State private var sessionApiCalls = 0
    @State private var totalApiCalls = 0
    
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
                    
                    // FIXED: Show session API calls (resets on app launch)
                    HStack {
                        Text("API Calls Made")
                        Spacer()
                        Text("\(sessionApiCalls)")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Total API Calls")
                        Spacer()
                        Text("\(totalApiCalls)")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Data Source")
                        Spacer()
                        Text("Seattle Open Data API")
                            .foregroundColor(.green)
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
            .onAppear {
                loadApiCallCounts()
            }
            .onChange(of: events.count) { oldValue, newValue in
                loadApiCallCounts()
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
                    
                    // FIXED: Use shared API tracking system
                    lastRefresh = Date()
                    incrementApiCallCount()
                    loadApiCallCounts() // Refresh displayed counts
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                    incrementApiCallCount() // Track failed calls too
                    loadApiCallCounts() // Refresh displayed counts
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
        sessionApiCalls = 0
        errorMessage = nil

        UserDefaults.standard.set(0, forKey: "BridgetSessionAPICallCount")
        loadApiCallCounts()
    }
    
    // FIXED: Use shared UserDefaults keys matching ContentViewModular
    private func loadApiCallCounts() {
        sessionApiCalls = UserDefaults.standard.integer(forKey: "BridgetSessionAPICallCount")
        totalApiCalls = UserDefaults.standard.integer(forKey: "BridgetAPICallCount")
        print("🌐 [DEBUG] Loaded API call counts: Session = \(sessionApiCalls), Total = \(totalApiCalls)")
    }

    private func incrementApiCallCount() {
        let newSessionCount = UserDefaults.standard.integer(forKey: "BridgetSessionAPICallCount") + 1
        let newTotalCount = UserDefaults.standard.integer(forKey: "BridgetAPICallCount") + 1
        
        UserDefaults.standard.set(newSessionCount, forKey: "BridgetSessionAPICallCount")
        UserDefaults.standard.set(newTotalCount, forKey: "BridgetAPICallCount")
        
        print("🌐 [DEBUG] API call count incremented: Session = \(newSessionCount), Total = \(newTotalCount)")
    }
}

#Preview {
    DebugView()
        .modelContainer(for: [DrawbridgeEvent.self, DrawbridgeInfo.self], inMemory: true)
}
