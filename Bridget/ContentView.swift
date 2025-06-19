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
    
    @State private var showDebugView = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Bridget")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Seattle Drawbridge Monitor")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if events.isEmpty {
                    Text("No bridge data loaded yet")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Data Summary:")
                            .font(.headline)
                        
                        Text("• \(events.count) bridge events")
                        Text("• \(uniqueBridgeCount) unique bridges")
                        Text("• \(currentlyOpenCount) currently open")
                        
                        if let lastEvent = events.sorted(by: { $0.openDateTime > $1.openDateTime }).first {
                            Text("• Last event: \(lastEvent.openDateTime.formatted(.relative(presentation: .named)))")
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("• Bridges monitored:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(uniqueBridgeNames)
                                .font(.caption)
                                .foregroundColor(.blue)
                                .multilineTextAlignment(.leading)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
                
                Spacer()
                
                Button("Open Debug Console") {
                    showDebugView = true
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("Bridget")
            .sheet(isPresented: $showDebugView) {
                DebugView()
            }
        }
    }
    
    private var currentlyOpenCount: Int {
        events.filter(\.isCurrentlyOpen).count
    }
    
    private var uniqueBridgeCount: Int {
        Set(events.map(\.entityName)).count
    }
    
    private var uniqueBridgeNames: String {
        let names = Set(events.map(\.entityName))
        return names.sorted().joined(separator: ", ")
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [DrawbridgeEvent.self, DrawbridgeInfo.self], inMemory: true)
}
