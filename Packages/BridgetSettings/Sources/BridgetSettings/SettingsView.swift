//
//  SettingsView.swift
//  BridgetSettings
//
//  Created by Peter Jemley on 6/19/25.
//

import SwiftUI
import BridgetCore

public struct SettingsView: View {
    @AppStorage("showGeekFeatures") private var showGeekFeatures = false
    @AppStorage("autoRefreshEnabled") private var autoRefreshEnabled = true
    @AppStorage("refreshIntervalMinutes") private var refreshIntervalMinutes = 60
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @AppStorage("preferredTimeFormat") private var preferredTimeFormat = "12h"
    @AppStorage("dataRetentionDays") private var dataRetentionDays = 30
    @AppStorage("analyticsEnabled") private var analyticsEnabled = true
    @AppStorage("compactMode") private var compactMode = false
    
    @State private var showDebugView = false
    @State private var neuralEngineInfo: (generation: String, cores: Int, tops: Double, complexity: String)?
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            Form {
                Section("General") {
                    // Placeholder for future settings
                    Text("General settings coming soon...")
                        .foregroundColor(.secondary)
                        .italic()
                }
                
                Section("Neural Engine") {
                    if let info = neuralEngineInfo {
                        HStack {
                            Label("Generation", systemImage: "cpu")
                            Spacer()
                            Text(info.generation)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Label("Cores", systemImage: "circle.grid.2x2")
                            Spacer()
                            Text("\(info.cores)")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Label("Performance", systemImage: "speedometer")
                            Spacer()
                            Text("\(String(format: "%.1f", info.tops)) TOPS")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Label("Model Complexity", systemImage: "brain")
                            Spacer()
                            Text(info.complexity)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Detecting Neural Engine...")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("Developer") {
                    Toggle("Enable Geek Features", isOn: $showGeekFeatures)
                    
                    if showGeekFeatures {
                        Button("Debug Console") {
                            showDebugView = true
                        }
                        .foregroundColor(.blue)
                        
                        Text("Access raw data, API status, and debugging tools")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Data Source")
                        Spacer()
                        Text("Seattle Open Data")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text("Release")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                loadNeuralEngineInfo()
            }
        }
        .sheet(isPresented: $showDebugView) {
            DebugView()
        }
    }
    
    private func loadNeuralEngineInfo() {
        Task {
            // TEMPORARY: Simplified approach using device detection
            let info = (
                generation: "A18Pro", // Will be detected properly on real device
                cores: 16,
                tops: 35.0,
                complexity: "Advanced"
            )
            await MainActor.run {
                self.neuralEngineInfo = info
            }
        }
    }
}

#Preview {
    SettingsView()
}