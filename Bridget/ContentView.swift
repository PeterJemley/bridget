//
//  ContentView.swift
//  Bridget
//
//  Created by Peter Jemley on 6/18/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var events: [DrawbridgeEvent]
    @Query private var bridgeInfo: [DrawbridgeInfo]
    
    var body: some View {
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

// MARK: - Bridge Detail View (Phase 1 Implementation)
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
                
                // Analysis Type Filter Buttons  
                AnalysisFilterSection(selectedAnalysis: $selectedAnalysis)
                
                // View Type Filter Buttons
                ViewFilterSection(selectedView: $selectedView)
                
                // Bridge Statistics Section
                BridgeStatsSection(
                    events: filteredEvents,
                    timePeriod: selectedPeriod
                )
                
                // Recent Activity for This Bridge
                BridgeActivitySection(
                    events: filteredEvents.prefix(10).map { $0 }
                )
                
                // Chart Placeholder Section (Bridge-specific)
                BridgeChartSection(
                    bridgeName: bridgeEvent.entityName,
                    events: filteredEvents
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
                if let event = lastKnownEvent {
                    Text(lastKnownStatusText(for: event))
                        .font(.headline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(statusColor(for: event))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                } else {
                    Text("NO DATA")
                        .font(.headline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Total Events")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(totalEvents)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            
            if let event = lastKnownEvent {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.secondary)
                    Text("Last activity \(timeAgoText(for: event))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func lastKnownStatusText(for event: DrawbridgeEvent) -> String {
        if event.closeDateTime != nil {
            return "CLOSED"
        } else {
            return "WAS OPEN"
        }
    }
    
    private func statusColor(for event: DrawbridgeEvent) -> Color {
        if event.closeDateTime != nil {
            return .green
        } else {
            return .orange
        }
    }
    
    private func timeAgoText(for event: DrawbridgeEvent) -> String {
        let relevantDate = event.closeDateTime ?? event.openDateTime
        return relevantDate.formatted(.relative(presentation: .named))
    }
}

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

struct BridgeStatsSection: View {
    let events: [DrawbridgeEvent]
    let timePeriod: TimePeriod
    
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
                    title: "Avg Duration",
                    value: averageDurationText,
                    icon: "timer",
                    color: .orange
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
    
    private var averageDurationText: String {
        guard !events.isEmpty else { return "0 min" }
        let avg = events.map(\.minutesOpen).reduce(0, +) / Double(events.count)
        return String(format: "%.0f min", avg)
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

struct BridgeActivitySection: View {
    let events: [DrawbridgeEvent]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Activity")
                    .font(.headline)
                Spacer()
                if !events.isEmpty {
                    Text("\(events.count) events")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if events.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clock.fill")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No activity in selected period")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                ForEach(events, id: \.id) { event in
                    BridgeActivityRow(event: event)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct BridgeActivityRow: View {
    let event: DrawbridgeEvent
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(event.openDateTime.formatted(.dateTime.month().day().hour().minute()))
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text(statusText)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(statusColor)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
                
                Text("Duration: \(String(format: "%.0f", event.minutesOpen)) minutes")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
    
    private var statusText: String {
        if event.closeDateTime != nil {
            return "OPENED & CLOSED"
        } else {
            return "OPENED"
        }
    }
    
    private var statusColor: Color {
        if event.closeDateTime != nil {
            return .green
        } else {
            return .orange
        }
    }
}

struct BridgeChartSection: View {
    let bridgeName: String
    let events: [DrawbridgeEvent]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(bridgeName) Activity Patterns")
                .font(.headline)
            
            Text("Opening frequency over time")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Chart placeholder - will be implemented in Phase 3
            VStack {
                HStack(alignment: .bottom) {
                    VStack(spacing: 20) {
                        Text("8").font(.caption).foregroundColor(.secondary)
                        Text("6").font(.caption).foregroundColor(.secondary)
                        Text("4").font(.caption).foregroundColor(.secondary)
                        Text("2").font(.caption).foregroundColor(.secondary)
                        Text("0").font(.caption).foregroundColor(.secondary)
                    }
                    
                    Rectangle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(height: 120)
                        .overlay(
                            VStack {
                                Text("Chart Preview")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                Text("\(events.count) events to visualize")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        )
                }
                
                HStack {
                    Spacer()
                    Text("Recent").font(.caption).foregroundColor(.secondary)
                    Spacer()
                    Text("Activity").font(.caption).foregroundColor(.secondary)
                    Spacer()
                    Text("Timeline").font(.caption).foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 20)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
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

// MARK: - Analysis Filter Section Component (Restored)
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

// MARK: - View Filter Section Component (Restored)
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

// MARK: - Filter Button Component (Restored)
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

// MARK: - Placeholder Views (FIXED)
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

#Preview {
    ContentView()
        .modelContainer(for: [DrawbridgeEvent.self, DrawbridgeInfo.self], inMemory: true)
}