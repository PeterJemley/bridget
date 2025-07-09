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
import MapKit
import BridgetDashboard

public struct DebugView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var events: [DrawbridgeEvent]
    @Query private var bridgeInfo: [DrawbridgeInfo]
    
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var lastRefresh: Date?
    @State private var sessionApiCalls = 0
    @State private var totalApiCalls = 0
    @State private var motionService = MotionDetectionService()
    @State private var showingMotionSummary = false
    @State private var motionSummaryText = ""
    
    @AppStorage("showMotionDebug") private var showMotionDebug = false
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 16) {
            DebugDashboardSection(motionService: MotionDetectionService.shared, backgroundAgent: BackgroundTrafficAgent(trafficService: TrafficAwareRoutingService(), motionService: MotionDetectionService.shared))
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
                        
                        // TODO: Remove before App Store submission - Traffic Routing Example
                        Button(action: runTrafficRoutingExample) {
                            HStack {
                                Image(systemName: "car.fill")
                                Text("Run UW → Space Needle Route Example")
                            }
                        }
                        .foregroundColor(.blue)
                    }
                    
                    Section("Motion Data") {
                        HStack {
                            Text("Logged Entries")
                            Spacer()
                            Text("\(motionService.loggedEntriesCount)")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Polling Rate")
                            Spacer()
                            Text("\(String(format: "%.1f", motionService.currentPollingRate)) Hz")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("High Detail Mode")
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { motionService.isHighDetailMode },
                                set: { motionService.setHighDetailMode($0) }
                            ))
                        }
                        
                        Button(action: exportMotionData) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Export Motion Data")
                            }
                        }
                        .disabled(motionService.loggedEntriesCount == 0)
                        
                        Button(action: clearMotionData) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Clear Motion Logs")
                            }
                        }
                        .foregroundColor(.red)
                        .disabled(motionService.loggedEntriesCount == 0)
                        
                        if motionService.loggedEntriesCount > 0 {
                            Button(action: showMotionSummary) {
                                HStack {
                                    Image(systemName: "chart.bar")
                                    Text("Show Motion Summary")
                                }
                            }
                            .foregroundColor(.blue)
                        }
                    }
                    
                    Section("Motion Configuration") {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Polling Interval")
                                .font(.headline)
                            
                            HStack {
                                Text("Current:")
                                Spacer()
                                Text("\(String(format: "%.2f", motionService.pollingInterval))s")
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack(spacing: 8) {
                                Button("1 Hz (1.0s) - Battery Efficient") {
                                    motionService.setPollingInterval(1.0)
                                }
                                .buttonStyle(.bordered)
                                .disabled(motionService.pollingInterval == 1.0)
                                
                                Button("5 Hz (0.2s) - Balanced") {
                                    motionService.setPollingInterval(0.2)
                                }
                                .buttonStyle(.bordered)
                                .disabled(motionService.pollingInterval == 0.2)
                                
                                Button("10 Hz (0.1s) - High Detail") {
                                    motionService.setPollingInterval(0.1)
                                }
                                .buttonStyle(.bordered)
                                .disabled(motionService.pollingInterval == 0.1)
                                
                                Button("20 Hz (0.05s) - Maximum") {
                                    motionService.setPollingInterval(0.05)
                                }
                                .buttonStyle(.bordered)
                                .disabled(motionService.pollingInterval == 0.05)
                            }
                            
                            Text("Higher rates use more battery and generate more data")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
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
                    MotionDetectionService.shared.showMotionDebug = showMotionDebug
                    if !MotionDetectionService.shared.isMonitoring {
                        MotionDetectionService.shared.startMonitoring()
                    }
                }
                .onChange(of: events.count) { oldValue, newValue in
                    loadApiCallCounts()
                }
                .sheet(isPresented: $showingMotionSummary) {
                    NavigationView {
                        ScrollView {
                            Text(motionSummaryText)
                                .font(.system(.body, design: .monospaced))
                                .padding()
                        }
                        .navigationTitle("Motion Summary")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    showingMotionSummary = false
                                }
                            }
                        }
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
                // Clear all existing DrawbridgeEvent records before inserting new ones
                let fetchRequest = FetchDescriptor<DrawbridgeEvent>()
                if let oldEvents = try? modelContext.fetch(fetchRequest) {
                    for event in oldEvents {
                        modelContext.delete(event)
                    }
                    try? modelContext.save()
                    SecurityLogger.main("🧹 Cleared \(oldEvents.count) old events from SwiftData (DebugView)")
                }
            }
            do {
                let fetchedEventDTOs = try await DrawbridgeAPI.fetchDrawbridgeData(limit: 100)
                
                await MainActor.run {
                    // Convert DTOs to model objects and store
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
        SecurityLogger.debug("Loaded API call counts: Session = \(sessionApiCalls), Total = \(totalApiCalls)")
    }

    private func incrementApiCallCount() {
        let newSessionCount = UserDefaults.standard.integer(forKey: "BridgetSessionAPICallCount") + 1
        let newTotalCount = UserDefaults.standard.integer(forKey: "BridgetAPICallCount") + 1
        
        UserDefaults.standard.set(newSessionCount, forKey: "BridgetSessionAPICallCount")
        UserDefaults.standard.set(newTotalCount, forKey: "BridgetAPICallCount")
        
        SecurityLogger.debug("API call count incremented: Session = \(newSessionCount), Total = \(newTotalCount)")
    }
    
    // TODO: Remove before App Store submission - Traffic Routing Example
    @MainActor
    private func runTrafficRoutingExample() {
        Task {
            SecurityLogger.debug("Starting UW → Space Needle Traffic Routing Example...")
            
            // Create example instance
            let example = TrafficRoutingExample()
            
            do {
                // Run the example
                await example.planUWToSpaceNeedleRoute()
                SecurityLogger.debug("Traffic routing example completed successfully!")
            } catch {
                SecurityLogger.error("Traffic routing example failed", error: error)
            }
        }
    }
    
    // MARK: - Motion Data Actions
    
    private func exportMotionData() {
        if let fileURL = motionService.exportMotionData() {
            SecurityLogger.debug("Motion data exported successfully")
            
            // Show success message
            errorMessage = "Motion data exported successfully to Documents folder"
        } else {
            SecurityLogger.error("Failed to export motion data")
            errorMessage = "Failed to export motion data"
        }
    }
    
    private func clearMotionData() {
        motionService.clearMotionLogs()
        SecurityLogger.debug("Motion logs cleared")
        errorMessage = "Motion logs cleared"
    }
    
    private func showMotionSummary() {
        motionSummaryText = motionService.getMotionLogSummary()
        showingMotionSummary = true
    }
}

#Preview {
    DebugView()
        .modelContainer(for: [DrawbridgeEvent.self, DrawbridgeInfo.self], inMemory: true)
}
