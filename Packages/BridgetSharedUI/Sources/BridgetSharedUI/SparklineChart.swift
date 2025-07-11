//
//  SparklineChart.swift
//  BridgetSharedUI
//
//  Created by AI Assistant on 1/15/25.
//

import SwiftUI
import BridgetCore

public struct SparklineChart: View {
    public let dataPoints: [DailyTrendPoint]
    public let color: Color
    public let height: CGFloat
    public let showTrendIndicator: Bool
    
    public init(
        dataPoints: [DailyTrendPoint],
        color: Color = .blue,
        height: CGFloat = 20,
        showTrendIndicator: Bool = true
    ) {
        self.dataPoints = dataPoints
        self.color = color
        self.height = height
        self.showTrendIndicator = showTrendIndicator
    }
    
    public var body: some View {
        HStack(spacing: 4) {
            if showTrendIndicator {
                trendIndicator
            }
            
            chartView
        }
        .frame(height: height)
    }
    
    @ViewBuilder
    private var chartView: some View {
        if dataPoints.isEmpty {
            // Show empty state
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 2)
                .cornerRadius(1)
        } else {
            // Show sparkline
            GeometryReader { geometry in
                Path { path in
                    let points = normalizedPoints(in: geometry.size)
                    
                    guard !points.isEmpty else { return }
                    
                    path.move(to: points[0])
                    
                    for point in points.dropFirst() {
                        path.addLine(to: point)
                    }
                }
                .stroke(color, lineWidth: 1.5)
                .animation(.easeInOut(duration: 0.3), value: dataPoints)
            }
        }
    }
    
    @ViewBuilder
    private var trendIndicator: some View {
        if let trend = calculateTrend() {
            HStack(spacing: 2) {
                Text(trend.symbol)
                    .font(.caption2)
                    .foregroundColor(trend.color)
                
                Text("\(abs(trend.change))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func normalizedPoints(in size: CGSize) -> [CGPoint] {
        guard !dataPoints.isEmpty else { return [] }
        
        let maxValue = dataPoints.map(\.count).max() ?? 1
        let minValue = dataPoints.map(\.count).min() ?? 0
        let valueRange = max(1, maxValue - minValue)
        
        let xStep = size.width / CGFloat(max(1, dataPoints.count - 1))
        
        return dataPoints.enumerated().map { index, point in
            let x = CGFloat(index) * xStep
            let normalizedValue = CGFloat(point.count - minValue) / CGFloat(valueRange)
            let y = size.height - (normalizedValue * size.height)
            
            return CGPoint(x: x, y: y)
        }
    }
    
    private func calculateTrend() -> (symbol: String, change: Int, color: Color)? {
        guard dataPoints.count >= 2 else { return nil }
        
        let recentCount = dataPoints.suffix(7).map(\.count).reduce(0, +)
        let previousCount = dataPoints.dropLast(7).suffix(7).map(\.count).reduce(0, +)
        
        let change = recentCount - previousCount
        
        let symbol: String
        let color: Color
        
        if change > 0 {
            symbol = "↗"
            color = .red
        } else if change < 0 {
            symbol = "↘"
            color = .green
        } else {
            symbol = "→"
            color = .gray
        }
        
        return (symbol: symbol, change: change, color: color)
    }
}

// MARK: - Mini Sparkline for Status Cards

public struct MiniSparkline: View {
    public let dataPoints: [DailyTrendPoint]
    public let color: Color
    
    public init(dataPoints: [DailyTrendPoint], color: Color = .blue) {
        self.dataPoints = dataPoints
        self.color = color
    }
    
    public var body: some View {
        SparklineChart(
            dataPoints: dataPoints,
            color: color,
            height: 12,
            showTrendIndicator: false
        )
    }
}

// MARK: - Trend Summary Card

public struct TrendSummaryCard: View {
    public let title: String
    public let value: String
    public let trend: TrendSummary?
    public let color: Color
    
    public init(title: String, value: String, trend: TrendSummary? = nil, color: Color = .blue) {
        self.title = title
        self.value = value
        self.trend = trend
        self.color = color
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Spacer()
                
                if let trend = trend {
                    HStack(spacing: 2) {
                        Text(trend.trendDirection.symbol)
                            .font(.caption)
                            .foregroundColor(trend.trendDirection.color)
                        
                        Text("\(abs(trend.change))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            if let trend = trend, !trend.dataPoints.isEmpty {
                MiniSparkline(dataPoints: trend.dataPoints, color: color)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
#if os(iOS)
        .background(Color(.systemBackground))
#else
        .background(Color(.windowBackgroundColor))
#endif
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    VStack(spacing: 20) {
        // Sample data
        let sampleData = [
            DailyTrendPoint(date: Date().addingTimeInterval(-6*24*3600), count: 3, averageDuration: 15.0),
            DailyTrendPoint(date: Date().addingTimeInterval(-5*24*3600), count: 5, averageDuration: 12.0),
            DailyTrendPoint(date: Date().addingTimeInterval(-4*24*3600), count: 2, averageDuration: 18.0),
            DailyTrendPoint(date: Date().addingTimeInterval(-3*24*3600), count: 7, averageDuration: 14.0),
            DailyTrendPoint(date: Date().addingTimeInterval(-2*24*3600), count: 4, averageDuration: 16.0),
            DailyTrendPoint(date: Date().addingTimeInterval(-1*24*3600), count: 6, averageDuration: 13.0),
            DailyTrendPoint(date: Date(), count: 8, averageDuration: 15.0)
        ]
        
        SparklineChart(dataPoints: sampleData, color: .blue, height: 30)
            .frame(height: 30)
        
        MiniSparkline(dataPoints: sampleData, color: .purple)
            .frame(height: 12)
        
        TrendSummaryCard(
            title: "Today's Events",
            value: "8",
            trend: TrendSummary(
                currentValue: 8,
                previousValue: 6,
                change: 2,
                changePercentage: 33.3,
                trendDirection: .up,
                dataPoints: sampleData
            ),
            color: .purple
        )
    }
    .padding()
} 