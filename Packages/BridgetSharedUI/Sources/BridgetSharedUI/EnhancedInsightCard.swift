//
//  EnhancedInsightCard.swift
//  BridgetSharedUI
//
//  Created by AI Assistant on 1/15/25.
//

import SwiftUI
import BridgetCore

/**
 * Enhanced insight card with integrated sparkline visualization
 * 
 * This component provides a more sophisticated insight card that includes
 * mini sparkline charts to show trends and patterns alongside the key metrics.
 * 
 * Features:
 * - Integrated mini sparkline charts
 * - Trend indicators and color coding
 * - Accessibility support
 * - Responsive design
 */
public struct EnhancedInsightCard: View {
    public let title: String
    public let value: String
    public let subtitle: String
    public let color: Color
    public let sparklineData: [EnhancedSparklinePoint]
    
    public init(
        title: String,
        value: String,
        subtitle: String,
        color: Color,
        sparklineData: [EnhancedSparklinePoint] = []
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.color = color
        self.sparklineData = sparklineData
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with title and trend indicator
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if !sparklineData.isEmpty {
                    trendIndicator
                }
            }
            
            // Main value display
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            // Subtitle
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            // Mini sparkline chart
            if !sparklineData.isEmpty {
                miniSparklineChart
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(title): \(value), \(subtitle)"))
        .accessibilityHint(Text("Insight card showing \(title.lowercased()) with trend visualization"))
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
            }
        }
    }
    
    // MARK: - Mini Sparkline Chart
    
    private var miniSparklineChart: some View {
        EnhancedSparklineChart(
            dataPoints: sparklineData,
            config: SparklineConfig(
                chartType: .line,
                color: color,
                height: 32,
                showGrid: false,
                showTrendIndicator: false,
                showTooltips: false,
                animationDuration: 0.3
            )
        )
        .frame(height: 32)
    }
    
    // MARK: - Trend Calculation
    
    private func calculateTrend() -> (change: Double, symbol: String, color: Color)? {
        guard sparklineData.count >= 2 else { return nil }
        
        let recentValues = sparklineData.suffix(3).map(\.value)
        let olderValues = sparklineData.prefix(3).map(\.value)
        
        let recentAvg = recentValues.reduce(0, +) / Double(recentValues.count)
        let olderAvg = olderValues.reduce(0, +) / Double(olderValues.count)
        
        let change = recentAvg - olderAvg
        let percentChange = olderAvg > 0 ? (change / olderAvg) * 100 : 0
        
        if abs(percentChange) < 5 {
            return nil // No significant trend
        }
        
        let symbol = percentChange > 0 ? "arrow.up" : "arrow.down"
        let color: Color = percentChange > 0 ? .green : .red
        
        return (change: percentChange, symbol: symbol, color: color)
    }
}

// MARK: - Preview

#Preview {
    let sampleData = [
        EnhancedSparklinePoint(date: Date().addingTimeInterval(-86400 * 6), value: 5, label: "Day 1"),
        EnhancedSparklinePoint(date: Date().addingTimeInterval(-86400 * 5), value: 8, label: "Day 2"),
        EnhancedSparklinePoint(date: Date().addingTimeInterval(-86400 * 4), value: 3, label: "Day 3"),
        EnhancedSparklinePoint(date: Date().addingTimeInterval(-86400 * 3), value: 12, label: "Day 4"),
        EnhancedSparklinePoint(date: Date().addingTimeInterval(-86400 * 2), value: 7, label: "Day 5"),
        EnhancedSparklinePoint(date: Date().addingTimeInterval(-86400 * 1), value: 15, label: "Day 6"),
        EnhancedSparklinePoint(date: Date(), value: 10, label: "Today")
    ]
    
    VStack(spacing: 16) {
        EnhancedInsightCard(
            title: "Peak Day",
            value: "Wednesday",
            subtitle: "15 avg events",
            color: .orange,
            sparklineData: sampleData
        )
        
        EnhancedInsightCard(
            title: "Avg Duration",
            value: "12min",
            subtitle: "per opening",
            color: .purple,
            sparklineData: sampleData
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
} 