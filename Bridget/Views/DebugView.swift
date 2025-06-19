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
    
    @State private var isBulkImporting = false
    @State private var importProgress: DrawbridgeAPI.ImportProgress?
    @State private var totalRecordsAvailable: Int?
    @State private var showBulkImportConfirmation = false
    
    @State private var lastDataStoreUpdate: Date?
    
    @State private var searchQuery = ""
    @State private var searchResults: [DrawbridgeEvent] = []
    @State private var showDuplicateAnalysis = false
    @State private var duplicateAnalysis: [String] = []

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
                            Text("Last API Fetch")
                            Spacer()
                            Text(lastRefresh.formatted(.dateTime))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if let lastDataStoreUpdate = lastDataStoreUpdate {
                        HStack {
                            Text("Data Store Updated")
                            Spacer()
                            Text(lastDataStoreUpdate.formatted(.dateTime))
                                .foregroundColor(.green)
                        }
                    }
                    
                    HStack {
                        Text("API Calls Made")
                        Spacer()
                        Text("\(apiCallCount)")
                            .foregroundColor(.secondary)
                    }
                    
                    if let totalRecordsAvailable = totalRecordsAvailable {
                        HStack {
                            Text("Records Available")
                            Spacer()
                            Text("\(totalRecordsAvailable)")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    if let errorMessage = errorMessage {
                        Text("Error: \(errorMessage)")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Section("SwiftData Search") {
                    HStack {
                        TextField("Search bridge name...", text: $searchQuery)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Button("Search") {
                            performSearch()
                        }
                        .disabled(searchQuery.isEmpty)
                    }
                    
                    if !searchResults.isEmpty {
                        Text("Found \(searchResults.count) events for '\(searchQuery)'")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        ForEach(searchResults.prefix(3)) { event in
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(event.entityName)
                                        .font(.headline)
                                    Spacer()
                                    Text(event.isCurrentlyOpen ? "OPEN" : "CLOSED")
                                        .font(.caption)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 1)
                                        .background(event.isCurrentlyOpen ? Color.orange : Color.green)
                                        .foregroundColor(.white)
                                        .cornerRadius(3)
                                }
                                Text("Entity ID: \(event.entityID) | \(event.openDateTime.formatted(.dateTime))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("Duration: \(event.minutesOpen, specifier: "%.1f") min | Lat: \(event.latitude, specifier: "%.4f")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                        
                        if searchResults.count > 3 {
                            Text("... and \(searchResults.count - 3) more results")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button("Analyze Duplicates") {
                        analyzeDuplicates()
                    }
                    .foregroundColor(.orange)
                }
                
                if showDuplicateAnalysis {
                    Section("Duplicate Analysis") {
                        if duplicateAnalysis.isEmpty {
                            Text("✅ No exact duplicates found")
                                .foregroundColor(.green)
                        } else {
                            ForEach(duplicateAnalysis, id: \.self) { analysis in
                                Text(analysis)
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }

                if isBulkImporting || importProgress != nil {
                    Section("Bulk Import Progress") {
                        if let progress = importProgress {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Progress")
                                    Spacer()
                                    Text("\(Int(progress.progressPercentage * 100))%")
                                        .foregroundColor(.blue)
                                }
                                
                                ProgressView(value: progress.progressPercentage)
                                    .progressViewStyle(LinearProgressViewStyle())
                                
                                HStack {
                                    Text("Batch \(progress.currentBatch) of \(progress.totalBatches)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("\(progress.recordsImported) / \(progress.totalRecords)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                if progress.isComplete {
                                    Text("✅ Import Complete!")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                            }
                        } else if isBulkImporting {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Preparing bulk import...")
                                    .foregroundColor(.secondary)
                            }
                        }
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
                        Text("\(actualUniqueBridgeCount)")
                            .foregroundColor(.secondary)
                    }
                    
                    if bridgeInfo.count != actualUniqueBridgeCount {
                        HStack {
                            Text("Bridge Info Records")
                            Spacer()
                            Text("\(bridgeInfo.count)")
                                .foregroundColor(.orange)
                        }
                        
                        Text("⚠️ Bridge info count mismatch - needs refresh")
                            .font(.caption)
                            .foregroundColor(.orange)
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
                        
                        if let totalRecordsAvailable = totalRecordsAvailable {
                            HStack {
                                Text("Data Completeness")
                                Spacer()
                                let percentage = Double(events.count) / Double(totalRecordsAvailable) * 100
                                Text("\(Int(percentage))%")
                                    .foregroundColor(percentage > 80 ? .green : percentage > 50 ? .orange : .red)
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
                        ForEach(events.sorted(by: { $0.openDateTime > $1.openDateTime }).prefix(10)) { event in
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
                                
                                Text("Duration: \(event.minutesOpen, specifier: "%.0f") minutes")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text("Entity ID: \(event.entityID) | Location: \(event.latitude, specifier: "%.6f"), \(event.longitude, specifier: "%.6f")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                        
                        if events.count > 10 {
                            Text("... and \(events.count - 10) more events")
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
                    .disabled(isLoading || isBulkImporting)
                    
                    Button(action: getTotalRecords) {
                        HStack {
                            Image(systemName: "number.circle")
                            Text("Check Total Records")
                        }
                    }
                    .disabled(isLoading || isBulkImporting)
                    
                    Button(action: { showBulkImportConfirmation = true }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("Import All Historical Data")
                        }
                    }
                    .disabled(isLoading || isBulkImporting)
                    .foregroundColor(.blue)
                    
                    Button(action: clearData) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Clear All Data")
                        }
                    }
                    .foregroundColor(.red)
                    .disabled(events.isEmpty && bridgeInfo.isEmpty || isBulkImporting)
                }
            }
            .navigationTitle("Debug Console")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isLoading || isBulkImporting {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }
            .alert("Import All Historical Data", isPresented: $showBulkImportConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Import", role: .destructive) {
                    Task { await bulkImportAllData() }
                }
            } message: {
                if let totalRecordsAvailable = totalRecordsAvailable {
                    Text("This will import approximately \(totalRecordsAvailable) historical bridge events. This may take several minutes and will use significant storage space.")
                } else {
                    Text("This will import all available historical bridge events. This may take several minutes and will use significant storage space.")
                }
            }
        }
        .task {
            if events.isEmpty {
                await fetchData()
            }
            if totalRecordsAvailable == nil {
                await getTotalRecords()
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var connectionStatusColor: Color {
        if isLoading || isBulkImporting { return .orange }
        if errorMessage != nil { return .red }
        if !events.isEmpty { return .green }
        return .gray
    }
    
    private var connectionStatusText: String {
        if isBulkImporting { return "Importing..." }
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
    
    private var actualUniqueBridgeCount: Int {
        Set(events.map(\.entityName)).count
    }
    
    private func performSearch() {
        let query = searchQuery.lowercased()
        searchResults = events.filter { event in
            event.entityName.lowercased().contains(query)
        }.sorted { $0.openDateTime > $1.openDateTime }
    }
    
    private func analyzeDuplicates() {
        var duplicateGroups: [String: [DrawbridgeEvent]] = [:]
        var analysis: [String] = []
        
        // Group events by potential duplicate key (entityID + openDateTime + duration)
        for event in events {
            let key = "\(event.entityID)_\(event.openDateTime.timeIntervalSince1970)_\(event.minutesOpen)"
            if duplicateGroups[key] == nil {
                duplicateGroups[key] = []
            }
            duplicateGroups[key]?.append(event)
        }
        
        // Find groups with more than one event (potential duplicates)
        let duplicates = duplicateGroups.filter { $1.count > 1 }
        
        if duplicates.isEmpty {
            analysis.append("✅ No exact duplicates found")
        } else {
            analysis.append("⚠️ Found \(duplicates.count) potential duplicate groups:")
            
            for (key, events) in duplicates.prefix(5) {
                let event = events.first!
                analysis.append("• \(event.entityName): \(events.count) identical events at \(event.openDateTime.formatted(.dateTime))")
            }
            
            if duplicates.count > 5 {
                analysis.append("... and \(duplicates.count - 5) more duplicate groups")
            }
        }
        
        duplicateAnalysis = analysis
        showDuplicateAnalysis = true
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
                    lastDataStoreUpdate = Date()
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
    
    private func getTotalRecords() {
        Task {
            do {
                let total = try await DrawbridgeAPI.getTotalRecordCount()
                await MainActor.run {
                    totalRecordsAvailable = total
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to get total record count: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func bulkImportAllData() {
        Task {
            await MainActor.run {
                isBulkImporting = true
                errorMessage = nil
                importProgress = nil
            }
            
            do {
                let allEvents = try await DrawbridgeAPI.importAllHistoricalData { progress in
                    Task { @MainActor in
                        self.importProgress = progress
                    }
                }
                
                await MainActor.run {
                    // Clear existing data first to avoid duplicates
                    for event in events {
                        modelContext.delete(event)
                    }
                    for info in bridgeInfo {
                        modelContext.delete(info)
                    }
                    
                    var uniqueEvents: [String: DrawbridgeEvent] = [:]
                    var duplicatesFound = 0
                    
                    for event in allEvents {
                        let key = "\(event.entityID)_\(event.openDateTime.timeIntervalSince1970)_\(event.minutesOpen)"
                        if uniqueEvents[key] == nil {
                            uniqueEvents[key] = event
                        } else {
                            duplicatesFound += 1
                        }
                    }
                    
                    // Insert only unique events
                    for (_, event) in uniqueEvents {
                        modelContext.insert(event)
                    }
                    
                    // Update bridge info
                    updateBridgeInfo(from: Array(uniqueEvents.values))
                    
                    try? modelContext.save()
                    
                    lastRefresh = Date()
                    lastDataStoreUpdate = Date()
                    apiCallCount += 1
                    isBulkImporting = false
                    
                    print("🎉 Successfully imported \(uniqueEvents.count) unique events, removed \(duplicatesFound) duplicates from API response")
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Bulk import failed: \(error.localizedDescription)"
                    isBulkImporting = false
                }
            }
        }
    }
    
    private func updateBridgeInfo(from events: [DrawbridgeEvent]) {
        let uniqueBridges = DrawbridgeEvent.getUniqueBridges(events)
        
        print("🔍 Found \(uniqueBridges.count) unique bridges:")
        for bridge in uniqueBridges {
            print("   - \(bridge.entityName) (ID: \(bridge.entityID))")
        }
        
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
                print("✅ Updated \(existing.entityName): \(existing.totalOpenings) events")
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
                print("➕ Created \(newBridgeInfo.entityName): \(newBridgeInfo.totalOpenings) events")
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
        importProgress = nil
        totalRecordsAvailable = nil
        lastDataStoreUpdate = Date()
    }
}

#Preview {
    DebugView()
        .modelContainer(for: [DrawbridgeEvent.self, DrawbridgeInfo.self], inMemory: true)
}