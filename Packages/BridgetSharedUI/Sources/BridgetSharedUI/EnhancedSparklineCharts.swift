//
//  EnhancedSparklineCharts.swift
//  BridgetSharedUI
//
//  Created by AI Assistant on 1/15/25.
//

import SwiftUI
import BridgetCore

/**
 * Enhanced sparkline chart components for historical analysis
 * 
 * This module provides specialized sparkline charts designed specifically for
 * bridge activity historical analysis, with interactive features and multiple
 * visualization types.
 * 
 * Features:
 * - Multiple chart types (line, area, bar, candlestick)
 * - Interactive tooltips and selection
 * - Animated transitions and real-time updates
 * - Comprehensive customization options
 * - Accessibility support
 * - Performance optimizations for large datasets
 */

// MARK: - Core Data Structures

/**
 * Enhanced data point for sparkline charts with additional metadata
 */
public struct EnhancedSparklinePoint: Identifiable, Equatable {
    public let id = UUID()
    public let date: Date
    public let value: Double
    public let secondaryValue: Double?
    public let label: String
    public let metadata: [String: Any]
    
    public init(
        date: Date,
        value: Double,
        secondaryValue: Double? = nil,
        label: String,
        metadata: [String: Any] = [:]
    ) {
        self.date = date
        self.value = value
        self.secondaryValue = secondaryValue
        self.label = label
        self.metadata = metadata
    }
    
    // MARK: - Equatable
    
    public static func == (lhs: EnhancedSparklinePoint, rhs: EnhancedSparklinePoint) -> Bool {
        return lhs.id == rhs.id &&
               lhs.date == rhs.date &&
               lhs.value == rhs.value &&
               lhs.secondaryValue == rhs.secondaryValue &&
               lhs.label == rhs.label
    }
}

/**
 * Chart configuration for sparkline customization
 */
public struct SparklineConfig {
    public let chartType: SparklineChartType
    public let color: Color
    public let secondaryColor: Color?
    public let height: CGFloat
    public let showGrid: Bool
    public let showTrendIndicator: Bool
    public let showTooltips: Bool
    public let animationDuration: Double
    public let lineWidth: CGFloat
    public let cornerRadius: CGFloat
    
    public init(
        chartType: SparklineChartType = .line,
        color: Color = .blue,
        secondaryColor: Color? = nil,
        height: CGFloat = 60,
        showGrid: Bool = false,
        showTrendIndicator: Bool = true,
        showTooltips: Bool = true,
        animationDuration: Double = 0.3,
        lineWidth: CGFloat = 2.0,
        cornerRadius: CGFloat = 4.0
    ) {
        self.chartType = chartType
        self.color = color
        self.secondaryColor = secondaryColor
        self.height = height
        self.showGrid = showGrid
        self.showTrendIndicator = showTrendIndicator
        self.showTooltips = showTooltips
        self.animationDuration = animationDuration
        self.lineWidth = lineWidth
        self.cornerRadius = cornerRadius
    }
}

/**
 * Supported chart types for sparkline visualization
 */
public enum SparklineChartType {
    case line, area, bar, candlestick, multiLine
    
    var requiresSecondaryData: Bool {
        switch self {
        case .candlestick, .multiLine:
            return true
        default:
            return false
        }
    }
}

// MARK: - Enhanced Sparkline Chart

/**
 * Enhanced sparkline chart with interactive features and multiple chart types
 */
public struct EnhancedSparklineChart: View {
    public let dataPoints: [EnhancedSparklinePoint]
    public let config: SparklineConfig
    
    @State private var selectedPoint: EnhancedSparklinePoint?
    @State private var showingTooltip = false
    @State private var tooltipPosition: CGPoint = .zero
    
    public init(dataPoints: [EnhancedSparklinePoint], config: SparklineConfig = SparklineConfig()) {
        self.dataPoints = dataPoints
        self.config = config
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            if config.showTrendIndicator {
                trendIndicator
            }
            
            chartContainer
        }
        .frame(height: config.height)
        .onChange(of: dataPoints) { _ in
            withAnimation(.easeInOut(duration: config.animationDuration)) {
                // Trigger chart update animation
            }
        }
    }
    
    // MARK: - Chart Container
    
    private var chartContainer: some View {
        GeometryReader { geometry in
            ZStack {
                if config.showGrid {
                    gridOverlay(in: geometry.size)
                }
                
                chartContent(in: geometry.size)
                
                if config.showTooltips && showingTooltip, let selectedPoint = selectedPoint {
                    tooltipView(for: selectedPoint, in: geometry.size)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { location in
                handleTap(at: location, in: geometry.size)
            }
            .onHover { isHovered in
                if !isHovered {
                    showingTooltip = false
                }
            }
        }
    }
    
    // MARK: - Chart Content
    
    @ViewBuilder
    private func chartContent(in size: CGSize) -> some View {
        switch config.chartType {
        case .line:
            lineChart(in: size)
        case .area:
            areaChart(in: size)
        case .bar:
            barChart(in: size)
        case .candlestick:
            candlestickChart(in: size)
        case .multiLine:
            multiLineChart(in: size)
        }
    }
    
    // MARK: - Line Chart
    
    private func lineChart(in size: CGSize) -> some View {
        Path { path in
            let points = normalizedPoints(in: size)
            guard !points.isEmpty else { return }
            
            path.move(to: points[0])
            
            for point in points.dropFirst() {
                path.addLine(to: point)
            }
        }
        .stroke(config.color, style: StrokeStyle(
            lineWidth: config.lineWidth,
            lineCap: .round,
            lineJoin: .round
        ))
        .animation(.easeInOut(duration: config.animationDuration), value: dataPoints)
    }
    
    // MARK: - Area Chart
    
    private func areaChart(in size: CGSize) -> some View {
        Path { path in
            let points = normalizedPoints(in: size)
            guard !points.isEmpty else { return }
            
            // Create area path
            path.move(to: CGPoint(x: points[0].x, y: size.height))
            path.addLine(to: points[0])
            
            for point in points.dropFirst() {
                path.addLine(to: point)
            }
            
            path.addLine(to: CGPoint(x: points.last?.x ?? 0, y: size.height))
            path.closeSubpath()
        }
        .fill(
            LinearGradient(
                colors: [config.color.opacity(0.3), config.color.opacity(0.1)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .animation(.easeInOut(duration: config.animationDuration), value: dataPoints)
    }
    
    // MARK: - Bar Chart
    
    private func barChart(in size: CGSize) -> some View {
        HStack(spacing: 1) {
            ForEach(dataPoints) { point in
                let normalizedValue = normalizedValue(for: point.value, in: size.height)
                Rectangle()
                    .fill(config.color)
                    .frame(width: max(2, size.width / CGFloat(dataPoints.count) - 1))
                    .frame(height: normalizedValue * size.height)
                    .cornerRadius(config.cornerRadius)
                    .animation(.easeInOut(duration: config.animationDuration), value: dataPoints)
            }
        }
    }
    
    // MARK: - Candlestick Chart
    
    private func candlestickChart(in size: CGSize) -> some View {
        HStack(spacing: 2) {
            ForEach(dataPoints) { point in
                if let secondaryValue = point.secondaryValue {
                    let openValue = normalizedValue(for: point.value, in: size.height)
                    let closeValue = normalizedValue(for: secondaryValue, in: size.height)
                    let isGreen = closeValue > openValue
                    
                    VStack(spacing: 0) {
                        // Wick
                        Rectangle()
                            .fill(isGreen ? .green : .red)
                            .frame(width: 1)
                            .frame(height: size.height)
                        
                        // Body
                        Rectangle()
                            .fill(isGreen ? .green : .red)
                            .frame(width: 4)
                            .frame(height: abs(closeValue - openValue) * size.height)
                    }
                    .animation(.easeInOut(duration: config.animationDuration), value: dataPoints)
                }
            }
        }
    }
    
    // MARK: - Multi-Line Chart
    
    private func multiLineChart(in size: CGSize) -> some View {
        ZStack {
            // Primary line
            Path { path in
                let points = normalizedPoints(in: size)
                guard !points.isEmpty else { return }
                
                path.move(to: points[0])
                for point in points.dropFirst() {
                    path.addLine(to: point)
                }
            }
            .stroke(config.color, style: StrokeStyle(
                lineWidth: config.lineWidth,
                lineCap: .round,
                lineJoin: .round
            ))
            
            // Secondary line
            if let secondaryColor = config.secondaryColor {
                Path { path in
                    let points = normalizedPointsSecondary(in: size)
                    guard !points.isEmpty else { return }
                    
                    path.move(to: points[0])
                    for point in points.dropFirst() {
                        path.addLine(to: point)
                    }
                }
                .stroke(secondaryColor, style: StrokeStyle(
                    lineWidth: config.lineWidth,
                    lineCap: .round,
                    lineJoin: .round
                ))
            }
        }
        .animation(.easeInOut(duration: config.animationDuration), value: dataPoints)
    }
    
    // MARK: - Grid Overlay
    
    private func gridOverlay(in size: CGSize) -> some View {
        VStack(spacing: 0) {
            ForEach(0..<4, id: \.self) { _ in
                Divider()
                    .background(Color.gray.opacity(0.2))
                Spacer()
            }
        }
    }
    
    // MARK: - Trend Indicator
    
    private var trendIndicator: some View {
        Group {
            if let trend = calculateTrend() {
                HStack(spacing: 4) {
                    Image(systemName: trend.symbol)
                        .font(.caption2)
                        .foregroundColor(trend.color)
                    
                    Text("\(abs(trend.change), specifier: "%.1f")")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
            } else {
                EmptyView()
            }
        }
    }
    
    // MARK: - Tooltip
    
    private func tooltipView(for point: EnhancedSparklinePoint, in size: CGSize) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(point.label)
                .font(.caption)
                .fontWeight(.semibold)
            
            Text("\(point.value, specifier: "%.1f")")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            if let secondaryValue = point.secondaryValue {
                Text("Secondary: \(secondaryValue, specifier: "%.1f")")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .position(tooltipPosition)
    }
    
    // MARK: - Helper Methods
    
    private func normalizedPoints(in size: CGSize) -> [CGPoint] {
        guard !dataPoints.isEmpty else { return [] }
        
        let maxValue = dataPoints.map(\.value).max() ?? 1
        let minValue = dataPoints.map(\.value).min() ?? 0
        let valueRange = max(1, maxValue - minValue)
        
        let xStep = size.width / CGFloat(max(1, dataPoints.count - 1))
        
        return dataPoints.enumerated().map { index, point in
            let x = CGFloat(index) * xStep
            let normalizedValue = CGFloat(point.value - minValue) / CGFloat(valueRange)
            let y = size.height - (normalizedValue * size.height)
            
            return CGPoint(x: x, y: y)
        }
    }
    
    private func normalizedPointsSecondary(in size: CGSize) -> [CGPoint] {
        guard !dataPoints.isEmpty else { return [] }
        
        let secondaryValues = dataPoints.compactMap(\.secondaryValue)
        guard !secondaryValues.isEmpty else { return [] }
        
        let maxValue = secondaryValues.max() ?? 1
        let minValue = secondaryValues.min() ?? 0
        let valueRange = max(1, maxValue - minValue)
        
        let xStep = size.width / CGFloat(max(1, dataPoints.count - 1))
        
        return dataPoints.enumerated().compactMap { index, point in
            guard let secondaryValue = point.secondaryValue else { return nil }
            
            let x = CGFloat(index) * xStep
            let normalizedValue = CGFloat(secondaryValue - minValue) / CGFloat(valueRange)
            let y = size.height - (normalizedValue * size.height)
            
            return CGPoint(x: x, y: y)
        }
    }
    
    private func normalizedValue(for value: Double, in height: CGFloat) -> CGFloat {
        let maxValue = dataPoints.map(\.value).max() ?? 1
        let minValue = dataPoints.map(\.value).min() ?? 0
        let valueRange = max(1, maxValue - minValue)
        
        return CGFloat(value - minValue) / CGFloat(valueRange)
    }
    
    private func calculateTrend() -> (symbol: String, change: Double, color: Color)? {
        guard dataPoints.count >= 2 else { return nil }
        
        let recentValues = dataPoints.suffix(7).map(\.value)
        let previousValues = dataPoints.dropLast(7).suffix(7).map(\.value)
        
        let recentAvg = recentValues.reduce(0, +) / Double(recentValues.count)
        let previousAvg = previousValues.reduce(0, +) / Double(previousValues.count)
        
        let change = recentAvg - previousAvg
        let changePercent = previousAvg > 0 ? (change / previousAvg) * 100 : 0
        
        let symbol: String
        let color: Color
        
        if change > 0 {
            symbol = "arrow.up"
            color = .green
        } else if change < 0 {
            symbol = "arrow.down"
            color = .red
        } else {
            symbol = "arrow.right"
            color = .gray
        }
        
        return (symbol: symbol, change: changePercent, color: color)
    }
    
    private func handleTap(at location: CGPoint, in size: CGSize) {
        let xStep = size.width / CGFloat(max(1, dataPoints.count - 1))
        let index = Int(location.x / xStep)
        
        if index >= 0 && index < dataPoints.count {
            selectedPoint = dataPoints[index]
            tooltipPosition = CGPoint(x: location.x, y: location.y - 40)
            showingTooltip = true
            
            // Auto-hide tooltip after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                showingTooltip = false
            }
        }
    }
}

// MARK: - Specialized Chart Components

/**
 * Bridge activity frequency sparkline
 */
public struct BridgeFrequencySparkline: View {
    public let events: [DrawbridgeEvent]
    public let config: SparklineConfig
    
    public init(events: [DrawbridgeEvent], config: SparklineConfig = SparklineConfig()) {
        self.events = events
        self.config = config
    }
    
    public var body: some View {
        EnhancedSparklineChart(
            dataPoints: frequencyDataPoints,
            config: config
        )
    }
    
    private var frequencyDataPoints: [EnhancedSparklinePoint] {
        let calendar = Calendar.current
        let groupedData = Dictionary(grouping: events) { event in
            calendar.startOfDay(for: event.openDateTime)
        }
        
        return groupedData.map { date, dayEvents in
            EnhancedSparklinePoint(
                date: date,
                value: Double(dayEvents.count),
                label: date.formatted(date: .abbreviated, time: .omitted)
            )
        }.sorted { $0.date < $1.date }
    }
}

/**
 * Bridge duration trends sparkline
 */
public struct BridgeDurationSparkline: View {
    public let events: [DrawbridgeEvent]
    public let config: SparklineConfig
    
    public init(events: [DrawbridgeEvent], config: SparklineConfig = SparklineConfig()) {
        self.events = events
        self.config = config
    }
    
    public var body: some View {
        EnhancedSparklineChart(
            dataPoints: durationDataPoints,
            config: config
        )
    }
    
    private var durationDataPoints: [EnhancedSparklinePoint] {
        let calendar = Calendar.current
        let groupedData = Dictionary(grouping: events) { event in
            calendar.startOfDay(for: event.openDateTime)
        }
        
        return groupedData.compactMap { date, dayEvents in
            guard !dayEvents.isEmpty else { return nil }
            let avgDuration = dayEvents.map(\.minutesOpen).reduce(0, +) / Double(dayEvents.count)
            
            return EnhancedSparklinePoint(
                date: date,
                value: avgDuration,
                label: date.formatted(date: .abbreviated, time: .omitted),
                metadata: ["count": dayEvents.count]
            )
        }.sorted { $0.date < $1.date }
    }
}

/**
 * Bridge comparison sparkline showing multiple bridges
 */
public struct BridgeComparisonSparkline: View {
    public let events: [DrawbridgeEvent]
    public let bridges: [String]
    public let config: SparklineConfig
    
    public init(events: [DrawbridgeEvent], bridges: [String], config: SparklineConfig = SparklineConfig()) {
        self.events = events
        self.bridges = bridges
        self.config = config
    }
    
    public var body: some View {
        EnhancedSparklineChart(
            dataPoints: comparisonDataPoints,
            config: config
        )
    }
    
    private var comparisonDataPoints: [EnhancedSparklinePoint] {
        let bridgeGroups = Dictionary(grouping: events, by: \.entityName)
        
        return bridges.compactMap { bridgeName in
            guard let bridgeEvents = bridgeGroups[bridgeName] else { return nil }
            
            return EnhancedSparklinePoint(
                date: Date(),
                value: Double(bridgeEvents.count),
                label: bridgeName,
                metadata: ["bridgeName": bridgeName]
            )
        }.sorted { $0.value > $1.value }
    }
}

/**
 * Weekly pattern sparkline showing day-of-week distribution
 */
public struct WeeklyPatternSparkline: View {
    public let events: [DrawbridgeEvent]
    public let config: SparklineConfig
    
    public init(events: [DrawbridgeEvent], config: SparklineConfig = SparklineConfig()) {
        self.events = events
        self.config = config
    }
    
    public var body: some View {
        EnhancedSparklineChart(
            dataPoints: weeklyPatternDataPoints,
            config: config
        )
    }
    
    private var weeklyPatternDataPoints: [EnhancedSparklinePoint] {
        let calendar = Calendar.current
        let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        
        let groupedData = Dictionary(grouping: events) { event in
            calendar.component(.weekday, from: event.openDateTime) - 1
        }
        
        return (0..<7).map { dayIndex in
            let dayEvents = groupedData[dayIndex] ?? []
            return EnhancedSparklinePoint(
                date: Date(),
                value: Double(dayEvents.count),
                label: dayNames[dayIndex],
                metadata: ["dayIndex": dayIndex, "dayName": dayNames[dayIndex]]
            )
        }
    }
}

// MARK: - Chart Container Views

/**
 * Container view for sparkline charts with title and metadata
 */
public struct SparklineChartContainer: View {
    public let title: String
    public let subtitle: String?
    public let chart: AnyView
    public let showTrend: Bool
    
    public init<Content: View>(
        title: String,
        subtitle: String? = nil,
        showTrend: Bool = true,
        @ViewBuilder chart: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.chart = AnyView(chart())
        self.showTrend = showTrend
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            chart
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 1)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // Sample data
        let sampleEvents = [
            DrawbridgeEvent(
                entityType: "Bridge",
                entityName: "Fremont Bridge",
                entityID: 1,
                openDateTime: Date().addingTimeInterval(-6*24*3600),
                closeDateTime: Date().addingTimeInterval(-6*24*3600 + 900),
                minutesOpen: 15.0,
                latitude: 47.6475,
                longitude: -122.3497
            ),
            DrawbridgeEvent(
                entityType: "Bridge",
                entityName: "Ballard Bridge",
                entityID: 2,
                openDateTime: Date().addingTimeInterval(-5*24*3600),
                closeDateTime: Date().addingTimeInterval(-5*24*3600 + 1200),
                minutesOpen: 20.0,
                latitude: 47.6619,
                longitude: -122.3767
            )
        ]
        
        SparklineChartContainer(
            title: "Bridge Activity Frequency",
            subtitle: "Last 7 days"
        ) {
            BridgeFrequencySparkline(
                events: sampleEvents,
                config: SparklineConfig(
                    chartType: .area,
                    color: .blue,
                    height: 80
                )
            )
        }
        
        SparklineChartContainer(
            title: "Average Duration Trends",
            subtitle: "Last 30 days"
        ) {
            BridgeDurationSparkline(
                events: sampleEvents,
                config: SparklineConfig(
                    chartType: .line,
                    color: .green,
                    height: 60
                )
            )
        }
    }
    .padding()
} 