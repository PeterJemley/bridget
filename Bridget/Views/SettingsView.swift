//
//  SettingsView.swift
//  Bridget
//
//  Created by Peter Jemley on 6/18/25.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("showGeekFeatures") private var showGeekFeatures = false
    @State private var showDebugView = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("General") {
                    // Placeholder for future settings
                    Text("General settings coming soon...")
                        .foregroundColor(.secondary)
                        .italic()
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
                }
            }
            .navigationTitle("Settings")
        }
        .sheet(isPresented: $showDebugView) {
            DebugView()
        }
    }
}

#Preview {
    SettingsView()
}