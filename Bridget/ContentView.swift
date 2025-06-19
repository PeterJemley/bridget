//
//  ContentView.swift
//  Bridget
//
//  Created by Peter Jemley on 6/18/25.
//

import SwiftUI
import SwiftData
import Charts

struct ContentView: View {
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
                // Dashboard Tab
                DashboardView(events: events, bridgeInfo: bridgeInfo)
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Dashboard")
                    }
                
                // Bridges Tab
                BridgesListView(events: events, bridgeInfo: bridgeInfo)
                    .tabItem {
                        Image(systemName: "road.lanes")
                        Text("Bridges")
                    }
                
                // History Tab
                HistoryView(events: events)
                    .tabItem {
                        Image(systemName: "clock.fill")
                        Text("History")
                    }
                
                // Statistics Tab
                StatisticsView(events: events, bridgeInfo: bridgeInfo)
                    .tabItem {
                        Image(systemName: "chart.bar.fill")
                        Text("Statistics")
                    }
                
                // Settings Tab (with Debug Console)
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
    
    // Bridge info update function (copied from DebugView)
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

// Loading overlay component
struct LoadingDataOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                
                VStack(spacing: 8) {
                    Text("Loading Bridge Data")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Accessing Seattle Open Data API")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Getting the latest bridge information...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(30)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 20)
        }
    }
}

// MARK: - Dashboard View
struct DashboardView: View {
    let events: [DrawbridgeEvent]
    let bridgeInfo: [DrawbridgeInfo]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Section
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "laurel.leading")
                                .font(.largeTitle)
                                .foregroundColor(.green)
                            
                            Text("Bridget")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Image(systemName: "laurel.trailing")
                                .font(.largeTitle)
                                .foregroundColor(.green)
                        }
                        
                        (Text("Ditch the spanxiety and bridge the gap between ") +
                         Text("you").italic() +
                         Text(" and ") +
                         Text("on time").italic())
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)
                    
                    // Data source information
                    if !events.isEmpty {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                            Text("Data provided by Seattle Open Data API")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    
                    // Status Overview Card
                    StatusOverviewCard(events: events, bridgeInfo: bridgeInfo)
                    
                    // Last Known Status Section
                    LastKnownStatusSection(events: lastKnownStatusPerBridge)
                    
                    // Recent Activity Section (Historical)
                    RecentActivitySection(events: recentEvents)
                    
                    Spacer(minLength: 100) // Bottom padding for tab bar
                }
                .padding(.horizontal)
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Computed Properties with Historical Data Binding
    private var lastKnownStatusPerBridge: [DrawbridgeEvent] {
        let groupedEvents = DrawbridgeEvent.groupedByBridge(events)
        return groupedEvents.compactMap { (_, bridgeEvents) in
            bridgeEvents.max(by: { $0.openDateTime < $1.openDateTime })
        }.sorted { $0.openDateTime > $1.openDateTime }
    }
    
    private var recentEvents: [DrawbridgeEvent] {
        events.sorted { $0.openDateTime > $1.openDateTime }.prefix(5).map { $0 }
    }
    
    private var todaysEvents: [DrawbridgeEvent] {
        DrawbridgeEvent.eventsToday(events)
    }
}

// MARK: - Status Overview Card Component
struct StatusOverviewCard: View {
    let events: [DrawbridgeEvent]
    let bridgeInfo: [DrawbridgeInfo]
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Historical Data Overview")
                    .font(.headline)
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatusCard(
                    title: "Bridges Monitored",
                    value: "\(uniqueBridgeCount)",
                    color: .blue
                )
                
                StatusCard(
                    title: "Today's Events",
                    value: "\(todaysEventsCount)",
                    color: .purple
                )
                
                StatusCard(
                    title: totalEventsTitle,
                    value: totalEventsValue,
                    color: .gray
                )
                
                StatusCard(
                    title: "Data Range",
                    value: dataRangeText,
                    color: .green
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Data Binding Computed Properties
    private var uniqueBridgeCount: Int {
        Set(events.map(\.entityName)).count
    }
    
    private var todaysEventsCount: Int {
        DrawbridgeEvent.eventsToday(events).count
    }
    
    private var totalEventsTitle: String {
        guard let oldest = events.map(\.openDateTime).min(),
              let newest = events.map(\.openDateTime).max() else {
            return "Total Events"
        }
        
        return "Total Events"
    }
    
    private var totalEventsValue: String {
        "\(events.count)"
    }
    
    private var dataRangeText: String {
        guard let oldest = events.map(\.openDateTime).min(),
              let newest = events.map(\.openDateTime).max() else {
            return "No data"
        }
        
        let daysDifference = Calendar.current.dateComponents([.day], from: oldest, to: newest).day ?? 0
        return "\(daysDifference) days"
    }
}

// MARK: - Status Card Component
struct StatusCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(minHeight: 60)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

// MARK: - Last Known Status Section
struct LastKnownStatusSection: View {
    let events: [DrawbridgeEvent]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Last Known Status")
                    .font(.headline)
                Spacer()
                Text("Historical Data")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            if events.isEmpty {
                Text("No bridge data available")
                    .foregroundColor(.secondary)
                    .italic()
                    .padding()
            } else {
                ForEach(events) { event in
                    NavigationLink(destination: BridgeDetailPlaceholderView(event: event)) {
                        BridgeHistoricalStatusRow(event: event)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Recent Activity Section
struct RecentActivitySection: View {
    let events: [DrawbridgeEvent]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Historical Activity")
                    .font(.headline)
                Spacer()
            }
            
            if events.isEmpty {
                Text("No recent activity")
                    .foregroundColor(.secondary)
                    .italic()
                    .padding()
            } else {
                ForEach(events) { event in
                    NavigationLink(destination: BridgeDetailPlaceholderView(event: event)) {
                        BridgeHistoricalStatusRow(event: event)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Bridge Historical Status Row Component
struct BridgeHistoricalStatusRow: View {
    let event: DrawbridgeEvent
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(event.entityName)
                    .font(.headline)
                
                HStack(spacing: 8) {
                    Text(lastKnownStatusText)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(statusColor)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                    
                    Text(timeAgoText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
    
    // MARK: - Historical Status Logic
    private var lastKnownStatusText: String {
        if event.closeDateTime != nil {
            return "CLOSED"
        } else {
            return "WAS OPEN"
        }
    }
    
    private var statusColor: Color {
        if event.closeDateTime != nil {
            return .green  // Bridge was closed (good for traffic)
        } else {
            return .orange // Bridge was open (may have affected traffic)
        }
    }
    
    private var timeAgoText: String {
        let relevantDate = event.closeDateTime ?? event.openDateTime
        return relevantDate.formatted(.relative(presentation: .named))
    }
}

// MARK: - Bridge Detail Placeholder View
struct BridgeDetailPlaceholderView: View {
    let event: DrawbridgeEvent
    
    var body: some View {
        BridgeDetailView(bridgeEvent: event)
    }
}

// MARK: - Bridge Detail View
struct BridgeDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allEvents: [DrawbridgeEvent]
    
    let bridgeEvent: DrawbridgeEvent
    @State private var selectedPeriod: TimePeriod = .sevenDays
    @State private var selectedAnalysis: AnalysisType = .patterns
    @State private var selectedView: ViewType = .activity
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Section with Bridge-specific Data
                BridgeHeaderSection(
                    bridgeName: bridgeEvent.entityName,
                    lastKnownEvent: lastKnownEvent,
                    totalEvents: bridgeSpecificEvents.count
                )
                
                // Time Period Filter Buttons (Functional)
                FunctionalTimeFilterSection(
                    selectedPeriod: $selectedPeriod,
                    bridgeEvents: bridgeSpecificEvents
                )
                
                // Analysis Type Filter Buttons (NOW FUNCTIONAL)
                AnalysisFilterSection(selectedAnalysis: $selectedAnalysis)
                
                // View Type Filter Buttons (NOW FUNCTIONAL)
                ViewFilterSection(selectedView: $selectedView)
                
                // Bridge Statistics Section (Updated to use selected filters)
                BridgeStatsSection(
                    events: filteredEvents,
                    timePeriod: selectedPeriod,
                    analysisType: selectedAnalysis
                )
                
                // Dynamic Content Section Based on Selected Analysis and View
                DynamicAnalysisSection(
                    events: filteredEvents,
                    analysisType: selectedAnalysis,
                    viewType: selectedView,
                    bridgeName: bridgeEvent.entityName
                )
                
                // Bridge Info Section
                BridgeInfoSection(event: bridgeEvent)
                
                Spacer(minLength: 100)
            }
            .padding()
        }
        .navigationTitle(bridgeEvent.entityName)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Phase 1 Data Filtering Logic
    private var bridgeSpecificEvents: [DrawbridgeEvent] {
        allEvents.filter { $0.entityID == bridgeEvent.entityID }
            .sorted { $0.openDateTime > $1.openDateTime }
    }
    
    private var filteredEvents: [DrawbridgeEvent] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -selectedPeriod.days, to: Date()) ?? Date()
        return bridgeSpecificEvents.filter { $0.openDateTime >= cutoffDate }
    }
    
    private var lastKnownEvent: DrawbridgeEvent? {
        bridgeSpecificEvents.first
    }
}

// MARK: - Dynamic Analysis Section
struct DynamicAnalysisSection: View {
    let events: [DrawbridgeEvent]
    let analysisType: AnalysisType
    let viewType: ViewType
    let bridgeName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(sectionTitle)
                    .font(.headline)
                Spacer()
                Text(analysisDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Content changes based on analysis and view type combination
            Group {
                switch (analysisType, viewType) {
                case (.patterns, .activity):
                    PatternsActivityView(events: events)
                case (.patterns, .weekly):
                    PatternsWeeklyView(events: events)
                case (.patterns, .duration):
                    PatternsDurationView(events: events)
                case (.cascade, .activity):
                    CascadeActivityView(events: events, bridgeName: bridgeName)
                case (.cascade, .weekly):
                    CascadeWeeklyView(events: events, bridgeName: bridgeName)
                case (.cascade, .duration):
                    CascadeDurationView(events: events, bridgeName: bridgeName)
                case (.predictions, .activity):
                    PredictionsActivityView(events: events, bridgeName: bridgeName)
                case (.predictions, .weekly):
                    PredictionsWeeklyView(events: events, bridgeName: bridgeName)
                case (.predictions, .duration):
                    PredictionsDurationView(events: events, bridgeName: bridgeName)
                case (.impact, .activity):
                    ImpactActivityView(events: events, bridgeName: bridgeName)
                case (.impact, .weekly):
                    ImpactWeeklyView(events: events, bridgeName: bridgeName)
                case (.impact, .duration):
                    ImpactDurationView(events: events, bridgeName: bridgeName)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var sectionTitle: String {
        switch analysisType {
        case .patterns: return "Pattern Analysis"
        case .cascade: return "Cascade Analysis"
        case .predictions: return "Predictive Analysis"
        case .impact: return "Traffic Impact Analysis"
        }
    }
    
    private var analysisDescription: String {
        switch (analysisType, viewType) {
        case (.patterns, .activity): return "Activity patterns over time"
        case (.patterns, .weekly): return "Weekly opening patterns"
        case (.patterns, .duration): return "Duration patterns analysis"
        case (.cascade, .activity): return "Bridge interaction timeline"
        case (.cascade, .weekly): return "Weekly cascade patterns"
        case (.cascade, .duration): return "Duration cascade effects"
        case (.predictions, .activity): return "Future activity predictions"
        case (.predictions, .weekly): return "Weekly prediction patterns"
        case (.predictions, .duration): return "Predicted durations"
        case (.impact, .activity): return "Traffic impact timeline"
        case (.impact, .weekly): return "Weekly traffic impact"
        case (.impact, .duration): return "Duration impact analysis"
        }
    }
}

// MARK: - Patterns Analysis Views
struct PatternsActivityView: View {
    let events: [DrawbridgeEvent]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hourly Activity Pattern")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            // Enhanced hourly distribution chart using SwiftUI Charts
            Chart {
                ForEach(hourlyChartData, id: \.hour) { data in
                    BarMark(
                        x: .value("Hour", data.hour),
                        y: .value("Count", data.count)
                    )
                    .foregroundStyle(Color.blue.opacity(0.7))
                    .cornerRadius(2)
                }
            }
            .frame(height: 100)
            .chartXAxis {
                AxisMarks(values: .stride(by: 6)) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            Text("\(intValue)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .chartYAxis(.hidden)
            
            Text("Most Active Hours")
                .font(.subheadline)
                .fontWeight(.semibold)
                .padding(.top)
            
            ForEach(Array(hourlyStats.prefix(3).enumerated()), id: \.offset) { index, stat in
                HStack {
                    Circle()
                        .fill(Color.blue.opacity(0.7))
                        .frame(width: 8, height: 8)
                    Text(String(format: "%02d:00 - %d openings", stat.hour, stat.count))
                        .font(.caption)
                    Spacer()
                    Text("\(stat.percentage, specifier: "%.1f")%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var hourlyChartData: [HourlyData] {
        var hourCounts: [Int: Int] = [:]
        let calendar = Calendar.current
        
        for event in events {
            let hour = calendar.component(.hour, from: event.openDateTime)
            hourCounts[hour, default: 0] += 1
        }
        
        return (0..<24).map { hour in
            HourlyData(hour: hour, count: hourCounts[hour] ?? 0)
        }
    }
    
    private var hourlyStats: [(hour: Int, count: Int, percentage: Double)] {
        let calendar = Calendar.current
        var hourCounts: [Int: Int] = [:]
        
        for event in events {
            let hour = calendar.component(.hour, from: event.openDateTime)
            hourCounts[hour, default: 0] += 1
        }
        
        let total = Double(events.count)
        return hourCounts
            .map { (hour: $0.key, count: $0.value, percentage: Double($0.value) / total * 100) }
            .sorted { $0.count > $1.count }
    }
}

struct PatternsWeeklyView: View {
    let events: [DrawbridgeEvent]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity Patterns")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text("When bridges open most frequently")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Weekly area chart using SwiftUI Charts
            Chart {
                ForEach(weeklyChartData, id: \.dayIndex) { data in
                    AreaMark(
                        x: .value("Day", data.dayName),
                        y: .value("Count", data.count)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.8), Color.blue.opacity(0.3)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
            }
            .frame(height: 180)
            .chartXAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let stringValue = value.as(String.self) {
                            Text(String(stringValue.prefix(3)))
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            Text("\(intValue)")
                                .font(.caption2)
                        }
                    }
                }
            }
        }
    }
    
    private var weeklyChartData: [WeeklyData] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        
        var dayCounts: [String: Int] = [:]
        
        for event in events {
            let dayName = formatter.string(from: event.openDateTime)
            dayCounts[dayName, default: 0] += 1
        }
        
        let daysOfWeek = ["Thursday", "Friday", "Saturday", "Sunday", "Monday", "Tuesday", "Wednesday"]
        
        return daysOfWeek.enumerated().map { index, day in
            WeeklyData(dayIndex: index, dayName: day, count: dayCounts[day] ?? 0)
        }
    }
}

struct PatternsDurationView: View {
    let events: [DrawbridgeEvent]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Duration Distribution")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            // Duration ranges
            ForEach(durationRanges, id: \.range) { stat in
                HStack {
                    Text(stat.range)
                        .font(.caption)
                        .frame(width: 80, alignment: .leading)
                    
                    ProgressView(value: stat.normalizedCount, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: .orange))
                    
                    Text("\(stat.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 30, alignment: .trailing)
                }
            }
            
            // Average duration
            if !events.isEmpty {
                let avgDuration = events.map(\.minutesOpen).reduce(0, +) / Double(events.count)
                Text("Average: \(avgDuration, specifier: "%.1f") minutes")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.top, 4)
            }
        }
    }
    
    private var durationRanges: [(range: String, count: Int, normalizedCount: Double)] {
        let ranges = [
            (label: "< 5 min", min: 0.0, max: 5.0),
            (label: "5-15 min", min: 5.0, max: 15.0),
            (label: "15-30 min", min: 15.0, max: 30.0),
            (label: "30-60 min", min: 30.0, max: 60.0),
            (label: "> 60 min", min: 60.0, max: Double.infinity)
        ]
        
        var rangeCounts: [String: Int] = [:]
        
        for event in events {
            for range in ranges {
                if event.minutesOpen >= range.min && event.minutesOpen < range.max {
                    rangeCounts[range.label, default: 0] += 1
                    break
                }
            }
        }
        
        let maxCount = Double(rangeCounts.values.max() ?? 1)
        
        return ranges.map { range in
            let count = rangeCounts[range.label] ?? 0
            return (range: range.label, count: count, normalizedCount: Double(count) / maxCount)
        }
    }
}

// MARK: - Cascade Analysis Views
struct CascadeActivityView: View {
    let events: [DrawbridgeEvent]
    let bridgeName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Bridge Interaction Timeline")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text("Analyzing how \(bridgeName) openings correlate with other bridge activity...")
                .font(.caption)
                .foregroundColor(.secondary)
                .italic()
            
            // Placeholder for cascade analysis
            HStack {
                Image(systemName: "arrow.triangle.branch")
                    .foregroundColor(.blue)
                VStack(alignment: .leading) {
                    Text("Feature Coming Soon")
                        .font(.caption)
                        .fontWeight(.medium)
                    Text("Cascade analysis requires multiple bridge data correlation")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(8)
        }
    }
}

struct CascadeWeeklyView: View {
    let events: [DrawbridgeEvent]
    let bridgeName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Cascade Patterns")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text("Coming Soon: Weekly correlation analysis")
                .font(.caption)
                .foregroundColor(.secondary)
                .italic()
        }
    }
}

struct CascadeDurationView: View {
    let events: [DrawbridgeEvent]
    let bridgeName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Duration Cascade Effects")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text("Coming Soon: Duration impact on other bridges")
                .font(.caption)
                .foregroundColor(.secondary)
                .italic()
        }
    }
}

// MARK: - Prediction Analysis Views
struct PredictionsActivityView: View {
    let events: [DrawbridgeEvent]
    let bridgeName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity Predictions")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            // Next hour prediction
            if let prediction = nextHourPrediction {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Next Hour Prediction")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    HStack {
                        Text("Probability:")
                        Spacer()
                        Text(prediction.probabilityText)
                            .foregroundColor(probabilityColor(prediction.probability))
                            .fontWeight(.medium)
                    }
                    .font(.caption)
                    
                    HStack {
                        Text("Expected Duration:")
                        Spacer()
                        Text(prediction.durationText)
                            .foregroundColor(.orange)
                    }
                    .font(.caption)
                    
                    HStack {
                        Text("Confidence:")
                        Spacer()
                        Text(prediction.confidenceText)
                            .foregroundColor(.blue)
                    }
                    .font(.caption)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(8)
            } else {
                Text("Generating predictions from historical data...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
    }
    
    private var nextHourPrediction: BridgePrediction? {
        // Create a mock bridge info for prediction
        let bridgeInfo = DrawbridgeInfo(
            entityID: events.first?.entityID ?? 0,
            entityName: bridgeName,
            entityType: events.first?.entityType ?? "Bridge",
            latitude: events.first?.latitude ?? 0,
            longitude: events.first?.longitude ?? 0
        )
        
        // Calculate analytics and get prediction
        let analytics = BridgeAnalyticsCalculator.calculateAnalytics(from: events)
        return BridgeAnalytics.getCurrentPrediction(for: bridgeInfo, from: analytics)
    }
    
    private func probabilityColor(_ probability: Double) -> Color {
        switch probability {
        case 0.0..<0.3: return .green
        case 0.3..<0.6: return .orange
        case 0.6...1.0: return .red
        default: return .gray
        }
    }
}

struct PredictionsWeeklyView: View {
    let events: [DrawbridgeEvent]
    let bridgeName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Predictions")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text("Coming Soon: 7-day forecast based on historical patterns")
                .font(.caption)
                .foregroundColor(.secondary)
                .italic()
        }
    }
}

struct PredictionsDurationView: View {
    let events: [DrawbridgeEvent]
    let bridgeName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Duration Predictions")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text("Coming Soon: Predicted opening durations")
                .font(.caption)
                .foregroundColor(.secondary)
                .italic()
        }
    }
}

// MARK: - Impact Analysis Views
struct ImpactActivityView: View {
    let events: [DrawbridgeEvent]
    let bridgeName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Traffic Impact Analysis")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            // Impact severity distribution
            ForEach(impactLevels, id: \.level) { impact in
                HStack {
                    Circle()
                        .fill(impact.color)
                        .frame(width: 8, height: 8)
                    
                    Text(impact.level)
                        .font(.caption)
                        .frame(width: 80, alignment: .leading)
                    
                    ProgressView(value: impact.normalizedCount, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: impact.color))
                    
                    Text("\(impact.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 30, alignment: .trailing)
                }
            }
            
            // Traffic advice
            Text("⚠️ High impact openings typically occur during rush hours (7-9 AM, 5-7 PM)")
                .font(.caption2)
                .foregroundColor(.orange)
                .padding(.top, 4)
        }
    }
    
    private var impactLevels: [(level: String, count: Int, normalizedCount: Double, color: Color)] {
        let levels = [
            (label: "Low Impact", min: 0.0, max: 10.0, color: Color.green),
            (label: "Medium Impact", min: 10.0, max: 30.0, color: Color.orange),
            (label: "High Impact", min: 30.0, max: Double.infinity, color: Color.red)
        ]
        
        var levelCounts: [String: Int] = [:]
        
        for event in events {
            for level in levels {
                if event.minutesOpen >= level.min && event.minutesOpen < level.max {
                    levelCounts[level.label, default: 0] += 1
                    break
                }
            }
        }
        
        let maxCount = Double(levelCounts.values.max() ?? 1)
        
        return levels.map { level in
            let count = levelCounts[level.label] ?? 0
            return (level: level.label, count: count, normalizedCount: Double(count) / maxCount, color: level.color)
        }
    }
}

struct ImpactWeeklyView: View {
    let events: [DrawbridgeEvent]
    let bridgeName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Traffic Impact")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text("Coming Soon: Weekly traffic impact analysis")
                .font(.caption)
                .foregroundColor(.secondary)
                .italic()
        }
    }
}

struct ImpactDurationView: View {
    let events: [DrawbridgeEvent]
    let bridgeName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Duration Impact Analysis")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text("Coming Soon: How opening duration affects traffic")
                .font(.caption)
                .foregroundColor(.secondary)
                .italic()
        }
    }
}

// MARK: - Hourly Pattern Chart
struct HourlyPatternChart: View {
    let events: [DrawbridgeEvent]
    
    var body: some View {
        Chart {
            ForEach(hourlyChartData, id: \.hour) { data in
                BarMark(
                    x: .value("Hour", data.hour),
                    y: .value("Count", data.count)
                )
                .foregroundStyle(Color.blue.opacity(0.7))
            }
        }
        .frame(height: 120)
        .chartXAxis {
            AxisMarks(values: .stride(by: 6)) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let intValue = value.as(Int.self) {
                        Text("\(intValue)")
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
    }
    
    private var hourlyChartData: [HourlyData] {
        var hourCounts: [Int: Int] = [:]
        let calendar = Calendar.current
        
        for event in events {
            let hour = calendar.component(.hour, from: event.openDateTime)
            hourCounts[hour, default: 0] += 1
        }
        
        return (0..<24).map { hour in
            HourlyData(hour: hour, count: hourCounts[hour] ?? 0)
        }
    }
}

struct HourlyData {
    let hour: Int
    let count: Int
}

struct WeeklyData {
    let dayIndex: Int
    let dayName: String
    let count: Int
}

// MARK: - Bridge Header Section
struct BridgeHeaderSection: View {
    let bridgeName: String
    let lastKnownEvent: DrawbridgeEvent?
    let totalEvents: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(bridgeName)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(bridgeName)
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 8) {
                        Circle()
                            .fill(statusColor(for: lastKnownEvent))
                            .frame(width: 8, height: 8)
                        
                        Text(lastKnownStatusText(for: lastKnownEvent))
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Last Updated")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(lastUpdateTime)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func lastKnownStatusText(for event: DrawbridgeEvent?) -> String {
        guard let event = event else { return "No Data" }
        
        if event.closeDateTime != nil {
            return "Open to Traffic"
        } else {
            return "Was Open"
        }
    }
    
    private func statusColor(for event: DrawbridgeEvent?) -> Color {
        guard let event = event else { return .gray }
        
        if event.closeDateTime != nil {
            return .green  // Bridge is closed (open to traffic)
        } else {
            return .orange // Bridge was open
        }
    }
    
    private var lastUpdateTime: String {
        guard let event = lastKnownEvent else { return "N/A" }
        let relevantDate = event.closeDateTime ?? event.openDateTime
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: relevantDate)
    }
}

// MARK: - Functional Time Filter Section
struct FunctionalTimeFilterSection: View {
    @Binding var selectedPeriod: TimePeriod
    let bridgeEvents: [DrawbridgeEvent]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Time Period")
                    .font(.headline)
                Spacer()
                Text("Showing \(eventsInPeriod) events")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 12) {
                ForEach(TimePeriod.allCases, id: \.self) { period in
                    FilterButton(
                        title: periodTitle(for: period),
                        isSelected: selectedPeriod == period,
                        action: { selectedPeriod = period }
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var eventsInPeriod: Int {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -selectedPeriod.days, to: Date()) ?? Date()
        return bridgeEvents.filter { $0.openDateTime >= cutoffDate }.count
    }
    
    private func periodTitle(for period: TimePeriod) -> String {
        switch period {
        case .twentyFourHours: return "24H"
        case .sevenDays: return "7D"
        case .thirtyDays: return "30D"
        case .ninetyDays: return "90D"
        }
    }
}

// MARK: - Bridge Statistics Section
struct BridgeStatsSection: View {
    let events: [DrawbridgeEvent]
    let timePeriod: TimePeriod
    let analysisType: AnalysisType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistics (\(periodDescription))")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatCard(
                    title: "Total Openings",
                    value: "\(events.count)",
                    icon: "arrow.up.circle.fill",
                    color: .blue
                )
                
                StatCard(
                    title: analysisSpecificTitle,
                    value: analysisSpecificValue,
                    icon: analysisSpecificIcon,
                    color: analysisSpecificColor
                )
                
                StatCard(
                    title: "Longest Opening",
                    value: longestDurationText,
                    icon: "clock.fill",
                    color: .red
                )
                
                StatCard(
                    title: "Most Active Day",
                    value: mostActiveDayText,
                    icon: "calendar",
                    color: .green
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var periodDescription: String {
        switch timePeriod {
        case .twentyFourHours: return "Last 24 Hours"
        case .sevenDays: return "Last 7 Days"
        case .thirtyDays: return "Last 30 Days"
        case .ninetyDays: return "Last 90 Days"
        }
    }
    
    private var analysisSpecificTitle: String {
        switch analysisType {
        case .patterns: return "Avg Duration"
        case .cascade: return "Peak Hour"
        case .predictions: return "Next Probability"
        case .impact: return "High Impact"
        }
    }
    
    private var analysisSpecificValue: String {
        switch analysisType {
        case .patterns:
            guard !events.isEmpty else { return "0 min" }
            let avg = events.map(\.minutesOpen).reduce(0, +) / Double(events.count)
            return String(format: "%.0f min", avg)
        case .cascade:
            return peakHour
        case .predictions:
            return "Coming Soon"
        case .impact:
            let highImpact = events.filter { $0.minutesOpen > 30 }.count
            return "\(highImpact)"
        }
    }
    
    private var analysisSpecificIcon: String {
        switch analysisType {
        case .patterns: return "timer"
        case .cascade: return "arrow.triangle.branch"
        case .predictions: return "crystal.ball"
        case .impact: return "exclamationmark.triangle.fill"
        }
    }
    
    private var analysisSpecificColor: Color {
        switch analysisType {
        case .patterns: return .orange
        case .cascade: return .purple
        case .predictions: return .blue
        case .impact: return .red
        }
    }
    
    private var peakHour: String {
        let calendar = Calendar.current
        var hourCounts: [Int: Int] = [:]
        
        for event in events {
            let hour = calendar.component(.hour, from: event.openDateTime)
            hourCounts[hour, default: 0] += 1
        }
        
        if let peak = hourCounts.max(by: { $0.value < $1.value }) {
            return "\(peak.key):00"
        }
        return "None"
    }
    
    private var longestDurationText: String {
        guard let longest = events.map(\.minutesOpen).max() else { return "0 min" }
        return String(format: "%.0f min", longest)
    }
    
    private var mostActiveDayText: String {
        guard !events.isEmpty else { return "None" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        
        let dayGroups = Dictionary(grouping: events) { event in
            formatter.string(from: event.openDateTime)
        }
        
        let mostActiveDay = dayGroups.max { $0.value.count < $1.value.count }
        return mostActiveDay?.key ?? "None"
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
        }
        .frame(minHeight: 80)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

// MARK: - Bridge Info Section
struct BridgeInfoSection: View {
    let event: DrawbridgeEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Bridge Information")
                .font(.headline)
            
            InfoRow(label: "Type", value: event.entityType)
            InfoRow(label: "Entity ID", value: "\(event.entityID)")
            InfoRow(label: "Location", value: String(format: "%.4f, %.4f", event.latitude, event.longitude))
            
            if event.closeDateTime != nil {
                InfoRow(label: "Duration", value: String(format: "%.0f minutes", event.minutesOpen))
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Data Model Enums
enum TimePeriod: CaseIterable {
    case twentyFourHours, sevenDays, thirtyDays, ninetyDays
    
    var days: Int {
        switch self {
        case .twentyFourHours: return 1
        case .sevenDays: return 7
        case .thirtyDays: return 30
        case .ninetyDays: return 90
        }
    }
}

enum AnalysisType: CaseIterable {
    case patterns, cascade, predictions, impact
}

enum ViewType: CaseIterable {
    case activity, weekly, duration
}

// MARK: - Analysis Filter Section Component
struct AnalysisFilterSection: View {
    @Binding var selectedAnalysis: AnalysisType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                FilterButton(
                    title: "Patterns",
                    isSelected: selectedAnalysis == .patterns,
                    action: { selectedAnalysis = .patterns }
                )
                
                FilterButton(
                    title: "Cascade",
                    isSelected: selectedAnalysis == .cascade,
                    action: { selectedAnalysis = .cascade }
                )
                
                FilterButton(
                    title: "Predictions", 
                    isSelected: selectedAnalysis == .predictions,
                    action: { selectedAnalysis = .predictions }
                )
                
                FilterButton(
                    title: "Impact",
                    isSelected: selectedAnalysis == .impact,
                    action: { selectedAnalysis = .impact }
                )
            }
        }
    }
}

// MARK: - View Filter Section Component
struct ViewFilterSection: View {
    @Binding var selectedView: ViewType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                FilterButton(
                    title: "Activity",
                    isSelected: selectedView == .activity,
                    action: { selectedView = .activity }
                )
                
                FilterButton(
                    title: "Weekly",
                    isSelected: selectedView == .weekly,
                    action: { selectedView = .weekly }
                )
                
                FilterButton(
                    title: "Duration",
                    isSelected: selectedView == .duration,
                    action: { selectedView = .duration }
                )
            }
        }
    }
}

// MARK: - Filter Button Component
struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(8)
        }
    }
}

// MARK: - Bridge Views (Placeholder implementations)
struct BridgesListView: View {
    let events: [DrawbridgeEvent]
    let bridgeInfo: [DrawbridgeInfo]
    
    var body: some View {
        NavigationView {
            Text("Bridge Analysis - Coming Soon")
                .navigationTitle("Bridges")
        }
    }
}

struct HistoryView: View {
    let events: [DrawbridgeEvent]
    
    var body: some View {
        NavigationView {
            Text("Historical Patterns - Coming Soon")
                .navigationTitle("History")
        }
    }
}

struct StatisticsView: View {
    let events: [DrawbridgeEvent]
    let bridgeInfo: [DrawbridgeInfo]
    
    var body: some View {
        NavigationView {
            Text("Predictive Analytics - Coming Soon")
                .navigationTitle("Statistics")
        }
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .modelContainer(for: [DrawbridgeEvent.self, DrawbridgeInfo.self], inMemory: true)
    }
}