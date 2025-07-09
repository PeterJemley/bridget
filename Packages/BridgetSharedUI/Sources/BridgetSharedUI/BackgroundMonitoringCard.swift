//
//  BackgroundMonitoringCard.swift
//  BridgetSharedUI
//
//  Created by Peter Jemley on 7/8/25.
//

import SwiftUI
import BridgetCore

public struct BackgroundMonitoringCard: View {
    @ObservedObject var backgroundAgent: BackgroundTrafficAgent
    @State private var showingAlerts = false
    
    public init(backgroundAgent: BackgroundTrafficAgent) {
        self.backgroundAgent = backgroundAgent
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .foregroundColor(.blue)
                Text("Background Monitoring")
                    .font(.headline)
                Spacer()
                
                // Status indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                    Text(backgroundAgent.monitoringStatus.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Status details
            VStack(spacing: 8) {
                HStack {
                    Text("Monitoring")
                    Spacer()
                    Text(backgroundAgent.isMonitoring ? "Active" : "Inactive")
                        .fontWeight(.medium)
                        .foregroundColor(backgroundAgent.isMonitoring ? .green : .red)
                }
                
                if let lastUpdate = backgroundAgent.lastUpdateTime {
                    HStack {
                        Text("Last Update")
                        Spacer()
                        Text(lastUpdate, style: .time)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    Text("Active Alerts")
                    Spacer()
                    Text("\(backgroundAgent.getActiveAlerts().count)")
                        .fontWeight(.medium)
                        .foregroundColor(backgroundAgent.getActiveAlerts().isEmpty ? .green : .orange)
                }
            }
            
            // Control buttons
            HStack(spacing: 12) {
                Button(action: {
                    if backgroundAgent.isMonitoring {
                        backgroundAgent.stopBackgroundMonitoring()
                    } else {
                        backgroundAgent.startBackgroundMonitoring()
                    }
                }) {
                    HStack {
                        Image(systemName: backgroundAgent.isMonitoring ? "stop.fill" : "play.fill")
                        Text(backgroundAgent.isMonitoring ? "Stop" : "Start")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(backgroundAgent.isMonitoring ? Color.red : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                
                Button(action: {
                    showingAlerts = true
                }) {
                    HStack {
                        Image(systemName: "bell.fill")
                        Text("Alerts")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
            
            // Recent alerts preview
            if !backgroundAgent.backgroundAlerts.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent Alerts")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ForEach(backgroundAgent.backgroundAlerts.prefix(3)) { alert in
                        HStack {
                            Image(systemName: alert.severity.systemImage)
                                .foregroundColor(severityColor(for: alert.severity))
                                .font(.caption)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(alert.message)
                                    .font(.caption)
                                    .lineLimit(2)
                                
                                Text(alert.timestamp, style: .time)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text(alert.type.rawValue)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(6)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .sheet(isPresented: $showingAlerts) {
            BackgroundAlertsView(backgroundAgent: backgroundAgent)
        }
    }
    
    private var statusColor: Color {
        switch backgroundAgent.monitoringStatus {
        case .inactive: return .gray
        case .active: return .green
        case .enhanced: return .blue
        case .expired: return .orange
        }
    }
    
    private func severityColor(for severity: AlertSeverity) -> Color {
        switch severity {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
}

struct BackgroundAlertsView: View {
    @ObservedObject var backgroundAgent: BackgroundTrafficAgent
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                if backgroundAgent.backgroundAlerts.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bell.slash")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        
                        Text("No Background Alerts")
                            .font(.headline)
                        
                        Text("Background monitoring will generate alerts when traffic conditions change or when you enter/exit a vehicle.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(backgroundAgent.backgroundAlerts) { alert in
                        AlertRow(alert: alert)
                    }
                }
            }
            .navigationTitle("Background Alerts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear All") {
                        backgroundAgent.clearAlerts()
                    }
                    .disabled(backgroundAgent.backgroundAlerts.isEmpty)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AlertRow: View {
    let alert: TrafficAlert
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: alert.severity.systemImage)
                .foregroundColor(severityColor(for: alert.severity))
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(alert.message)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    Text(alert.type.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(alert.timestamp, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private func severityColor(for severity: AlertSeverity) -> Color {
        switch severity {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
}

#Preview {
    BackgroundMonitoringCard(backgroundAgent: BackgroundTrafficAgent(
        trafficService: TrafficAwareRoutingService(),
        motionService: MotionDetectionService()
    ))
    .padding()
} 